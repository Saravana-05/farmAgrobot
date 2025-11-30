import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../config/api.dart';
import '../../../core/values/app_colors.dart';
import '../../../data/models/crops/crop_model.dart';
import '../../../routes/app_pages.dart';
import '../controller/crop_view_controller.dart';

class ViewCrops extends StatelessWidget {
  final CropsViewController controller = Get.put(CropsViewController());

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
                  hintText: 'Search crops...',
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

          // Crops List
          Expanded(
            child: Obx(() => _buildCropsList()),
          ),
        ],
      ),
    );
  }

  Widget _buildCropsList() {
    if (controller.isLoading.value) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: kPrimaryColor),
            SizedBox(height: 16),
            Text('Loading crops...'),
          ],
        ),
      );
    }

    if (controller.filteredCrops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.agriculture, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No crops found.'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: controller.refreshCrops,
              child: Text('Refresh'),
            ),
          ],
        ),
      );
    }

    final paginatedCrops = controller.getPaginatedCrops();

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.refreshCrops,
            child: ListView.builder(
              itemCount: paginatedCrops.length,
              itemBuilder: (context, index) {
                final crop = paginatedCrops[index];

                final backgroundColor = backgroundColors[index % 2];

                return Container(
                  color: backgroundColor,
                  padding: EdgeInsets.all(10.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Crop Image
                      GestureDetector(
                        onTap: () => _showImageDialog(crop.cropImage),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: crop.cropImage != null
                                ? Image.network(
                                    getFullImageUrl(crop.cropImage),
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          color: kPrimaryColor,
                                          strokeWidth: 2,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.agriculture,
                                        color: Colors.grey[400],
                                        size: 30,
                                      );
                                    },
                                  )
                                : Icon(
                                    Icons.agriculture,
                                    color: Colors.grey[400],
                                    size: 30,
                                  ),
                          ),
                        ),
                      ),

                      SizedBox(width: 12),

                      // Crop Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              crop.cropName,
                              style: boldTextStyle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (crop.createdAt != null) ...[
                              SizedBox(height: 4),
                              Text(
                                'Added on ${DateFormat('dd MMM yyyy').format(crop.createdAt!)}',
                                style: textStyle,
                              ),
                            ],
                            if (crop.updatedAt != null &&
                                crop.updatedAt != crop.createdAt) ...[
                              SizedBox(height: 2),
                              Text(
                                'Updated ${DateFormat('dd MMM yyyy').format(crop.updatedAt!)}',
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
                              _showCropDetailsDialog(crop);
                              break;
                            case 'edit':
                              // Use the new method that properly handles the edit flow
                              controller.handleEditCrop(crop);
                              break;
                            case 'delete':
                              _showDeleteConfirmation(crop);
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

  // Method to show detailed crop view dialog
  void _showCropDetailsDialog(Crop crop) {
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
                    Icon(Icons.agriculture, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Crop Details',
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
                      // Crop Name
                      _buildDetailRow(
                        'Crop Name',
                        crop.cropName,
                        Icons.agriculture,
                        valueStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),

                      SizedBox(height: 16),

                      // Crop ID
                      _buildDetailRow(
                        'Crop ID',
                        crop.id,
                        Icons.tag,
                      ),

                      if (crop.createdAt != null) ...[
                        SizedBox(height: 16),
                        _buildDetailRow(
                          'Created Date',
                          DateFormat('dd MMM yyyy, hh:mm a')
                              .format(crop.createdAt!),
                          Icons.calendar_today,
                        ),
                      ],

                      if (crop.updatedAt != null &&
                          crop.updatedAt != crop.createdAt) ...[
                        SizedBox(height: 16),
                        _buildDetailRow(
                          'Last Updated',
                          controller.formatTimestamp(crop.updatedAt),
                          Icons.update,
                        ),
                      ],

                      SizedBox(height: 20),

                      // Crop Image Section
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.image, color: kSecondaryColor),
                                SizedBox(width: 8),
                                Text(
                                  'Crop Image',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: kSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            _buildCropImage(crop.cropImage),
                          ],
                        ),
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
                          Get.back(); // Close the dialog first
                          controller.handleEditCrop(
                              crop); // Then handle edit properly
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
                          _showDeleteConfirmation(crop);
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

  Widget _buildCropImage(String? imageUrl) {
    // Get the full image URL using your helper function
    final String fullImageUrl = getFullImageUrl(imageUrl);

    if (fullImageUrl.isEmpty) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.agriculture, size: 40, color: Colors.grey[400]),
            SizedBox(height: 8),
            Text(
              'No crop image available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showFullScreenImage(fullImageUrl),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            fullImageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  color: kPrimaryColor,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[100],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 40, color: Colors.red[300]),
                    SizedBox(height: 8),
                    Text(
                      'Failed to load image',
                      style: TextStyle(
                        color: Colors.red[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Get.dialog(
      Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Get.back(),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 50, color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showImageDialog(String? imageUrl) {
    // Get the full image URL using your helper function
    final String fullImageUrl = getFullImageUrl(imageUrl);

    if (fullImageUrl.isEmpty) {
      Get.snackbar(
        'No Image',
        'No image available for this crop',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    Get.dialog(
      Dialog(
        child: SizedBox(
          width: 300,
          height: 300,
          child: Image.network(
            fullImageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 50, color: Colors.red),
                    Text('Failed to load image'),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Crop crop) {
    Get.dialog(
      AlertDialog(
        title: Text("Confirm Deletion"),
        content: Text("Are you sure you want to delete '${crop.cropName}'?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              controller.deleteCrop(crop.id.toString());
              Get.back();
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
