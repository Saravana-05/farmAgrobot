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
    // Initialize both controllers
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
            tooltip: 'Refresh Dashboard',
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
            child: Column(
              children: [
                _buildHeaderSection(dashboardController),
                const SizedBox(height: 12),
                _buildMainContent(dashboardController, cropController),
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
            style: TextStyle(color: kSecondaryColor, fontSize: 16),
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
              'Failed to Load Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
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
            ElevatedButton.icon(
              onPressed: () {
                dashboardController.refreshDashboard();
                cropController.refreshCropDashboard();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: kLightColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(DashboardController controller) {
    return Container(
      color: kLightColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() {
                  String periodText = '';
                  switch (controller.selectedPeriod.value) {
                    case 'week':
                      periodText = 'Weekly';
                      break;
                    case 'month':
                      periodText = 'Monthly';
                      break;
                    case 'year':
                      periodText = 'Yearly';
                      break;
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Financial Report',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        periodText,
                        style: const TextStyle(
                          color: kPrimaryColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  );
                }),
                _buildPeriodToggle(controller),
              ],
            ),
            const SizedBox(height: 12),
            _buildFinancialOverview(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodToggle(DashboardController controller) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          _buildToggleButton('W', 'week', controller),
          _buildToggleButton('M', 'month', controller),
          _buildToggleButton('Y', 'year', controller),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? kLightColor : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? kPrimaryColor : kLightColor,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kLightGreen,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: profit >= 0
                        ? kSecondaryColor.withOpacity(0.15)
                        : kRed.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    profit >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    color: profit >= 0 ? kSecondaryColor : kRed,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profit >= 0 ? 'Net Profit' : 'Net Loss',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      controller.formatCurrency(profit.abs()),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: profit >= 0 ? kSecondaryColor : kRed,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatPill(
                    'Revenue',
                    controller.formatCurrency(revenue),
                    kPrimaryColor,
                    Icons.arrow_circle_up,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatPill(
                    'Expenses',
                    controller.formatCurrency(expenses),
                    kRed,
                    Icons.arrow_circle_down,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatPill(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(DashboardController dashboardController,
      CropYieldController cropController) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          _buildYieldsSection(cropController),
          const SizedBox(height: 12),
          _buildSalesSection(cropController),
        ],
      ),
    );
  }

  Widget _buildYieldsSection(CropYieldController controller) {
    return Container(
      decoration: BoxDecoration(
        color: kLightColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kSecondaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          const Icon(Icons.eco, color: kLightColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Crop Yields',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                _buildCropPeriodSelector(controller),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: _buildCropCards(controller),
          ),
        ],
      ),
    );
  }

  Widget _buildCropPeriodSelector(CropYieldController controller) {
    return Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: kLightGreen,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.selectedCropPeriod.value,
              isDense: true,
              items: const [
                DropdownMenuItem(value: 'current_week', child: Text('Week')),
                DropdownMenuItem(value: 'current_month', child: Text('Month')),
                DropdownMenuItem(
                    value: 'last_month', child: Text('Last Month')),
                DropdownMenuItem(value: 'current_year', child: Text('Year')),
              ],
              onChanged: (value) => controller.changeCropPeriod(value),
              style: TextStyle(
                color: kPrimaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
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
          padding: const EdgeInsets.all(30),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.agriculture, size: 40, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Text(
                  'No crop data available',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          ),
        );
      }

      return SizedBox(
        height: 130,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: controller.cropYieldData.length,
          itemBuilder: (context, index) {
            var crop = controller.cropYieldData[index];
            return Padding(
              padding: EdgeInsets.only(
                  right: index == controller.cropYieldData.length - 1 ? 0 : 10),
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
        final value = yields[controller.selectedCropPeriod.value];
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

      return Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kLightYellow,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: kSecondaryColor.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: kLightColor,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: cropImage != null && cropImage.isNotEmpty
                    ? Image.network(
                        cropImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.spa,
                            color: kSecondaryColor,
                            size: 22,
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                            ),
                          );
                        },
                      )
                    : Icon(
                        Icons.spa,
                        color: kSecondaryColor,
                        size: 22,
                      ),
              ),
            ),
            Column(
              children: [
                Text(
                  crop['crop_name'] ?? 'Unknown',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: -0.2,
                    color: kBlackColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${currentYield.toStringAsFixed(0)} ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: kPrimaryColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: displayUnit,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSalesSection(CropYieldController controller) {
    return Container(
      decoration: BoxDecoration(
        color: kLightColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shopping_bag,
                      color: kLightColor, size: 18),
                ),
                const SizedBox(width: 10),
                Obx(() {
                  double totalYield = controller.getTotalYieldForPeriod();
                  int totalRecords = controller.getTotalYieldRecords();

                  return Row(
                    children: [
                      const Text(
                        'Crop Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: kLightGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$totalRecords harvests',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: kPrimaryColor,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          Obx(() => _buildDynamicSalesItems(controller)),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildDynamicSalesItems(CropYieldController controller) {
    if (controller.cropYieldData.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(30),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.shopping_cart_outlined,
                  size: 40, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text(
                'No crop data available',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // Get top performing crops
    final topCrops = controller.getTopPerformingCrops(limit: 3);

    List<Widget> salesItems = [];
    for (int i = 0; i < topCrops.length; i++) {
      var crop = topCrops[i];

      // FIX: Don't cast - check type instead
      final yields = crop['yields'];
      double yieldAmount = 0.0;

      if (yields != null && yields is Map) {
        final value = yields[controller.selectedCropPeriod.value];
        yieldAmount = controller.getCurrentYieldForPeriod(
          Map<String, dynamic>.from(yields),
          controller.selectedCropPeriod.value,
        );
      }

      // FIX: Don't cast - check type instead
      final units = crop['units'];
      String displayUnit = 'kg';
      if (units != null && units is Map && units.isNotEmpty) {
        displayUnit = units.keys.first.toString();
      }

      // FIX: Safe integer conversion
      int yieldCount = 0;
      final yieldCountValue = crop['yield_count'];
      if (yieldCountValue != null) {
        if (yieldCountValue is int) {
          yieldCount = yieldCountValue;
        } else if (yieldCountValue is num) {
          yieldCount = yieldCountValue.toInt();
        }
      }

      salesItems.add(
        _buildSalesItem(
          crop['crop_name']?.toString() ?? 'Unknown',
          '${yieldAmount.toStringAsFixed(1)} $displayUnit',
          '$yieldCount harvests',
          _getCropIcon(crop['crop_name']?.toString()),
          controller
              .getCropDisplayColor(crop['crop_name']?.toString() ?? 'Unknown'),
        ),
      );

      if (i < topCrops.length - 1) {
        salesItems.add(_buildDivider());
      }
    }

    return Column(children: salesItems);
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

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Divider(height: 1, color: kListGrey),
    );
  }

  Widget _buildSalesItem(String name, String quantity, String subtitle,
      IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
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
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: kBlackColor,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  quantity,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: kLightGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: kPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
