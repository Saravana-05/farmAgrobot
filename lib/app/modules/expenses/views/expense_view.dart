import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../config/api.dart';
import '../../../core/values/app_colors.dart';
import '../../../data/models/expense/expense_model.dart';
import '../../../routes/app_pages.dart';
import '../controller/expense_view_controller.dart';
import 'edit_expense_view.dart';

class ViewExpenses extends StatelessWidget {
  final ExpensesViewController controller = Get.put(ExpensesViewController());

  final List<Color> backgroundColors = [
    kLightGreen, 
    kListBg, 
  ];

  final List<Color> iconBackgroundColors = [
    kLightYellow, 
    kLightGreen, 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Compact Header with Search
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: Colors.grey[100],
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: TextField(
                        onChanged: controller.runFilter,
                        style: TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search expenses...',
                          hintStyle:
                              TextStyle(color: Colors.grey[400], fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          prefixIcon: Icon(Icons.search,
                              color: kSecondaryColor, size: 20),
                        ),
                      ),
                    ),

                    SizedBox(height: 10),

                    // Date Filters Row
                    Row(
                      children: [
                        // From Date
                        Expanded(
                          child: Obx(() => _buildDateButton(
                                context,
                                icon: Icons.calendar_today_outlined,
                                label: controller.fromDate.value == null
                                    ? 'From'
                                    : DateFormat('dd MMM')
                                        .format(controller.fromDate.value!),
                                onTap: () => _selectFromDate(context),
                              )),
                        ),
                        SizedBox(width: 8),

                        // To Date
                        Expanded(
                          child: Obx(() => _buildDateButton(
                                context,
                                icon: Icons.calendar_today_outlined,
                                label: controller.toDate.value == null
                                    ? 'To'
                                    : DateFormat('dd MMM')
                                        .format(controller.toDate.value!),
                                onTap: () => _selectToDate(context),
                              )),
                        ),
                        SizedBox(width: 8),

                        // Export Button
                        Obx(() => Container(
                              height: 42,
                              width: 42,
                              decoration: BoxDecoration(
                                color: kPrimaryColor,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: kPrimaryColor.withOpacity(0.25),
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: controller.isExporting.value ||
                                      controller.isDownloading.value
                                  ? Center(
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : PopupMenuButton<String>(
                                      icon: Icon(Icons.download_outlined,
                                          color: Colors.white, size: 20),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'pdf',
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.red
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Icon(
                                                    Icons.picture_as_pdf,
                                                    color: Colors.red,
                                                    size: 16),
                                              ),
                                              SizedBox(width: 10),
                                              Text('PDF',
                                                  style:
                                                      TextStyle(fontSize: 14)),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'excel',
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.green
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Icon(Icons.table_chart,
                                                    color: Colors.green,
                                                    size: 16),
                                              ),
                                              SizedBox(width: 10),
                                              Text('Excel',
                                                  style:
                                                      TextStyle(fontSize: 14)),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onSelected: (value) {
                                        if (value == 'pdf') {
                                          controller.downloadExpenseBills();
                                        } else if (value == 'excel') {
                                          controller.exportToExcel();
                                        }
                                      },
                                    ),
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Compact Summary Card
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Obx(() => Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.85)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryColor.withOpacity(0.25),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.account_balance_wallet,
                            color: Colors.white, size: 22),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          controller.getSummaryText(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ),

          // Expenses List
          Expanded(
            child: Obx(() => _buildExpensesList()),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: kPrimaryColor, size: 16),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: kSecondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList() {
    if (controller.isLoading.value) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: kPrimaryColor, strokeWidth: 3),
            SizedBox(height: 16),
            Text('Loading expenses...',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      );
    }

    if (controller.filteredExpenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_outlined,
                  size: 48, color: Colors.grey[400]),
            ),
            SizedBox(height: 16),
            Text('No expenses found',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800])),
            SizedBox(height: 6),
            Text('Try adjusting your filters',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: controller.refreshExpenses,
              icon: Icon(Icons.refresh, size: 18),
              label: Text('Refresh', style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    final paginatedExpenses = controller.getPaginatedExpenses();

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.refreshExpenses,
            color: kPrimaryColor,
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: paginatedExpenses.length,
              itemBuilder: (context, index) {
                final expense = paginatedExpenses[index];
                return _buildExpenseCard(expense, index);
              },
            ),
          ),
        ),

        // Compact Pagination
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Obx(() => _buildPaginationControls()),
        ),
      ],
    );
  }

  Widget _buildExpenseCard(ExpenseModel expense, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: backgroundColors[index % 2],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!.withOpacity(0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showExpenseDetailsDialog(expense),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                // Receipt Icon with alternating background
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBackgroundColors[index % 2],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.receipt_long_outlined,
                        color: kPrimaryColor, size: 22),
                    onPressed: () => _showImageDialog(expense.expenseImageUrl),
                    padding: EdgeInsets.zero,
                  ),
                ),

                SizedBox(width: 12),

                // Expense Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.expenseName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 12, color: Colors.grey[500]),
                          SizedBox(width: 4),
                          Text(
                            controller.formatTimestamp(expense.expenseDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        '₹${expense.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Menu Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: PopupMenuButton<String>(
                    icon:
                        Icon(Icons.more_vert, color: kSecondaryColor, size: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_outlined,
                                color: kPrimaryColor, size: 18),
                            SizedBox(width: 10),
                            Text('View', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined,
                                color: kPrimaryColor, size: 18),
                            SizedBox(width: 10),
                            Text('Edit', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                color: Colors.red, size: 18),
                            SizedBox(width: 10),
                            Text('Delete',
                                style:
                                    TextStyle(color: Colors.red, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          _showExpenseDetailsDialog(expense);
                          break;
                        case 'edit':
                          Get.toNamed(Routes.EDIT_EXPENSE,
                              arguments: {'id': expense.id.toString()});
                          break;
                        case 'delete':
                          _showDeleteConfirmation(expense);
                          break;
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Previous
        Expanded(
          child: ElevatedButton(
            onPressed:
                controller.hasPrevious.value ? controller.previousPage : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: controller.hasPrevious.value
                  ? kPrimaryColor
                  : Colors.grey[200],
              foregroundColor: controller.hasPrevious.value
                  ? Colors.white
                  : Colors.grey[400],
              padding: EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chevron_left,color: kLightColor, size: 18),
                SizedBox(width: 2),
                Text('Previous',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ),

        // Page Info
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${controller.currentPage.value}/${controller.totalPages.value}',
              style: TextStyle(
                color: kSecondaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),

        // Next
        Expanded(
          child: ElevatedButton(
            onPressed: controller.hasNext.value ? controller.nextPage : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  controller.hasNext.value ? kPrimaryColor : Colors.grey[200],
              foregroundColor:
                  controller.hasNext.value ? Colors.white : Colors.grey[400],
              padding: EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Next',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                SizedBox(width: 2),
                Icon(Icons.chevron_right,color: kLightColor, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Keep all the other methods (_selectFromDate, _selectToDate, _showExpenseDetailsDialog, etc.)
  // exactly as they were in your original code...

  void _selectFromDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.fromDate.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: kPrimaryColor),
          ),
          child: child!,
        );
      },
    );
    controller.selectFromDate(picked);
  }

  void _selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.toDate.value ?? DateTime.now(),
      firstDate: controller.fromDate.value ?? DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: kPrimaryColor),
          ),
          child: child!,
        );
      },
    );
    controller.selectToDate(picked);
  }

  void _showExpenseDetailsDialog(ExpenseModel expense) {
    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: Get.width * 0.9,
          constraints: BoxConstraints(maxHeight: Get.height * 0.85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.receipt_long,
                          color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Expense Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Get.back(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildDetailCard('Expense Name', expense.expenseName,
                          Icons.receipt_long_outlined),
                      SizedBox(height: 12),
                      _buildDetailCard(
                          'Amount',
                          '₹${expense.amount.toStringAsFixed(0)}',
                          Icons.currency_rupee,
                          highlight: true),
                      SizedBox(height: 12),
                      _buildDetailCard(
                          'Date',
                          controller.formatTimestamp(expense.expenseDate),
                          Icons.calendar_today_outlined),
                      SizedBox(height: 12),
                      _buildDetailCard('Category', expense.expenseCategory,
                          Icons.category_outlined),
                      SizedBox(height: 12),
                      _buildDetailCard(
                          'Spent By', expense.spentBy, Icons.person_outline),
                      SizedBox(height: 20),
                      _buildBillImageSection(expense.expenseImageUrl),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.back();
                          Get.to(() => EditExpense(),
                              arguments: {'id': expense.id.toString()});
                        },
                        icon: Icon(Icons.edit_outlined),
                        label: Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Get.back();
                          _showDeleteConfirmation(expense);
                        },
                        icon: Icon(Icons.delete_outline),
                        label: Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red, width: 1.5),
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
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
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon,
      {bool highlight = false}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? kPrimaryColor.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color:
                highlight ? kPrimaryColor.withOpacity(0.3) : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: highlight
                  ? kPrimaryColor.withOpacity(0.15)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: highlight ? kPrimaryColor : kSecondaryColor, size: 22),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
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
                    fontSize: highlight ? 20 : 15,
                    fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                    color: highlight ? kPrimaryColor : Colors.grey[900],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillImageSection(String? imageUrl) {
    final String fullImageUrl = getFullImageUrl(imageUrl);
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.image_outlined,
                    color: kSecondaryColor, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Bill Image',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kSecondaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildBillImage(fullImageUrl),
        ],
      ),
    );
  }

  Widget _buildBillImage(String fullImageUrl) {
    if (fullImageUrl.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined,
                size: 48, color: Colors.grey[400]),
            SizedBox(height: 12),
            Text('No bill image',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showFullScreenImage(fullImageUrl),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            fullImageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  color: kPrimaryColor,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 40, color: Colors.red[300]),
                    SizedBox(height: 8),
                    Text('Failed to load',
                        style: TextStyle(color: Colors.red[400], fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Get.dialog(
      Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 50, color: Colors.white),
                              SizedBox(height: 16),
                              Text('Failed to load image',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImageDialog(String? imageUrl) {
    final String fullImageUrl = getFullImageUrl(imageUrl);

    if (fullImageUrl.isEmpty) {
      Get.snackbar(
        'No Image',
        'No image available for this expense',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        borderRadius: 12,
        margin: EdgeInsets.all(16),
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    _showFullScreenImage(fullImageUrl);
  }

  void _showDeleteConfirmation(ExpenseModel expense) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline, size: 48, color: Colors.red),
              ),
              SizedBox(height: 20),
              Text(
                'Delete Expense?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Are you sure you want to delete "${expense.expenseName}"? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancel',
                          style: TextStyle(color: Colors.grey[700])),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        controller.deleteExpense(expense.id.toString());
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text('Delete',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
