import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/values/app_colors.dart';
import '../../../data/services/merchant/merchant_service.dart';
import '../../../global_widgets/bottom_navigation/bottom_navigation_widget.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../../../global_widgets/elevated_button/custom_elevated_btn.dart';
import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
import '../controller/edit_merchant_controller.dart';

class MerchantEditScreen extends StatelessWidget {
  const MerchantEditScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MerchantEditController());

    return Scaffold(
      appBar: MenuAppBar(
        title: controller.isEditMode.value ? 'Edit Merchant' : 'Add Merchant',
        showAddIcon: true,
        addIcon: const Icon(
          Icons.visibility,
          size: 25.0,
          color: kTertiaryColor,
        ),
        onAddPressed: () => controller.navigateToViewMerchants(),
      ),
      extendBodyBehindAppBar: false,
      endDrawer: MyDrawer(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading merchant data...',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Merchant Name Field
                  _buildTextField(
                    'Merchant Name',
                    controller.nameController,
                    Icons.store,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Merchant name is required';
                      }
                      if (value.length > 255) {
                        return 'Merchant name must be less than 255 characters';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                    maxLength: 255,
                    onChanged: (value) {
                      // Check for duplicate name with debouncing
                      if (value.trim().length >= 3) {
                        Future.delayed(const Duration(milliseconds: 800), () {
                          if (controller.nameController.text.trim() == value.trim()) {
                            controller.checkMerchantNameExists();
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20.0),

                  // Address Field
                  _buildTextField(
                    'Address',
                    controller.addressController,
                    Icons.location_on,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Address is required';
                      }
                      if (value.length > 500) {
                        return 'Address must be less than 500 characters';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 20.0),

                  // Contact Number Field
                  _buildTextField(
                    'Contact Number',
                    controller.contactController,
                    Icons.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Contact number is required';
                      }
                      if (!MerchantService.isValidContactNumber(value)) {
                        return 'Please enter a valid contact number (10-15 digits)';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d+]')),
                      LengthLimitingTextInputFormatter(15),
                    ],
                    onChanged: (value) {
                      controller.formatContactNumber(value);
                    },
                  ),
                  const SizedBox(height: 20.0),

                  // Payment Terms Dropdown
                  _buildPaymentTermsDropdown(controller),
                  const SizedBox(height: 30.0),

                  // Save Button
                  Obx(() => CustomElevatedButton(
                        text: controller.isSaving.value
                            ? (controller.isEditMode.value ? 'Updating...' : 'Saving...')
                            : (controller.isEditMode.value ? 'Update Merchant' : 'Save Merchant'),
                        onPressed: controller.isSaving.value
                            ? () {}
                            : () => controller.saveMerchant(),
                        backgroundColor: kPrimaryColor,
                        textColor: kLightColor,
                      )),

                  
                ],
              ),
            ),
          ),
        );
      }),
      bottomNavigationBar: Obx(() => MyBottomNavigation(
            selectedIndex: controller.selectedIndex.value,
            onTabSelected: controller.navigateToTab,
          )),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController textController,
    IconData icon, {
    String? Function(String?)? validator,
    Color iconColor = kPrimaryColor,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    int? maxLength,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: textController,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: iconColor),
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: kSecondaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2.0),
        ),
        labelStyle: const TextStyle(color: kSecondaryColor),
        counterStyle: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      validator: validator,
      textCapitalization: textCapitalization,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      buildCounter: maxLength != null
          ? (context, {required currentLength, required isFocused, maxLength}) {
              return Text(
                '$currentLength/${maxLength ?? 255}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              );
            }
          : null,
    );
  }

  Widget _buildPaymentTermsDropdown(MerchantEditController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Terms',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: kSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => Container(
              decoration: BoxDecoration(
                border: Border.all(color: kSecondaryColor),
                borderRadius: BorderRadius.circular(50.0),
              ),
              child: DropdownButtonFormField<String>(
                value: controller.selectedPaymentTerms.value,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.payment, color: kPrimaryColor),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: controller.paymentTermsOptions
                    .map((String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              _getPaymentTermsIcon(value),
                              const SizedBox(width: 8),
                              Text(MerchantService.getPaymentTermsDisplayName(value)),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: controller.updatePaymentTerms,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select payment terms';
                  }
                  return null;
                },
                isExpanded: true,
                dropdownColor: Colors.white,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
            )),
        const SizedBox(height: 8),
        Obx(() => Text(
              'Selected: ${controller.paymentTermsDisplayName}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            )),
      ],
    );
  }

  Widget _getPaymentTermsIcon(String paymentTerm) {
    switch (paymentTerm.toLowerCase()) {
      case 'cash':
        return const Icon(Icons.money, size: 20, color: Colors.green);
      case 'card':
        return const Icon(Icons.credit_card, size: 20, color: Colors.blue);
      case 'upi':
        return const Icon(Icons.qr_code, size: 20, color: Colors.purple);
      case 'online':
        return const Icon(Icons.computer, size: 20, color: Colors.orange);
      default:
        return const Icon(Icons.payment, size: 20, color: kPrimaryColor);
    }
  }
}

