import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/values/app_colors.dart';
import '../../../data/models/attendance/attendance_record_model.dart';
import '../../../routes/app_pages.dart';
import '../controller/attendance_UI_controller.dart';
import '../controller/employee_detail_controller.dart';

class AttendanceUIScreen extends StatelessWidget {
  const AttendanceUIScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AttendanceUIController());

    return Scaffold(
      body: Obx(() => RefreshIndicator(
            onRefresh: () => controller.fetchWeeklyData(),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildDateRangeExportWidget(controller),
                  _buildWeekNavigation(controller),
                  _buildWagesSummaryAndActions(controller),
                  _buildEmployeeOrderButton(controller),
                  _buildAttendanceTable(controller),
                  _buildEmployeeCounts(controller),
                ],
              ),
            ),
          )),
    );
  }

  Widget _buildDateRangeExportWidget(AttendanceUIController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Card(
        elevation: 2,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(controller, true),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today,
                                size: 14, color: Colors.grey.shade700),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                controller.fromDate.value != null
                                    ? DateFormat('dd/MM/yyyy')
                                        .format(controller.fromDate.value!)
                                    : 'From Date',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(controller, false),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today,
                                size: 14, color: Colors.grey.shade700),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                controller.toDate.value != null
                                    ? DateFormat('dd/MM/yyyy')
                                        .format(controller.toDate.value!)
                                    : 'To Date',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Export to Excel',
                    child: InkWell(
                      onTap: (controller.fromDate.value != null &&
                              controller.toDate.value != null &&
                              !controller.isExporting.value)
                          ? () => controller.exportAttendanceToExcel(
                              controller.fromDate.value!,
                              controller.toDate.value!)
                          : null,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (controller.fromDate.value != null &&
                                  controller.toDate.value != null &&
                                  !controller.isExporting.value)
                              ? kPrimaryColor
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: controller.isExporting.value
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Icon(
                                Icons.file_download,
                                color: Colors.white,
                                size: 16,
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

  Future<void> _selectDate(
      AttendanceUIController controller, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: isFromDate
          ? (controller.fromDate.value ?? DateTime.now())
          : (controller.toDate.value ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      if (isFromDate) {
        controller.fromDate.value = picked;
      } else {
        controller.toDate.value = picked;
      }
    }
  }

  Widget _buildWeekNavigation(AttendanceUIController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: kPrimaryColor, size: 18),
            onPressed: controller.previousWeek,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Expanded(
            child: Text(
              controller.formattedWeekRange,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios,
                color: kPrimaryColor, size: 18),
            onPressed: controller.canNavigateNext ? controller.nextWeek : null,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          TextButton(
            onPressed: controller.goToCurrentWeek,
            child: const Text(
              'Today',
              style: TextStyle(color: kPrimaryColor, fontSize: 12),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 36),
            ),
          ),
        ],
      ),
    );
  }

  // FIXED: Updated wages summary to properly handle individual payments
  Widget _buildWagesSummaryAndActions(AttendanceUIController controller) {
    // Calculate total paid amount across all employees
    double totalPaidAmount = 0.0;
    for (var employee in controller.employees) {
      totalPaidAmount += controller.getPartialPayment(employee.id);
    }

    // Calculate remaining amount
    double remainingAmount = controller.grandTotalWages.value - totalPaidAmount;

    // FIXED: Check if ALL employees are fully paid (no remaining amounts)
    bool allEmployeesPaid = controller.employees.isNotEmpty &&
        controller.employees.every(
            (employee) => controller.getRemainingAmount(employee.id) <= 0);

    // FIXED: Check if there are any employees with remaining amounts > 0
    bool hasUnpaidEmployees = controller.employees
        .any((employee) => controller.getRemainingAmount(employee.id) > 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Column(
        children: [
          // Total wages info with breakdown
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Wages: ₹${controller.grandTotalWages.value.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (totalPaidAmount > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Paid: ₹${totalPaidAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              // FIXED: Only show remaining if there are actually unpaid employees
                              if (hasUnpaidEmployees && remainingAmount > 0)
                                Text(
                                  'Remaining: ₹${remainingAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ],
                        ),
                      ),
                      // Progress indicator for payment completion
                      if (controller.grandTotalWages.value > 0)
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: Stack(
                            children: [
                              CircularProgressIndicator(
                                value: totalPaidAmount /
                                    controller.grandTotalWages.value,
                                backgroundColor: Colors.grey.shade300,
                                valueColor:
                                    const AlwaysStoppedAnimation(kPrimaryColor),
                                strokeWidth: 3,
                              ),
                              Center(
                                child: Text(
                                  '${((totalPaidAmount / controller.grandTotalWages.value) * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: Container(), // Empty space to push buttons to right
              ),
              // FIXED: Show pay remaining button only when there are unpaid employees
              if (hasUnpaidEmployees && remainingAmount > 0)
                ElevatedButton.icon(
                  onPressed: () =>
                      _showPayWagesDialog(controller, remainingAmount),
                  icon: const Icon(Icons.money, color: kPrimaryColor, size: 14),
                  label: Text(
                    totalPaidAmount > 0 ? 'Pay Remaining' : 'Pay Wages',
                    style: const TextStyle(color: kPrimaryColor, fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(0, 32),
                    backgroundColor: Colors.white,
                    elevation: 1,
                  ),
                )
              // FIXED: Show "All Wages Paid" only when ALL employees are fully paid AND there are employees
              else if (allEmployeesPaid && controller.employees.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 18),
                    const SizedBox(width: 4),
                    const Text(
                      'All Wages Paid',
                      style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                )
              // Show nothing if no employees
              else if (controller.employees.isEmpty)
                const Text(
                  'No employees found',
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                onPressed: controller.fetchWageSummary,
                icon: const Icon(Icons.picture_as_pdf,
                    color: kPrimaryColor, size: 14),
                label: const Text(
                  'PDF',
                  style: TextStyle(color: kPrimaryColor, fontSize: 11),
                ),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(0, 32),
                  backgroundColor: Colors.white,
                  elevation: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // FIXED: Updated pay wages dialog to handle remaining amounts properly
  void _showPayWagesDialog(
      AttendanceUIController controller, double remainingAmount) {
    Get.dialog(
      AlertDialog(
        title: const Text('Pay Wages Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Remaining Amount: ₹${remainingAmount.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Choose how you want to pay wages:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _showIndividualPaymentSheet(controller);
            },
            child: const Text('Individual Payments'),
          ),
          if (remainingAmount > 0)
            ElevatedButton(
              onPressed: () {
                Get.back();
                _showPayAllRemainingConfirmation(controller, remainingAmount);
              },
              child: Text(
                  'Pay Remaining (₹${remainingAmount.toStringAsFixed(0)})'),
            ),
        ],
      ),
    );
  }

  // FIXED: New method to handle paying remaining amount
  void _showPayAllRemainingConfirmation(
      AttendanceUIController controller, double remainingAmount) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text(
            'Are you sure you want to pay the remaining wages totaling ₹${remainingAmount.toStringAsFixed(0)}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _payRemainingWages(controller);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _payRemainingWages(AttendanceUIController controller) async {
    // Make a copy to avoid modification issues
    final employeesCopy = List.of(controller.employees);

    for (var employee in employeesCopy) {
      final remainingAmount = controller.getRemainingAmount(employee.id);
      if (remainingAmount > 0) {
        await controller.payEmployeeWages(employee.id, remainingAmount);
      }
    }
  }

  void _showPayAllConfirmation(AttendanceUIController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text(
            'Are you sure you want to pay all wages totaling ₹${controller.grandTotalWages.value.toStringAsFixed(0)}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.payAllWages();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showIndividualPaymentSheet(AttendanceUIController controller) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            const Text(
              'Individual Employee Payments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() => ListView.builder(
                    itemCount: controller.employees.length,
                    itemBuilder: (context, index) {
                      final employee = controller.employees[index];
                      return _buildEmployeePaymentCard(
                          controller, employee as EmployeeAttendanceRecord);
                    },
                  )),
            ),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildEmployeePaymentCard(
      AttendanceUIController controller, EmployeeAttendanceRecord employee) {
    final paymentStatus = controller.getPaymentStatus(employee.id);
    final isPaid = paymentStatus == 'paid';
    final partialPayment = controller.getPartialPayment(employee.id);
    final remainingAmount = controller.getRemainingAmount(employee.id);
    final totalAmount = controller.getTotalWages(employee.id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Total Wages: ₹${totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      if (partialPayment > 0)
                        Text(
                          'Paid: ₹${partialPayment.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.green),
                        ),
                      if (remainingAmount > 0)
                        Text(
                          'Remaining: ₹${remainingAmount.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.orange),
                        ),
                    ],
                  ),
                ),
                if (isPaid)
                  const Icon(Icons.check_circle, color: Colors.green, size: 30)
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (remainingAmount > 0) ...[
                        IconButton(
                          onPressed: () => _showPartialPaymentDialog(
                              controller, employee, remainingAmount),
                          icon: const Icon(Icons.payment),
                          tooltip: 'Partial Payment',
                        ),
                        IconButton(
                          onPressed: () => controller.payEmployeeWages(
                              employee.id, remainingAmount),
                          icon: const Icon(Icons.done_all),
                          tooltip: 'Pay Full Amount',
                        ),
                      ],
                    ],
                  ),
              ],
            ),
            if (!isPaid && remainingAmount > 0 && totalAmount > 0)
              LinearProgressIndicator(
                value: partialPayment / totalAmount,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation(kPrimaryColor),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeOrderButton(AttendanceUIController controller) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Employees (${controller.employees.length})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.useCustomOrder.value)
                const Icon(Icons.reorder, color: kPrimaryColor, size: 14),
              TextButton.icon(
                onPressed: controller.showEmployeeOrderDialog,
                icon: const Icon(Icons.sort, size: 14),
                label: const Text('Reorder', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: kPrimaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTable(AttendanceUIController controller) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.employees.isEmpty) {
      return const Center(child: Text("No employees found."));
    }

    final daysOfWeek = List.generate(
        7,
        (index) =>
            controller.selectedWeekStart.value.add(Duration(days: index)));
    final abbreviatedDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(Get.context!).size.width,
        ),
        child: Obx(() => DataTable(
              columnSpacing: 8.0,
              dataRowHeight: 40,
              headingRowHeight: 36,
              horizontalMargin: 8,
              columns: [
                const DataColumn(
                    label: SizedBox(
                  width: 80,
                  child: Text(
                    'Name',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
                ...abbreviatedDays.map((day) => DataColumn(
                        label: SizedBox(
                      width: 28,
                      child: Text(
                        day,
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ))),
                const DataColumn(
                    label: SizedBox(
                  width: 50,
                  child: Text(
                    'Wages',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                )),
                const DataColumn(
                    label: SizedBox(
                  width: 40,
                  child: Text(
                    'Status',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                )),
                const DataColumn(
                    label: SizedBox(
                  width: 35,
                  child: Text(
                    'Action',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                )),
              ],
              rows: controller.employees.map((employee) {
                final presentCount =
                    controller.getTotalPresentDays(employee.id);
                final totalWages = controller.getTotalWages(employee.id);
                final paymentStatus = controller.getPaymentStatus(employee.id);
                final isPaid = paymentStatus == 'paid';
                final partialPayment =
                    controller.getPartialPayment(employee.id);
                final remainingAmount =
                    controller.getRemainingAmount(employee.id);

                return DataRow(cells: [
                  // Employee name cell
                  DataCell(
                    Container(
                      width: 80,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 6,
                            color: kPrimaryColor,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              employee.name,
                              style: const TextStyle(
                                fontSize: 10,
                                color: kPrimaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () => _navigateToEmployeeDetails(employee),
                  ),

                  // Attendance cells for each day of the week
                  ...daysOfWeek.map((date) {
                    // Normalize the date to remove time component
                    final normalizedDate =
                        DateTime(date.year, date.month, date.day);
                    final attendanceStatus = controller
                        .attendanceRecords[employee.id]?[normalizedDate];
                    final isToday = _isToday(date);

                    // Debug print to see what status we're getting
                    print(
                        'Employee: ${employee.name}, Date: $normalizedDate, Status: $attendanceStatus, Records: ${controller.attendanceRecords[employee.id]?.keys.toList()}');

                    return DataCell(
                      Container(
                        width: 28,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isToday
                              ? Colors.yellow[100]
                              : _getAttendanceBackgroundColor(attendanceStatus),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isToday
                                ? Colors.orange
                                : _getAttendanceBorderColor(attendanceStatus),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: _getAttendanceIcon(attendanceStatus),
                        ),
                      ),
                      onTap: () {
                        if (!controller.wagesPaid.value) {
                          // Toggle between 0 (absent) and 1 (present)
                          final newStatus = (attendanceStatus == 1) ? 0 : 1;
                          print(
                              'Updating attendance: ${employee.name}, $normalizedDate, $attendanceStatus -> $newStatus');
                          controller.updateAttendance(
                            employee.id,
                            employee.name,
                            normalizedDate,
                            newStatus,
                          );
                        } else {
                          _showWagesPaidDialog();
                        }
                      },
                    );
                  }),

                  // Wages cell
                  DataCell(
                    SizedBox(
                      width: 50,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '₹${totalWages.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (partialPayment > 0)
                            Text(
                              'P:₹${partialPayment.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 8,
                                color: Colors.green,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Status cell
                  DataCell(
                    SizedBox(
                      width: 40,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? Colors.green[100]
                              : partialPayment > 0
                                  ? Colors.orange[100]
                                  : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isPaid
                              ? 'Paid'
                              : partialPayment > 0
                                  ? 'Part Pay'
                                  : 'Pending',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: isPaid
                                ? Colors.green[700]
                                : partialPayment > 0
                                    ? Colors.orange[700]
                                    : Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),

                  // Action cell
                  DataCell(
                    SizedBox(
                      width: 35,
                      child: isPaid
                          ? const Icon(Icons.check_circle,
                              color: Colors.green, size: 16)
                          : Material(
                              color: Colors.transparent,
                              child: PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                iconSize: 16,
                                icon: const Icon(Icons.more_vert, size: 16),
                                itemBuilder: (context) => [
                                  if (remainingAmount > 0) ...[
                                    const PopupMenuItem(
                                      value: 'partial',
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.payment, size: 12),
                                          SizedBox(width: 4),
                                          Text('Partial',
                                              style: TextStyle(fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'full',
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.done_all, size: 12),
                                          SizedBox(width: 4),
                                          Text('Full',
                                              style: TextStyle(fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                                onSelected: (value) {
                                  if (value == 'partial') {
                                    _showPartialPaymentDialog(
                                        controller, employee, remainingAmount);
                                  } else if (value == 'full') {
                                    _showPayFullConfirmation(
                                        controller, employee, remainingAmount);
                                  }
                                },
                              ),
                            ),
                    ),
                  ),
                ]);
              }).toList(),
            )),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Color _getAttendanceBackgroundColor(int? status) {
    switch (status) {
      case 1:
        return Colors.green[100]!;
      case 2:
        return Colors.orange[100]!;
      case 0:
        return Colors.red[50]!;
      default:
        return Colors.grey[50]!;
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

  Widget _getAttendanceIcon(int? status) {
    switch (status) {
      case 1:
        return const Icon(
          Icons.check,
          size: 12,
          color: Colors.green,
        );
      case 2:
        return const Icon(
          Icons.close,
          size: 12,
          color: Colors.orange,
        );
      case 0:
        return const Icon(
          Icons.close,
          size: 12,
          color: Colors.red,
        );
      default:
        // This handles null status - means attendance not marked yet
        return const Icon(
          Icons.help_outline,
          size: 12,
          color: Colors.grey,
        );
    }
  }

  void _showWagesPaidDialog() {
    Get.dialog(
      AlertDialog(
        icon: const Icon(
          Icons.info,
          color: kPrimaryColor,
        ),
        content: const Text(
            "Wages have already been paid for this week. You cannot update attendance."),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _navigateToEmployeeDetails(employee) {
    try {
      // Clean up any existing controller before navigation
      if (Get.isRegistered<EmployeeDetailsController>()) {
        Get.delete<EmployeeDetailsController>();
      }

      // Navigate with employee data
      Get.toNamed(Routes.EMPLOYEE_DETAILS, arguments: employee);
    } catch (e) {
      print('Navigation error: $e');
      Get.snackbar(
        'Error',
        'Failed to open employee details',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  void _showPartialPaymentDialog(
      AttendanceUIController controller, employee, double maxAmount) {
    final TextEditingController amountController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('Partial Payment - ${employee.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Remaining Amount: ₹${maxAmount.toStringAsFixed(0)}'),
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
                controller.payEmployeeWages(employee.id, amount);
              } else {
                Get.snackbar('Error',
                    'Please enter a valid amount between 1 and ${maxAmount.toStringAsFixed(0)}');
              }
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );
  }

// FIXED: Updated pay full confirmation dialog to use remaining amount
  void _showPayFullConfirmation(
      AttendanceUIController controller, employee, double remainingAmount) {
    Get.dialog(
      AlertDialog(
        title: Text('Pay Remaining Wages - ${employee.name}'),
        content: Text(
            'Pay remaining amount of ₹${remainingAmount.toStringAsFixed(0)}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.payEmployeeWages(employee.id, remainingAmount);
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCounts(AttendanceUIController controller) {
    final daysOfWeek = List.generate(
        7,
        (index) =>
            controller.selectedWeekStart.value.add(Duration(days: index)));
    final abbreviatedDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'Weekly Employee Count: ${controller.weeklyEmployeeCount.value}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: daysOfWeek.asMap().entries.map((entry) {
                final index = entry.key;
                final date = entry.value;
                final count = controller.dailyEmployeeCount[date] ?? 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          children: [
                            Text(
                              abbreviatedDays[index],
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              DateFormat('dd').format(date),
                              style: const TextStyle(
                                fontSize: 8,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: kPrimaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _buildPaymentSummary(controller),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(AttendanceUIController controller) {
    int totalEmployees = controller.employees.length;
    int paidEmployees = 0;
    int partiallyPaidEmployees = 0;
    double totalPaidAmount = 0.0;

    // Calculate payment statistics
    for (var employee in controller.employees) {
      final paymentStatus = controller.getPaymentStatus(employee.id);
      final partialPayment = controller.getPartialPayment(employee.id);

      if (paymentStatus == 'paid') {
        paidEmployees++;
        totalPaidAmount += controller.getTotalWages(employee.id);
      } else if (partialPayment > 0) {
        partiallyPaidEmployees++;
        totalPaidAmount += partialPayment;
      }
    }

    int pendingEmployees = totalEmployees - paidEmployees;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSummaryItem('Total Employees',
                      totalEmployees.toString(), Colors.blue),
                  const SizedBox(width: 12),
                  _buildSummaryItem(
                      'Fully Paid', paidEmployees.toString(), Colors.green),
                  const SizedBox(width: 12),
                  _buildSummaryItem('Partially Paid',
                      (partiallyPaidEmployees).toString(), Colors.orange),
                  const SizedBox(width: 12),
                  _buildSummaryItem(
                      'Pending', pendingEmployees.toString(), Colors.red),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Wages: ₹${controller.grandTotalWages.value.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Amount Paid: ₹${totalPaidAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.green),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Remaining: ₹${(controller.grandTotalWages.value - totalPaidAmount).toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.red),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        value: totalPaidAmount /
                            (controller.grandTotalWages.value > 0
                                ? controller.grandTotalWages.value
                                : 1),
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation(kPrimaryColor),
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _navigateWithCleanup(employee) {
    try {
      // Navigate with a delay to ensure clean state
      Future.microtask(() {
        Get.toNamed(Routes.EMPLOYEE_DETAILS, arguments: employee);
      });
    } catch (e) {
      print('Navigation error: $e');
      Get.snackbar('Error', 'Failed to navigate to employee details');
    }
  }
}
