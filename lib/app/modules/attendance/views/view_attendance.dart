// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import '../../../core/values/app_colors.dart';
// import '../../../data/models/employee/emp_model.dart';
// import '../controller/view_attendance_controller.dart';


// class WeeklyAttendanceScreen extends StatelessWidget {
//   final WeeklyAttendanceController controller = Get.put(WeeklyAttendanceController());

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Weekly Attendance'),
//         backgroundColor: kPrimaryColor,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         actions: [
//           // Save Button
//           Obx(() => controller.hasChanges.value
//               ? IconButton(
//                   icon: controller.isSaving.value
//                       ? SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors.white,
//                           ),
//                         )
//                       : Icon(Icons.save),
//                   onPressed: controller.isSaving.value ? null : controller.saveAttendance,
//                 )
//               : SizedBox.shrink()),
          
//           // More Options
//           PopupMenuButton<String>(
//             icon: Icon(Icons.more_vert),
//             itemBuilder: (context) => [
//               PopupMenuItem(
//                 value: 'export',
//                 child: Row(
//                   children: [
//                     Icon(Icons.download, color: kPrimaryColor),
//                     SizedBox(width: 8),
//                     Text('Export'),
//                   ],
//                 ),
//               ),
//               PopupMenuItem(
//                 value: 'reset',
//                 child: Row(
//                   children: [
//                     Icon(Icons.refresh, color: Colors.orange),
//                     SizedBox(width: 8),
//                     Text('Reset Changes'),
//                   ],
//                 ),
//               ),
//             ],
//             onSelected: (value) {
//               switch (value) {
//                 case 'export':
//                   controller.exportWeeklyAttendance();
//                   break;
//                 case 'reset':
//                   controller.resetChanges();
//                   break;
//               }
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Week Navigation Header
//           _buildWeekNavigationHeader(),
          
//           // Attendance Summary
//           _buildAttendanceSummary(),
          
//           // Attendance Grid
//           Expanded(
//             child: Obx(() => _buildAttendanceGrid()),
//           ),
//         ],
//       ),
//       floatingActionButton: _buildFloatingActionButtons(),
//     );
//   }

//   Widget _buildWeekNavigationHeader() {
//     return Container(
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 5,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           // Week Navigation
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               IconButton(
//                 icon: Icon(Icons.chevron_left, color: kPrimaryColor),
//                 onPressed: controller.goToPreviousWeek,
//               ),
//               Expanded(
//                 child: Obx(() => GestureDetector(
//                   onTap: () => _showWeekPicker(Get.context!),
//                   child: Container(
//                     padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     decoration: BoxDecoration(
//                       color: kPrimaryColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.calendar_today, color: kPrimaryColor, size: 16),
//                         SizedBox(width: 8),
//                         Text(
//                           controller.getWeekRangeText(),
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: kPrimaryColor,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                       ],
//                     ),
//                   ),
//                 )),
//               ),
//               IconButton(
//                 icon: Icon(Icons.chevron_right, color: kPrimaryColor),
//                 onPressed: controller.goToNextWeek,
//               ),
//             ],
//           ),
          
