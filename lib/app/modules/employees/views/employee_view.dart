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

  final List<Color> backgroundColors = [
    kLightGreen,
    kListBg,
  ];

  final List<Color> avatarBorderColors = [
    kLightYellow,
    kLightGreen,
  ];

  ViewEmployees({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Compact Header with Search
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: TextField(
                    onChanged: controller.runFilter,
                    style: TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search employees...',
                      hintStyle:
                          TextStyle(color: Colors.grey[400], fontSize: 14),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      prefixIcon:
                          Icon(Icons.search, color: kSecondaryColor, size: 20),
                    ),
                  ),
                ),
              ),
            ),
          ),

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
            CircularProgressIndicator(color: kPrimaryColor, strokeWidth: 3),
            SizedBox(height: 16),
            Text('Loading employees...',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      );
    }

    if (controller.filteredEmployees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
            ),
            SizedBox(height: 16),
            Text('No employees found',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800])),
            SizedBox(height: 6),
            Text('Try adjusting your search',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: controller.refreshEmployees,
              icon: Icon(Icons.refresh, size: 18),
              label: Text('Refresh', style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
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
            color: kPrimaryColor,
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: paginatedEmployees.length,
              itemBuilder: (context, index) {
                final employee = paginatedEmployees[index];
                return _buildEmployeeCard(employee, index);
              },
            ),
          ),
        ),

        // Compact Pagination
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Obx(() => _buildPaginationControls()),
        ),
      ],
    );
  }

  Widget _buildEmployeeCard(Employee employee, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: backgroundColors[index % 2],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!.withOpacity(0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showEmployeeDetailsDialog(employee),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image with gender indicator
                GestureDetector(
                  onTap: () {
                    final imageUrl = controller.getEmployeeImageUrl(employee);
                    _showImageDialog(imageUrl);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: avatarBorderColors[index % 2],
                        width: 2.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        _buildEmployeeAvatar(employee, 48),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: _buildGenderBadge(employee.gender),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 12),

                // Employee Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Employee Name
                      Text(
                        controller.getEmployeeDisplayName(employee),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                          fontFamily: 'NotoSansTamil',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Tamil Name
                      if (employee.tamilName != null &&
                          employee.tamilName!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            employee.tamilName!,
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                              fontFamily: 'NotoSansTamil',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      SizedBox(height: 4),
                      // Employee Type and Gender
                      Row(
                        children: [
                          Text(
                            employee.empType ?? 'N/A',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          Text(' • ',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600])),
                          _buildGenderIcon(employee.gender),
                          SizedBox(width: 3),
                          Text(
                            employee.gender ?? 'N/A',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      // Joining Date and Status
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 12, color: Colors.grey[500]),
                          SizedBox(width: 4),
                          Text(
                            employee.joiningDate != null
                                ? DateFormat('dd MMM yyyy')
                                    .format(employee.joiningDate!)
                                : 'N/A',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          Spacer(),
                          GestureDetector(
                            onTap: () =>
                                _showStatusChangeConfirmation(employee),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (employee.status ?? false)
                                    ? Colors.green.withOpacity(0.15)
                                    : Colors.red.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
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
                                  SizedBox(width: 3),
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
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Menu Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: PopupMenuButton<String>(
                    icon:
                        Icon(Icons.more_vert, color: kSecondaryColor, size: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_outlined,
                                color: kPrimaryColor, size: 18),
                            SizedBox(width: 10),
                            Text('View', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined,
                                color: kPrimaryColor, size: 18),
                            SizedBox(width: 10),
                            Text('Edit', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                color: Colors.red, size: 18),
                            SizedBox(width: 10),
                            Text('Delete',
                                style:
                                    TextStyle(color: Colors.red, fontSize: 14)),
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
                          Get.toNamed(Routes.EDIT_EMPLOYEE,
                              arguments: {'id': employee.id.toString()});
                          break;
                        case 'delete':
                          _showDeleteConfirmation(employee);
                          break;
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderIcon(String? gender) {
    if (gender == null) {
      return Icon(Icons.help_outline, size: 13, color: Colors.grey);
    }

    String genderLower = gender.toLowerCase();

    if (genderLower.contains('female') || genderLower.contains('woman')) {
      return Icon(Icons.face_3, size: 13, color: Colors.pink[400]);
    } else if (genderLower.contains('male') || genderLower.contains('man')) {
      return Icon(Icons.face, size: 13, color: Colors.blue[400]);
    } else {
      return Icon(Icons.person_outline, size: 13, color: Colors.grey);
    }
  }

  Widget _buildGenderBadge(String? gender) {
    if (gender == null) {
      return SizedBox.shrink();
    }

    String genderLower = gender.toLowerCase();
    Color badgeColor;
    IconData iconData;

    if (genderLower.contains('female') || genderLower.contains('woman')) {
      badgeColor = Colors.pink;
      iconData = Icons.face_3;
    } else if (genderLower.contains('male') || genderLower.contains('man')) {
      badgeColor = Colors.blue;
      iconData = Icons.face;
    } else {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Icon(
        iconData,
        size: 11,
        color: Colors.white,
      ),
    );
  }

  Widget _buildEmployeeAvatar(Employee employee, double size) {
    final imageUrl = controller.getEmployeeImageUrl(employee);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[200],
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
            fontFamily: 'NotoSansTamil',
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
        // Previous
        Expanded(
          child: ElevatedButton(
            onPressed:
                controller.hasPrevious.value ? controller.previousPage : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: controller.hasPrevious.value
                  ? kPrimaryColor
                  : Colors.grey[200],
              foregroundColor: controller.hasPrevious.value
                  ? Colors.white
                  : Colors.grey[400],
              padding: EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chevron_left,
                  size: 18,
                  color: Colors.white,
                ),
                SizedBox(width: 2),
                Text('Previous',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ),

        // Page Info
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${controller.currentPage.value}/${controller.totalPages.value}',
              style: TextStyle(
                color: kSecondaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),

        // Next
        Expanded(
          child: ElevatedButton(
            onPressed: controller.hasNext.value ? controller.nextPage : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  controller.hasNext.value ? kPrimaryColor : Colors.grey[200],
              foregroundColor:
                  controller.hasNext.value ? Colors.white : Colors.grey[400],
              padding: EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Next',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                SizedBox(width: 2),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: kLightColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showEmployeeDetailsDialog(Employee employee) {
    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: Get.width * 0.9,
          constraints: BoxConstraints(maxHeight: Get.height * 0.85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.person, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Employee Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Get.back(),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            _buildEmployeeAvatar(employee, 100),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: _buildGenderBadge(employee.gender),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildDetailCard(
                        'Name',
                        controller.getEmployeeDisplayName(employee),
                        Icons.person,
                        useTamilFont: true,
                      ),
                      SizedBox(height: 12),
                      if (employee.tamilName != null &&
                          employee.tamilName!.isNotEmpty)
                        _buildDetailCard(
                          'Tamil Name',
                          employee.tamilName!,
                          Icons.translate,
                          useTamilFont: true,
                        ),
                      if (employee.tamilName != null &&
                          employee.tamilName!.isNotEmpty)
                        SizedBox(height: 12),
                      _buildDetailCard(
                        'Joining Date',
                        employee.joiningDate != null
                            ? DateFormat('dd MMM yyyy')
                                .format(employee.joiningDate!)
                            : 'N/A',
                        Icons.calendar_today,
                      ),
                      SizedBox(height: 12),
                      _buildDetailCard(
                        'Employee Type',
                        employee.empType ?? 'N/A',
                        Icons.work,
                      ),
                      SizedBox(height: 12),
                      _buildDetailCardWithGender(
                        'Gender',
                        employee.gender ?? 'N/A',
                        employee.gender,
                      ),
                      SizedBox(height: 12),
                      _buildDetailCard(
                        'Contact',
                        employee.contact ?? 'N/A',
                        Icons.phone,
                      ),
                      SizedBox(height: 12),
                      _buildDetailCard(
                        'Status',
                        (employee.status ?? false) ? 'Active' : 'Inactive',
                        Icons.info_outline,
                        highlight: true,
                        highlightColor: (employee.status ?? false)
                            ? Colors.green
                            : Colors.red,
                      ),
                    ],
                  ),
                ),
              ),

              // Actions
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.back();
                          Get.toNamed(Routes.EDIT_EMPLOYEE,
                              arguments: {'id': employee.id.toString()});
                        },
                        icon: Icon(Icons.edit_outlined, color: kLightColor),
                        label: Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
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
                        icon: Icon(
                          Icons.delete_outline,
                          color: kRed,
                        ),
                        label: Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red, width: 1.5),
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
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

  Widget _buildDetailCard(
    String label,
    String value,
    IconData icon, {
    bool highlight = false,
    Color? highlightColor,
    bool useTamilFont = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight
            ? (highlightColor ?? kPrimaryColor).withOpacity(0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? (highlightColor ?? kPrimaryColor).withOpacity(0.3)
              : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: highlight
                  ? (highlightColor ?? kPrimaryColor).withOpacity(0.15)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: highlight
                  ? (highlightColor ?? kPrimaryColor)
                  : kSecondaryColor,
              size: 22,
            ),
          ),
          SizedBox(width: 16),
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
                  style: TextStyle(
                    fontSize: highlight ? 16 : 15,
                    fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                    color: highlight
                        ? (highlightColor ?? kPrimaryColor)
                        : Colors.grey[900],
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

  Widget _buildDetailCardWithGender(
    String label,
    String value,
    String? gender,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: _buildGenderIcon(gender),
          ),
          SizedBox(width: 16),
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
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
        borderRadius: 12,
        margin: EdgeInsets.all(16),
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    Get.dialog(
      Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 50, color: Colors.white),
                              SizedBox(height: 16),
                              Text('Failed to load image',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                  ),
                ),
              ],
            ),
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
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: actionColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(actionIcon, size: 48, color: actionColor),
              ),
              SizedBox(height: 20),
              Text(
                '$actionText Employee',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Are you sure you want to $statusText this employee?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        _buildEmployeeAvatar(employee, 40),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: _buildGenderBadge(employee.gender),
                        ),
                      ],
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.getEmployeeDisplayName(employee),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              fontFamily: 'NotoSansTamil',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (employee.tamilName != null &&
                              employee.tamilName!.isNotEmpty)
                            Text(
                              employee.tamilName!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                                fontFamily: 'NotoSansTamil',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: currentStatus
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Current: ${currentStatus ? "Active" : "Inactive"}',
                              style: TextStyle(
                                fontSize: 9,
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
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_forward, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 6),
                  Text(
                    'Will become: ${!currentStatus ? "Active" : "Inactive"}',
                    style: TextStyle(
                      color:
                          !currentStatus ? Colors.green[700] : Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancel',
                          style: TextStyle(color: Colors.grey[700])),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        controller.toggleEmployeeStatus(employee.id,
                            newStatus: !currentStatus);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: actionColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(actionText,
                          style: TextStyle(fontWeight: FontWeight.w600)),
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

  void _showDeleteConfirmation(Employee employee) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline, size: 48, color: Colors.red),
              ),
              SizedBox(height: 20),
              Text(
                'Delete Employee?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Are you sure you want to delete this employee?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        _buildEmployeeAvatar(employee, 40),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: _buildGenderBadge(employee.gender),
                        ),
                      ],
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.getEmployeeDisplayName(employee),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              fontFamily: 'NotoSansTamil',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (employee.tamilName != null &&
                              employee.tamilName!.isNotEmpty)
                            Text(
                              employee.tamilName!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                                fontFamily: 'NotoSansTamil',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancel',
                          style: TextStyle(color: Colors.grey[700])),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        controller.deleteEmployee(employee.id ?? '');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text('Delete',
                          style: TextStyle(fontWeight: FontWeight.w600)),
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
}
