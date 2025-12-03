import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/values/app_colors.dart';
import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../../../global_widgets/bottom_navigation/bottom_navigation_widget.dart';
import '../controller/dashboard_controller.dart';
import '../controller/yield_dashboard_controller.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.put(DashboardController());
    final cropController = Get.put(CropYieldController());

    return Scaffold(
      appBar: MenuAppBar(
        title: 'Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              dashboardController.refreshDashboard();
              cropController.refreshCropDashboard();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      extendBodyBehindAppBar: false,
      endDrawer: const MyDrawer(),
      body: Obx(() {
        bool isLoading = dashboardController.isLoading.value ||
            cropController.isLoading.value;
        bool hasError =
            dashboardController.hasError.value || cropController.hasError.value;

        if (isLoading) {
          return _buildLoadingState();
        }

        if (hasError) {
          return _buildErrorState(dashboardController, cropController);
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              dashboardController.loadDashboardData(),
              cropController.loadCropDashboardData(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header with period selector
                _buildHeaderSection(dashboardController),
                const SizedBox(height: 20),

                // Financial Overview Card
                _buildFinancialOverview(dashboardController),
                const SizedBox(height: 20),

                // Crop Yields Section
                _buildYieldsSection(cropController),
                const SizedBox(height: 16),

                // Crop Summary Section
                _buildSalesSection(dashboardController),
              ],
            ),
          ),
        );
      }),
      bottomNavigationBar: Obx(() => MyBottomNavigation(
            selectedIndex: dashboardController.selectedIndex.value,
            onTabSelected: dashboardController.onTabSelected,
          )),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: kPrimaryColor),
          const SizedBox(height: 16),
          Text(
            'Loading dashboard...',
            style: TextStyle(color: kSecondaryColor, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(DashboardController dashboardController,
      CropYieldController cropController) {
    String errorMsg = dashboardController.hasError.value
        ? dashboardController.errorMessage.value
        : cropController.errorMessage.value;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: kRed),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kBlackColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMsg,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                dashboardController.refreshDashboard();
                cropController.refreshCropDashboard();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(DashboardController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Obx(() {
              String periodText = '';
              switch (controller.selectedPeriod.value) {
                case 'week':
                  periodText = 'This Week';
                  break;
                case 'month':
                  periodText = 'This Month';
                  break;
                case 'year':
                  periodText = 'This Year';
                  break;
              }
              return Text(
                periodText,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              );
            }),
          ],
        ),
        _buildPeriodToggle(controller),
      ],
    );
  }

  Widget _buildPeriodToggle(DashboardController controller) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildToggleButton('Week', 'week', controller),
          _buildToggleButton('Month', 'month', controller),
          _buildToggleButton('Year', 'year', controller),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
      String label, String period, DashboardController controller) {
    return Obx(() {
      bool isSelected = controller.selectedPeriod.value == period;
      return GestureDetector(
        onTap: () => controller.changePeriod(period),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? kPrimaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildFinancialOverview(DashboardController controller) {
    return Obx(() {
      double revenue = controller.getCurrentPeriodRevenue();
      double expenses = controller.getCurrentPeriodExpenses();
      double profit = revenue - expenses;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Financial Overview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kBlackColor,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: profit >= 0 ? kLightGreen : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        profit >= 0 ? Icons.trending_up : Icons.trending_down,
                        size: 14,
                        color: profit >= 0 ? kSecondaryColor : kRed,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        profit >= 0 ? 'Profit' : 'Loss',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: profit >= 0 ? kSecondaryColor : kRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Net Profit/Loss
            Center(
              child: Column(
                children: [
                  Text(
                    controller.formatCurrency(profit.abs()),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: profit >= 0 ? kSecondaryColor : kRed,
                    ),
                  ),
                  Text(
                    profit >= 0 ? 'Net Profit' : 'Net Loss',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Revenue and Expenses
            Row(
              children: [
                Expanded(
                  child: _buildFinanceCard(
                    'Revenue',
                    controller.formatCurrency(revenue),
                    kPrimaryColor,
                    Icons.arrow_upward,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFinanceCard(
                    'Expenses',
                    controller.formatCurrency(expenses),
                    kRed,
                    Icons.arrow_downward,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFinanceCard(
      String title, String amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYieldsSection(CropYieldController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Crop Yields',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kBlackColor,
                ),
              ),
              _buildCropPeriodSelector(controller),
            ],
          ),
          const SizedBox(height: 16),
          _buildCropCards(controller),
        ],
      ),
    );
  }

  Widget _buildCropPeriodSelector(CropYieldController controller) {
    return Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.selectedCropPeriod.value,
              isDense: true,
              items: const [
                DropdownMenuItem(
                    value: 'current_week', child: Text('This Week')),
                DropdownMenuItem(
                    value: 'current_month', child: Text('This Month')),
                DropdownMenuItem(
                    value: 'last_month', child: Text('Last Month')),
                DropdownMenuItem(
                    value: 'current_year', child: Text('This Year')),
              ],
              onChanged: (value) => controller.changeCropPeriod(value),
              style: TextStyle(
                color: kPrimaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              icon: Icon(Icons.expand_more, color: kPrimaryColor, size: 16),
            ),
          ),
        ));
  }

  Widget _buildCropCards(CropYieldController controller) {
    return Obx(() {
      if (controller.cropYieldData.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(Icons.agriculture, size: 40, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text(
                'No crop data',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
        );
      }

      return SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: controller.cropYieldData.length,
          itemBuilder: (context, index) {
            var crop = controller.cropYieldData[index];
            return Padding(
              padding: EdgeInsets.only(
                  right: index == controller.cropYieldData.length - 1 ? 0 : 12),
              child: _buildCropCard(crop, controller),
            );
          },
        ),
      );
    });
  }

  Widget _buildCropCard(
      Map<String, dynamic> crop, CropYieldController controller) {
    return Obx(() {
      final yields = crop['yields'];
      double currentYield = 0.0;

      if (yields != null && yields is Map) {
        currentYield = controller.getCurrentYieldForPeriod(
          Map<String, dynamic>.from(yields),
          controller.selectedCropPeriod.value,
        );
      }

      // Get crop image
      String? cropImage = crop['crop_image'] as String?;

      // Get units for display
      final units = crop['units'];
      String displayUnit = 'kg';
      if (units != null && units is Map && units.isNotEmpty) {
        displayUnit = units.keys.first.toString();
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;

          // Very conservative scaling
          final scale = screenWidth < 360
              ? 0.7
              : screenWidth < 400
                  ? 0.8
                  : screenWidth < 600
                      ? 0.9
                      : screenWidth < 900
                          ? 1.0
                          : 1.0; // Cap at 1.0 for tablets

          return Container(
            width: 130 * scale, // Even smaller base width
            padding: EdgeInsets.all(10 * scale), // Even smaller padding
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10 * scale),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4 * scale,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Crop Image/Icon - Much smaller
                Container(
                  width: 50 * scale,
                  height: 50 * scale,
                  decoration: BoxDecoration(
                    color: kLightGreen,
                    shape: BoxShape.circle,
                  ),
                  child: cropImage != null && cropImage.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            cropImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.spa,
                                color: kPrimaryColor,
                                size: 20 * scale,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.spa,
                          color: kPrimaryColor,
                          size: 20 * scale,
                        ),
                ),
                SizedBox(height: 6 * scale),

                // Crop Name
                SizedBox(
                  height: 32 * scale, // Fixed height for text
                  child: Text(
                    crop['crop_name'] ?? 'Unknown',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11 * scale,
                      color: kBlackColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 2 * scale),

                // Yield Amount
                Text(
                  '${currentYield.toStringAsFixed(0)} $displayUnit',
                  style: TextStyle(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w700,
                    color: kPrimaryColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildSalesSection(DashboardController controller) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(color: Colors.grey[100]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Sales',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kBlackColor,
              ),
            ),
            Obx(() {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kLightGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  controller.recentSalesPeriodLabel.value.isNotEmpty
                      ? controller.recentSalesPeriodLabel.value
                      : 'This Week',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kPrimaryColor,
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 16),
        _buildRecentSalesItems(controller),
      ],
    ),
  );
}

Widget _buildRecentSalesItems(DashboardController controller) {
  return Obx(() {
    if (controller.recentSales.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 40, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text(
              'No recent sales',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: controller.recentSales.asMap().entries.map((entry) {
        int index = entry.key;
        var sale = entry.value;

        return Column(
          children: [
            _buildSaleItem(
              merchantName: sale['merchant_name'] ?? 'Unknown',
              cropName: sale['crop_name'] ?? 'Unknown',
              amount: sale['final_amount']?.toDouble() ?? 0.0,
              paymentStatus: sale['payment_status'] ?? 'pending',
              controller: controller,
            ),
            if (index < controller.recentSales.length - 1)
              Divider(height: 1, color: Colors.grey[200]),
          ],
        );
      }).toList(),
    );
  });
}

Widget _buildSaleItem({
  required String merchantName,
  required String cropName,
  required double amount,
  required String paymentStatus,
  required DashboardController controller,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        // Icon based on payment status
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: controller.getPaymentStatusColor(paymentStatus).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            paymentStatus == 'paid' 
                ? Icons.check_circle 
                : paymentStatus == 'partial'
                    ? Icons.schedule
                    : Icons.pending,
            color: controller.getPaymentStatusColor(paymentStatus),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        
        // Merchant and Crop info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                merchantName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kBlackColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.spa, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      cropName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        
        // Amount and status
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              controller.formatCurrency(amount),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: controller.getPaymentStatusColor(paymentStatus).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                paymentStatus.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: controller.getPaymentStatusColor(paymentStatus),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  
}


  Widget _buildDynamicSalesItems(CropYieldController controller) {
    if (controller.cropYieldData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 40, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text(
              'No crop data available',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Get top performing crops
    final topCrops = controller.getTopPerformingCrops(limit: 3);

    return Column(
      children: topCrops.asMap().entries.map((entry) {
        int index = entry.key;
        var crop = entry.value;

        final yields = crop['yields'];
        double yieldAmount = 0.0;

        if (yields != null && yields is Map) {
          yieldAmount = controller.getCurrentYieldForPeriod(
            Map<String, dynamic>.from(yields),
            controller.selectedCropPeriod.value,
          );
        }

        final units = crop['units'];
        String displayUnit = 'kg';
        if (units != null && units is Map && units.isNotEmpty) {
          displayUnit = units.keys.first.toString();
        }

        int yieldCount = 0;
        final yieldCountValue = crop['yield_count'];
        if (yieldCountValue != null) {
          if (yieldCountValue is int) {
            yieldCount = yieldCountValue;
          } else if (yieldCountValue is num) {
            yieldCount = yieldCountValue.toInt();
          }
        }

        return Column(
          children: [
            _buildSalesItem(
              crop['crop_name']?.toString() ?? 'Unknown',
              '${yieldAmount.toStringAsFixed(1)} $displayUnit',
              '$yieldCount harvests',
              _getCropIcon(crop['crop_name']?.toString()),
              controller.getCropDisplayColor(
                  crop['crop_name']?.toString() ?? 'Unknown'),
            ),
            if (index < topCrops.length - 1)
              Divider(height: 1, color: Colors.grey[200]),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSalesItem(String name, String quantity, String subtitle,
      IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kBlackColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  quantity,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCropIcon(String? cropName) {
    if (cropName == null) return Icons.spa;

    String name = cropName.toLowerCase();
    if (name.contains('rice')) return Icons.rice_bowl;
    if (name.contains('wheat')) return Icons.eco_outlined;
    if (name.contains('corn') || name.contains('maize')) return Icons.grass;
    if (name.contains('banana')) return Icons.nature;
    if (name.contains('lemon') || name.contains('citrus'))
      return Icons.emoji_food_beverage;
    if (name.contains('tomato')) return Icons.local_florist;
    if (name.contains('potato')) return Icons.terrain;

    return Icons.spa;
  }
}
