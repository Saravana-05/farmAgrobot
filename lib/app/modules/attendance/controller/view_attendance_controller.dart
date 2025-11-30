// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:excel/excel.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'dart:io';

// import '../../../data/models/employee/emp_model.dart';
// import '../../../data/services/attendance/attendance_service.dart';
// import '../../../data/services/employee/emp_service.dart';
// import '../../../global_widgets/custom_snackbar/snackbar.dart';

// enum AttendanceStatus {
//   notMarked,
//   present,
//   absent,
//   halfDay,
//   leave,
//   holiday,
// }

// extension AttendanceStatusExtension on AttendanceStatus {
//   String get value {
//     switch (this) {
//       case AttendanceStatus.present:
//         return 'present';
//       case AttendanceStatus.absent:
//         return 'absent';
//       case AttendanceStatus.halfDay:
//         return 'half_day';
//       case AttendanceStatus.leave:
//         return 'leave';
//       case AttendanceStatus.holiday:
//         return 'holiday';
//       default:
//         return 'not_marked';
//     }
//   }

//   String get displayName {
//     switch (this) {
//       case AttendanceStatus.present:
//         return 'Present';
//       case AttendanceStatus.absent:
//         return 'Absent';
//       case AttendanceStatus.halfDay:
//         return 'Half Day';
//       case AttendanceStatus.leave:
//         return 'Leave';
//       case AttendanceStatus.holiday:
//         return 'Holiday';
//       default:
//         return 'Not Marked';
//     }
//   }

//   static AttendanceStatus fromString(String status) {
//     switch (status.toLowerCase()) {
//       case 'present':
//         return AttendanceStatus.present;
//       case 'absent':
//         return AttendanceStatus.absent;
//       case 'half_day':
//         return AttendanceStatus.halfDay;
//       case 'leave':
//         return AttendanceStatus.leave;
//       case 'holiday':
//         return AttendanceStatus.holiday;
//       default:
//         return AttendanceStatus.notMarked;
//     }
//   }
// }

// class WeeklyAttendanceController extends GetxController {
//   final EmployeeService _employeeService = Get.find<EmployeeService>();
//   final AttendanceService _attendanceService = Get.find<AttendanceService>();

//   // Observable variables
//   var isLoading = false.obs;
//   var isSaving = false.obs;
//   var hasChanges = false.obs;
  
//   // Week navigation
//   var currentWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)).obs;
  
//   // Data
//   var employees = <Employee>[].obs;
//   var weeklyAttendance = <String, Map<String, AttendanceStatus>>{}.obs; // employeeId -> {date -> status}
//   var originalAttendance = <String, Map<String, AttendanceStatus>>{}.obs; // For tracking changes
  
//   // Summary counts
//   var totalEmployees = 0.obs;
//   var totalPresent = 0.obs;
//   var totalAbsent = 0.obs;
//   var totalHalfDay = 0.obs;
//   var totalLeave = 0.obs;

//   // Week days data
//   List<Map<String, dynamic>> get weekDays {
//     List<Map<String, dynamic>> days = [];
//     DateTime startDate = currentWeekStart.value;
    
//     for (int i = 0; i < 7; i++) {
//       DateTime date = startDate.add(Duration(days: i));
//       days.add({
//         'dayName': DateFormat('EEE').format(date).toUpperCase(),
//         'date': DateFormat('dd').format(date),
//         'dateTime': date,
//         'fullDate': DateFormat('yyyy-MM-dd').format(date),
//       });
//     }
//     return days;
//   }

//   @override
//   void onInit() {
//     super.onInit();
//     _initializeWeekStart();
//     loadEmployees();
//   }

//   void _initializeWeekStart() {
//     DateTime now = DateTime.now();
//     int weekday = now.weekday; // 1 = Monday, 7 = Sunday
//     DateTime mondayOfCurrentWeek = now.subtract(Duration(days: weekday - 1));
//     currentWeekStart.value = DateTime(mondayOfCurrentWeek.year, mondayOfCurrentWeek.month, mondayOfCurrentWeek.day);
//   }

//   // ============= DATA LOADING METHODS =============

//   Future<void> loadEmployees() async {
//     try {
//       isLoading.value = true;
      
//       final response = await EmployeeService.getEmployeeList(
//         page: 1,
//         limit: 1000, // Get all employees
//         active: true,
//       );

//       if (response['success'] == true) {
//         final data = response['data'];
//         if (data != null) {
//           final employeesData = data['employees'] as List? ?? [];
//           employees.value = _employeeService.parseEmployeeList(employeesData);
//           totalEmployees.value = employees.length;
          
