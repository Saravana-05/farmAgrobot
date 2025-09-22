import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/values/app_colors.dart';
import '../../../global_widgets/menu_app_bar/menu_app_bar.dart';
import '../../../global_widgets/drawer/views/drawer.dart';
import '../../../global_widgets/bottom_navigation/bottom_navigation_widget.dart';
import '../controller/dashboard_controller.dart';

class DashboardScreen extends GetView<DashboardController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MenuAppBar(
        title: 'Dashboard',
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: controller.refreshDashboard,
            tooltip: 'Refresh Dashboard',
          ),
        ],
      ),
      extendBodyBehindAppBar: false,
      endDrawer: MyDrawer(),
      body: Obx(() => controller.isLoading.value
          ? _buildLoadingState()
          : RefreshIndicator(
              onRefresh: () async => controller.refreshDashboard(),
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeSection(),
                      SizedBox(height: 20),
                      _buildPeriodSelector(),
                      SizedBox(height: 20),
                      _buildMetricCards(),
                      SizedBox(height: 20),
                      _buildCropYieldSection(),
                      SizedBox(height: 20),
                      _buildQuickActions(),
                    ],
                  ),
                ),
              ),
            )),
      bottomNavigationBar: Obx(() => MyBottomNavigation(
            selectedIndex: controller.selectedIndex.value,
            onTabSelected: controller.onTabSelected,
          )),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: kPrimaryColor),
          SizedBox(height: 16),
          Text(
            'Loading dashboard...',
            style: TextStyle(
              color: kSecondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryColor, kSecondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Here\'s your farm\'s overview',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.agriculture,
            size: 60,
            color: Colors.white.withOpacity(0.7),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: kLightGreen.withOpacity(0.3),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          _buildPeriodButton('Week', 'week'),
          _buildPeriodButton('Month', 'month'),
          _buildPeriodButton('Year', 'year'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String period) {
    return Expanded(
      child: Obx(() => GestureDetector(
            onTap: () => controller.changePeriod(period),
            child: Container(
              margin: EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: controller.selectedPeriod.value == period
                    ? kPrimaryColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: controller.selectedPeriod.value == period
                        ? Colors.white
                        : kSecondaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          )),
    );
  }

  Widget _buildMetricCards() {
    return Obx(() {
      double revenue, expenses;
      String period = controller.selectedPeriod.value;

      switch (period) {
        case 'week':
          revenue = controller.weeklyRevenue.value;
          expenses = controller.weeklyExpenses.value;
          break;
        case 'month':
          revenue = controller.monthlyRevenue.value;
          expenses = controller.monthlyExpenses.value;
          break;
        case 'year':
        default:
          revenue = controller.totalRevenue.value;
          expenses = controller.totalExpenses.value;
      }

      double profit = revenue - expenses;

      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Revenue',
                  controller.formatCurrency(revenue),
                  Icons.trending_up,
                  kPrimaryColor,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Expenses',
                  controller.formatCurrency(expenses),
                  Icons.trending_down,
                  Color(0xFFF44336),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildProfitCard(profit),
        ],
      );
    });
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              Spacer(),
              Text(
                'This ${controller.selectedPeriod.value}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            title,
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitCard(double profit) {
    bool isPositive = profit >= 0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [Color(0xFF4CAF50), Color(0xFF2E7D32)]
              : [Color(0xFFF44336), Color(0xFFD32F2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? kPrimaryColor : Color(0xFFF44336))
                .withOpacity(0.3),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.account_balance_wallet : Icons.warning,
            color: Colors.white,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPositive ? 'Net Profit' : 'Net Loss',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  controller.formatCurrency(profit.abs()),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropYieldSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.agriculture, color: kPrimaryColor),
              SizedBox(width: 8),
              Text(
                'Crop Yields',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kSecondaryColor,
                ),
              ),
              Spacer(),
              _buildCropPeriodSelector(),
            ],
          ),
          SizedBox(height: 20),
          _buildCropList(),
        ],
      ),
    );
  }

  Widget _buildCropPeriodSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kLightGreen.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Obx(() => DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.selectedCropPeriod.value,
              items: [
                DropdownMenuItem(value: 'current_week', child: Text('This Week')),
                DropdownMenuItem(value: 'current_month', child: Text('This Month')),
                DropdownMenuItem(value: 'last_month', child: Text('Last Month')),
                DropdownMenuItem(value: 'current_year', child: Text('This Year')),
                DropdownMenuItem(value: 'last_year', child: Text('Last Year')),
              ],
              onChanged: controller.changeCropPeriod,
              style: TextStyle(
                color: kPrimaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              icon: Icon(Icons.arrow_drop_down, color: kPrimaryColor, size: 20),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          )),
    );
  }

  // Horizontal carousel slider for crops
  Widget _buildCropList() {
    return Obx(() => Container(
          height: 280, // Fixed height for the carousel
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.85),
            itemCount: controller.cropYieldData.length,
            itemBuilder: (context, index) {
              var crop = controller.cropYieldData[index];
              return Container(
                margin: EdgeInsets.only(
                  right: index == controller.cropYieldData.length - 1 ? 0 : 12,
                  left: index == 0 ? 0 : 6,
                ),
                child: _buildCropYieldCard(crop),
              );
            },
          ),
        ));
  }

  // Card design matching the image style
  Widget _buildCropYieldCard(Map<String, dynamic> crop) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF0F8E8), // Light green background like in image
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Crop Image/Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: crop['imagePath'] != null
                    ? Image.asset(
                        crop['imagePath'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.agriculture,
                            color: Color(crop['primaryColor'] ?? 0xFF4CAF50),
                            size: 32,
                          );
                        },
                      )
                    : Icon(
                        Icons.agriculture,
                        color: Color(crop['primaryColor'] ?? 0xFF4CAF50),
                        size: 32,
                      ),
              ),
            ),
            SizedBox(height: 12),

            // Crop Name
            Text(
              crop['name'] ?? 'Unknown Crop',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: kSecondaryColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12),

            // Time periods and values
            Expanded(
              child: Column(
                children: [
                  _buildPeriodRow('This Week', _getCropYieldForPeriod(crop, 'current_week'), crop['unit'] ?? 'kg'),
                  SizedBox(height: 6),
                  _buildPeriodRow('This Month', _getCropYieldForPeriod(crop, 'current_month'), crop['unit'] ?? 'kg'),
                  SizedBox(height: 6),
                  _buildPeriodRow('Last Month', _getCropYieldForPeriod(crop, 'last_month'), crop['unit'] ?? 'kg'),
                  SizedBox(height: 6),
                  _buildPeriodRow('This Year', _getCropYieldForPeriod(crop, 'current_year'), crop['unit'] ?? 'kg'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodRow(String period, double value, String unit) {
    return Row(
      children: [
        Expanded(
          child: Text(
            period,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF8BC34A), // Green color like in image
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value > 0 ? '${value.toStringAsFixed(0)} $unit' : '0 $unit',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  double _getCropYieldForPeriod(Map<String, dynamic> crop, String period) {
    // This method should get yield data for specific periods
    // You'll need to implement this based on your controller's data structure
    if (crop['yields'] != null && crop['yields'][period] != null) {
      return crop['yields'][period].toDouble();
    }
    return 0.0;
  }

  Widget _buildQuickActions() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kLightGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kSecondaryColor,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Add Sale',
                  Icons.add_shopping_cart,
                  kPrimaryColor,
                  () => Get.toNamed('/sales/add'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Add Expense',
                  Icons.receipt_long,
                  Color(0xFFF44336),
                  () => Get.toNamed('/expenses/add'),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'View Reports',
                  Icons.analytics,
                  Color(0xFF2196F3),
                  () => Get.toNamed('/reports'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Crop Manager',
                  Icons.eco,
                  Color(0xFF4CAF50),
                  () => Get.toNamed('/crops'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}