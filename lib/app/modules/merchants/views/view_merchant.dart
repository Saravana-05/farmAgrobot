import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/values/app_colors.dart';
import '../../../data/models/merchant/merchant_model.dart';
import '../../../routes/app_pages.dart';
import '../controller/view_merchant_controller.dart';

class ViewMerchants extends StatelessWidget {
  final MerchantsViewController controller = Get.put(MerchantsViewController());

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
                  hintText: 'Search merchants...',
                  hintStyle: TextStyle(color: kSecondaryColor),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: kSecondaryColor),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8.0),

          // Action buttons and summary
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Add Merchant Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Get.toNamed(Routes.ADD_MERCHANT),
                        icon: Icon(Icons.add, color: Colors.white),
                        label: Text(
                          'Add New Merchant',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),

                    // Refresh Button
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Obx(() => controller.isLoading.value
                          ? Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: kPrimaryColor,
                                ),
                              ),
                            )
                          : IconButton(
                              onPressed: controller.refreshMerchants,
                              icon: Icon(Icons.refresh, color: kPrimaryColor),
                            )),
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

          // Merchants List
          Expanded(
            child: Obx(() => _buildMerchantsList()),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantsList() {
    if (controller.isLoading.value) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: kPrimaryColor),
            SizedBox(height: 16),
            Text('Loading merchants...'),
          ],
        ),
      );
    }

    if (controller.filteredMerchants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No merchants found.'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: controller.refreshMerchants,
              child: Text('Refresh'),
            ),
          ],
        ),
      );
    }

    final paginatedMerchants = controller.getPaginatedMerchants();

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.refreshMerchants,
            child: ListView.builder(
              itemCount: paginatedMerchants.length,
              itemBuilder: (context, index) {
                final merchant = paginatedMerchants[index];
                final backgroundColor = backgroundColors[index % 2];

                return Container(
                  color: backgroundColor,
                  padding: EdgeInsets.all(10.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Merchant Icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
                        ),
                        child: Icon(
                          Icons.store,
                          color: kPrimaryColor,
                          size: 30,
                        ),
                      ),

                      SizedBox(width: 12),

                      // Merchant Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              merchant.name,
                              style: boldTextStyle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    merchant.address,
                                    style: textStyle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                                SizedBox(width: 4),
                                Text(
                                  controller.formatContactNumber(merchant.contact),
                                  style: textStyle,
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.payment, size: 14, color: Colors.grey[600]),
                                SizedBox(width: 4),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getPaymentTermsColor(merchant.paymentTerms),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    merchant.paymentTerms,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (merchant.createdAt != null) ...[
                              SizedBox(height: 4),
                              Text(
                                'Added on ${DateFormat('dd MMM yyyy').format(merchant.createdAt!)}',
                                style: textStyle.copyWith(
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
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
                                Icon(Icons.visibility_outlined, color: kPrimaryColor),
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
                              _showMerchantDetailsDialog(merchant);
                              break;
                            case 'edit':
                              controller.handleEditMerchant(merchant);
                              break;
                            case 'delete':
                              _showDeleteConfirmation(merchant);
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

  // Get color for payment terms badge
  Color _getPaymentTermsColor(String paymentTerms) {
    switch (paymentTerms.toLowerCase()) {
      case 'cash':
        return Colors.green;
      case 'card':
        return Colors.blue;
      case 'upi':
        return Colors.orange;
      case 'online':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // Method to show detailed merchant view dialog
  void _showMerchantDetailsDialog(Merchant merchant) {
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
                    Icon(Icons.store, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Merchant Details',
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
                      // Merchant Name
                      _buildDetailRow(
                        'Merchant Name',
                        merchant.name,
                        Icons.store,
                        valueStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),

                      SizedBox(height: 16),

                      // Merchant ID
                      _buildDetailRow(
                        'Merchant ID',
                        merchant.id,
                        Icons.tag,
                      ),

                      SizedBox(height: 16),

                      // Address
                      _buildDetailRow(
                        'Address',
                        merchant.address,
                        Icons.location_on,
                      ),

                      SizedBox(height: 16),

                      // Contact
                      _buildDetailRow(
                        'Contact Number',
                        controller.formatContactNumber(merchant.contact),
                        Icons.phone,
                      ),

                      SizedBox(height: 16),

                      // Payment Terms
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.payment, color: kSecondaryColor, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Payment Terms',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getPaymentTermsColor(merchant.paymentTerms),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      controller.getPaymentTermsDisplayName(merchant.paymentTerms),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (merchant.createdAt != null) ...[
                        SizedBox(height: 16),
                        _buildDetailRow(
                          'Created Date',
                          DateFormat('dd MMM yyyy, hh:mm a')
                              .format(merchant.createdAt!),
                          Icons.calendar_today,
                        ),
                      ],

                      if (merchant.updatedAt != null &&
                          merchant.updatedAt != merchant.createdAt) ...[
                        SizedBox(height: 16),
                        _buildDetailRow(
                          'Last Updated',
                          controller.formatTimestamp(merchant.updatedAt),
                          Icons.update,
                        ),
                      ],
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
                          Get.back(); // Close the dialog first
                          controller.handleEditMerchant(merchant);
                        },
                        icon: Icon(Icons.edit_outlined, color: kPrimaryColor),
                        label: Text('Edit', style: TextStyle(color: kBlackColor)),
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
                          _showDeleteConfirmation(merchant);
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

  void _showDeleteConfirmation(Merchant merchant) {
    Get.dialog(
      AlertDialog(
        title: Text("Confirm Deletion"),
        content: Text("Are you sure you want to delete '${merchant.name}'?\n\nThis action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              controller.deleteMerchant(merchant.id.toString());
              Get.back();
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}