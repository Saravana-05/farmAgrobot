import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/values/app_colors.dart';
import '../../../data/models/wages/wages_model.dart';
import '../../../routes/app_pages.dart';
import '../controller/view_wages_controller.dart';


class ViewWages extends StatelessWidget {
  final WagesViewController controller = Get.put(WagesViewController());

  final TextStyle textStyle = const TextStyle(fontSize: 12.0);
  final TextStyle boldTextStyle =
      const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold);

  final List<Color> backgroundColors = [
    kLightGreen.withOpacity(0.9),
    kListBg.withOpacity(0.9)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.only(top: 20.0, right: 20.0, left: 20.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25.0),
                color: Colors.grey[100],
              ),
              child: TextField(
                onChanged: controller.runFilter,
                decoration: InputDecoration(
                  hintText: 'Search wages...',
                  hintStyle: TextStyle(color: kSecondaryColor),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: kSecondaryColor),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8.0),

          // Date filters
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // From Date Button
                    SizedBox(
                      width: 130,
                      child: Obx(() => TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.grey[50],
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            icon: const Icon(Icons.calendar_today,
                                color: kPrimaryColor),
                            label: Text(
                              controller.fromDate.value == null
                                  ? 'From Date'
                                  : DateFormat('dd MMM yyyy')
                                      .format(controller.fromDate.value!),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: kSecondaryColor),
                            ),
                            onPressed: () => _selectFromDate(context),
                          )),
                    ),

                    // To Date Button
                    SizedBox(
                      width: 130,
                      child: Obx(() => TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.grey[50],
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            icon: const Icon(Icons.calendar_today,
                                color: kPrimaryColor),
                            label: Text(
                              controller.toDate.value == null
                                  ? 'To Date'
                                  : DateFormat('dd MMM yyyy')
                                      .format(controller.toDate.value!),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: kSecondaryColor),
                            ),
                            onPressed: () => _selectToDate(context),
                          )),
                    ),

                    // Clear Filters Button
                    Container(
                      width: 48,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.clear, color: kPrimaryColor),
                        onPressed: controller.clearFilters,
                        tooltip: 'Clear Filters',
                      ),
                    ),
                  ],
                ),

                // Summary Information
                SizedBox(height: 16),
                Obx(() => Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        controller.getSummaryText(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8.0),

          // Wages List
          Expanded(
            child: Obx(() => _buildWagesList()),
          ),
        ],
      ),
    );
  }

  Widget _buildWagesList() {
    if (controller.isLoading.value) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: kPrimaryColor),
            SizedBox(height: 16),
            Text('Loading wages...'),
          ],
        ),
      );
    }

    if (controller.filteredWages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No wages found.'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: controller.refreshWages,
              child: Text('Refresh'),
            ),
          ],
        ),
      );
    }

    final paginatedWages = controller.getPaginatedWages();

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.refreshWages,
            child: ListView.builder(
              itemCount: paginatedWages.length,
              itemBuilder: (context, index) {
                final wage = paginatedWages[index];
                final backgroundColor = backgroundColors[index % 2];

                return Container(
                  color: backgroundColor,
                  padding: EdgeInsets.all(10.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Employee Icon
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kSecondaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.person, color: kSecondaryColor),
                      ),

                      SizedBox(width: 12),

                      // Wage Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              wage.employeeName ?? 'Unknown Employee',
                              style: boldTextStyle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Effective: ${controller.formatTimestamp(wage.effectiveFrom)} - ${controller.formatTimestamp(wage.effectiveTo)}',
                              style: textStyle,
                            ),
                            Text(
                              '₹${_getSafeAmount(wage.amount)}',
                              style:
                                  boldTextStyle.copyWith(color: kPrimaryColor),
                            ),
                          ],
                        ),
                      ),

                      // Three Dots Menu
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: kSecondaryColor),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'view',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.visibility_outlined,
                                    color: kPrimaryColor),
                                SizedBox(width: 8),
                                Text('View'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.edit_outlined, color: kPrimaryColor),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.delete_outline, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          switch (value) {
                            case 'view':
                              _showWageDetailsDialog(wage);
                              break;
                            case 'edit':
                              Get.toNamed(Routes.WAGES,
                                  arguments: {'id': wage.id.toString()});
                              break;
                            case 'delete':
                              _showDeleteConfirmation(wage);
                              break;
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // Pagination Controls
        Padding(
          padding: EdgeInsets.all(16),
          child: Obx(() => _buildPaginationControls()),
        ),
      ],
    );
  }

  Widget _buildPaginationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Previous button
        ElevatedButton.icon(
          onPressed:
              controller.hasPrevious.value ? controller.previousPage : null,
          icon: Icon(Icons.chevron_left),
          label: Text('Previous'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
          ),
        ),

        // Page info
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Page ${controller.currentPage.value} of ${controller.totalPages.value}',
            style: TextStyle(
              color: kSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Next button
        ElevatedButton.icon(
          onPressed: controller.hasNext.value ? controller.nextPage : null,
          icon: Icon(Icons.chevron_right),
          label: Text('Next'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  void _selectFromDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.fromDate.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    controller.selectFromDate(picked);
  }

  void _selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.toDate.value ?? DateTime.now(),
      firstDate: controller.fromDate.value ?? DateTime(2000),
      lastDate: DateTime(2101),
    );
    controller.selectToDate(picked);
  }

  // Show detailed wage view dialog
  void _showWageDetailsDialog(Wage wage) {
    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.all(20),
        child: Container(
          width: Get.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: Get.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Wage Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Employee Name
                      _buildDetailRow(
                        'Employee Name',
                        wage.employeeName ?? 'Unknown Employee',
                        Icons.person,
                      ),

                      SizedBox(height: 16),

                      // Amount
                      _buildDetailRow(
                        'Amount',
                        '₹${_getSafeAmount(wage.amount)}',
                        Icons.currency_rupee,
                        valueColor: kPrimaryColor,
                        valueStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),

                      SizedBox(height: 16),

                      // Effective From
                      _buildDetailRow(
                        'Effective From',
                        controller.formatTimestamp(wage.effectiveFrom),
                        Icons.calendar_today,
                      ),

                      SizedBox(height: 16),

                      // Effective To
                      _buildDetailRow(
                        'Effective To',
                        controller.formatTimestamp(wage.effectiveTo),
                        Icons.calendar_today,
                      ),

                      SizedBox(height: 16),

                      // Notes/Remarks
                      if (wage.remarks != null && wage.remarks!.isNotEmpty)
                        _buildDetailRow(
                          'Notes',
                          wage.remarks!,
                          Icons.note,
                        ),
                    ],
                  ),
                ),
              ),

              // Footer Actions
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.back();
                          Get.toNamed(Routes.WAGES,
                              arguments: {'id': wage.id.toString()});
                        },
                        icon: Icon(Icons.edit),
                        label: Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Get.back();
                          _showDeleteConfirmation(wage);
                        },
                        icon: Icon(Icons.delete_outline, color: Colors.red),
                        label: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
    TextStyle? valueStyle,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: kSecondaryColor, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: valueStyle ??
                      TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: valueColor ?? Colors.black87,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Wage wage) {
    Get.dialog(
      AlertDialog(
        title: Text("Confirm Deletion"),
        content: Text(
            "Are you sure you want to delete wage for '${wage.employeeName ?? 'Unknown Employee'}'?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              controller.deleteWage(wage.id.toString());
              Get.back();
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Helper method to safely get amount
  String _getSafeAmount(dynamic amount) {
    if (amount == null) return '0';

    try {
      if (amount is num) {
        return amount.toStringAsFixed(2);
      } else if (amount is String) {
        double? parsed = double.tryParse(amount);
        return parsed?.toStringAsFixed(2) ?? '0.00';
      }
    } catch (e) {
      print('Error formatting amount: $e');
    }
    return '0.00';
  }
}