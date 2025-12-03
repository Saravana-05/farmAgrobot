import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../../../core/values/app_colors.dart';
import '../../../global_widgets/bottom_navigation/bottom_navigation_widget.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../../../global_widgets/elevated_button/custom_elevated_btn.dart';
import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
import '../controller/add_sales_controller.dart';

class AddSale extends GetView<AddSaleController> {
  const AddSale({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        controller.handleBackNavigation();
        return false;
      },
      child: Scaffold(
        appBar: MenuAppBar(
          title: 'Add Sale',
        ),
        extendBodyBehindAppBar: false,
        endDrawer: MyDrawer(),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                _buildImageUploadSection(context, controller),
                const SizedBox(height: 30),
                _buildReviewSaleButton(controller),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNavigation(controller),
      ),
    );
  }

  /// -------------------------------
  /// Sale Date Picker
  /// -------------------------------
  Widget _buildSaleDatePicker(AddSaleController controller) {
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
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select sale date';
            }
            return null;
          },
        ),
      ),
    );
  }

  /// -------------------------------
  /// Merchant Dropdown - FIXED
  /// -------------------------------
  Widget _buildMerchantDropdown(AddSaleController controller) {
    return Obx(() {
      // Access observable variables directly within Obx
      final selectedId = controller.selectedMerchantId;
      final merchants = controller.merchants;

      return DropdownButtonFormField<String>(
        value: selectedId.isEmpty ? null : selectedId,
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
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a merchant';
          }
          return null;
        },
      );
    });
  }

  /// -------------------------------
  /// Total Amount Field - FIXED
  /// -------------------------------
  Widget _buildTotalAmountField(AddSaleController controller) {
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter total amount';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'Please enter a valid amount';
        }
        return null;
      },
    );
  }

  /// -------------------------------
  /// Payment Mode Dropdown - FIXED
  /// -------------------------------
  Widget _buildPaymentModeDropdown(AddSaleController controller) {
    return Obx(() {
      final selectedPayment = controller.selectedPaymentMode;
      final paymentModes = controller.paymentModes;

      return DropdownButtonFormField<String>(
        value: selectedPayment.isEmpty ? null : selectedPayment,
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
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a payment mode';
          }
          return null;
        },
      );
    });
  }

  /// -------------------------------
  /// Yield Dropdown - FIXED
  /// -------------------------------
  Widget _buildYieldDropdown(AddSaleController controller) {
    return Obx(() {
      final selectedYield = controller.selectedYieldId;
      final availableYields = controller.availableYields;

      return DropdownButtonFormField<String>(
        value: selectedYield.isEmpty ? null : selectedYield,
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
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a yield record';
          }
          return null;
        },
      );
    });
  }

  /// -------------------------------
  /// Image Upload Section - FIXED
  /// -------------------------------
  Widget _buildImageUploadSection(
      BuildContext context, AddSaleController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Bill Images',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kSecondaryColor,
              ),
            ),
            Obx(() {
              final imageCount = controller.billImages.length;
              return Text(
                '$imageCount/10',
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
            const SizedBox(width: 10),
           
          ],
        ),
        const SizedBox(height: 15),

        // Display selected images
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
                    'No images selected',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  Text(
                    'Add bill images using the buttons above',
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
                          onTap: () => controller.removeImage(index),
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
                      // Show compression status
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
          'Maximum 10 images allowed. Images will be compressed automatically.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ],
    );
  }

  /// Show image source dialog
  void _showImageSourceDialog(
      BuildContext context, AddSaleController controller) {
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

  /// -------------------------------
  /// Review Sale Button - FIXED
  /// -------------------------------
  Widget _buildReviewSaleButton(AddSaleController controller) {
    return Obx(() {
      final isLoading = controller.isLoading;
      return CustomElevatedButton(
        text: isLoading ? 'Loading...' : 'Review Sale',
        onPressed: isLoading ? () {} : () => controller.navigateToReviewSale(),
        backgroundColor: kSecondaryColor,
        textColor: kLightColor,
      );
    });
  }

  /// -------------------------------
  /// Bottom Navigation - FIXED
  /// -------------------------------
  Widget _buildBottomNavigation(AddSaleController controller) {
    // Option 1: Use AddSaleController's own navigation
    return MyBottomNavigation(
      selectedIndex: controller.selectedIndex,
      onTabSelected: controller.navigateToTab,
    );
  }
}
