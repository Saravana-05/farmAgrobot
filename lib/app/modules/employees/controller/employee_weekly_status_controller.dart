import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/employee/employee_weekly_status_service.dart';
import '../../../data/models/attendance/attendance_record_model.dart';

class EmployeeWeeklyStatusController extends GetxController {
  // Loading state
  var isUpdating = false.obs;

  // Selected week data
  var selectedWeekStart = DateTime.now().obs;
  var currentYear = 0.obs;
  var currentWeekNumber = 0.obs;

  // Employee status tracking
  var employeeWeeklyStatus = <String, bool>{}.obs; // employeeId -> isActive

  @override
  void onInit() {
    super.onInit();
    _updateWeekInfo();
  }

  /// Update week information based on selected date
  void _updateWeekInfo() {
    final weekInfo = EmployeeWeeklyStatusService.getWeekInfo(selectedWeekStart.value);
    currentYear.value = weekInfo['year']!;
    currentWeekNumber.value = weekInfo['week']!;
  }

  /// Set selected week
  void setWeek(DateTime weekStart) {
    selectedWeekStart.value = weekStart;
    _updateWeekInfo();
  }

  /// Update employee weekly status
  Future<bool> updateEmployeeStatus({
    required String employeeId,
    required String employeeName,
    required bool isActive,
    String? reason,
  }) async {
    if (isUpdating.value) return false;

    isUpdating.value = true;

    try {
      final response = await EmployeeWeeklyStatusService.updateEmployeeWeeklyStatus(
        employeeId: employeeId,
        year: currentYear.value,
        weekNumber: currentWeekNumber.value,
        isActive: isActive,
        reason: reason,
      );

      if (response['success'] == true) {
        // Update local status
        employeeWeeklyStatus[employeeId] = isActive;
        employeeWeeklyStatus.refresh();

        // Extract success message
        final data = response['data'];
        final message = data['message'] ?? 
            '${isActive ? 'Activated' : 'Deactivated'} $employeeName for this week';

        _showSuccessMessage(message);
        return true;
      } else {
        _handleApiError(response);
        return false;
      }
    } catch (e) {
      _handleException('Failed to update employee status', e);
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  /// Show employee status dialog
  void showEmployeeStatusDialog({
    required BuildContext context,
    required EmployeeAttendanceRecord employee,
    required bool currentStatus,
    required VoidCallback onStatusChanged,
  }) {
    final TextEditingController reasonController = TextEditingController();
    final RxBool isActive = currentStatus.obs;

    Get.dialog(
      AlertDialog(
        title: Text('Update Status for ${employee.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Week: ${_getWeekDateRange()}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Status for this week only:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() => SwitchListTile(
              title: Text(
                isActive.value ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive.value ? Colors.green : Colors.red,
                ),
              ),
              subtitle: Text(
                isActive.value 
                    ? 'Employee will appear in attendance for this week'
                    : 'Employee will be hidden for this week',
                style: TextStyle(fontSize: 12),
              ),
              value: isActive.value,
              onChanged: (value) => isActive.value = value,
              activeColor: Colors.green,
            )),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'e.g., On leave, Sick, etc.',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This change only affects this specific week. Past and future weeks remain unchanged.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              
              final success = await updateEmployeeStatus(
                employeeId: employee.id,
                employeeName: employee.name,
                isActive: isActive.value,
                reason: reasonController.text.trim(),
              );

              if (success) {
                onStatusChanged();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive.value ? Colors.green : Colors.red,
            ),
            child: Text(isActive.value ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );
  }

  /// Get formatted week date range
  String _getWeekDateRange() {
    final weekRange = EmployeeWeeklyStatusService.getWeekRange(selectedWeekStart.value);
    final start = weekRange['start']!;
    final end = weekRange['end']!;
    
    return '${_formatDate(start)} - ${_formatDate(end)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Error and success handling
  void _showSuccessMessage(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: 3),
    );
  }

  void _showErrorMessage(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: 4),
    );
  }

  void _handleApiError(Map<String, dynamic> response) {
    String message = 'An error occurred';

    if (response['data'] != null && response['data'] is Map) {
      final data = response['data'] as Map;
      message = data['message'] ?? data['error'] ?? message;
    }

    _showErrorMessage(message);
  }

  void _handleException(String context, dynamic error) {
    Get.snackbar(
      'Error',
      '$context: ${error.toString()}',
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}