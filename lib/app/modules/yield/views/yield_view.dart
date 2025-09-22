import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/api.dart';
import '../../../core/values/app_colors.dart';
import '../../../data/models/yield/yield_model.dart';
import '../controller/view_yield_controller.dart';

class ViewYields extends StatelessWidget {
  final YieldViewController controller = Get.put(YieldViewController());

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
          // Search Bar and Filters
          _buildSearchAndFilters(),

          // Action buttons and summary
          _buildActionSection(),

          const SizedBox(height: 8.0),

          // Yields List
          Expanded(
            child: Obx(() => _buildYieldsList()),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.only(top: 20.0, right: 20.0, left: 20.0),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25.0),
              color: Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: controller.searchController,
              onChanged: controller.runFilter,
              decoration: InputDecoration(
                hintText: 'Search yields by crop name...',
                hintStyle: TextStyle(color: kSecondaryColor),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, color: kSecondaryColor),
                suffixIcon: Obx(() => controller.searchKeyword.value.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: kSecondaryColor),
                        onPressed: () {
                          controller.searchController.clear();
                          controller.runFilter('');
                        },
                      )
                    : SizedBox.shrink()),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterPill(
                  'Date Range',
                  Icons.date_range,
                  () => _showDateRangeFilter(),
                  isActive: controller.selectedStartDate.value != null ||
                      controller.selectedEndDate.value != null,
                ),
                _buildFilterPill(
                  'With Bills',
                  Icons.receipt_long,
                  () => _showBillsFilter(),
                  isActive: controller.filterHasBills.value != null,
                ),
                _buildFilterPill(
                  'Clear Filters',
                  Icons.clear_all,
                  controller.clearFilters,
                  isActive: false,
                  isAction: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool isActive = false,
    bool isAction = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isAction
                ? Colors.grey[100]
                : isActive
                    ? kPrimaryColor.withOpacity(0.1)
                    : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isAction
                  ? Colors.grey[300]!
                  : isActive
                      ? kPrimaryColor
                      : Colors.grey[300]!,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isAction
                    ? Colors.grey[600]
                    : isActive
                        ? kPrimaryColor
                        : kSecondaryColor,
              ),
              SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isAction
                      ? Colors.grey[600]
                      : isActive
                          ? kPrimaryColor
                          : kSecondaryColor,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionSection() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Add Yield Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: controller.addNewYield,
                  icon: Icon(Icons.add, color: Colors.white),
                  label: Text(
                    'Add New Yield',
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
                        onPressed: controller.refreshYields,
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
    );
  }

  Widget _buildYieldsList() {
    if (controller.isLoading.value) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: kPrimaryColor),
            SizedBox(height: 16),
            Text('Loading yields...'),
          ],
        ),
      );
    }

    if (controller.filteredYields.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.agriculture, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No yields found.'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: controller.refreshYields,
              child: Text('Refresh'),
            ),
          ],
        ),
      );
    }

    final paginatedYields = controller.getPaginatedYields();

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.refreshYields,
            child: ListView.builder(
              itemCount: paginatedYields.length,
              itemBuilder: (context, index) {
                final yield = paginatedYields[index];
                final backgroundColor = backgroundColors[index % 2];

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () => _showYieldDetailsDialog(yield),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bill Images Preview
                          _buildBillImagesPreview(yield),

                          SizedBox(width: 16),

                          // Yield Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Crop Name and Harvest Date
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        yield.cropName,
                                        style: boldTextStyle.copyWith(
                                          color: kPrimaryColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: kPrimaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        controller.formatHarvestDate(
                                            yield.harvestDate),
                                        style: textStyle.copyWith(
                                          color: kPrimaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 8),

                                // Yield Variants Summary
                                Text(
                                  'Total: ${controller.getYieldVariantsSummary(yield)}',
                                  style: textStyle.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                                SizedBox(height: 4),

                                // Farm Segments
                                if (yield.yieldFarmSegments.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      Icon(Icons.location_on,
                                          size: 14, color: Colors.grey[600]),
                                      SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${yield.yieldFarmSegments.length} farm segment(s)',
                                          style: textStyle.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                ],

                                // Bills Status
                                Row(
                                  children: [
                                    Icon(
                                      controller.yieldHasBills(yield)
                                          ? Icons.receipt_long
                                          : Icons.receipt_long_outlined,
                                      size: 14,
                                      color: controller.yieldHasBills(yield)
                                          ? Colors.green
                                          : Colors.grey[400],
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      controller.yieldHasBills(yield)
                                          ? '${controller.getBillCount(yield)} bill(s)'
                                          : 'No bills',
                                      style: textStyle.copyWith(
                                        color: controller.yieldHasBills(yield)
                                            ? Colors.green
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Actions Menu
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, color: kSecondaryColor),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.edit_outlined,
                                        color: kSecondaryColor),
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
                                    Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete'),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              switch (value) {
                                case 'view':
                                  _showYieldDetailsDialog(yield);
                                  break;
                                case 'edit':
                                  controller.editYield(yield);
                                  break;
                                case 'delete':
                                  _showDeleteConfirmation(yield);
                                  break;
                              }
                            },
                          ),
                        ],
                      ),
                    ),
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

  Widget _buildBillImagesPreview(YieldModel yield) {
    print(
        '\n=== DEBUG: Building bill images preview for yield ${yield.id} ===');

    // Debug: Print yield model data
    print('Yield billImages count: ${yield.billImages.length}');
    print(
        'Yield billImages: ${yield.billImages.map((bi) => bi.toJson()).toList()}');

    // Debug: Print model's billUrls getter result
    print('Model billUrls getter: ${yield.billUrls}');

    // Get processed URLs using controller method
    List<String> billUrls = controller.getYieldBillUrls(yield);

    print('Final processed URLs: $billUrls');
    print('=== END DEBUG for yield ${yield.id} ===\n');

    if (billUrls.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: Colors.grey[400],
              size: 20,
            ),
            Text(
              'No Bills',
              style: TextStyle(
                fontSize: 8,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    if (billUrls.length == 1) {
      String imageUrl = billUrls.first;
      print('Loading single image: $imageUrl');

      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: GestureDetector(
            onTap: () => _showBillImagesDialog(billUrls, 0),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                print('Loading progress for $imageUrl');
                return Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: kPrimaryColor,
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                print('Image error for $imageUrl: $error');
                print('Stack trace: $stackTrace');
                return Container(
                  color: Colors.red[50],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 16,
                      ),
                      Text(
                        'Error',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 8,
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

    // Multiple images - create a grid preview
    return GestureDetector(
      onTap: () => _showBillImagesDialog(billUrls, 0),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Stack(
          children: [
            // Background grid
            _buildImageGrid(billUrls),

            // Overlay for count if more than 4 images
            if (billUrls.length > 4)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${billUrls.length - 4}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(List<String> billUrls) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              // Top left image
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: 1, bottom: 1),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                    ),
                    child: Image.network(
                      billUrls[0],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.image, size: 12),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Bottom left image (if available)
              if (billUrls.length > 2)
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: 1, top: 1),
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                      ),
                      child: Image.network(
                        billUrls[2],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.image, size: 12),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Right side image
        if (billUrls.length > 1)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: 1),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                child: Image.network(
                  billUrls[1],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.image, size: 12),
                    );
                  },
                ),
              ),
            ),
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

  // Helper method to get full image URL using controller
  String getFullImageUrl(String imageUrl) {
    return controller.processImageUrl(imageUrl);
  }

  // Modern Image Gallery Dialog
  void _showBillImagesDialog(List<String> imageUrls, int initialIndex) {
    if (imageUrls.isEmpty) {
      Get.snackbar(
        'No Images',
        'No bill images available for this yield',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final PageController pageController =
        PageController(initialPage: initialIndex);
    final RxInt currentIndex = initialIndex.obs;

    Get.dialog(
      Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () => Get.back(),
            ),
            title: Obx(() => Text(
                  '${currentIndex.value + 1} of ${imageUrls.length}',
                  style: TextStyle(color: Colors.white),
                )),
            actions: [
              IconButton(
                icon: Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  // Implement share functionality if needed
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              // Main Image Gallery
              PageView.builder(
                controller: pageController,
                itemCount: imageUrls.length,
                onPageChanged: (index) => currentIndex.value = index,
                itemBuilder: (context, index) {
                  return Center(
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.network(
                        getFullImageUrl(imageUrls[index]),
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: Colors.white,
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Loading image...',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error,
                                    size: 50, color: Colors.white),
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
                  );
                },
              ),

              // Navigation arrows for multiple images
              if (imageUrls.length > 1) ...[
                // Left arrow
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Obx(() => AnimatedOpacity(
                          opacity: currentIndex.value > 0 ? 1.0 : 0.3,
                          duration: Duration(milliseconds: 300),
                          child: IconButton(
                            onPressed: currentIndex.value > 0
                                ? () {
                                    pageController.previousPage(
                                      duration: Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                : null,
                            icon: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.chevron_left,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        )),
                  ),
                ),

                // Right arrow
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Obx(() => AnimatedOpacity(
                          opacity: currentIndex.value < imageUrls.length - 1
                              ? 1.0
                              : 0.3,
                          duration: Duration(milliseconds: 300),
                          child: IconButton(
                            onPressed: currentIndex.value < imageUrls.length - 1
                                ? () {
                                    pageController.nextPage(
                                      duration: Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                : null,
                            icon: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        )),
                  ),
                ),
              ],

              // Bottom thumbnail strip
              if (imageUrls.length > 1)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: imageUrls.length,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        return Obx(() => GestureDetector(
                              onTap: () {
                                pageController.animateToPage(
                                  index,
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: Container(
                                width: 60,
                                height: 60,
                                margin: EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: currentIndex.value == index
                                        ? kPrimaryColor
                                        : Colors.white.withOpacity(0.5),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    getFullImageUrl(imageUrls[index]),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[300],
                                        child: Icon(Icons.image,
                                            color: Colors.grey),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ));
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Updated Yield Details Dialog
  void _showYieldDetailsDialog(YieldModel yield) {
    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.all(20),
        child: Container(
          width: Get.width * 0.95,
          constraints: BoxConstraints(
            maxHeight: Get.height * 0.85,
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
                        'Yield Details',
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
                      // Basic Info
                      _buildDetailSection(
                        'Basic Information',
                        [
                          _buildDetailRow(
                              'Crop', yield.cropName, Icons.agriculture),
                          _buildDetailRow(
                            'Harvest Date',
                            controller.formatHarvestDate(yield.harvestDate),
                            Icons.calendar_today,
                          ),
                          _buildDetailRow(
                              'Yield ID', yield.id.toString(), Icons.tag),
                          _buildDetailRow(
                            'Total Quantity',
                            '${controller.getTotalYieldQuantity(yield)} units',
                            Icons.scale,
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Yield Variants
                      if (yield.yieldVariants.isNotEmpty) ...[
                        _buildDetailSection(
                          'Yield Variants',
                          yield.yieldVariants
                              .map((variant) => _buildDetailRow(
                                    variant.cropVariantName ??
                                        'Unknown Variant',
                                    '${variant.quantity ?? 0} ${variant.unit ?? 'units'}',
                                    Icons.inventory,
                                  ))
                              .toList(),
                        ),
                        SizedBox(height: 16),
                      ],

                      // Farm Segments
                      if (yield.yieldFarmSegments.isNotEmpty) ...[
                        _buildDetailSection(
                          'Farm Segments',
                          yield.yieldFarmSegments
                              .map((segment) => _buildDetailRow(
                                    'Segment',
                                    segment.farmSegmentName ??
                                        'Unknown Segment',
                                    Icons.location_on,
                                  ))
                              .toList(),
                        ),
                        SizedBox(height: 16),
                      ],

                      // Bill Images
                      _buildBillImagesSection(yield),

                      // Timestamps
                      if (yield.createdAt != null ||
                          yield.updatedAt != null) ...[
                        SizedBox(height: 16),
                        _buildDetailSection(
                          'Timestamps',
                          [
                            if (yield.createdAt != null)
                              _buildDetailRow(
                                'Created',
                                controller.formatTimestamp(yield.createdAt),
                                Icons.schedule,
                              ),
                            if (yield.updatedAt != null)
                              _buildDetailRow(
                                'Updated',
                                controller.formatTimestamp(yield.updatedAt),
                                Icons.update,
                              ),
                          ],
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
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Get.back();
                          controller.editYield(yield);
                        },
                        icon: Icon(Icons.edit_outlined, color: kPrimaryColor),
                        label: Text('Edit',
                            style: TextStyle(color: kPrimaryColor)),
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
                          _showDeleteConfirmation(yield);
                        },
                        icon: Icon(Icons.delete_outline, color: Colors.red),
                        label:
                            Text('Delete', style: TextStyle(color: Colors.red)),
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

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
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
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kSecondaryColor,
            ),
          ),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillImagesSection(YieldModel yield) {
    print(
        '\n=== DEBUG: Building bill images section for yield ${yield.id} ===');

    List<String> billUrls = controller.getYieldBillUrls(yield);
    print("Bill URLs in section: $billUrls");

    // Also check the raw data
    Map<String, dynamic> rawData = yield.toJson();
    print("Raw yield data keys: ${rawData.keys.toList()}");
    print(
        "Raw billImages field: ${rawData['billImages'] ?? rawData['bill_images'] ?? 'NOT_FOUND'}");

    print('=== END DEBUG for bill section yield ${yield.id} ===\n');

    return Container(
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
              Icon(Icons.receipt_long, color: kSecondaryColor),
              SizedBox(width: 8),
              Text(
                'Bill Images',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kSecondaryColor,
                ),
              ),
              Spacer(),
              // Debug info in development mode
              if (true) // Set to false in production
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        billUrls.isEmpty ? Colors.red[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Count: ${billUrls.length}',
                    style: TextStyle(
                      fontSize: 10,
                      color: billUrls.isEmpty
                          ? Colors.red[800]
                          : Colors.green[800],
                    ),
                  ),
                ),
              SizedBox(width: 8),
              if (billUrls.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    Get.back();
                    _showBillImagesDialog(billUrls, 0);
                  },
                  icon: Icon(Icons.visibility, size: 16),
                  label: Text('View All'),
                ),
            ],
          ),
          SizedBox(height: 12),
          if (billUrls.isEmpty)
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 40, color: Colors.grey[400]),
                  SizedBox(height: 8),
                  Text(
                    'No bill images available',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  // Debug info
                  if (true) // Set to false in production
                    Column(
                      children: [
                        SizedBox(height: 4),
                        Text(
                          'Debug: billImages.length = ${yield.billImages.length}',
                          style: TextStyle(
                            color: Colors.red[600],
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            )
          else
            Container(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: billUrls.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Get.back();
                      _showBillImagesDialog(billUrls, index);
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      margin: EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          billUrls[index],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: kPrimaryColor,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print(
                                'Thumbnail error for ${billUrls[index]}: $error');
                            return Container(
                              color: Colors.grey[100],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                                  Text(
                                    'Error',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 8,
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
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(YieldModel yield) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Yield'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this yield record for "${yield.cropName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteYield(yield.id.toString());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDateRangeFilter() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Filter by Date Range'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Start Date
            Obx(() => ListTile(
                  leading: Icon(Icons.calendar_today),
                  title: Text('Start Date'),
                  subtitle: Text(
                    controller.selectedStartDate.value != null
                        ? controller.formatHarvestDate(
                            controller.selectedStartDate.value!)
                        : 'Select start date',
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: Get.context!,
                      initialDate:
                          controller.selectedStartDate.value ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      controller.selectedStartDate.value = date;
                    }
                  },
                )),

            // End Date
            Obx(() => ListTile(
                  leading: Icon(Icons.event),
                  title: Text('End Date'),
                  subtitle: Text(
                    controller.selectedEndDate.value != null
                        ? controller.formatHarvestDate(
                            controller.selectedEndDate.value!)
                        : 'Select end date',
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: Get.context!,
                      initialDate:
                          controller.selectedEndDate.value ?? DateTime.now(),
                      firstDate:
                          controller.selectedStartDate.value ?? DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      controller.selectedEndDate.value = date;
                    }
                  },
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.selectedStartDate.value = null;
              controller.selectedEndDate.value = null;
              Get.back();
            },
            child: Text('Clear'),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.setDateRangeFilter(
                controller.selectedStartDate.value,
                controller.selectedEndDate.value,
              );
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showBillsFilter() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Filter by Bills'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => RadioListTile<bool?>(
                  title: Text('All yields'),
                  value: null,
                  groupValue: controller.filterHasBills.value,
                  onChanged: (value) {
                    controller.filterHasBills.value = value;
                  },
                )),
            Obx(() => RadioListTile<bool?>(
                  title: Text('With bills only'),
                  value: true,
                  groupValue: controller.filterHasBills.value,
                  onChanged: (value) {
                    controller.filterHasBills.value = value;
                  },
                )),
            Obx(() => RadioListTile<bool?>(
                  title: Text('Without bills only'),
                  value: false,
                  groupValue: controller.filterHasBills.value,
                  onChanged: (value) {
                    controller.filterHasBills.value = value;
                  },
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.setBillsFilter(controller.filterHasBills.value);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }
}
