import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/values/app_colors.dart';
import '../../../global_widgets/bottom_navigation/bottom_navigation_widget.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../../../global_widgets/elevated_button/custom_elevated_btn.dart';
import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
import '../controller/add_merchant_controller.dart';

class AddMerchant extends StatelessWidget {
  const AddMerchant({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddMerchantController());

    return Scaffold(
      appBar: MenuAppBar(
        title: 'Add Merchant',
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                'Merchant Name',
                controller.nameController,
                Icons.store,
              ),
              const SizedBox(height: 20.0),
              _buildTextField(
                'Address',
                controller.addressController,
                Icons.location_on,
                isMultiline: true,
              ),
              const SizedBox(height: 20.0),
              _buildTextField(
                'Contact Number',
                controller.contactController,
                Icons.phone,
                isNumeric: true,
              ),
              const SizedBox(height: 20.0),
              _buildPaymentTermsDropdown(controller),
              const SizedBox(height: 30.0),
              _buildMerchantInfoCard(),
              const SizedBox(height: 30.0),
              Obx(() => CustomElevatedButton(
                    text: controller.isSaving.value
                        ? 'Saving...'
                        : 'Add Merchant',
                    onPressed: controller.isSaving.value
                        ? () {}
                        : () => controller.saveMerchant(),
                  ))
            ],
          ),
        ),
      ),
      bottomNavigationBar: Obx(() => MyBottomNavigation(
            selectedIndex: controller.selectedIndex.value,
            onTabSelected: controller.navigateToTab,
          )),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isNumeric = false,
    bool isMultiline = false,
    Color iconColor = kPrimaryColor,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric
          ? TextInputType.phone
          : (isMultiline ? TextInputType.multiline : TextInputType.text),
      maxLines: isMultiline ? null : 1,
      maxLength: isNumeric ? 15 : null,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: iconColor),
        labelText: label,
        helperText: isNumeric ? 'Enter 10-15 digit mobile number' : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: kSecondaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2.0),
        ),
        labelStyle: const TextStyle(color: kSecondaryColor),
        counterText: '', // Hide character counter for phone number
      ),
    );
  }

  Widget _buildPaymentTermsDropdown(AddMerchantController controller) {
    return Obx(() => DropdownButtonFormField<String>(
          value: controller.selectedPaymentTerms.value,
          onChanged: (String? newValue) {
            controller.selectedPaymentTerms.value = newValue;
          },
          items: controller.paymentTerms.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Row(
                children: [
                  Icon(
                    _getPaymentIcon(value),
                    color: kPrimaryColor,
                    size: 20.0,
                  ),
                  const SizedBox(width: 10.0),
                  Text(controller.getPaymentTermsDisplayName(value)),
                ],
              ),
            );
          }).toList(),
          decoration: InputDecoration(
            labelText: 'Payment Terms',
            prefixIcon: const Icon(Icons.payment, color: kPrimaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: const BorderSide(color: kSecondaryColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
              borderSide: const BorderSide(color: kPrimaryColor, width: 2.0),
            ),
            labelStyle: const TextStyle(color: kSecondaryColor),
          ),
          hint: const Text('Select payment method'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select payment terms';
            }
            return null;
          },
        ));
  }

  Widget _buildMerchantInfoCard() {
    return Card(
      elevation: 4.0,
      color: kLightGreen.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: kPrimaryColor,
                  size: 24.0,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Merchant Information',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            _buildInfoRow(
              Icons.store,
              'Merchant Details',
              'Add supplier or vendor information for better tracking',
            ),
            const SizedBox(height: 8.0),
            _buildInfoRow(
              Icons.phone,
              'Contact Information',
              'Mobile number will be used for communication',
            ),
            const SizedBox(height: 8.0),
            _buildInfoRow(
              Icons.payment,
              'Payment Terms',
              'Select preferred payment method for transactions',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: kSecondaryColor,
          size: 18.0,
        ),
        const SizedBox(width: 10.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: kSecondaryColor,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getPaymentIcon(String paymentTerm) {
    switch (paymentTerm.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'upi':
        return Icons.qr_code;
      case 'online':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }
}