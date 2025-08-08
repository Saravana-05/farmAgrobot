import 'package:get/get.dart';
import 'package:farm_agrobot/app/data/models/employee/emp_dummy_model.dart';

class EmployeeDetailsController extends GetxController {
  // Observable variables
  var isLoading = true.obs;
  var employee = Rxn<Employee>();
  var attendanceRecords = <DateTime, int>{}.obs;
  var totalDaysWorked = 0.obs;
  var totalWages = 0.0.obs;
  var profileImageUrl = Rxn<String>();
  var selectedIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // Get employee data from arguments
    final employeeData = Get.arguments as Employee?;
    if (employeeData != null) {
      employee.value = employeeData;
      fetchData();
    }
  }

  Future<void> fetchData() async {
    if (employee.value == null) return;
    
    isLoading.value = true;
    
    try {
      await Future.wait([
        fetchAttendanceData(),
        fetchProfileImage(),
      ]);
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchProfileImage() async {
    try {
      // Mock profile image fetch - replace with actual implementation
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock some employees have profile images
      final employeeId = employee.value?.id ?? '';
      if (['1', '3', '5'].contains(employeeId)) {
        profileImageUrl.value = 'https://via.placeholder.com/150x150/4CAF50/FFFFFF?text=${employee.value?.name[0] ?? 'U'}';
      }
    } catch (e) {
      print("Error fetching profile image: $e");
    }
  }

  Future<void> fetchAttendanceData() async {
    if (employee.value == null) return;
    
    try {
      final DateTime endDate = DateTime.now();
      final DateTime startDate = DateTime(
        endDate.year,
        endDate.month,
        endDate.day - 27,
      );

      attendanceRecords.clear();

      // Mock attendance data for last 28 days
      for (int i = 0; i < 28; i++) {
        final date = startDate.add(Duration(days: i));
        final normalizedDate = DateTime(date.year, date.month, date.day);
        
        // Mock attendance pattern - more realistic
        final isSunday = date.weekday == DateTime.sunday;
        if (!isSunday) {
          // Random attendance with 80% probability of being present
          attendanceRecords[normalizedDate] = 
              (date.day + employee.value!.id.hashCode) % 10 < 8 ? 1 : 0;
        }
      }

      // Calculate total days worked and wages
      totalDaysWorked.value = attendanceRecords.values.where((status) => status == 1).length;
      totalWages.value = totalDaysWorked.value * (double.tryParse(employee.value?.wages ?? '0') ?? 0.0);
      
    } catch (e) {
      print("Error fetching attendance data: $e");
    }
  }

  void onTabSelected(int index) {
    selectedIndex.value = index;
    
    switch (index) {
      case 0:
        Get.offAllNamed('/home');
        break;
      case 1:
        Get.offAllNamed('/dashboard');
        break;
      case 2:
        Get.offAllNamed('/settings');
        break;
    }
  }

  Future<void> refreshData() async {
    await fetchData();
  }

  // Get last 28 days for calendar
  List<DateTime> getLast28Days() {
    return List.generate(
      28,
      (index) => DateTime.now().subtract(Duration(days: 27 - index)),
    ).map((date) => DateTime(date.year, date.month, date.day)).toList();
  }

  // Check if date is today
  bool isToday(DateTime date) {
    final today = DateTime.now();
    return date.isAtSameMomentAs(DateTime(today.year, today.month, today.day));
  }

  // Check if date is Sunday
  bool isSunday(DateTime date) {
    return date.weekday == DateTime.sunday;
  }

  // Get attendance status for a date
  int getAttendanceStatus(DateTime date) {
    return attendanceRecords[date] ?? 0;
  }
}