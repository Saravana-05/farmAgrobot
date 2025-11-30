import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/attendance/attendance_record_model.dart';
import '../../employees/controller/employee_weekly_status_controller.dart';
import '../controller/attendance_UI_controller.dart';

class EmployeeWeeklyStatusButton extends StatelessWidget {
  final EmployeeAttendanceRecord employee;
  final AttendanceUIController attendanceController;
  
  const EmployeeWeeklyStatusButton({
    Key? key,
    required this.employee,
    required this.attendanceController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusController = Get.put(EmployeeWeeklyStatusController());
    
    // Sync week with attendance controller
    statusController.setWeek(attendanceController.selectedWeekStart.value);

    return IconButton(
      icon: Icon(
        Icons.event_available,
        size: 20,
        color: Colors.blue.shade600,
      ),
      tooltip: 'Manage weekly status',
      onPressed: () {
        statusController.showEmployeeStatusDialog(
          context: context,
          employee: employee,
          currentStatus: true, // Default to active
          onStatusChanged: () {
            // Refresh attendance data after status change
            attendanceController.fetchWeeklyData();
          },
        );
      },
    );
  }
}

/// Full-screen Employee Weekly Status Manager
class EmployeeWeeklyStatusScreen extends StatelessWidget {
  const EmployeeWeeklyStatusScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusController = Get.put(EmployeeWeeklyStatusController());
    final attendanceController = Get.find<AttendanceUIController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Weekly Status'),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Week selector
          _buildWeekSelector(statusController, attendanceController),
          
          // Employee list
          Expanded(
            child: Obx(() {
              if (attendanceController.isLoading.value) {
                return Center(child: CircularProgressIndicator());
              }

              if (attendanceController.employees.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No employees found for this week',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: attendanceController.employees.length,
                itemBuilder: (context, index) {
                  final employee = attendanceController.employees[index];
                  return _buildEmployeeCard(
                    context,
                    employee,
                    statusController,
                    attendanceController,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSelector(
    EmployeeWeeklyStatusController statusController,
    AttendanceUIController attendanceController,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Week',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left),
                onPressed: () {
                  attendanceController.previousWeek();
                  statusController.setWeek(attendanceController.selectedWeekStart.value);
                },
              ),
              Expanded(
                child: Obx(() => Text(
                  attendanceController.formattedWeekRange,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                )),
              ),
              Obx(() => IconButton(
                icon: Icon(Icons.chevron_right),
                onPressed: attendanceController.canNavigateNext
                    ? () {
                        attendanceController.nextWeek();
                        statusController.setWeek(attendanceController.selectedWeekStart.value);
                      }
                    : null,
              )),
            ],
          ),
          Obx(() => Text(
            'Week ${statusController.currentWeekNumber.value}, ${statusController.currentYear.value}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(
    BuildContext context,
    EmployeeAttendanceRecord employee,
    EmployeeWeeklyStatusController statusController,
    AttendanceUIController attendanceController,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            employee.name[0].toUpperCase(),
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          employee.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Daily Wage: ₹${employee.dailyWage.toStringAsFixed(0)}',
          style: TextStyle(fontSize: 12),
        ),
        trailing: Obx(() => statusController.isUpdating.value
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status indicator
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: Colors.grey),
                ],
              )),
        onTap: () {
          statusController.showEmployeeStatusDialog(
            context: context,
            employee: employee,
            currentStatus: true,
            onStatusChanged: () {
              attendanceController.fetchWeeklyData();
            },
          );
        },
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('How It Works'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoPoint(
              'Week-Specific',
              'Changes only affect the selected week, not past or future weeks.',
            ),
            SizedBox(height: 12),
            _buildInfoPoint(
              'Deactivate Temporarily',
              'Deactivate employees who are on leave, sick, or absent for a specific week.',
            ),
            SizedBox(height: 12),
            _buildInfoPoint(
              'Automatic Hiding',
              'Deactivated employees won\'t appear in attendance marking for that week.',
            ),
            SizedBox(height: 12),
            _buildInfoPoint(
              'Easy Reactivation',
              'Activate them again for any future week when they return.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPoint(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle, size: 16, color: Colors.green),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}