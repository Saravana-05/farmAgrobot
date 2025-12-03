import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/values/app_colors.dart';
import '../../../data/models/attendance/emp_advance_model.dart';
import '../../../data/models/employee/emp_model.dart';
import '../controller/emp_advance_controller.dart';

class EmployeeAdvanceWidget extends StatelessWidget {
  const EmployeeAdvanceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EmployeeAdvanceController());

    return Obx(() => Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: const Icon(Icons.monetization_on,
                  color: kPrimaryColor, size: 20),
              title: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Employee Advances',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                  if (controller.advances.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${controller.advances.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: controller.isLoading.value
                  ? const Text('Loading...', style: TextStyle(fontSize: 11))
                  : Text(
                      'Total: ₹${controller.totalAdvanceAmount.value.toStringAsFixed(0)} | Pending: ${controller.pendingAdvances.value}',
                      style: const TextStyle(fontSize: 11),
                    ),
              children: [
                if (controller.isLoading.value)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  _buildQuickStats(controller),
                  _buildActionButtons(controller),
                  _buildFilterChips(controller),
                  _buildAdvancesList(controller),
                  _buildPagination(controller),
                ],
              ],
            ),
          ),
        ));
  }

  Widget _buildQuickStats(EmployeeAdvanceController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatCard(
              'Total Amount',
              '₹${controller.totalAdvanceAmount.value.toStringAsFixed(0)}',
              Colors.blue,
              Icons.attach_money,
            ),
            const SizedBox(width: 8),
            _buildStatCard(
              'Adjusted',
              '₹${controller.totalAdjustedAmount.value.toStringAsFixed(0)}',
              Colors.green,
              Icons.check_circle,
            ),
            const SizedBox(width: 8),
            _buildStatCard(
              'Pending',
              '${controller.pendingAdvances.value}',
              Colors.orange,
              Icons.pending,
            ),
            const SizedBox(width: 8),
            _buildStatCard(
              'Records',
              '${controller.totalRecords.value}',
              Colors.purple,
              Icons.list_alt,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(EmployeeAdvanceController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          // Employee count badge
          Obx(() => controller.employees.isNotEmpty
              ? Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people, size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 6),
                      Text(
                        '${controller.employees.length} Active Employees',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: controller.refreshEmployees,
                        child: Icon(
                          Icons.refresh,
                          size: 14,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink()),

          // Existing buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateAdvanceDialog(controller),
                  icon: const Icon(Icons.add, size: 16),
                  label:
                      const Text('New Advance', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              // ... rest of your buttons
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(EmployeeAdvanceController controller) {
    if (!controller.hasFilters) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          if (controller.selectedStatus.value != null)
            _buildFilterChip(
              controller.selectedStatus.value!,
              () => controller.filterByStatus(null),
            ),
          if (controller.selectedPaymentMode.value != null)
            _buildFilterChip(
              controller.selectedPaymentMode.value!,
              () => controller.filterByPaymentMode(null),
            ),
          if (controller.fromDate.value != null ||
              controller.toDate.value != null)
            _buildFilterChip(
              'Date Range',
              () => controller.setDateRange(null, null),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 10)),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onDelete,
      backgroundColor: kPrimaryColor.withOpacity(0.1),
      deleteIconColor: kPrimaryColor,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(2),
    );
  }

  Widget _buildAdvancesList(EmployeeAdvanceController controller) {
    if (controller.advances.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No advances found',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            if (controller.hasFilters) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: controller.clearFilters,
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: controller.advances.length,
      itemBuilder: (context, index) {
        final advance = controller.advances[index];
        return _buildAdvanceCard(controller, advance);
      },
    );
  }

  Widget _buildAdvanceCard(
      EmployeeAdvanceController controller, EmployeeAdvance advance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _showAdvanceDetails(controller, advance),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                advance.employeeName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (advance.tamilName != null) ...[
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '(${advance.tamilName})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          controller.formatDate(advance.advanceDate),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${advance.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: controller
                              .getStatusColor(advance.status)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          advance.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: controller.getStatusColor(advance.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    controller.getPaymentModeIcon(advance.paymentMode),
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    advance.paymentMode,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (advance.adjustedAmount > 0) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.check_circle,
                        size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Adjusted: ₹${advance.adjustedAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.green,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (!advance.isFullyAdjusted)
                    IconButton(
                      onPressed: () => controller.deleteAdvance(
                        advance.advanceId,
                        advance.employeeName,
                      ),
                      icon: const Icon(Icons.delete, size: 16),
                      color: Colors.red,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                ],
              ),
              if (advance.reason != null) ...[
                const SizedBox(height: 6),
                Text(
                  advance.reason!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagination(EmployeeAdvanceController controller) {
    if (controller.totalPages.value <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed:
                controller.canGoPrevious ? controller.previousPage : null,
            icon: const Icon(Icons.chevron_left),
            iconSize: 20,
          ),
          Text(
            controller.paginationText,
            style: const TextStyle(fontSize: 11),
          ),
          IconButton(
            onPressed: controller.canGoNext ? controller.nextPage : null,
            icon: const Icon(Icons.chevron_right),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  void _showCreateAdvanceDialog(EmployeeAdvanceController controller) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final referenceController = TextEditingController();
    final remarksController = TextEditingController();
    final searchController = TextEditingController();

    Employee? selectedEmployee;
    String selectedPaymentMode = 'Cash';
    final selectedDateObs = DateTime.now().obs;

    // For search functionality
    var filteredEmployees = <Employee>[].obs;
    filteredEmployees.value = controller.employees;

    // Search filter function
    void filterEmployees(String query) {
      if (query.isEmpty) {
        filteredEmployees.value = controller.employees;
      } else {
        filteredEmployees.value = controller.employees.where((employee) {
          final nameLower = employee.name.toLowerCase();

          final queryLower = query.toLowerCase();
          return nameLower.contains(queryLower) ||
              nameLower.startsWith(queryLower);
        }).toList();
      }
    }

    // Load employees if not already loaded
    if (controller.employees.isEmpty) {
      controller.loadEmployees();
    }

    Get.dialog(
      AlertDialog(
        title:
            const Text('New Employee Advance', style: TextStyle(fontSize: 16)),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        content: SizedBox(
          width: Get.width * 0.9,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Loading indicator or employee selection
                  Obx(() {
                    if (controller.isLoadingEmployees.value) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 12),
                              Text(
                                'Loading employees...',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (controller.employees.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No active employees found',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  TextButton.icon(
                                    onPressed: controller.refreshEmployees,
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Retry',
                                        style: TextStyle(fontSize: 12)),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(50, 30),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search field
                        TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            labelText: 'Search Employee',
                            hintText: 'Type name to search...',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      searchController.clear();
                                      filterEmployees('');
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          style: const TextStyle(fontSize: 13),
                          onChanged: filterEmployees,
                        ),
                        const SizedBox(height: 12),

                        // Employee dropdown
                        Obx(() => DropdownButtonFormField<Employee>(
                              value: selectedEmployee,
                              decoration: InputDecoration(
                                labelText: 'Select Employee *',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.person, size: 20),
                                helperText: filteredEmployees.isEmpty
                                    ? 'No employees match your search'
                                    : '${filteredEmployees.length} employee(s) available',
                                helperStyle: const TextStyle(fontSize: 11),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.black),
                              isExpanded: true,
                              items: filteredEmployees.map((employee) {
                                return DropdownMenuItem<Employee>(
                                  value: employee,
                                  child: Text(
                                    employee.displayName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (Employee? value) {
                                selectedEmployee = value;
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select an employee';
                                }
                                return null;
                              },
                            )),
                      ],
                    );
                  }),

                  const SizedBox(height: 12),

                  // Amount Field
                  TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount *',
                      hintText: 'Enter advance amount',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_rupee, size: 20),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 13),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter valid amount greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Payment Mode Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedPaymentMode,
                    decoration: const InputDecoration(
                      labelText: 'Payment Mode *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.payment, size: 20),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(fontSize: 13, color: Colors.black),
                    items: ['Cash', 'UPI', 'Bank Transfer', 'Cheque']
                        .map((mode) => DropdownMenuItem(
                              value: mode,
                              child: Row(
                                children: [
                                  Icon(
                                    controller.getPaymentModeIcon(mode),
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(mode),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) selectedPaymentMode = value;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Date Picker
                  Obx(() => InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: Get.context!,
                            initialDate: selectedDateObs.value,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: kPrimaryColor,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            selectedDateObs.value =
                                picked; // ✅ Update observable
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Advance Date *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today, size: 20),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('yyyy-MM-dd')
                                    .format(selectedDateObs.value),
                                style: const TextStyle(fontSize: 13),
                              ),
                              Icon(Icons.arrow_drop_down,
                                  color: Colors.grey.shade600),
                            ],
                          ),
                        ),
                      )),
                  const SizedBox(height: 12),

                  // Payment Reference
                  TextFormField(
                    controller: referenceController,
                    decoration: const InputDecoration(
                      labelText: 'Payment Reference (Optional)',
                      hintText: 'e.g., Transaction ID, Cheque No.',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.receipt, size: 20),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),

                  // Remarks
                  TextFormField(
                    controller: remarksController,
                    decoration: const InputDecoration(
                      labelText: 'Remarks (Optional)',
                      hintText: 'Add any additional notes',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.notes, size: 20),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                    maxLines: 3,
                    minLines: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          Obx(() => ElevatedButton(
                onPressed: controller.isCreating.value
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          if (selectedEmployee == null) {
                            Get.snackbar(
                              'Validation Error',
                              'Please select an employee',
                              backgroundColor: Colors.red.shade100,
                              colorText: Colors.red.shade800,
                              snackPosition: SnackPosition.BOTTOM,
                              duration: const Duration(seconds: 3),
                            );
                            return;
                          }

                          Get.back();

                          final success = await controller.createAdvance(
                            employeeId: selectedEmployee!.id,
                            employeeName: selectedEmployee!.name,
                            amount: double.parse(amountController.text.trim()),
                            paymentMode: selectedPaymentMode,
                            date: selectedDateObs
                                .value, // ✅ Use the observable value
                            paymentReference:
                                referenceController.text.trim().isEmpty
                                    ? null
                                    : referenceController.text.trim(),
                            remarks: remarksController.text.trim().isEmpty
                                ? null
                                : remarksController.text.trim(),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                ),
                child: controller.isCreating.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Create Advance'),
              )),
        ],
      ),
    );
  }

  void _showFilterDialog(EmployeeAdvanceController controller) {
    String? selectedStatus = controller.selectedStatus.value;
    String? selectedPaymentMode = controller.selectedPaymentMode.value;
    DateTime? fromDate = controller.fromDate.value;
    DateTime? toDate = controller.toDate.value;

    Get.dialog(
      AlertDialog(
        title: const Text('Filter Advances', style: TextStyle(fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 13, color: Colors.black),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...['pending', 'paid', 'adjusted']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.toUpperCase()),
                          )),
                ],
                onChanged: (value) => selectedStatus = value,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedPaymentMode,
                decoration: const InputDecoration(
                  labelText: 'Payment Mode',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 13, color: Colors.black),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...['Cash', 'UPI', 'Bank Transfer', 'Cheque']
                      .map((mode) => DropdownMenuItem(
                            value: mode,
                            child: Text(mode),
                          )),
                ],
                onChanged: (value) => selectedPaymentMode = value,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: Get.context!,
                          initialDate: fromDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) fromDate = picked;
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'From Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          fromDate != null
                              ? DateFormat('yyyy-MM-dd').format(fromDate!)
                              : 'Select',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: Get.context!,
                          initialDate: toDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) toDate = picked;
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'To Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          toDate != null
                              ? DateFormat('yyyy-MM-dd').format(toDate!)
                              : 'Select',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.clearFilters();
              Get.back();
            },
            child: const Text('Clear All'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.applyFilters(
                status: selectedStatus,
                paymentMode: selectedPaymentMode,
                from: fromDate,
                to: toDate,
              );
              Get.back();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showAdvanceDetails(
      EmployeeAdvanceController controller, EmployeeAdvance advance) {
    Get.dialog(
      AlertDialog(
        title: Text(
          'Advance Details',
          style: const TextStyle(fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Employee', advance.employeeName),
              if (advance.tamilName != null)
                _buildDetailRow('Tamil Name', advance.tamilName!),
              const Divider(),
              _buildDetailRow(
                  'Amount', '₹${advance.amount.toStringAsFixed(2)}'),
              _buildDetailRow(
                  'Date', controller.formatDate(advance.advanceDate)),
              _buildDetailRow('Payment Mode', advance.paymentMode),
              if (advance.paymentReference != null)
                _buildDetailRow('Reference', advance.paymentReference!),
              const Divider(),
              _buildDetailRow('Status', advance.status.toUpperCase()),
              _buildDetailRow('Adjusted Amount',
                  '₹${advance.adjustedAmount.toStringAsFixed(2)}'),
              _buildDetailRow('Remaining',
                  '₹${advance.remainingAmount.toStringAsFixed(2)}'),
              if (advance.reason != null) ...[
                const Divider(),
                _buildDetailRow('Reason', advance.reason!),
              ],
              if (advance.remarks != null) ...[
                const Divider(),
                _buildDetailRow('Remarks', advance.remarks!),
              ],
            ],
          ),
        ),
        actions: [
          if (!advance.isFullyAdjusted)
            TextButton(
              onPressed: () {
                Get.back();
                controller.deleteAdvance(
                    advance.advanceId, advance.employeeName);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
