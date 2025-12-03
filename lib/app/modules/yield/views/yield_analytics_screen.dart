import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/values/app_colors.dart';
import '../controller/yield_analytics_controller.dart';

class YieldAnalyticsScreen extends StatelessWidget {
  final YieldAnalyticsController controller =
      Get.put(YieldAnalyticsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yield Analytics & Reports',
            style: TextStyle(color: Colors.white)),
        backgroundColor: kPrimaryColor,
        actions: [
          // Export to Excel Button
          Obx(() => IconButton(
                icon: controller.isExporting.value
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.file_download, color: Colors.white),
                tooltip: 'Export to Excel',
                onPressed: controller.isExporting.value
                    ? null
                    : controller.exportToExcel,
              )),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'refresh') {
                controller.refreshData();
              } else if (value == 'settings') {
                _showAnalyticsSettings();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('Refresh Data'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: kPrimaryColor, size: 20),
                    SizedBox(width: 8),
                    Text('Analytics Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: kPrimaryColor),
                SizedBox(height: 16),
                Text('Loading analytics data...'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Period Selector and Filters
                _buildPeriodSelector(),

                // Crop Filter
                _buildCropFilter(),

                // Summary Cards
                _buildSummaryCards(),

                // Charts Section
                _buildChartsSection(),

                // Detailed Data Tables
                _buildDetailedDataSection(),

                SizedBox(height: 20),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Period',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: kSecondaryColor,
            ),
          ),
          SizedBox(height: 12),
          Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPeriodChip('Current Week', 'current_week'),
                  _buildPeriodChip('Current Month', 'current_month'),
                  _buildPeriodChip('Last Month', 'last_month'),
                  _buildPeriodChip('Current Year', 'current_year'),
                  _buildPeriodChip('Custom Range', 'custom'),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String period) {
    final isSelected = controller.selectedPeriod.value == period;
    return GestureDetector(
      onTap: () {
        if (period == 'custom') {
          _showCustomDateRangeDialog();
        } else {
          controller.selectPeriod(period);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? kPrimaryColor : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : kSecondaryColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCropFilter() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by Crop',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: kSecondaryColor,
            ),
          ),
          SizedBox(height: 12),
          Obx(() {
            if (controller.availableCrops.isEmpty) {
              return Text('No crops available',
                  style: TextStyle(color: Colors.grey));
            }

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCropFilterChip('All Crops', null),
                ...controller.availableCrops.map((crop) {
                  return _buildCropFilterChip(
                    crop['crop_name'] ?? 'Unknown',
                    crop['crop_id'] ?? '',
                  );
                }).toList(),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCropFilterChip(String label, String? cropId) {
    final isSelected = controller.selectedCropId.value == cropId;
    return GestureDetector(
      onTap: () => controller.selectCrop(cropId),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kPrimaryColor : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? kPrimaryColor : kSecondaryColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Obx(() {
      final data = controller.dashboardData.value;
      if (data == null) return SizedBox.shrink();

      final stats = data['overall_stats'] ?? {};

      return Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Yields',
                    '${stats['total_yield_records'] ?? 0}',
                    Icons.agriculture,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Unique Crops',
                    '${stats['total_crops'] ?? 0}',
                    Icons.grass,
                    Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Quantity',
                    controller.getTotalQuantityDisplay(),
                    Icons.scale,
                    Colors.orange,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Avg per Yield',
                    controller.getAverageQuantityDisplay(),
                    Icons.analytics,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Spacer(),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // FIXED: Removed Obx wrapper from this method
  Widget _buildChartsSection() {
    final data = controller.dashboardData.value;
    if (data == null) return SizedBox.shrink();

    return Column(
      children: [
        // Yield Trend Chart
        _buildChartCard(
          'Yield Trends by Period',
          _buildYieldTrendChart(),
        ),

        // Crop Distribution Chart
        _buildChartCard(
          'Crop Distribution',
          _buildCropDistributionChart(),
        ),

        // Quantity by Crop Chart
        _buildChartCard(
          'Quantity by Crop',
          _buildQuantityByChartChart(),
        ),

        // Monthly Performance Chart - FIXED: Direct access instead of Obx
        if (controller.selectedPeriod.value == 'current_year')
          _buildChartCard(
            'Monthly Performance',
            _buildMonthlyPerformanceChart(),
          ),
      ],
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
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
          SizedBox(height: 16),
          chart,
        ],
      ),
    );
  }

  // FIXED: Removed Obx wrapper
  Widget _buildYieldTrendChart() {
    final periodData = controller.getCurrentPeriodData();
    if (periodData == null || periodData['crops'] == null) {
      return _buildEmptyChart('No yield data available');
    }

    final List crops = periodData['crops'] ?? [];
    if (crops.isEmpty) {
      return _buildEmptyChart('No crops found for this period');
    }

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: controller.getMaxYieldCount() * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${crops[groupIndex]['crop_name']}\n${rod.toY.toInt()} yields',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= crops.length) return Text('');
                  return Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      controller
                          .getCropShortName(crops[value.toInt()]['crop_name']),
                      style: TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(crops.length, (index) {
            final crop = crops[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: (crop['total_yield_records'] ?? 0).toDouble(),
                  color: Colors.blue,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // FIXED: Removed Obx wrapper
  Widget _buildCropDistributionChart() {
    final periodData = controller.getCurrentPeriodData();
    if (periodData == null || periodData['crops'] == null) {
      return _buildEmptyChart('No data available');
    }

    final List crops = periodData['crops'] ?? [];
    if (crops.isEmpty) {
      return _buildEmptyChart('No crops found');
    }

    final total = crops.fold<double>(
      0,
      (sum, crop) => sum + (crop['total_yield_records'] ?? 0).toDouble(),
    );

    return SizedBox(
      height: 250,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sections: List.generate(crops.length, (index) {
                  final crop = crops[index];
                  final value = (crop['total_yield_records'] ?? 0).toDouble();
                  final percentage = (value / total * 100);

                  return PieChartSectionData(
                    value: value,
                    title: '${percentage.toStringAsFixed(1)}%',
                    radius: 100,
                    titleStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    color: controller.getChartColor(index),
                  );
                }),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(crops.length, (index) {
                final crop = crops[index];
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: controller.getChartColor(index),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.getCropShortName(crop['crop_name']),
                          style: TextStyle(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // FIXED: Removed Obx wrapper
  Widget _buildQuantityByChartChart() {
    final periodData = controller.getCurrentPeriodData();
    if (periodData == null || periodData['crops'] == null) {
      return _buildEmptyChart('No quantity data available');
    }

    final List crops = periodData['crops'] ?? [];
    if (crops.isEmpty) {
      return _buildEmptyChart('No crops found');
    }

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: controller.getMaxQuantity() * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final crop = crops[groupIndex];
                return BarTooltipItem(
                  '${crop['crop_name']}\n${rod.toY.toStringAsFixed(1)} units',
                  TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= crops.length) return Text('');
                  return Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      controller
                          .getCropShortName(crops[value.toInt()]['crop_name']),
                      style: TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    controller.formatQuantityShort(value),
                    style: TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(crops.length, (index) {
            final crop = crops[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: (crop['total_quantity'] ?? 0).toDouble(),
                  color: Colors.green,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // FIXED: Removed Obx wrapper
  Widget _buildMonthlyPerformanceChart() {
    final monthlyData = controller.getMonthlyData();
    if (monthlyData.isEmpty) {
      return _buildEmptyChart('No monthly data available');
    }

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300],
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= monthlyData.length) return Text('');
                  return Text(
                    monthlyData[value.toInt()]['month'],
                    style: TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                monthlyData.length,
                (index) => FlSpot(
                  index.toDouble(),
                  monthlyData[index]['count'].toDouble(),
                ),
              ),
              isCurved: true,
              color: kPrimaryColor,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: kPrimaryColor.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return Container(
      height: 250,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey[300]),
            SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Removed Obx wrapper
  Widget _buildDetailedDataSection() {
    final periodData = controller.getCurrentPeriodData();
    if (periodData == null) return SizedBox.shrink();

    final List crops = periodData['crops'] ?? [];
    if (crops.isEmpty) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Detailed Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kSecondaryColor,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
              columns: [
                DataColumn(
                    label: Text('Crop',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Yields',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Quantity',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Variants',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Units',
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: crops.map<DataRow>((crop) {
                return DataRow(cells: [
                  DataCell(Text(crop['crop_name'] ?? 'Unknown')),
                  DataCell(Text('${crop['total_yield_records'] ?? 0}')),
                  DataCell(Text(
                      '${crop['total_quantity']?.toStringAsFixed(1) ?? '0'}')),
                  DataCell(Text('${crop['variant_count'] ?? 0}')),
                  DataCell(Text(controller.getUnitsDisplay(crop))),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomDateRangeDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('Custom Date Range'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Start Date'),
              subtitle: Obx(() => Text(
                    controller.customStartDate.value != null
                        ? controller
                            .formatDate(controller.customStartDate.value!)
                        : 'Select date',
                  )),
              onTap: () async {
                final date = await showDatePicker(
                  context: Get.context!,
                  initialDate:
                      controller.customStartDate.value ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  controller.customStartDate.value = date;
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.event),
              title: Text('End Date'),
              subtitle: Obx(() => Text(
                    controller.customEndDate.value != null
                        ? controller.formatDate(controller.customEndDate.value!)
                        : 'Select date',
                  )),
              onTap: () async {
                final date = await showDatePicker(
                  context: Get.context!,
                  initialDate: controller.customEndDate.value ?? DateTime.now(),
                  firstDate: controller.customStartDate.value ?? DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  controller.customEndDate.value = date;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.applyCustomDateRange();
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showAnalyticsSettings() {
    Get.dialog(
      AlertDialog(
        title: Text('Analytics Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('Show Percentage'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: Text('Include Zero Values'),
              value: false,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: Text('Auto Refresh'),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