//           await loadWeeklyAttendance();
//         }
//       } else {
//         _showErrorMessage(response['message'] ?? 'Failed to load employees');
//       }
//     } catch (e) {
//       _showErrorMessage('Error loading employees: ${e.toString()}');
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   Future<void> loadWeeklyAttendance() async {
//     try {
//       DateTime startDate = currentWeekStart.value;
//       DateTime endDate = startDate.add(Duration(days: 6));
      
//       final response = await _attendanceService.getWeeklyAttendance(
//         startDate: _formatDateForApi(startDate),
//         endDate: _formatDateForApi(endDate),
//       );

//       if (response['success'] == true) {
//         final data = response['data'] as Map<String, dynamic>? ?? {};
//         _parseWeeklyAttendanceData(data);
//         _calculateSummary();
//         _storeOriginalAttendance();
//         hasChanges.value = false;
//       } else {
//         // Initialize empty attendance if no data found
//         _initializeEmptyAttendance();
//       }
//     } catch (e) {
//       _showErrorMessage('Error loading attendance: ${e.toString()}');
//       _initializeEmptyAttendance();
//     }
//   }

//   void _parseWeeklyAttendanceData(Map<String, dynamic> data) {
//     weeklyAttendance.clear();
    
//     // Initialize all employees with not marked status
//     for (Employee employee in employees) {
//       weeklyAttendance[employee.id!] = {};
//       for (Map<String, dynamic> day in weekDays) {
//         String dateKey = day['fullDate'];
//         weeklyAttendance[employee.id!]![dateKey] = AttendanceStatus.notMarked;
//       }
//     }
    
//     // Parse actual attendance data
//     if (data['attendance'] != null) {
//       Map<String, dynamic> attendanceData = data['attendance'];
      
//       attendanceData.forEach((employeeId, employeeAttendance) {
//         if (weeklyAttendance.containsKey(employeeId)) {
//           Map<String, dynamic> employeeDays = employeeAttendance as Map<String, dynamic>;
//           employeeDays.forEach((date, status) {
//             weeklyAttendance[employeeId]![date] = AttendanceStatusExtension.fromString(status.toString());
//           });
//         }
//       });
//     }
//   }

//   void _initializeEmptyAttendance() {
//     weeklyAttendance.clear();
//     for (Employee employee in employees) {
//       weeklyAttendance[employee.id!] = {};
//       for (Map<String, dynamic> day in weekDays) {
//         String dateKey = day['fullDate'];
//         weeklyAttendance[employee.id!]![dateKey] = AttendanceStatus.notMarked;
//       }
//     }
//     _calculateSummary();
//     _storeOriginalAttendance();
//   }

//   void _storeOriginalAttendance() {
//     originalAttendance.clear();
//     weeklyAttendance.forEach((employeeId, attendance) {
//       originalAttendance[employeeId] = Map<String, AttendanceStatus>.from(attendance);
//     });
//   }

// // ============= WEEK NAVIGATION METHODS =============

//   void goToPreviousWeek() {
//     currentWeekStart.value = currentWeekStart.value.subtract(Duration(days: 7));
//     loadWeeklyAttendance();
//   }

//   void goToNextWeek() {
//     currentWeekStart.value = currentWeekStart.value.add(Duration(days: 7));
//     loadWeeklyAttendance();
//   }

//   void setWeekByDate(DateTime date) {
//     int weekday = date.weekday; // 1 = Monday, 7 = Sunday
//     DateTime mondayOfWeek = date.subtract(Duration(days: weekday - 1));
//     currentWeekStart.value = DateTime(mondayOfWeek.year, mondayOfWeek.month, mondayOfWeek.day);
//     loadWeeklyAttendance();
//   }

//   String getWeekRangeText() {
//     DateTime endDate = currentWeekStart.value.add(Duration(days: 6));
//     return '${DateFormat('MMM dd').format(currentWeekStart.value)} - ${DateFormat('MMM dd, yyyy').format(endDate)}';
//   }

//   // ============= ATTENDANCE MANAGEMENT METHODS =============

//   AttendanceStatus getAttendanceStatus(String employeeId, DateTime date) {
//     String dateKey = DateFormat('yyyy-MM-dd').format(date);
//     return weeklyAttendance[employeeId]?[dateKey] ?? AttendanceStatus.notMarked;
//   }

//   void setAttendanceStatus(String employeeId, DateTime date, AttendanceStatus status) {
//     String dateKey = DateFormat('yyyy-MM-dd').format(date);
    
//     if (weeklyAttendance[employeeId] == null) {
//       weeklyAttendance[employeeId] = {};
//     }
    
//     weeklyAttendance[employeeId]![dateKey] = status;
//     _calculateSummary();
//     _checkForChanges();
//   }

//   void markAllEmployees(AttendanceStatus status) {
//     for (Employee employee in employees) {
//       for (Map<String, dynamic> day in weekDays) {
//         DateTime date = day['dateTime'];
//         // Don't mark future dates
//         if (!date.isAfter(DateTime.now())) {
//           setAttendanceStatus(employee.id!, date, status);
//         }
//       }
//     }
//     _showSuccessMessage('All employees marked as ${status.displayName}');
//   }

//   void clearAllAttendance() {
//     for (Employee employee in employees) {
//       for (Map<String, dynamic> day in weekDays) {
//         DateTime date = day['dateTime'];
//         if (!date.isAfter(DateTime.now())) {
//           setAttendanceStatus(employee.id!, date, AttendanceStatus.notMarked);
//         }
//       }
//     }
//     _showSuccessMessage('All attendance cleared');
//   }

//   bool isToday(DateTime date) {
//     DateTime now = DateTime.now();
//     return date.year == now.year && date.month == now.month && date.day == now.day;
//   }

//   // ============= SAVE AND RESET METHODS =============

//   Future<void> saveAttendance() async {
//     try {
//       isSaving.value = true;
      
//       // Prepare attendance data for API
//       Map<String, Map<String, String>> attendanceData = {};
      
//       weeklyAttendance.forEach((employeeId, attendance) {
//         Map<String, String> employeeAttendance = {};
//         attendance.forEach((date, status) {
//           if (status != AttendanceStatus.notMarked) {
//             employeeAttendance[date] = status.value;
//           }
//         });
//         if (employeeAttendance.isNotEmpty) {
//           attendanceData[employeeId] = employeeAttendance;
//         }
//       });

//       DateTime startDate = currentWeekStart.value;
//       DateTime endDate = startDate.add(Duration(days: 6));
      
//       final response = await _attendanceService.saveWeeklyAttendance(
//         startDate: _formatDateForApi(startDate),
//         endDate: _formatDateForApi(endDate),
//         attendanceData: attendanceData,
//       );

//       if (response['success'] == true) {
//         _storeOriginalAttendance();
//         hasChanges.value = false;
//         _showSuccessMessage('Attendance saved successfully');
//       } else {
//         _showErrorMessage(response['message'] ?? 'Failed to save attendance');
//       }
//     } catch (e) {
//       _showErrorMessage('Error saving attendance: ${e.toString()}');
//     } finally {
//       isSaving.value = false;
//     }
//   }

//   void resetChanges() {
//     weeklyAttendance.clear();
//     originalAttendance.forEach((employeeId, attendance) {
//       weeklyAttendance[employeeId] = Map<String, AttendanceStatus>.from(attendance);
//     });
//     _calculateSummary();
//     hasChanges.value = false;
//     _showSuccessMessage('Changes reset successfully');
//   }

//   Future<void> refreshData() async {
//     await loadEmployees();
//   }

//   // ============= EXPORT METHODS =============

//   Future<void> exportWeeklyAttendance() async {
//     try {
//       // Request storage permission
//       final status = await Permission.storage.request();
//       if (!status.isGranted) {
//         _showErrorMessage('Storage permission required to export file');
//         return;
//       }

//       // Create Excel workbook
//       var excel = Excel.createExcel();
//       Sheet sheetObject = excel['Weekly Attendance'];
      
//       // Remove default sheet if exists
//       if (excel.sheets.containsKey('Sheet1')) {
//         excel.delete('Sheet1');
//       }

//       // Add headers
//       List<String> headers = ['Employee Name', 'Employee ID'];
//       for (Map<String, dynamic> day in weekDays) {
//         headers.add('${day['dayName']} ${day['date']}');
//       }
      
//       for (int i = 0; i < headers.length; i++) {
//         var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
//         cell.value = headers[i] as CellValue?;
//         cell.cellStyle = CellStyle(
//           bold: true,
//           backgroundColorHex: '#4CAF50',
//           fontColorHex: '#FFFFFF',
//         );
//       }

//       // Add employee data
//       for (int empIndex = 0; empIndex < employees.length; empIndex++) {
//         Employee employee = employees[empIndex];
//         int rowIndex = empIndex + 1;
        
//         // Employee name and ID
//         sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = employee.name as CellValue?;
//         sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = employee.employeeId ?? '';
        
//         // Attendance for each day
//         for (int dayIndex = 0; dayIndex < weekDays.length; dayIndex++) {
//           Map<String, dynamic> day = weekDays[dayIndex];
//           DateTime date = day['dateTime'];
//           AttendanceStatus status = getAttendanceStatus(employee.id!, date);
          
//           var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: dayIndex + 2, rowIndex: rowIndex));
//           cell.value = status.displayName as CellValue?;
          
//           // Color code cells based on status
//           String colorHex = '#FFFFFF';
//           switch (status) {
//             case AttendanceStatus.present:
//               colorHex = '#E8F5E8';
//               break;
//             case AttendanceStatus.absent:
//               colorHex = '#FFEBEE';
//               break;
//             case AttendanceStatus.halfDay:
//               colorHex = '#FFF3E0';
//               break;
//             case AttendanceStatus.leave:
//               colorHex = '#F3E5F5';
//               break;
//             case AttendanceStatus.holiday:
//               colorHex = '#E3F2FD';
//               break;
//             default:
//               colorHex = '#F5F5F5';
//           }
          
//           cell.cellStyle = CellStyle(backgroundColorHex: colorHex);
//         }
//       }

//       // Add summary row
//       int summaryRowIndex = employees.length + 2;
//       sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRowIndex)).value = 'SUMMARY' as CellValue?;
//       sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRowIndex)).value = 'Total: ${totalEmployees.value}' as CellValue?;
      
//       sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: summaryRowIndex)).value = 'Present: ${totalPresent.value}' as CellValue?;
//       sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: summaryRowIndex)).value = 'Absent: ${totalAbsent.value}' as CellValue?;
//       sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: summaryRowIndex)).value = 'Half Day: ${totalHalfDay.value}' as CellValue?;
//       sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: summaryRowIndex)).value = 'Leave: ${totalLeave.value}' as CellValue?;

//       // Save file
//       Directory? directory = await getExternalStorageDirectory();
//       String fileName = 'Weekly_Attendance_${DateFormat('yyyy-MM-dd').format(currentWeekStart.value)}.xlsx';
//       String filePath = '${directory!.path}/$fileName';
      
//       File file = File(filePath);
//       await file.writeAsBytes(excel.encode()!);
      
//       _showSuccessMessage('Attendance exported to: $fileName');
//     } catch (e) {
//       _showErrorMessage('Error exporting attendance: ${e.toString()}');
//     }
//   }

//   // ============= UTILITY METHODS =============

//   void _calculateSummary() {
//     int present = 0, absent = 0, halfDay = 0, leave = 0;
    
//     for (Employee employee in employees) {
//       for (Map<String, dynamic> day in weekDays) {
//         DateTime date = day['dateTime'];
//         if (!date.isAfter(DateTime.now())) {
//           AttendanceStatus status = getAttendanceStatus(employee.id!, date);
//           switch (status) {
//             case AttendanceStatus.present:
//               present++;
//               break;
//             case AttendanceStatus.absent:
//               absent++;
//               break;
//             case AttendanceStatus.halfDay:
//               halfDay++;
//               break;
//             case AttendanceStatus.leave:
//               leave++;
//               break;
//             default:
//               break;
//           }
//         }
//       }
//     }
    
//     totalPresent.value = present;
//     totalAbsent.value = absent;
//     totalHalfDay.value = halfDay;
//     totalLeave.value = leave;
//   }

//   void _checkForChanges() {
//     bool hasChanged = false;
    
//     for (String employeeId in weeklyAttendance.keys) {
//       Map<String, AttendanceStatus>? original = originalAttendance[employeeId];
//       Map<String, AttendanceStatus>? current = weeklyAttendance[employeeId];
      
//       if (original == null || current == null) {
//         hasChanged = true;
//         break;
//       }
      
//       for (String date in current.keys) {
//         if (original[date] != current[date]) {
//           hasChanged = true;
//           break;
//         }
//       }
      
//       if (hasChanged) break;
//     }
    
//     hasChanges.value = hasChanged;
//   }

//   String _formatDateForApi(DateTime date) {
//     return DateFormat('yyyy-MM-dd').format(date);
//   }

//   void _showSuccessMessage(String message) {
//     CustomSnackbar.showSuccess(message: message, title: '');
//   }

//   void _showErrorMessage(String message) {
//     CustomSnackbar.showError(message: message, title: '');
//   }

//   @override
//   void onClose() {
//     // Clean up resources if needed
//     super.onClose();
//   }
// }