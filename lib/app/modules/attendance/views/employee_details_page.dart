import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controller/employee_detail_controller.dart';
import '../../../core/values/app_colors.dart';

class EmployeeDetailsPage extends StatelessWidget {
  const EmployeeDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Get.put instead of Get.find to ensure controller is created
    final controller = Get.put(EmployeeDetailsController());

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
              controller.employee.value?.name ?? 'Employee Details',
              style: const TextStyle(fontSize: 18),
            )),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshData,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: kPrimaryColor),
          );
        }

        if (controller.employee.value == null) {
          return const Center(
            child: Text('No employee data found'),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildProfileSection(controller),
                _buildStatsCards(controller),
                _buildAttendanceCalendar(controller),
                const SizedBox(height: 80), // Space for bottom navigation
              ],
            ),
          ),
        );
      }),
      bottomNavigationBar: _buildBottomNavigation(controller),
    );
  }

  Widget _buildProfileSection(EmployeeDetailsController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Profile Image
          Obx(() => CircleAvatar(
                radius: 50,
                backgroundImage: controller.profileImageUrl.value != null
                    ? NetworkImage(controller.profileImageUrl.value!)
                    : null,
                backgroundColor: Colors.white,
                child: controller.profileImageUrl.value == null
                    ? Text(
                        controller.employee.value?.name.isNotEmpty == true
                            ? controller.employee.value!.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      )
                    : null,
              )),
          const SizedBox(height: 15),

          // Employee Name
          Obx(() => Text(
                controller.employee.value?.name ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )),

          // Employee ID
          Obx(() => Text(
                'ID: ${controller.employee.value?.id ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              )),

          const SizedBox(height: 10),

          // Daily Wage
          Obx(() => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Daily Wage: ₹${controller.employee.value?.wages ?? '0'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildStatsCards(EmployeeDetailsController controller) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildIntStatCard(
              'Days Worked',
              controller.totalDaysWorked,
              Icons.calendar_today,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildDoubleStatCard(
              'Total Wages',
              controller.totalWages,
              Icons.currency_rupee,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntStatCard(
    String title,
    RxInt value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Obx(() => Text(
                value.value.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              )),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDoubleStatCard(
    String title,
    RxDouble value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Obx(() => Text(
                '₹${value.value.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              )),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCalendar(EmployeeDetailsController controller) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last 28 Days Attendance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('Present', Colors.green),
              _buildLegendItem('Absent', Colors.red),
              _buildLegendItem('Sunday', Colors.grey),
              _buildLegendItem('Today', Colors.orange),
            ],
          ),

          const SizedBox(height: 15),

          // Calendar Grid
          Obx(() {
            final days = controller.getLast28Days();
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final date = days[index];
                final isToday = controller.isToday(date);
                final isSunday = controller.isSunday(date);
                final attendanceStatus = controller.getAttendanceStatus(date);

                Color backgroundColor;
                Color borderColor;
                Color textColor = Colors.white;

                if (isToday) {
                  backgroundColor = Colors.orange;
                  borderColor = Colors.orange.shade700;
                } else if (isSunday) {
                  backgroundColor = Colors.grey;
                  borderColor = Colors.grey.shade600;
                } else if (attendanceStatus == 1) {
                  backgroundColor = Colors.green;
                  borderColor = Colors.green.shade700;
                } else {
                  backgroundColor = Colors.red.shade400;
                  borderColor = Colors.red.shade600;
                }

                return Container(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('dd').format(date),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM').format(date),
                        style: TextStyle(
                          fontSize: 8,
                          color: textColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(EmployeeDetailsController controller) {
    return Obx(() => BottomNavigationBar(
          currentIndex: controller.selectedIndex.value,
          onTap: controller.onTabSelected,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: kPrimaryColor,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ));
  }
}
