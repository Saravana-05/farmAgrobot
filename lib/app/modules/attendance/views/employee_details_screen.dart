import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/values/app_colors.dart';

import '../../../data/models/attendance/attendance_record_model.dart';
import '../controller/employee_details_controller.dart';

class EmployeeDetailsScreen extends StatelessWidget {
  const EmployeeDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EmployeeDetailsController());

    return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Obx(() => Text(
                controller.employeeData.value?.name ?? 'Employee Details',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )),
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: controller.fetchEmployeeReport,
            ),
          ],
        ),
        body: Obx(() {
          if (controller.isLoadingReport.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: controller.fetchEmployeeReport,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildEmployeeHeader(controller),
                  _buildDateRangeCard(controller),
                  _buildSummaryCards(controller),
                  _buildPaymentSection(controller),
                  _buildWeeklyBreakdown(controller),
                  _buildAttendanceCalendar(controller),
                ],
              ),
            ),
          );
        }),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: controller.showExportOptionsDialog,
          backgroundColor: kPrimaryColor,
          icon: const Icon(Icons.file_download, color: Colors.white),
          label: const Text('Export', style: TextStyle(color: Colors.white)),
        ));
  }

  Widget _buildEmployeeHeader(EmployeeDetailsController controller) {
    return Obx(() {
      final employee = controller.employeeData.value;
      final imageUrl = employee?.profileImageUrl;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kPrimaryColor,
              kPrimaryColor.withOpacity(0.8),
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Profile Picture
            Stack(
              children: [
                // Outer glow circle
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: _buildProfileImage(imageUrl, employee?.name ?? 'U'),
                  ),
                ),
                // Online/Active indicator (optional)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Employee Name
            Text(
              employee?.name ?? 'Unknown Employee',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Daily Wage Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.currency_rupee,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${employee?.dailyWage.toStringAsFixed(0) ?? '0'} / day',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildProfileImage(String? imageUrl, String employeeName) {
    // If image URL exists and is not empty
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 48,
        backgroundColor: Colors.white,
        child: ClipOval(
          child: Image.network(
            imageUrl,
            width: 96,
            height: 96,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    kPrimaryColor.withOpacity(0.7),
                  ),
                  strokeWidth: 3,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              // Show default avatar if image fails to load
              return _buildDefaultAvatar(employeeName);
            },
          ),
        ),
      );
    }

    // Show default avatar if no image URL
    return CircleAvatar(
      radius: 48,
      backgroundColor: Colors.white,
      child: _buildDefaultAvatar(employeeName),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    // Get first letter of name for avatar
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kPrimaryColor.withOpacity(0.7),
            kPrimaryColor.withOpacity(0.5),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeCard(EmployeeDetailsController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Report Period',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showDateRangePicker(controller),
                    icon: const Icon(Icons.date_range, size: 18),
                    label: const Text('Change', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: kPrimaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  controller.formattedDateRange,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kPrimaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(EmployeeDetailsController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Attendance Summary
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attendance Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          'Total Days',
                          controller.totalDays.value.toString(),
                          Colors.blue,
                          Icons.calendar_today,
                        ),
                      ),
                      Expanded(
                        child: _buildSummaryItem(
                          'Present',
                          controller.presentDays.value.toString(),
                          Colors.green,
                          Icons.check_circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          'Half Days',
                          controller.halfDays.value.toString(),
                          Colors.orange,
                          Icons.schedule,
                        ),
                      ),
                      Expanded(
                        child: _buildSummaryItem(
                          'Absent',
                          controller.absentDays.value.toString(),
                          Colors.red,
                          Icons.cancel,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Attendance Percentage
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Attendance Rate',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${controller.attendancePercentage.value.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getPercentageColor(
                              controller.attendancePercentage.value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: controller.attendancePercentage.value / 100,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation(
                      _getPercentageColor(
                          controller.attendancePercentage.value),
                    ),
                    minHeight: 8,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Wages Summary
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Wages Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildWageRow('Total Earned',
                      controller.totalWagesEarned.value, Colors.blue),
                  const SizedBox(height: 8),
                  _buildWageRow('Amount Paid', controller.totalWagesPaid.value,
                      Colors.green),
                  const SizedBox(height: 8),
                  _buildWageRow('Pending Amount',
                      controller.totalWagesPending.value, Colors.red),
                  const SizedBox(height: 16),
                  // Payment Percentage
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Payment Progress',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${controller.paymentPercentage.value.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getPercentageColor(
                              controller.paymentPercentage.value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: controller.paymentPercentage.value / 100,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation(
                      _getPercentageColor(controller.paymentPercentage.value),
                    ),
                    minHeight: 8,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWageRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection(EmployeeDetailsController controller) {
    if (!controller.hasPendingWages) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.check_circle,
                    color: Colors.green.shade700, size: 30),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'All wages have been paid',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet,
                      color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Pending Payment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '₹${controller.totalWagesPending.value.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showPartialPaymentDialog(controller),
                      icon: const Icon(Icons.payment),
                      label: const Text('Partial Payment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showFullPaymentDialog(controller),
                      icon: const Icon(Icons.done_all),
                      label: const Text('Pay Full'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyBreakdown(EmployeeDetailsController controller) {
    if (controller.weeklyBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Weekly Breakdown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              ...controller.weeklyBreakdown.map((week) => _buildWeekCard(week)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekCard(WeeklyBreakdown week) {
    final startDate = DateTime.tryParse(week.weekStart);
    final endDate = DateTime.tryParse(week.weekEnd);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${startDate != null ? DateFormat('dd MMM').format(startDate) : ''} - ${endDate != null ? DateFormat('dd MMM').format(endDate) : ''}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kPrimaryColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPaymentStatusColor(week.paymentStatus)
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getPaymentStatusText(week.paymentStatus),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getPaymentStatusColor(week.paymentStatus),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildWeekStat(
                    'Present', week.presentDays.toString(), Colors.green),
              ),
              Expanded(
                child: _buildWeekStat(
                    'Half', week.halfDays.toString(), Colors.orange),
              ),
              Expanded(
                child: _buildWeekStat(
                    'Absent', week.absentDays.toString(), Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Earned: ₹${week.totalWagesEarned.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12, color: Colors.blue),
              ),
              Text(
                'Paid: ₹${week.wagesPaid.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12, color: Colors.green),
              ),
              if (week.wagesPending > 0)
                Text(
                  'Pending: ₹${week.wagesPending.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceCalendar(EmployeeDetailsController controller) {
    if (controller.dailyAttendanceData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Daily Attendance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildAttendanceLegend(),
              const SizedBox(height: 16),
              _buildAttendanceGrid(controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem('Present', Colors.green, Icons.check),
        _buildLegendItem('Half Day', Colors.orange, Icons.schedule),
        _buildLegendItem('Absent', Colors.red, Icons.close),
        _buildLegendItem('Not Marked', Colors.grey, Icons.help_outline),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceGrid(EmployeeDetailsController controller) {
    // Group attendance data by month for better organization
    Map<String, List<AttendanceDay>> monthlyData = {};

    for (var day in controller.dailyAttendanceData) {
      final date = DateTime.tryParse(day.date);
      if (date != null) {
        final monthKey = DateFormat('MMM yyyy').format(date);
        if (!monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey] = [];
        }
        monthlyData[monthKey]!.add(day);
      }
    }

    return Column(
      children: monthlyData.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: entry.value.length,
              itemBuilder: (context, index) {
                final day = entry.value[index];
                return _buildAttendanceDay(day);
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAttendanceDay(AttendanceDay day) {
    final date = DateTime.tryParse(day.date);
    final isToday = date != null && _isToday(date);

    return Container(
      decoration: BoxDecoration(
        color: isToday
            ? Colors.yellow.shade100
            : _getAttendanceBackgroundColor(day.statusCode),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isToday
              ? Colors.orange
              : _getAttendanceBorderColor(day.statusCode),
          width: isToday ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getAttendanceIcon(day.statusCode),
            size: 14,
            color: _getAttendanceBorderColor(day.statusCode),
          ),
          const SizedBox(height: 2),
          Text(
            date != null ? DateFormat('d').format(date) : '',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (day.wageEarned > 0)
            Text(
              '₹${day.wageEarned.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                color: Colors.green,
              ),
            ),
        ],
      ),
    );
  }

  // Helper methods
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  String _getPaymentStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'PAID';
      case 'partial':
        return 'PARTIAL';
      default:
        return 'PENDING';
    }
  }

  Color _getAttendanceBackgroundColor(int? status) {
    switch (status) {
      case 1:
        return Colors.green.shade100;
      case 2:
        return Colors.orange.shade100;
      case 0:
        return Colors.red.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  Color _getAttendanceBorderColor(int? status) {
    switch (status) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 0:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getAttendanceIcon(int? status) {
    switch (status) {
      case 1:
        return Icons.check;
      case 2:
        return Icons.schedule;
      case 0:
        return Icons.close;
      default:
        return Icons.help_outline;
    }
  }

  // Dialog methods
  void _showDateRangePicker(EmployeeDetailsController controller) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: Get.context!,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: controller.startDate.value,
        end: controller.endDate.value,
      ),
    );

    if (picked != null) {
      await controller.updateDateRange(picked.start, picked.end);
    }
  }

  void _showPartialPaymentDialog(EmployeeDetailsController controller) {
    final TextEditingController amountController = TextEditingController();
    final maxAmount = controller.totalWagesPending.value;

    Get.dialog(
      AlertDialog(
        title: const Text('Partial Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pending Amount: ₹${maxAmount.toStringAsFixed(0)}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Payment Amount',
                prefixText: '₹',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount > 0 && amount <= maxAmount) {
                Get.back();
                controller.payEmployeeWages(amount);
              } else {
                Get.snackbar(
                  'Error',
                  'Please enter a valid amount between 1 and ${maxAmount.toStringAsFixed(0)}',
                );
              }
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );
  }

  void _showFullPaymentDialog(EmployeeDetailsController controller) {
    final amount = controller.totalWagesPending.value;

    Get.dialog(
      AlertDialog(
        title: const Text('Full Payment'),
        content:
            Text('Pay full pending amount of ₹${amount.toStringAsFixed(0)}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.payEmployeeWages(amount);
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );
  }
}
