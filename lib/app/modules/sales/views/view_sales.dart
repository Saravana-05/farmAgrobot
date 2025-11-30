import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/values/app_colors.dart';
import '../../../data/models/sales/sales_model.dart';
import '../controller/view_sales_controller.dart';

class ViewSales extends StatelessWidget {
  final ViewSalesController controller = Get.put(ViewSalesController());

  final TextStyle textStyle = const TextStyle(fontSize: 12.0);
  final TextStyle boldTextStyle =
      const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold);

  final List<Color> backgroundColors = [
    kLightGreen.withOpacity(0.9),
    kListBg.withOpacity(0.9)
  ];

  ViewSales({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: controller.refreshSales,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Bar and Filters
            _buildSearchAndFilters(),

            // Action buttons and summary
            _buildActionSection(),

            const SizedBox(height: 8.0),

            // Sales List
            Expanded(
              child: Obx(() => _buildSalesList()),
            ),
          ],
        ),
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
                hintText: 'Search sales by merchant, crop, or ID...',
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
                  'Payment Mode',
                  Icons.payment,
                  () => _showPaymentModeFilter(),
                  isActive: controller.selectedPaymentMode.value != null,
                ),
                _buildFilterPill(
                  'Status',
                  Icons.flag,
                  () => _showStatusFilter(),
                  isActive: controller.selectedStatus.value != null,
                ),
                _buildFilterPill(
                  'Payment Status',
                  Icons.account_balance_wallet,
                  () => _showPaymentStatusFilter(),
                  isActive: controller.selectedPaymentStatus.value != null,
                ),
                _buildFilterPill(
                  'Amount Range',
                  Icons.currency_rupee,
                  () => _showAmountRangeFilter(),
                  isActive: controller.minAmount.value != null ||
                      controller.maxAmount.value != null,
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
          // Summary Information

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

  Widget _buildSalesList() {
    if (controller.isLoading.value) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: kPrimaryColor),
            SizedBox(height: 16),
            Text('Loading sales...'),
          ],
        ),
      );
    }

    if (controller.filteredSales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No sales found.'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: controller.refreshSales,
              child: Text('Refresh'),
            ),
          ],
        ),
      );
    }

    final paginatedSales = controller.getPaginatedSales();

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.refreshSales,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: paginatedSales.length,
              itemBuilder: (context, index) {
                final sale = paginatedSales[index];
                final backgroundColor = backgroundColors[index % 2];

                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        spreadRadius: 0,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () => _showSaleDetailsDialog(sale),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row - Merchant Name and Sale ID
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  sale.merchantName,
                                  style: boldTextStyle.copyWith(
                                    color: kPrimaryColor,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: kPrimaryColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '#${sale.id}',
                                  style: textStyle.copyWith(
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              // Actions Menu
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: kSecondaryColor,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.visibility_outlined,
                                            color: kSecondaryColor, size: 18),
                                        SizedBox(width: 12),
                                        Text('View Details'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.edit_outlined,
                                            color: kSecondaryColor, size: 18),
                                        SizedBox(width: 12),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'payment',
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.payment,
                                            color: Colors.green, size: 18),
                                        SizedBox(width: 12),
                                        Text('Add Payment'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'pdf_bill',
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.picture_as_pdf,
                                            color: Colors.orange, size: 18),
                                        SizedBox(width: 12),
                                        Text('Generate PDF'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.delete_outline,
                                            color: Colors.red, size: 18),
                                        SizedBox(width: 12),
                                        Text('Delete'),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  switch (value) {
                                    case 'view':
                                      _showSaleDetailsDialog(sale);
                                      break;
                                    case 'edit':
                                      controller.editSale(sale);
                                      break;
                                    case 'payment':
                                      _showAddPaymentDialog(sale);
                                      break;
                                    case 'pdf_bill':
                                      controller
                                          .generatePdfBill(sale.id.toString());
                                      break;
                                    case 'delete':
                                      _showDeleteConfirmation(sale);
                                      break;
                                  }
                                },
                              ),
                            ],
                          ),

                          SizedBox(height: 12),

                          // Content Row - Image and Details
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sale Images Preview
                              _buildSaleImagesPreview(sale),

                              SizedBox(width: 16),

                              // Sale Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Crop Name and Final Amount
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            sale.cropName,
                                            style: textStyle.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[800],
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          controller
                                              .formatCurrency(sale.finalAmount),
                                          style: boldTextStyle.copyWith(
                                            color: Colors.green[700],
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 8),

                                    // Sale Variants Summary
                                    Text(
                                      'Items: ${controller.getSaleVariantsSummary(sale)}',
                                      style: textStyle.copyWith(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 16),

                          // Footer Row - Status and Date Information
                          Row(
                            children: [
                              // Pending Amount Section
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pending Amount',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: kSecondaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      controller
                                          .formatCurrency(sale.pendingAmount),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.red[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Payment Status Badge
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: controller
                                          .getPaymentStatusColor(
                                              sale.paymentStatus)
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: controller
                                            .getPaymentStatusColor(
                                                sale.paymentStatus)
                                            .withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      sale.paymentStatus.toUpperCase(),
                                      style: textStyle.copyWith(
                                        color: controller.getPaymentStatusColor(
                                            sale.paymentStatus),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                        letterSpacing: 0.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),

                              // Sale Date
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Sale Date',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      controller
                                          .formatTimestamp(sale.harvestDate),
                                      style: textStyle.copyWith(
                                        color: Colors.grey[700],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.end,
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
                );
              },
            ),
          ),
        ),

        // Pagination Controls
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(
              top: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
          ),
          child: Obx(() => _buildPaginationControls()),
        ),
      ],
    );
  }

  Widget _buildSaleImagesPreview(SaleModel sale) {
    List<String> imageUrls = controller.getSaleImageUrls(sale);

    if (imageUrls.isEmpty) {
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
              Icons.image_not_supported_outlined,
              color: Colors.grey[400],
              size: 20,
            ),
            Text(
              'No Images',
              style: TextStyle(
                fontSize: 8,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    if (imageUrls.length == 1) {
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
            onTap: () => _showSaleImagesDialog(imageUrls, 0),
            child: Image.network(
              imageUrls.first,
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
      onTap: () => _showSaleImagesDialog(imageUrls, 0),
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
            _buildImageGrid(imageUrls),

            // Overlay for count if more than 4 images
            if (imageUrls.length > 4)
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
                    '+${imageUrls.length - 4}',
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

  Widget _buildImageGrid(List<String> imageUrls) {
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
                      imageUrls[0],
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
              if (imageUrls.length > 2)
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: 1, top: 1),
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                      ),
                      child: Image.network(
                        imageUrls[2],
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
        if (imageUrls.length > 1)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: 1),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                child: Image.network(
                  imageUrls[1],
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
          icon: Icon(Icons.chevron_left, color: kLightColor, size: 18),
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
          icon: Icon(Icons.chevron_right, color: kLightColor, size: 18),
          label: Text('Next'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // Sale Images Dialog
  void _showSaleImagesDialog(List<String> imageUrls, int initialIndex) {
    if (imageUrls.isEmpty) {
      Get.snackbar(
        'No Images',
        'No sale images available',
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
          ),
          body: PageView.builder(
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
                    imageUrls[index],
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
              );
            },
          ),
        ),
      ),
    );
  }

  // Sale Details Dialog
  void _showSaleDetailsDialog(SaleModel sale) {
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
                    Icon(Icons.store, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sale Details #${sale.id}',
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
                        'Sale Information',
                        [
                          _buildDetailRow(
                              'Merchant', sale.merchantName, Icons.person),
                          _buildDetailRow(
                              'Crop', sale.cropName, Icons.agriculture),
                          _buildDetailRow(
                            'Payment Mode',
                            sale.paymentMode,
                            Icons.account_balance_wallet,
                          ),
                          _buildDetailRow(
                            'Payment Status',
                            sale.paymentStatus.toUpperCase(),
                            Icons.payment,
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Financial Breakdown - NEW SECTION
                      _buildDetailSection(
                        'Financial Breakdown',
                        [
                          _buildFinancialRow(
                            'Total Amount',
                            controller.formatCurrency(sale.totalAmount),
                            Colors.blue[700]!,
                            Icons.attach_money,
                          ),
                          if (sale.commission > 0)
                            _buildFinancialRow(
                              'Commission',
                              '- ${controller.formatCurrency(sale.commission)}',
                              Colors.orange[700]!,
                              Icons.percent,
                            ),
                          if (sale.lorryRent > 0)
                            _buildFinancialRow(
                              'Lorry Rent',
                              '- ${controller.formatCurrency(sale.lorryRent)}',
                              Colors.orange[700]!,
                              Icons.local_shipping,
                            ),
                          if (sale.coolyCharges > 0)
                            _buildFinancialRow(
                              'Cooly Charges',
                              '- ${controller.formatCurrency(sale.coolyCharges)}',
                              Colors.orange[700]!,
                              Icons.construction,
                            ),
                          if (sale.totalDeductions > 0)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(thickness: 1),
                            ),
                          if (sale.totalDeductions > 0)
                            _buildFinancialRow(
                              'Total Deductions',
                              '- ${controller.formatCurrency(sale.totalDeductions)}',
                              Colors.red[700]!,
                              Icons.remove_circle_outline,
                              isBold: true,
                            ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(thickness: 2, color: kPrimaryColor),
                          ),
                          _buildFinancialRow(
                            'Final Amount',
                            controller.formatCurrency(sale.finalAmount),
                            Colors.green[700]!,
                            Icons.account_balance,
                            isBold: true,
                            isLarge: true,
                          ),
                          _buildFinancialRow(
                            'Paid Amount',
                            controller.formatCurrency(sale.paidAmount),
                            Colors.green[600]!,
                            Icons.check_circle_outline,
                          ),
                          _buildFinancialRow(
                            'Outstanding Amount',
                            controller.formatCurrency(sale.pendingAmount),
                            Colors.red[700]!,
                            Icons.pending_actions,
                            isBold: sale.pendingAmount > 0,
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Sale Variants
                      if (sale.saleVariants.isNotEmpty) ...[
                        _buildDetailSection(
                          'Sale Items',
                          sale.saleVariants
                              .map((variant) => _buildVariantRow(variant))
                              .toList(),
                        ),
                        SizedBox(height: 16),
                      ],

                      // Payment History - NEW SECTION
                      if (sale.paymentHistory.isNotEmpty) ...[
                        _buildPaymentHistorySection(sale),
                        SizedBox(height: 16),
                      ],

                      // Sale Images
                      _buildSaleImagesSection(sale),

                      // Timestamps
                      if (sale.createdAt != null || sale.updatedAt != null) ...[
                        SizedBox(height: 16),
                        _buildDetailSection(
                          'Timestamps',
                          [
                            if (sale.createdAt != null)
                              _buildDetailRow(
                                'Created',
                                controller.formatTimestamp(sale.createdAt),
                                Icons.schedule,
                              ),
                            if (sale.updatedAt != null)
                              _buildDetailRow(
                                'Updated',
                                controller.formatTimestamp(sale.updatedAt),
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
                          controller.editSale(sale);
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
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.back();
                          _showAddPaymentDialog(sale);
                        },
                        icon: Icon(Icons.payment, color: Colors.white),
                        label: Text('Add Payment',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
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

  Widget _buildFinancialRow(
    String label,
    String value,
    Color color,
    IconData icon, {
    bool isBold = false,
    bool isLarge = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isBold ? color.withOpacity(0.3) : Colors.grey[200]!,
          width: isBold ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: isLarge ? 24 : 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isLarge ? 14 : 12,
                color: Colors.grey[700],
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isLarge ? 18 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

// NEW: Variant Row Widget
  Widget _buildVariantRow(SaleVariant variant) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory, color: kSecondaryColor, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  variant.cropVariantName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quantity',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${variant.quantity} ${variant.unit}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Rate',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    controller.formatCurrency(variant.amountPerUnit),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    controller.formatCurrency(variant.totalAmount),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

// NEW: Payment History Section
  Widget _buildPaymentHistorySection(SaleModel sale) {
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
              Icon(Icons.payment, color: kSecondaryColor),
              SizedBox(width: 8),
              Text(
                'Payment History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kSecondaryColor,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${sale.paymentHistory.length} payment${sale.paymentHistory.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...sale.paymentHistory
              .map((payment) => _buildPaymentHistoryRow(payment))
              .toList(),
        ],
      ),
    );
  }

// NEW: Payment History Row Widget
  Widget _buildPaymentHistoryRow(PaymentHistory payment) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _getPaymentMethodIcon(payment.paymentMethod),
                  SizedBox(width: 8),
                  Text(
                    payment.paymentMethod.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              Text(
                controller.formatCurrency(payment.paymentAmount),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
              SizedBox(width: 4),
              Text(
                controller.formatTimestamp(payment.paymentDate),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              if (payment.paymentReference?.isNotEmpty == true) ...[
                SizedBox(width: 12),
                Icon(Icons.receipt_long, size: 12, color: Colors.grey[600]),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    payment.paymentReference!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          if (payment.notes?.isNotEmpty == true) ...[
            SizedBox(height: 6),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.note, size: 12, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      payment.notes!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _buildSaleImagesSection(SaleModel sale) {
    List<String> imageUrls = controller.getSaleImageUrls(sale);

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
              Icon(Icons.image, color: kSecondaryColor),
              SizedBox(width: 8),
              Text(
                'Sale Images',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kSecondaryColor,
                ),
              ),
              Spacer(),
              if (imageUrls.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    Get.back();
                    _showSaleImagesDialog(imageUrls, 0);
                  },
                  icon: Icon(Icons.visibility, size: 16),
                  label: Text('View All'),
                ),
            ],
          ),
          SizedBox(height: 12),
          if (imageUrls.isEmpty)
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.image_not_supported_outlined,
                      size: 40, color: Colors.grey[400]),
                  SizedBox(height: 8),
                  Text(
                    'No sale images available',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            Container(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Get.back();
                      _showSaleImagesDialog(imageUrls, index);
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
                          imageUrls[index],
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

  // Add Payment Dialog
  void _showAddPaymentDialog(SaleModel sale) {
    final paymentAmountController = TextEditingController();
    final paymentReferenceController = TextEditingController();
    final notesController = TextEditingController();
    final selectedPaymentMethod = 'Cash'.obs;

    // Define payment methods with proper display names and backend values
    final Map<String, String> paymentMethods = {
      'Cash': 'Cash',
      'UPI': 'UPI',
      'Card': 'Card',
      'Online': 'Online',
    };
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
            'Add Payment - ${controller.formatCurrency(sale.finalAmount)}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Outstanding amount info
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Outstanding Amount',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            controller.formatCurrency(sale.pendingAmount),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Payment Amount
              TextField(
                controller: paymentAmountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Payment Amount',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Enter amount',
                  helperText:
                      'Max: ${controller.formatCurrency(sale.pendingAmount)}',
                ),
                onChanged: (value) {
                  // Optional: Add real-time validation
                  final amount = double.tryParse(value);
                  if (amount != null && amount > sale.pendingAmount) {
                    // Show warning or limit input
                  }
                },
              ),

              SizedBox(height: 16),

              // Payment Method
              Obx(() => DropdownButtonFormField<String>(
                    value: selectedPaymentMethod.value,
                    decoration: InputDecoration(
                      labelText: 'Payment Method',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.payment),
                    ),
                    items: paymentMethods.entries
                        .map((entry) => DropdownMenuItem(
                              value: entry.value,
                              child: Row(
                                children: [
                                  _getPaymentMethodIcon(entry.key),
                                  SizedBox(width: 8),
                                  Text(entry.key),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) selectedPaymentMethod.value = value;
                    },
                  )),

              SizedBox(height: 16),

              // Payment Reference (Optional)
              TextField(
                controller: paymentReferenceController,
                decoration: InputDecoration(
                  labelText: 'Payment Reference (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Transaction ID, Cheque No, etc.',
                  prefixIcon: Icon(Icons.receipt_long),
                ),
              ),

              SizedBox(height: 16),

              // Notes (Optional)
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Additional notes about payment',
                  prefixIcon: Icon(Icons.note),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(paymentAmountController.text);

              // Validation
              if (amount == null || amount <= 0) {
                Get.snackbar(
                  'Invalid Amount',
                  'Please enter a valid payment amount',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              if (amount > sale.pendingAmount) {
                Get.snackbar(
                  'Amount Exceeds Outstanding',
                  'Payment amount cannot exceed outstanding amount of ${controller.formatCurrency(sale.pendingAmount)}',
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                );
                return;
              }

              Get.back();
              controller.addPaymentToSale(
                saleId: sale.id.toString(),
                paymentAmount: amount,
                paymentMethod: selectedPaymentMethod
                    .value, // This is now the proper backend value
                paymentReference: paymentReferenceController.text.isNotEmpty
                    ? paymentReferenceController.text
                    : null,
                notes: notesController.text.isNotEmpty
                    ? notesController.text
                    : null,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Add Payment'),
          ),
        ],
      ),
    );
  }

  // Helper method to get payment method icons
  Icon _getPaymentMethodIcon(String paymentMethod) {
    switch (paymentMethod.toLowerCase()) {
      case 'cash':
        return Icon(Icons.money, color: Colors.green, size: 20);
      case 'bank transfer':
        return Icon(Icons.account_balance, color: Colors.blue, size: 20);
      case 'upi':
        return Icon(Icons.qr_code, color: Colors.purple, size: 20);
      case 'cheque':
        return Icon(Icons.receipt, color: Colors.orange, size: 20);
      case 'card':
        return Icon(Icons.credit_card, color: Colors.indigo, size: 20);
      case 'online':
        return Icon(Icons.language, color: Colors.teal, size: 20);
      default:
        return Icon(Icons.payment, color: Colors.grey, size: 20);
    }
  }

  // Delete Confirmation Dialog
  void _showDeleteConfirmation(SaleModel sale) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Sale'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this sale record for "${sale.merchantName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteSale(sale.id.toString());
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

  // Filter Dialogs
  void _showDateRangeFilter() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Filter by Date Range'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => ListTile(
                  leading: Icon(Icons.calendar_today),
                  title: Text('Start Date'),
                  subtitle: Text(
                    controller.selectedStartDate.value != null
                        ? controller.formatTimestamp(
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
            Obx(() => ListTile(
                  leading: Icon(Icons.event),
                  title: Text('End Date'),
                  subtitle: Text(
                    controller.selectedEndDate.value != null
                        ? controller
                            .formatTimestamp(controller.selectedEndDate.value!)
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

  void _showPaymentModeFilter() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Filter by Payment Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => RadioListTile<String?>(
                  title: Text('All'),
                  value: null,
                  groupValue: controller.selectedPaymentMode.value,
                  onChanged: (value) {
                    controller.selectedPaymentMode.value = value;
                  },
                )),
            ...['Cash', 'UPI', 'Card', 'Online']
                .map((mode) => Obx(() => RadioListTile<String?>(
                      title: Text(mode.toUpperCase()),
                      value: mode,
                      groupValue: controller.selectedPaymentMode.value,
                      onChanged: (value) {
                        controller.selectedPaymentMode.value = value;
                      },
                    )))
                .toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller
                  .setPaymentModeFilter(controller.selectedPaymentMode.value);
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

  void _showStatusFilter() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Filter by Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => RadioListTile<String?>(
                  title: Text('All'),
                  value: null,
                  groupValue: controller.selectedStatus.value,
                  onChanged: (value) {
                    controller.selectedStatus.value = value;
                  },
                )),
            ...['pending', 'completed', 'cancelled']
                .map((status) => Obx(() => RadioListTile<String?>(
                      title: Text(status.toUpperCase()),
                      value: status,
                      groupValue: controller.selectedStatus.value,
                      onChanged: (value) {
                        controller.selectedStatus.value = value;
                      },
                    )))
                .toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.setStatusFilter(controller.selectedStatus.value);
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

  void _showPaymentStatusFilter() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Filter by Payment Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => RadioListTile<String?>(
                  title: Text('All'),
                  value: null,
                  groupValue: controller.selectedPaymentStatus.value,
                  onChanged: (value) {
                    controller.selectedPaymentStatus.value = value;
                  },
                )),
            ...['pending', 'paid', 'partial', 'failed', 'cancelled']
                .map((status) => Obx(() => RadioListTile<String?>(
                      title: Text(status.toUpperCase()),
                      value: status,
                      groupValue: controller.selectedPaymentStatus.value,
                      onChanged: (value) {
                        controller.selectedPaymentStatus.value = value;
                      },
                    )))
                .toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.setPaymentStatusFilter(
                  controller.selectedPaymentStatus.value);
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

  void _showAmountRangeFilter() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Filter by Amount Range'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller.minAmountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Minimum Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Enter minimum amount',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: controller.maxAmountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Maximum Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Enter maximum amount',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.minAmountController.clear();
              controller.maxAmountController.clear();
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
              final minAmt =
                  double.tryParse(controller.minAmountController.text);
              final maxAmt =
                  double.tryParse(controller.maxAmountController.text);

              controller.setAmountRangeFilter(minAmt, maxAmt);
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
