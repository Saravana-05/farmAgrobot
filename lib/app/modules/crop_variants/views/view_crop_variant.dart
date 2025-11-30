import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/values/app_colors.dart';
import '../../../data/models/crop_variant/crop_variant_model.dart';
import '../../../routes/app_pages.dart';
import '../controller/view_crop_variant_controller.dart';

class ViewCropVariants extends StatelessWidget {
  final CropVariantViewController controller = Get.put(CropVariantViewController());

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
                  hintText: 'Search crop variants...',
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

          // Crop Variants List
          Expanded(
            child: Obx(() => _buildCropVariantsList()),
          ),
        ],
      ),
    );
  }

  Widget _buildCropVariantsList() {
    if (controller.isLoading.value) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: kPrimaryColor),
            SizedBox(height: 16),
            Text('Loading crop variants...'),
          ],
        ),
      );
    }

    if (controller.filteredCropVariants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No crop variants found.'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: controller.refreshCropVariants,
              child: Text('Refresh'),
            ),
          ],
        ),
      );
    }

    final paginatedCropVariants = controller.getPaginatedCropVariants();

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.refreshCropVariants,
            child: ListView.builder(
              itemCount: paginatedCropVariants.length,
              itemBuilder: (context, index) {
                final cropVariant = paginatedCropVariants[index];

                final backgroundColor = backgroundColors[index % 2];

                return Container(
                  color: backgroundColor,
                  padding: EdgeInsets.all(10.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Crop Variant Icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
                        ),
                        child: Icon(
                          Icons.category,
                          color: kPrimaryColor,
                          size: 30,
                        ),
                      ),

                      SizedBox(width: 12),

                      // Crop Variant Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cropVariant.cropVariant,
                              style: boldTextStyle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Crop: ${cropVariant.cropName}',
                              style: textStyle.copyWith(
                                fontWeight: FontWeight.w500,
                                color: kSecondaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: kPrimaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                'Unit: ${controller.getUnitDisplayName(cropVariant.unit)}',
                                style: textStyle.copyWith(
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (cropVariant.createdAt != null) ...[
                              SizedBox(height: 4),
                              Text(
                                'Added on ${DateFormat('dd MMM yyyy').format(cropVariant.createdAt!)}',
                                style: textStyle,
                              ),
                            ],
                            if (cropVariant.updatedAt != null &&
                                cropVariant.updatedAt != cropVariant.createdAt) ...[
                              SizedBox(height: 2),
                              Text(
                                'Updated ${DateFormat('dd MMM yyyy').format(cropVariant.updatedAt!)}',
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
                              _showCropVariantDetailsDialog(cropVariant);
                              break;
                            case 'edit':
                              controller.handleEditCropVariant(cropVariant);
                              break;
                            case 'delete':
                              _showDeleteConfirmation(cropVariant);
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

  // Method to show detailed crop variant view dialog
  void _showCropVariantDetailsDialog(CropVariant cropVariant) {
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
                    Icon(Icons.category, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Crop Variant Details',
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
                      // Crop Variant Name
                      _buildDetailRow(
                        'Variant Name',
                        cropVariant.cropVariant,
                        Icons.category,
                        valueStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),

                      SizedBox(height: 16),

                      // Crop Name
                      _buildDetailRow(
                        'Crop Name',
                        cropVariant.cropName,
                        Icons.agriculture,
                      ),

                      SizedBox(height: 16),

                      // Unit
                      _buildDetailRow(
                        'Unit',
                        controller.getUnitDisplayName(cropVariant.unit),
                        Icons.straighten,
                      ),

                      SizedBox(height: 16),

                      // Crop Variant ID
                      _buildDetailRow(
                        'Variant ID',
                        cropVariant.id,
                        Icons.tag,
                      ),

                      SizedBox(height: 16),

                      // Crop ID
                      _buildDetailRow(
                        'Crop ID',
                        cropVariant.cropId,
                        Icons.link,
                      ),

                      if (cropVariant.createdAt != null) ...[
                        SizedBox(height: 16),
                        _buildDetailRow(
                          'Created Date',
                          DateFormat('dd MMM yyyy, hh:mm a')
                              .format(cropVariant.createdAt!),
                          Icons.calendar_today,
                        ),
                      ],

                      if (cropVariant.updatedAt != null &&
                          cropVariant.updatedAt != cropVariant.createdAt) ...[
                        SizedBox(height: 16),
                        _buildDetailRow(
                          'Last Updated',
                          controller.formatTimestamp(cropVariant.updatedAt),
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
                          controller.handleEditCropVariant(cropVariant);
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
                          _showDeleteConfirmation(cropVariant);
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

  void _showDeleteConfirmation(CropVariant cropVariant) {
    Get.dialog(
      AlertDialog(
        title: Text("Confirm Deletion"),
        content: Text("Are you sure you want to delete '${cropVariant.cropVariant}'?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              controller.deleteCropVariant(cropVariant.id.toString());
              Get.back();
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}