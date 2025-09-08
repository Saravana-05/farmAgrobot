import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/values/app_colors.dart';
import '../../../data/models/employee/emp_model.dart';
import '../../../routes/app_pages.dart';
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
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  prefixIcon: Icon(Icons.search, color: kSecondaryColor),
                ),
                // Add support for Tamil text input
                style: TextStyle(
                  fontFamily: 'NotoSansTamil', // For Tamil text input
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
                      // Profile Image with proper handling
                      GestureDetector(
                        onTap: () {
                          final imageUrl =
                              controller.getEmployeeImageUrl(employee);
                          _showImageDialog(imageUrl);
                        },
                        child: _buildEmployeeAvatar(employee, 50),
                      ),

                      SizedBox(width: 10),

                      // Employee Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Employee Name with Tamil support
                            Text(
                              controller.getEmployeeDisplayName(employee),
                              style: boldTextStyle.copyWith(
                                fontFamily:
                                    'NotoSansTamil', // Tamil font support
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Tamil Name
                            if (employee.tamilName != null &&
                                employee.tamilName!.isNotEmpty)
                              Text(
                                employee.tamilName!,
                                style: textStyle.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600],
                                  fontFamily:
                                      'NotoSansTamil', // Tamil font support
                                ),
                              ),
                            Text(
                              '${employee.empType ?? 'N/A'} • ${employee.gender ?? 'N/A'}',
                              style: textStyle,
                            ),
                            Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 12, color: kSecondaryColor),
                                SizedBox(width: 4),
                                Text(
                                  employee.joiningDate != null
                                      ? DateFormat('dd MMM yyyy')
                                          .format(employee.joiningDate!)
                                      : 'N/A',
                                  style: textStyle,
                                ),
                                Spacer(),
                                GestureDetector(
                                  onTap: () =>
                                      _showStatusChangeConfirmation(employee),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (employee.status ?? false)
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: (employee.status ?? false)
                                            ? Colors.green.withOpacity(0.3)
                                            : Colors.red.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          (employee.status ?? false)
                                              ? 'Active'
                                              : 'Inactive',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: (employee.status ?? false)
                                                ? Colors.green[700]
                                                : Colors.red[700],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(width: 2),
                                        Icon(
                                          Icons.touch_app_outlined,
                                          size: 10,
                                          color: (employee.status ?? false)
                                              ? Colors.green[700]
                                              : Colors.red[700],
                                        ),
                                      ],
                                    ),
                                  ),
                                )
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
                                    color: kSecondaryColor),
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
                              // Updated to use Get.to() navigation
                              Get.toNamed(Routes.EDIT_EMPLOYEE,
                                  arguments: {'id': employee.id.toString()});
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

  Widget _buildEmployeeAvatar(Employee employee, double size) {
    final imageUrl = controller.getEmployeeImageUrl(employee);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: SizedBox(
                      width: size * 0.4,
                      height: size * 0.4,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(kPrimaryColor),
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) {
                  print('Image load error for ${employee.name}: $error');
                  return _buildAvatarFallback(employee, size);
                },
                httpHeaders: {
                  'User-Agent': 'YourApp/1.0',
                },
              )
            : _buildAvatarFallback(employee, size),
      ),
    );
  }

  Widget _buildAvatarFallback(Employee employee, double size) {
    String initials = _getInitials(controller.getEmployeeDisplayName(employee));

    return Container(
      color: _getAvatarColor(employee.name ?? ''),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansTamil', // Support Tamil initials
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    List<String> nameParts = name.trim().split(' ');

    if (nameParts.length == 1) {
      return name.length >= 2
          ? name.substring(0, 2).toUpperCase()
          : name.substring(0, 1).toUpperCase();
    } else {
      String first =
          nameParts[0].isNotEmpty ? nameParts[0].substring(0, 1) : '';
      String second = nameParts.length > 1 && nameParts[1].isNotEmpty
          ? nameParts[1].substring(0, 1)
          : '';
      return (first + second).toUpperCase();
    }
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    int hash = name.hashCode;
    return colors[hash.abs() % colors.length];
  }

  Widget _buildPaginationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Previous button
        ElevatedButton.icon(
          onPressed:
              controller.hasPrevious.value ? controller.previousPage : null,
          icon: Icon(Icons.chevron_left, color: kLightColor),
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
          icon: Icon(Icons.chevron_right, color: kLightColor),
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
                        child: _buildEmployeeAvatar(employee, 120),
                      ),

                      SizedBox(height: 24),

                      // Employee Details
                      _buildDetailRow(
                          'Name',
                          controller.getEmployeeDisplayName(employee),
                          Icons.person,
                          useTamilFont: true),
                      SizedBox(height: 16),
                      if (employee.tamilName != null &&
                          employee.tamilName!.isNotEmpty)
                        _buildDetailRow(
                            'Tamil Name', employee.tamilName!, Icons.translate,
                            useTamilFont: true),
                      SizedBox(height: 16),
                      _buildDetailRow(
                          'Joining Date',
                          employee.joiningDate != null
                              ? DateFormat('dd MMM yyyy')
                                  .format(employee.joiningDate!)
                              : 'N/A',
                          Icons.calendar_today),
                      SizedBox(height: 16),
                      _buildDetailRow('Employee Type',
                          employee.empType ?? 'N/A', Icons.work),
                      SizedBox(height: 16),
                      _buildDetailRow('Gender', employee.gender ?? 'N/A',
                          Icons.person_outline),
                      SizedBox(height: 16),
                      _buildDetailRow(
                          'Contact', employee.contact ?? 'N/A', Icons.phone),
                      SizedBox(height: 16),
                      _buildDetailRow(
                          'Status',
                          (employee.status ?? false) ? 'Active' : 'Inactive',
                          Icons.info_outline,
                          valueColor: (employee.status ?? false)
                              ? Colors.green
                              : Colors.red,
                          valueStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: (employee.status ?? false)
                                ? Colors.green
                                : Colors.red,
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
                        icon: Icon(Icons.edit_outlined, color: kPrimaryColor),
                        label:
                            Text('Edit', style: TextStyle(color: kBlackColor)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: kPrimaryColor),
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
    bool useTamilFont = false,
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
                        fontFamily: useTamilFont ? 'NotoSansTamil' : null,
                      ),
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
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(
                      width: 200,
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(color: kPrimaryColor),
                      ),
                    ),
                    errorWidget: (context, url, error) {
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

  void _showStatusChangeConfirmation(Employee employee) {
    bool currentStatus = employee.status ?? false;
    String actionText = currentStatus ? 'Deactivate' : 'Activate';
    String statusText = currentStatus ? 'deactivate' : 'activate';
    Color actionColor = currentStatus ? Colors.orange : Colors.green;
    IconData actionIcon = currentStatus ? Icons.toggle_off : Icons.toggle_on;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            Icon(actionIcon, color: actionColor, size: 28),
            SizedBox(width: 8),
            Text('$actionText Employee'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to $statusText this employee?'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _buildEmployeeAvatar(employee, 40),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.getEmployeeDisplayName(employee),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: 'NotoSansTamil',
                          ),
                        ),
                        if (employee.tamilName != null &&
                            employee.tamilName!.isNotEmpty)
                          Text(
                            employee.tamilName!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                              fontFamily: 'NotoSansTamil',
                            ),
                          ),
                        SizedBox(height: 4),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: currentStatus
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Current: ${currentStatus ? "Active" : "Inactive"}',
                            style: TextStyle(
                              fontSize: 10,
                              color: currentStatus
                                  ? Colors.green[700]
                                  : Colors.red[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.arrow_forward, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  'Will become: ${!currentStatus ? "Active" : "Inactive"}',
                  style: TextStyle(
                    color: !currentStatus ? Colors.green[700] : Colors.red[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
              // Call the controller method to toggle status
              controller.toggleEmployeeStatus(employee.id,
                  newStatus: !currentStatus);
            },
            child: Text(actionText),
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
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
            Icon(Icons.warning_amber_outlined, color: Colors.orange, size: 28),
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
                  _buildEmployeeAvatar(employee, 40),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.getEmployeeDisplayName(employee),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: 'NotoSansTamil',
                          ),
                        ),
                        if (employee.tamilName != null &&
                            employee.tamilName!.isNotEmpty)
                          Text(
                            employee.tamilName!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                              fontFamily: 'NotoSansTamil',
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
              controller.deleteEmployee(employee.id ?? '');
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