//           // Quick Actions
//           SizedBox(height: 12),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _buildQuickActionButton(
//                 'Mark All Present',
//                 Icons.check_circle,
//                 Colors.green,
//                 () => controller.markAllEmployees(AttendanceStatus.present),
//               ),
//               _buildQuickActionButton(
//                 'Mark All Absent',
//                 Icons.cancel,
//                 Colors.red,
//                 () => controller.markAllEmployees(AttendanceStatus.absent),
//               ),
//               _buildQuickActionButton(
//                 'Clear All',
//                 Icons.clear,
//                 Colors.orange,
//                 () => controller.clearAllAttendance(),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
//     return InkWell(
//       onTap: onPressed,
//       borderRadius: BorderRadius.circular(8),
//       child: Container(
//         padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: color.withOpacity(0.3)),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, color: color, size: 16),
//             SizedBox(width: 4),
//             Text(
//               text,
//               style: TextStyle(
//                 color: color,
//                 fontWeight: FontWeight.w600,
//                 fontSize: 12,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAttendanceSummary() {
//     return Obx(() => Container(
//       margin: EdgeInsets.all(16),
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [kPrimaryColor.withOpacity(0.1), kPrimaryColor.withOpacity(0.05)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _buildSummaryItem('Total', '${controller.totalEmployees.value}', Icons.people, kPrimaryColor),
//           _buildSummaryItem('Present', '${controller.totalPresent.value}', Icons.check_circle, Colors.green),
//           _buildSummaryItem('Absent', '${controller.totalAbsent.value}', Icons.cancel, Colors.red),
//           _buildSummaryItem('Half Day', '${controller.totalHalfDay.value}', Icons.schedule, Colors.orange),
//         ],
//       ),
//     ));
//   }

//   Widget _buildSummaryItem(String label, String count, IconData icon, Color color) {
//     return Column(
//       children: [
//         Icon(icon, color: color, size: 24),
//         SizedBox(height: 4),
//         Text(
//           count,
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 12,
//             color: Colors.grey[600],
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildAttendanceGrid() {
//     if (controller.isLoading.value) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(color: kPrimaryColor),
//             SizedBox(height: 16),
//             Text('Loading attendance data...'),
//           ],
//         ),
//       );
//     }

//     if (controller.employees.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.people_outline, size: 64, color: Colors.grey),
//             SizedBox(height: 16),
//             Text('No employees found'),
//             SizedBox(height: 8),
//             ElevatedButton(
//               onPressed: controller.loadEmployees,
//               child: Text('Refresh'),
//             ),
//           ],
//         ),
//       );
//     }

//     return SingleChildScrollView(
//       padding: EdgeInsets.all(16),
//       child: Column(
//         children: [
//           // Header Row (Days)
//           Container(
//             decoration: BoxDecoration(
//               color: kPrimaryColor,
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(8),
//                 topRight: Radius.circular(8),
//               ),
//             ),
//             child: Row(
//               children: [
//                 // Employee Name Header
//                 Container(
//                   width: 120,
//                   padding: EdgeInsets.all(12),
//                   child: Text(
//                     'Employee',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ),
//                 // Day Headers
//                 ...controller.weekDays.map((day) => Expanded(
//                   child: Container(
//                     padding: EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       border: Border(
//                         left: BorderSide(color: Colors.white.withOpacity(0.3)),
//                       ),
//                     ),
//                     child: Column(
//                       children: [
//                         Text(
//                           day['dayName'],
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 12,
//                           ),
//                         ),
//                         Text(
//                           day['date'],
//                           style: TextStyle(
//                             color: Colors.white.withOpacity(0.8),
//                             fontSize: 10,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 )).toList(),
//               ],
//             ),
//           ),
          
//           // Employee Rows
//           ...controller.employees.asMap().entries.map((entry) {
//             int index = entry.key;
//             Employee employee = entry.value;
            
//             return Container(
//               decoration: BoxDecoration(
//                 color: index % 2 == 0 ? Colors.grey[50] : Colors.white,
//                 border: Border(
//                   bottom: BorderSide(color: Colors.grey[200]!),
//                   left: BorderSide(color: Colors.grey[200]!),
//                   right: BorderSide(color: Colors.grey[200]!),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   // Employee Name Cell
//                   Container(
//                     width: 120,
//                     padding: EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       border: Border(
//                         right: BorderSide(color: Colors.grey[200]!),
//                       ),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           employee.name,
//                           style: TextStyle(
//                             fontWeight: FontWeight.w600,
//                             fontSize: 13,
//                           ),
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         if (employee.employeeId != null)
//                           Text(
//                             employee.employeeId!,
//                             style: TextStyle(
//                               color: Colors.grey[600],
//                               fontSize: 10,
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
                  
//                   // Attendance Cells for each day
//                   ...controller.weekDays.asMap().entries.map((dayEntry) {
//                     int dayIndex = dayEntry.key;
//                     Map<String, dynamic> dayInfo = dayEntry.value;
//                     DateTime date = dayInfo['dateTime'];
                    
//                     return Expanded(
//                       child: _buildAttendanceCell(employee, date, dayIndex),
//                     );
//                   }).toList(),
//                 ],
//               ),
//             );
//           }).toList(),
//         ],
//       ),
//     );
//   }

//   Widget _buildAttendanceCell(Employee employee, DateTime date, int dayIndex) {
//     return Obx(() {
//       AttendanceStatus status = controller.getAttendanceStatus(employee.id!, date);
//       bool isToday = controller.isToday(date);
//       bool isFutureDate = date.isAfter(DateTime.now());
      
//       return GestureDetector(
//         onTap: isFutureDate ? null : () => _showAttendanceOptions(employee, date),
//         child: Container(
//           height: 60,
//           decoration: BoxDecoration(
//             color: _getStatusBackgroundColor(status, isToday),
//             border: Border(
//               left: BorderSide(color: Colors.grey[200]!),
//             ),
//           ),
//           child: Stack(
//             children: [
//               Center(
//                 child: _getStatusIcon(status, isFutureDate),
//               ),
//               if (isToday)
//                 Positioned(
//                   top: 4,
//                   right: 4,
//                   child: Container(
//                     width: 8,
//                     height: 8,
//                     decoration: BoxDecoration(
//                       color: kPrimaryColor,
//                       shape: BoxShape.circle,
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       );
//     });
//   }

//   Widget _getStatusIcon(AttendanceStatus status, bool isFutureDate) {
//     if (isFutureDate) {
//       return Icon(Icons.schedule, color: Colors.grey[400], size: 20);
//     }
    
//     switch (status) {
//       case AttendanceStatus.present:
//         return Icon(Icons.check_circle, color: Colors.green, size: 24);
//       case AttendanceStatus.absent:
//         return Icon(Icons.cancel, color: Colors.red, size: 24);
//       case AttendanceStatus.halfDay:
//         return Icon(Icons.schedule, color: Colors.orange, size: 24);
//       case AttendanceStatus.leave:
//         return Icon(Icons.event_busy, color: Colors.purple, size: 24);
//       case AttendanceStatus.holiday:
//         return Icon(Icons.celebration, color: Colors.blue, size: 24);
//       default:
//         return Icon(Icons.help_outline, color: Colors.grey, size: 20);
//     }
//   }

//   Color _getStatusBackgroundColor(AttendanceStatus status, bool isToday) {
//     Color baseColor;
//     switch (status) {
//       case AttendanceStatus.present:
//         baseColor = Colors.green;
//         break;
//       case AttendanceStatus.absent:
//         baseColor = Colors.red;
//         break;
//       case AttendanceStatus.halfDay:
//         baseColor = Colors.orange;
//         break;
//       case AttendanceStatus.leave:
//         baseColor = Colors.purple;
//         break;
//       case AttendanceStatus.holiday:
//         baseColor = Colors.blue;
//         break;
//       default:
//         baseColor = Colors.grey;
//     }
    
//     return baseColor.withOpacity(isToday ? 0.2 : 0.1);
//   }

//   void _showAttendanceOptions(Employee employee, DateTime date) {
//     Get.bottomSheet(
//       Container(
//         padding: EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(20),
//             topRight: Radius.circular(20),
//           ),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: Colors.grey[300],
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             SizedBox(height: 20),
//             Text(
//               'Mark attendance for ${employee.name}',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: 8),
//             Text(
//               DateFormat('EEEE, MMM dd, yyyy').format(date),
//               style: TextStyle(
//                 color: Colors.grey[600],
//               ),
//             ),
//             SizedBox(height: 20),
            
//             // Attendance Options
//             GridView.count(
//               shrinkWrap: true,
//               crossAxisCount: 2,
//               childAspectRatio: 2,
//               mainAxisSpacing: 12,
//               crossAxisSpacing: 12,
//               children: [
//                 _buildAttendanceOption(
//                   'Present',
//                   Icons.check_circle,
//                   Colors.green,
//                   () => controller.setAttendanceStatus(employee.id!, date, AttendanceStatus.present),
//                 ),
//                 _buildAttendanceOption(
//                   'Absent',
//                   Icons.cancel,
//                   Colors.red,
//                   () => controller.setAttendanceStatus(employee.id!, date, AttendanceStatus.absent),
//                 ),
//                 _buildAttendanceOption(
//                   'Half Day',
//                   Icons.schedule,
//                   Colors.orange,
//                   () => controller.setAttendanceStatus(employee.id!, date, AttendanceStatus.halfDay),
//                 ),
//                 _buildAttendanceOption(
//                   'Leave',
//                   Icons.event_busy,
//                   Colors.purple,
//                   () => controller.setAttendanceStatus(employee.id, date, AttendanceStatus.leave),
//                 ),
//               ],
//             ),
            
//             SizedBox(height: 20),
//             Row(
//               children: [
//                 Expanded(
//                   child: TextButton(
//                     onPressed: () => Get.back(),
//                     child: Text('Cancel'),
//                   ),
//                 ),
//                 SizedBox(width: 12),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: () {
//                       controller.setAttendanceStatus(employee.id!, date, AttendanceStatus.notMarked);
//                       Get.back();
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.grey,
//                     ),
//                     child: Text('Clear', style: TextStyle(color: Colors.white)),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAttendanceOption(String title, IconData icon, Color color, VoidCallback onTap) {
//     return InkWell(
//       onTap: () {
//         onTap();
//         Get.back();
//       },
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: color.withOpacity(0.3)),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: color, size: 28),
//             SizedBox(height: 4),
//             Text(
//               title,
//               style: TextStyle(
//                 color: color,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildFloatingActionButtons() {
//     return Obx(() => Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         if (controller.hasChanges.value)
//           FloatingActionButton(
//             heroTag: "save",
//             onPressed: controller.isSaving.value ? null : controller.saveAttendance,
//             backgroundColor: Colors.green,
//             child: controller.isSaving.value
//                 ? SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
//                   )
//                 : Icon(Icons.save, color: Colors.white),
//           ),
//         SizedBox(height: 12),
//         FloatingActionButton(
//           heroTag: "refresh",
//           onPressed: controller.isLoading.value ? null : controller.refreshData,
//           backgroundColor: kPrimaryColor,
//           child: controller.isLoading.value
//               ? SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
//                 )
//               : Icon(Icons.refresh, color: Colors.white),
//         ),
//       ],
//     ));
//   }

//   void _showWeekPicker(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: controller.currentWeekStart.value,
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2030),
//     );
    
//     if (picked != null) {
//       controller.setWeekByDate(picked);
//     }
//   }
// }