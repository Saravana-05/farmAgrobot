import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../../core/values/app_colors.dart';
import '../../../data/models/sales/sales_model.dart';
import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../../../global_widgets/elevated_button/custom_elevated_btn.dart';
import '../../../global_widgets/custom_snackbar/snackbar.dart';
import '../../../data/services/sales/sales_service.dart';
import '../../../data/models/yield/yield_model.dart';
import '../../../routes/app_pages.dart';

class CropVariant {
  final String id;
  final String name;
  final double quantity;
  double pricePerUnit;
  final String unit;

  CropVariant({
    required this.id,
    required this.name,
    required this.quantity,
    this.pricePerUnit = 0.0,
    this.unit = 'kg',
  });

  double get totalAmount => quantity * pricePerUnit;

  factory CropVariant.fromYieldVariant(YieldVariant yieldVariant) {
    return CropVariant(
      id: yieldVariant.id ?? '',
      name: yieldVariant.cropVariantName,
      quantity: yieldVariant.quantity,
      unit: yieldVariant.unit,
    );
  }
}

class SaleReviewScreen extends StatefulWidget {
  const SaleReviewScreen({Key? key}) : super(key: key);

  @override
  State<SaleReviewScreen> createState() => _SaleReviewScreenState();
}

class _SaleReviewScreenState extends State<SaleReviewScreen> {
  Map<String, dynamic>? saleData;
  List<CropVariant> cropVariants = [];
  double commission = 0.0;
  double lorryRent = 0.0;
  double coolyCharges = 0.0;
  bool _isSubmitting = false;
  bool _isLoadingVariants = false;
  String? selectedYieldId;
  AvailableYield? selectedYield;

  // CORRECTED: Final amount should be calculated from variant totals, not add sale amount
  double get totalAmountFromAddSale =>
      saleData!['totalAmount']?.toDouble() ?? 0.0;
  double get calculatedTotalFromVariants =>
      cropVariants.fold(0.0, (sum, variant) => sum + variant.totalAmount);
  double get totalDeductions => commission + lorryRent + coolyCharges;
  double get finalAmount =>
      calculatedTotalFromVariants - totalDeductions; // FIXED: Use variant total

  // Check if variants have pricing set (no longer need to match add sale total)
  bool get variantPricingValid {
    if (cropVariants.isEmpty) return false;
    return cropVariants.every((variant) => variant.pricePerUnit > 0);
  }

