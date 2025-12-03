import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../../../core/values/app_colors.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../../../global_widgets/elevated_button/custom_elevated_btn.dart';
import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
import '../controller/edit_sales_controller.dart';

class EditSale extends GetView<EditSaleController> {
  const EditSale({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        controller.handleBackNavigation();
        return false;
      },
      child: Scaffold(
        appBar: MenuAppBar(
          title: 'Edit Sale',
        ),
        extendBodyBehindAppBar: false,
        endDrawer: MyDrawer(),
        body: Obx(() {
          if (controller.isLoadingSale) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: kPrimaryColor),
                  SizedBox(height: 16),
                  Text(
                    'Loading sale details...',
                    style: TextStyle(color: kSecondaryColor),
                  ),
                ],
              ),
            );
          }

          if (controller.loadError.isNotEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      controller.loadError,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 24),
                    CustomElevatedButton(
                      text: 'Try Again',
                      onPressed: () => controller.refreshData(),
                      backgroundColor: kPrimaryColor,
                      textColor: kLightColor,
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sale info banner
                  _buildSaleInfoBanner(context),
                  const SizedBox(height: 20),
                  _buildSaleDatePicker(controller),
                  const SizedBox(height: 20),
                  _buildMerchantDropdown(controller),
                  const SizedBox(height: 20),
                  _buildTotalAmountField(controller),
                  const SizedBox(height: 20),
                  _buildPaymentModeDropdown(controller),
                  const SizedBox(height: 20),
                  _buildYieldDropdown(controller),
                  const SizedBox(height: 20),
                  _buildExistingImagesSection(context, controller),
                  const SizedBox(height: 20),
                  _buildNewImageUploadSection(context, controller),
                  const SizedBox(height: 30),
                  _buildSaveButton(controller),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  /// -------------------------------
  /// Sale Info Banner
  /// -------------------------------
  Widget _buildSaleInfoBanner(BuildContext context) {
    return Obx(() {
      final sale = controller.currentSale;
      if (sale == null) return SizedBox.shrink();

      return Card(
        color: kLightGreen,
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: kPrimaryColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Editing Sale #${sale.id}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Current Total: ${controller.formattedTotalAmount}',
                style: TextStyle(
                  fontSize: 14,
                  color: kSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                controller.imageSummary,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// -------------------------------
  /// Sale Date Picker
  /// -------------------------------
  Widget _buildSaleDatePicker(EditSaleController controller) {
    return GestureDetector(
      onTap: () => controller.selectSaleDate(),
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller.saleDateController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.calendar_today, color: kPrimaryColor),
            labelText: 'Sale Date',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: const BorderSide(color: kSecondaryColor),
            ),
            labelStyle: const TextStyle(color: kSecondaryColor),
          ),
        ),
      ),
    );
  }

  /// -------------------------------
  /// Merchant Dropdown
  /// -------------------------------
  /// Merchant Dropdown - UPDATED
  Widget _buildMerchantDropdown(EditSaleController controller) {
    return Obx(() {
      final selectedId = controller.selectedMerchantId;
      final merchants = controller.merchants;
      final isLoading = controller.isLoadingMerchants;

      if (isLoading) {
        return _buildLoadingField('Loading merchants...');
      }

      if (merchants.isEmpty) {
        return _buildErrorField('No merchants available');
      }

      // FIXED: Check if selected value exists in items
      final bool hasValidSelection =
          selectedId.isNotEmpty && merchants.any((m) => m.id == selectedId);

      return DropdownButtonFormField<String>(
        value: hasValidSelection ? selectedId : null, // Set to null if invalid
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.person, color: kPrimaryColor),
          labelText: 'Select Merchant',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50.0),
            borderSide: const BorderSide(color: kSecondaryColor),
          ),
          labelStyle: const TextStyle(color: kSecondaryColor),
        ),
        items: merchants
            .map((merchant) => DropdownMenuItem<String>(
                  value: merchant.id,
                  child: Text(merchant.name),
                ))
            .toList(),
        onChanged: (value) => controller.selectMerchant(value),
      );
    });
  }

  /// -------------------------------
  /// Total Amount Field
  /// -------------------------------
  Widget _buildTotalAmountField(EditSaleController controller) {
    return TextFormField(
      controller: controller.totalAmountController,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.currency_rupee, color: kPrimaryColor),
        labelText: 'Total Amount',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: kSecondaryColor),
        ),
        labelStyle: const TextStyle(color: kSecondaryColor),
      ),
      onChanged: (value) => controller.updateTotalAmount(value),
    );
  }

  /// -------------------------------
  /// Payment Mode Dropdown
  /// -------------------------------
  Widget _buildPaymentModeDropdown(EditSaleController controller) {
    return Obx(() {
      final selectedPayment = controller.selectedPaymentMode;
      final paymentModes = controller.paymentModes;

      // FIXED: Check if selected value exists in items
      final bool hasValidSelection =
          selectedPayment.isNotEmpty && paymentModes.contains(selectedPayment);

      return DropdownButtonFormField<String>(
        value: hasValidSelection
            ? selectedPayment
            : null, // Set to null if invalid
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.payment, color: kPrimaryColor),
          labelText: 'Select Payment Mode',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50.0),
            borderSide: const BorderSide(color: kSecondaryColor),
          ),
          labelStyle: const TextStyle(color: kSecondaryColor),
        ),
        items: paymentModes
            .map((mode) => DropdownMenuItem<String>(
                  value: mode,
                  child: Text(mode),
                ))
            .toList(),
        onChanged: (value) => controller.selectPaymentMode(value),
      );
    });
  }

  /// -------------------------------
  /// Yield Dropdown
  /// -------------------------------
  Widget _buildYieldDropdown(EditSaleController controller) {
    return Obx(() {
      final selectedYield = controller.selectedYieldId;
      final availableYields = controller.availableYields;
      final isLoading = controller.isLoadingYields;

      if (isLoading) {
        return _buildLoadingField('Loading yields...');
      }

      if (availableYields.isEmpty) {
        return _buildErrorField('No yield records available');
      }

      // FIXED: Check if selected value exists in items
      final bool hasValidSelection = selectedYield.isNotEmpty &&
          availableYields.any((y) => y.id == selectedYield);

      return DropdownButtonFormField<String>(
        value:
            hasValidSelection ? selectedYield : null, // Set to null if invalid
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.inventory, color: kPrimaryColor),
          labelText: 'Select Yield Record',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50.0),
            borderSide: const BorderSide(color: kSecondaryColor),
          ),
          labelStyle: const TextStyle(color: kSecondaryColor),
        ),
        items: availableYields
            .map((yieldRecord) => DropdownMenuItem<String>(
                  value: yieldRecord.id,
                  child: Text(
                      '${yieldRecord.cropName} - ${yieldRecord.harvestDate.day}/${yieldRecord.harvestDate.month}/${yieldRecord.harvestDate.year}'),
                ))
            .toList(),
        onChanged: (value) => controller.selectYield(value),
      );
    });
  }

  /// -------------------------------
  /// Existing Images Section
  /// -------------------------------
  Widget _buildExistingImagesSection(
      BuildContext context, EditSaleController controller) {
    return Obx(() {
      final existingImages = controller.existingImages;

      if (existingImages.isEmpty) {
        return SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Existing Images',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kSecondaryColor,
                ),
              ),
              Text(
                '${existingImages.length} image(s)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: existingImages.length,
              itemBuilder: (context, index) {
                final image = existingImages[index];
                final isMarkedForDeletion =
                    controller.isImageMarkedForDeletion(image.id);

                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      Opacity(
                        opacity: isMarkedForDeletion ? 0.4 : 1.0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            image.imageUrl,
                            width: 150,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 150,
                                height: 200,
                                color: Colors.grey[300],
                                child: Icon(Icons.broken_image, size: 40),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 150,
                                height: 200,
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: GestureDetector(
                          onTap: () =>
                              _showDeleteImageDialog(context, image.id),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isMarkedForDeletion
                                  ? Colors.orange
                                  : Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isMarkedForDeletion ? Icons.undo : Icons.delete,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      if (isMarkedForDeletion)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.delete_forever,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tap the delete icon to remove an image',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      );
    });
  }

  /// -------------------------------
  /// New Image Upload Section
  /// -------------------------------
  Widget _buildNewImageUploadSection(
      BuildContext context, EditSaleController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Add New Images',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kSecondaryColor,
              ),
            ),
            Obx(() {
              final totalCount = controller.totalImagesCount;
              return Text(
                '$totalCount/$maxImages',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 10),

        // Image upload buttons
        Row(
          children: [
            Expanded(
              child: Obx(() {
                final maxReached = controller.maxImagesReached;
                return ElevatedButton.icon(
                  onPressed: maxReached
                      ? null
                      : () => _showImageSourceDialog(context, controller),
                  icon: const Icon(
                    Icons.add_a_photo,
                    color: kLightColor,
                  ),
                  label: const Text('Add Images'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: kLightColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 15),

        // Display new images
        Obx(() {
          final images = controller.billImages;
          final isCompressing = controller.isCompressing;

          if (images.isEmpty) {
            return Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                border: Border.all(color: kSecondaryColor, width: 2),
                color: Colors.grey[100],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No new images',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  Text(
                    'Add new images using the button above',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            );
          }

          return Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                final image = images[index];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(image.path),
                          width: 150,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: GestureDetector(
                          onTap: () => controller.removeNewImage(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      if (isCompressing)
                        Positioned(
                          bottom: 5,
                          left: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Compressing...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        }),

        const SizedBox(height: 10),
        Text(
          'Maximum $maxImages images total (existing + new). Images will be compressed automatically.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ],
    );
  }

  /// Show image source dialog
  void _showImageSourceDialog(
      BuildContext context, EditSaleController controller) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  controller.pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  controller.pickMultipleImages();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show delete image confirmation dialog
  void _showDeleteImageDialog(BuildContext context, String imageId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteExistingImage(imageId);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// -------------------------------
  /// Save Button
  /// -------------------------------
  Widget _buildSaveButton(EditSaleController controller) {
    return Obx(() {
      final isSaving = controller.isSaving;
      final canSave = controller.canSave;

      return CustomElevatedButton(
        text: isSaving ? 'Saving...' : 'Save Changes',
        onPressed: canSave ? () => controller.updateSale() : null,
        backgroundColor: canSave ? kSecondaryColor : Colors.grey,
        textColor: kLightColor,
      );
    });
  }

  /// -------------------------------
  /// Helper Widgets
  /// -------------------------------
  Widget _buildLoadingField(String text) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: kSecondaryColor),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildErrorField(String text) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(50),
        color: Colors.red.shade50,
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 20),
          SizedBox(width: 12),
          Text(text, style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  static const int maxImages = 10;
}
