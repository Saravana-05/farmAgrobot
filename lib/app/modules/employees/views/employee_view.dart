import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/values/app_colors.dart';
import '../../../data/models/employee/emp_model.dart';
import '../controller/emp_view_controller.dart';

class ViewEmployees extends StatelessWidget {
  final EmployeeViewController controller = Get.put(EmployeeViewController());

  final TextStyle textStyle = const TextStyle(fontSize: 12.0);
  final TextStyle boldTextStyle =
      const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold);

  final List<Color> backgroundColors = [
    kLightGreen.withOpacity(0.9),
    kListBg.withOpacity(0.9)
  ];

  ViewEmployees({Key? key}) : super(key: key);

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
                  hintText: 'Search employees...',
                  hintStyle: TextStyle(color: kSecondaryColor),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  prefixIcon: Icon(Icons.search, color: kSecondaryColor),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8.0),

         
          const SizedBox(height: 8.0),

          // Employees List
          Expanded(
            child: Obx(() => _buildEmployeesList()),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeesList() {
    if (controller.isLoading.value) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: kPrimaryColor),
            SizedBox(height: 16),
            Text('Loading employees...'),
          ],
        ),
      );
    }

    if (controller.filteredEmployees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No employees found.'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: controller.refreshEmployees,
              child: Text('Refresh'),
            ),
          ],
        ),
      );
    }

    final paginatedEmployees = controller.getPaginatedEmployees();

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.refreshEmployees,
            child: ListView.builder(
              itemCount: paginatedEmployees.length,
              itemBuilder: (context, index) {
                final employee = paginatedEmployees[index];
                final backgroundColor = backgroundColors[index % 2];

                return Container(
                  color: backgroundColor,
                  padding: EdgeInsets.all(10.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Profile Image
                      GestureDetector(
                        onTap: () => _showImageDialog(employee.imageUrl),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[200],
                          ),
                          child: ClipOval(
                            child: employee.imageUrl != null && employee.imageUrl!.isNotEmpty
                                ? Image.network(
                                    employee.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.person, 
                                          color: kSecondaryColor, size: 30);
                                    },
                                  )
                                : Icon(Icons.person, 
                                    color: kSecondaryColor, size: 30),
                          ),
                        ),
                      ),

                      SizedBox(width: 10),

                      // Employee Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employee.name,
                              style: boldTextStyle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              employee.tamilName,
                              style: textStyle.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${employee.empType} • ${employee.gender}',
                              style: textStyle,
                            ),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, 
                                     size: 12, color: kSecondaryColor),
                                SizedBox(width: 4),
                                Text(
                                  DateFormat('dd MMM yyyy')
                                      .format(employee.joiningDate),
                                  style: textStyle,
                                ),
                                Spacer(),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: employee.status 
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    employee.status ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: employee.status 
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
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
                              _showEmployeeDetailsDialog(employee);
                              break;
                            case 'edit':
                              Get.snackbar('Info', 'Edit functionality - Navigate to edit page');
                              break;
                            case 'delete':
                              _showDeleteConfirmation(employee);
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

  // Employee Details Dialog
  void _showEmployeeDetailsDialog(Employee employee) {
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
                        'Employee Details',
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
                      // Profile Image Section
                      Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[200],
                            border: Border.all(
                                color: kPrimaryColor, width: 3),
                          ),
                          child: ClipOval(
                            child: employee.imageUrl != null && employee.imageUrl!.isNotEmpty
                                ? Image.network(
                                    employee.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.person, 
                                          color: kSecondaryColor, size: 60);
                                    },
                                  )
                                : Icon(Icons.person, 
                                    color: kSecondaryColor, size: 60),
                          ),
                        ),
                      ),

                      SizedBox(height: 24),

                      // Employee Details
                      _buildDetailRow('Name', employee.name, Icons.person),
                      SizedBox(height: 16),
                      _buildDetailRow('Tamil Name', employee.tamilName, Icons.translate),
                      SizedBox(height: 16),
                      _buildDetailRow('Joining Date', 
                          DateFormat('dd MMM yyyy').format(employee.joiningDate),
                          Icons.calendar_today),
                      SizedBox(height: 16),
                      _buildDetailRow('Employee Type', employee.empType, Icons.work),
                      SizedBox(height: 16),
                      _buildDetailRow('Gender', employee.gender, Icons.person_outline),
                      SizedBox(height: 16),
                      _buildDetailRow('Contact', employee.contact, Icons.phone),
                      SizedBox(height: 16),
                      _buildDetailRow('Status', employee.status ? 'Active' : 'Inactive',
                          Icons.info_outline,
                          valueColor: employee.status ? Colors.green : Colors.red,
                          valueStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: employee.status ? Colors.green : Colors.red,
                          )),
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
                          Get.snackbar('Info', 'Edit functionality');
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
                          _showDeleteConfirmation(employee);
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
                        color: valueColor ?? Colors.black87,),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      Get.snackbar(
        'No Image',
        'No profile image available for this employee',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: Get.width * 0.8,
                  maxHeight: Get.height * 0.6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, 
                                 size: 48, color: Colors.grey[600]),
                            SizedBox(height: 8),
                            Text('Failed to load image',
                                 style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: Text('Close'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Employee employee) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_outlined, 
                 color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Confirm Deletion'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this employee?'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                    ),
                    child: ClipOval(
                      child: employee.imageUrl != null && employee.imageUrl!.isNotEmpty
                          ? Image.network(
                              employee.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.person, 
                                     color: kSecondaryColor, size: 20);
                              },
                            )
                          : Icon(Icons.person, 
                               color: kSecondaryColor, size: 20),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          employee.tamilName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: kSecondaryColor,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteEmployee(employee.id);
            },
            child: Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}