  @override
  void initState() {
    super.initState();
    saleData = Get.arguments as Map<String, dynamic>?;

    if (saleData == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        CustomSnackbar.showError(
          title: 'Error',
          message: 'No sale data found',
        );
        Get.back();
      });
    } else {
      selectedYieldId = saleData!['yieldId'];
      _loadCropVariantsFromYield();
    }
  }

  void _loadCropVariantsFromYield() {
    setState(() {
      _isLoadingVariants = true;
    });

    try {
      if (selectedYieldId != null && selectedYieldId!.isNotEmpty) {
        _loadVariantsForYield(selectedYieldId!);
      } else {
        _createDefaultVariants();
      }
    } catch (e) {
      print('Error loading crop variants: $e');
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to load crop variants: ${e.toString()}',
      );
      _createDefaultVariants();
    } finally {
      setState(() {
        _isLoadingVariants = false;
      });
    }
  }

  Future<void> _loadVariantsForYield(String yieldId) async {
    try {
      final result = await SalesService.getYieldVariants(yieldId);
      print('Yield variants result: $result');

      if (result['success'] && result['data'] != null) {
        final yieldData = result['data']['data'];

        if (yieldData != null && yieldData['yield_variants'] != null) {
          List<dynamic> variantsJson = yieldData['yield_variants'];
          print('Found ${variantsJson.length} variants');

          List<CropVariant> variants = variantsJson.map((variantJson) {
            return CropVariant(
              id: variantJson['crop_variant_id']?.toString() ??
                  variantJson['id']?.toString() ??
                  '',
              name: variantJson['crop_variant_name']?.toString() ?? 'Unknown',
              quantity:
                  double.tryParse(variantJson['quantity']?.toString() ?? '0') ??
                      0.0,
              unit: variantJson['unit']?.toString() ?? 'kg',
            );
          }).toList();

          setState(() {
            cropVariants = variants;
          });

          if (variants.isEmpty) {
            _createDefaultVariants();
          }
        } else {
          _createDefaultVariants();
        }
      } else {
        CustomSnackbar.showError(
          title: 'Error',
          message:
              result['data']?['message'] ?? 'Failed to load yield variants',
        );
        _createDefaultVariants();
      }
    } catch (e) {
      print('Error fetching yield variants: $e');
      CustomSnackbar.showError(
        title: 'Error',
        message: 'Failed to load crop variants: ${e.toString()}',
      );
      _createDefaultVariants();
    }
  }

  void _createDefaultVariants() {
    setState(() {
      cropVariants = [
        CropVariant(
          id: '1',
          name: 'Standard Grade',
          quantity: 100.0, // Default quantity
        ),
      ];
    });
  }

  String formatDate(dynamic date) {
    if (date == null) return 'N/A';

    if (date is DateTime) {
      return DateFormat('dd MMM yyyy').format(date);
    } else if (date is String) {
      try {
        return DateFormat('dd MMM yyyy').format(DateTime.parse(date));
      } catch (e) {
        return date;
      }
    }
    return 'Invalid Date';
  }

  @override
  Widget build(BuildContext context) {
    if (saleData == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: MenuAppBar(
        title: 'Review Sale',
      ),
      extendBodyBehindAppBar: false,
      endDrawer: MyDrawer(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Total Amount Display Card - FIXED
            Card(
              color: kLightGreen,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Total Sale Amount',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: kSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '₹ ${totalAmountFromAddSale.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Amount entered in Add Sale screen',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Sale Summary Card - FIXED with harvest date
            Card(
              color: kLightGreen,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sale Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 600) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildLeftColumn()),
                              SizedBox(width: 16),
                              Expanded(child: _buildRightColumn()),
                            ],
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLeftColumn(),
                              SizedBox(height: 16),
                              _buildRightColumn(),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Crop Variants Section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Crop Variants & Pricing',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: kSecondaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        if (_isLoadingVariants)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Set prices for each variant. The total will be used for final calculation.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 16),
                    if (_isLoadingVariants)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Loading crop variants...'),
                        ),
                      )
                    else if (cropVariants.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(Icons.info_outline, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('No variants available for this crop'),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._buildVariantsList(),

                    // Variant pricing validation
                    if (cropVariants.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(top: 16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: variantPricingValid
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: variantPricingValid
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              variantPricingValid
                                  ? Icons.check_circle
                                  : Icons.info,
                              color: variantPricingValid
                                  ? Colors.green
                                  : Colors.orange,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                variantPricingValid
                                    ? 'All variants have prices set. Total: ₹${calculatedTotalFromVariants.toStringAsFixed(2)}'
                                    : 'Please set prices for all variants to continue',
                                style: TextStyle(
                                  color: variantPricingValid
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
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

            SizedBox(height: 16),

            // Bill Images Section
            if (saleData!['billImages'] != null &&
                (saleData!['billImages'] as List).isNotEmpty)
              Card(
                color: kLightGreen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Bill Images (${(saleData!['billImages'] as List).length})',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: kPrimaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      height: 400,
                      child: PageView.builder(
                        itemCount: (saleData!['billImages'] as List).length,
                        itemBuilder: (context, index) {
                          final imageFile =
                              (saleData!['billImages'] as List<File>)[index];
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 8),
                            child: InteractiveViewer(
                              minScale: 0.5,
                              maxScale: 3.0,
                              child: Image.file(
                                imageFile,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: Center(
                                      child: Text('Error loading image'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if ((saleData!['billImages'] as List).length > 1)
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Swipe to view all images',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            SizedBox(height: 16),

            // Deductions Card - FIXED
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deductions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: kSecondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Enter deduction amounts that will be subtracted from total sale amount',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 600) {
                          return Row(
                            children: [
                              Expanded(child: _buildCommissionField()),
                              SizedBox(width: 12),
                              Expanded(child: _buildLorryRentField()),
                              SizedBox(width: 12),
                              Expanded(child: _buildCoolyChargesField()),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildCommissionField(),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _buildLorryRentField()),
                                  SizedBox(width: 12),
                                  Expanded(child: _buildCoolyChargesField()),
                                ],
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // CORRECTED Final Calculation Summary
            Card(
              color: kLightGreen,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Final Calculation',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Total Sale Amount',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: kSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '₹ ${totalAmountFromAddSale.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: 16),
                    _buildSummaryRow('Variant Pricing Total:',
                        calculatedTotalFromVariants, false,
                        textColor: kPrimaryColor),
                    SizedBox(height: 6),
                    Divider(height: 20, thickness: 1),
                    _buildSummaryRow('Commission:', commission, true),
                    SizedBox(height: 6),
                    _buildSummaryRow('Lorry Rent:', lorryRent, true),
                    SizedBox(height: 6),
                    _buildSummaryRow('Cooly Charges:', coolyCharges, true),
                    SizedBox(height: 6),
                    _buildSummaryRow('Total Deductions:', totalDeductions, true,
                        textColor: Colors.red.shade700),
                    Divider(height: 20, thickness: 2),
                    _buildSummaryRow(
                      'Final Amount:',
                      finalAmount,
                      false,
                      isTotal: true,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Final Amount = Variant Pricing Total - All Deductions',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Submit Button - FIXED validation
            CustomElevatedButton(
              text: _isSubmitting ? 'Submitting...' : 'Confirm and Submit Sale',
              onPressed: (_isSubmitting ||
                      !variantPricingValid ||
                      cropVariants.isEmpty)
                  ? null
                  : _submitSale,
              backgroundColor: (_isSubmitting ||
                      !variantPricingValid ||
                      cropVariants.isEmpty)
                  ? Colors.grey
                  : kSecondaryColor,
              textColor: kLightColor,
            ),

            if (!variantPricingValid || cropVariants.isEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  !variantPricingValid
                      ? 'Please set prices for all crop variants before submitting.'
                      : 'Please ensure crop variants are loaded before submitting.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // UPDATED: Left column with harvest date from yield
  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Sale Date:', formatDate(saleData!['saleDate'])),
        SizedBox(height: 8),
        // FIXED: Show harvest date from yield instead of sale date
        _buildInfoRow(
            'Harvest Date:',
            formatDate(
                saleData!['harvestDate'] ?? saleData!['yieldHarvestDate'])),
        SizedBox(height: 8),
        _buildInfoRow('Merchant:', saleData!['merchantName'] ?? 'N/A'),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Payment Mode:', saleData!['paymentMode'] ?? 'N/A'),
        SizedBox(height: 8),
        _buildInfoRow('Yield Record:', saleData!['yieldName'] ?? 'N/A'),
        SizedBox(height: 8),
        _buildInfoRow(
            'Crop:', saleData!['cropName'] ?? saleData!['yieldName'] ?? 'N/A'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildVariantsList() {
    return cropVariants.asMap().entries.map((entry) {
      int index = entry.key;
      CropVariant variant = entry.value;

      return Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    variant.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: kSecondaryColor,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Qty: ${variant.quantity.toStringAsFixed(2)} ${variant.unit}',
                    style: TextStyle(
                      color: kPrimaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Price per ${variant.unit}',
                      border: OutlineInputBorder(),
                      prefixText: '₹ ',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() {
                        variant.pricePerUnit = double.tryParse(value) ?? 0;
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: variant.totalAmount > 0
                          ? kLightGreen
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: variant.totalAmount > 0
                            ? kPrimaryColor
                            : Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '₹ ${variant.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: variant.totalAmount > 0
                                ? kSecondaryColor
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildCommissionField() {
    return TextFormField(
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Commission Amount',
        border: OutlineInputBorder(),
        prefixText: '₹ ',
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: (value) {
        setState(() {
          commission = double.tryParse(value) ?? 0;
        });
      },
    );
  }

  Widget _buildLorryRentField() {
    return TextFormField(
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Lorry Rent',
        border: OutlineInputBorder(),
        prefixText: '₹ ',
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: (value) {
        setState(() {
          lorryRent = double.tryParse(value) ?? 0;
        });
      },
    );
  }

  Widget _buildCoolyChargesField() {
    return TextFormField(
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Cooly Charges',
        border: OutlineInputBorder(),
        prefixText: '₹ ',
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: (value) {
        setState(() {
          coolyCharges = double.tryParse(value) ?? 0;
        });
      },
    );
  }

  Widget _buildSummaryRow(String label, double amount, bool isDeduction,
      {bool isTotal = false, Color? textColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kSecondaryColor,
                  )
              : Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: textColor),
        ),
        Text(
          '₹ ${amount.toStringAsFixed(2)}',
          style: isTotal
              ? Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kSecondaryColor,
                  )
              : Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: textColor ?? (isDeduction ? Colors.red : null),
                  ),
        ),
      ],
    );
  }

  Future<void> _submitSale() async {
    if (_isSubmitting || !variantPricingValid || cropVariants.isEmpty) return;

    // Validation
    if (saleData!['merchantId'] == null ||
        saleData!['merchantId'].toString() == '0') {
      CustomSnackbar.showError(
        title: 'Validation Error',
        message: 'Please select a valid merchant',
      );
      return;
    }

    if (saleData!['yieldId'] == null ||
        saleData!['yieldId'].toString() == '0') {
      CustomSnackbar.showError(
        title: 'Validation Error',
        message: 'Please select a valid yield record',
      );
      return;
    }

    // Check finalAmount vs entered total
    if (finalAmount.toStringAsFixed(2) !=
        totalAmountFromAddSale.toStringAsFixed(2)) {
      CustomSnackbar.showError(
        title: 'Mismatch',
        message:
            'Final calculation (₹${finalAmount.toStringAsFixed(2)}) must match the entered total amount (₹${totalAmountFromAddSale.toStringAsFixed(2)}). Please adjust pricing or deductions.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      List<Map<String, dynamic>> variantData = cropVariants
          .map((variant) => {
                'crop_variant_id': variant.id,
                'quantity': variant.quantity,
                'amount': variant.pricePerUnit,
                'unit': variant.unit,
              })
          .toList();

      // Parse dates safely
      DateTime saleDate = saleData!['saleDate'] ?? DateTime.now();
      DateTime harvestDate = saleData!['harvestDate'] ??
          saleData!['yieldHarvestDate'] ??
          DateTime.now();

      // Format dates as YYYY-MM-DD (Django's expected format)
      String formatDate(DateTime date) {
        return date.toIso8601String().split('T')[0];
      }

      Map<String, dynamic> finalSaleData = {
        'merchant': saleData!['merchantId'].toString(),
        'yield_record': saleData!['yieldId'].toString(),
        'payment_mode': saleData!['paymentMode'] ?? 'Cash',
        'sale_date': formatDate(saleDate),
        'harvest_date': formatDate(harvestDate),
        'total_amount': calculatedTotalFromVariants,
        'total_calculated_amount': calculatedTotalFromVariants,
        'commission': commission,
        'lorry_rent': lorryRent,
        'cooly_charges': coolyCharges,
        'paid_amount': 0.0,
        'variants': variantData,
      };

      // Get the images properly
      List<File>? imageFiles;
      if (saleData!['billImages'] != null) {
        final billImages = saleData!['billImages'];
        if (billImages is List<File>) {
          imageFiles = billImages;
        } else if (billImages is List) {
          imageFiles = billImages.whereType<File>().toList();
        }
      }

      print('=== Final Sale Submission Debug ===');
      print(
          'Merchant ID: ${finalSaleData['merchant']} (${finalSaleData['merchant'].runtimeType})');
      print(
          'Yield Record ID: ${finalSaleData['yield_record']} (${finalSaleData['yield_record'].runtimeType})');
      print('Sale Date: ${finalSaleData['sale_date']}');
      print('Harvest Date: ${finalSaleData['harvest_date']}');
      print('Variants: ${json.encode(variantData)}');
      print('Total Amount: ${finalSaleData['total_amount']}');
      print('Calculated Amount: ${finalSaleData['total_calculated_amount']}');
      print('Images count: ${imageFiles?.length ?? 0}');
      print('Full payload: ${json.encode(finalSaleData)}');
      print('=== End Debug ===');

      // Call the service method
      Map<String, dynamic> result = await SalesService.saveSale(
        saleData: finalSaleData,
        saleImages: imageFiles,
      );

      // ===== DETAILED RESPONSE LOGGING =====
      print('\n=== SERVER RESPONSE DEBUG ===');
      print('Response success: ${result['success']}');
      print('Response status code: ${result['statusCode'] ?? "N/A"}');
      print('Full response data: ${json.encode(result)}');

      if (result['data'] != null) {
        print('Response data type: ${result['data'].runtimeType}');
        print('Response data: ${json.encode(result['data'])}');
      }

      if (result['error'] != null) {
        print('Response error: ${result['error']}');
      }

      if (result['data'] is Map && result['data']['errors'] != null) {
        print('Validation errors: ${json.encode(result['data']['errors'])}');
      }
      print('=== END SERVER RESPONSE ===\n');
      // ===== END RESPONSE LOGGING =====

      if (result['success']) {
        CustomSnackbar.showSuccess(
          title: 'Success',
          message: result['data']['message'] ?? 'Sale submitted successfully!',
        );

        await Future.delayed(const Duration(milliseconds: 1500));
        Get.offAllNamed(Routes.SALES, arguments: {'refresh': true});
      } else {
        String errorMessage =
            result['data']['message'] ?? 'Failed to submit sale';

        if (result['data']['errors'] != null) {
          final errors = result['data']['errors'] as Map<String, dynamic>;
          if (errors.isNotEmpty) {
            List<String> errorMessages = [];
            errors.forEach((key, value) {
              if (value is List) {
                errorMessages.add('$key: ${value.join(", ")}');
              } else {
                errorMessages.add('$key: $value');
              }
            });
            errorMessage = errorMessages.join('\n');
            print('All validation errors: $errors');
          }
        }

        CustomSnackbar.showError(
          title: 'Submission Failed',
          message: errorMessage,
        );
      }
    } catch (e, stackTrace) {
      print('\n=== EXCEPTION CAUGHT ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      print('=== END EXCEPTION ===\n');

      CustomSnackbar.showError(
        title: 'Error',
        message:
            'Network error occurred. Please check your connection and try again.',
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}
