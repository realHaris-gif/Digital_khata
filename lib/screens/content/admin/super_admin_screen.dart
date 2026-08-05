import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:digital_khata/theme/app_theme.dart';
import 'package:digital_khata/controller/theme_controller.dart';
import 'package:digital_khata/controller/language_controller.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _client = Supabase.instance.client;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  bool _isAuthorized = false;
  int _selectedTabIndex = 0;

  // Metrics
  int _totalUsers = 0;
  int _blockedUsers = 0;
  int _totalBusinesses = 0;
  int _totalInvoices = 0;
  double _totalRevenue = 277455.0;
  double _totalStockValue = 0.0;
  int _totalSuppliers = 0;
  int _totalCustomers = 0;
  int _totalEmployees = 0;

  // Data lists for full management
  List<Map<String, dynamic>> _profiles = [];
  List<Map<String, dynamic>> _businesses = [];
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _invoices = [];

  late TabController _tabController;

  final List<_SidebarItem> _sidebarItems = [
    _SidebarItem(
      icon: Icons.dashboard_rounded,
      label: 'Dashboard',
      urduLabel: 'ڈیش بورڈ',
      index: 0,
    ),
    _SidebarItem(
      icon: Icons.people_alt_rounded,
      label: 'Users',
      urduLabel: 'صارفین',
      index: 1,
    ),
    _SidebarItem(
      icon: Icons.storefront_rounded,
      label: 'Businesses',
      urduLabel: 'کاروبار',
      index: 2,
    ),
    _SidebarItem(
      icon: Icons.local_shipping_rounded,
      label: 'Suppliers',
      urduLabel: 'سپلائرز',
      index: 3,
    ),
    _SidebarItem(
      icon: Icons.groups_rounded,
      label: 'Customers & Staff',
      urduLabel: 'گاہک اور اسٹاف',
      index: 4,
    ),
    _SidebarItem(
      icon: Icons.receipt_long_rounded,
      label: 'Invoices',
      urduLabel: 'انوائسز',
      index: 5,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _checkAdminAndLoadMetrics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminAndLoadMetrics() async {
    setState(() => _isLoading = true);
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        if (mounted) context.go('/login');
        return;
      }

      final profileRes = await _client
          .from('profiles')
          .select('is_super_admin')
          .eq('id', user.id)
          .maybeSingle();

      final isSuperAdmin =
          profileRes != null && (profileRes['is_super_admin'] == true);

      if (!isSuperAdmin) {
        setState(() {
          _isAuthorized = false;
          _isLoading = false;
        });
        return;
      }

      setState(() => _isAuthorized = true);

      final responses = await Future.wait([
        _client.from('admin_user_overview').select(),
        _client.from('businesses').select(),
        _client.from('invoices').select(),
        _client.from('suppliers').select(),
        _client.from('products').select(),
        _client.from('customers').select(),
        _client.from('employees').select(),
      ]);

      final profilesData = List<Map<String, dynamic>>.from(responses[0]);
      final businessesData = List<Map<String, dynamic>>.from(responses[1]);
      final invoicesData = List<Map<String, dynamic>>.from(responses[2]);
      final suppliersData = List<Map<String, dynamic>>.from(responses[3]);
      final productsData = List<Map<String, dynamic>>.from(responses[4]);
      final customersData = List<Map<String, dynamic>>.from(responses[5]);
      final employeesData = List<Map<String, dynamic>>.from(responses[6]);

      double revSum = 0;
      for (var inv in invoicesData) {
        revSum += (inv['total_amount'] ?? inv['amount'] ?? 0.0) as num;
      }

      double stockSum = 0;
      for (var prod in productsData) {
        final qty = (prod['stock_quantity'] ?? prod['quantity'] ?? 0) as num;
        final price = (prod['selling_price'] ?? prod['price'] ?? 0) as num;
        stockSum += qty * price;
      }

      int blockedCount = profilesData.where((p) => p['is_blocked'] == true).length;

      setState(() {
        _profiles = profilesData;
        _businesses = businessesData;
        _suppliers = suppliersData;
        _customers = customersData;
        _employees = employeesData;
        _invoices = invoicesData;

        _totalUsers = profilesData.length;
        _blockedUsers = blockedCount;
        _totalBusinesses = businessesData.length;
        _totalInvoices = invoicesData.length;
        _totalRevenue = revSum;
        _totalStockValue = stockSum;
        _totalSuppliers = suppliersData.length;
        _totalCustomers = customersData.length;
        _totalEmployees = employeesData.length;
      });
    } catch (e) {
      debugPrint('Admin fetch error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final isDark = ThemeController.isDarkMode;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text(LanguageController.isUrdu ? 'لاگ آؤٹ کی تصدیق کریں' : 'Confirm Logout',
            textDirection: LanguageController.contentTextDirection,
            style: TextStyle(color: isDark ? Colors.white : AppColors.oxfordBlue, fontWeight: FontWeight.bold)),
        content: Text(
            LanguageController.isUrdu ? 'کیا آپ واقعی سپر ایڈمن سیشن سے لاگ آؤٹ کرنا چاہتے ہیں؟' : 'Are you sure you want to log out from the Super Admin session?',
            textDirection: LanguageController.contentTextDirection,
            style: TextStyle(color: isDark ? AppColors.lavender : Colors.grey.shade700)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LanguageController.isUrdu ? 'منسوخ کریں' : 'Cancel',
                textDirection: LanguageController.contentTextDirection,
                style: TextStyle(color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(LanguageController.isUrdu ? 'لاگ آؤٹ' : 'Logout', textDirection: LanguageController.contentTextDirection, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _client.auth.signOut();
        if (mounted) context.go('/login');
      } catch (e) {
        _showSnackBar(LanguageController.isUrdu ? 'لاگ آؤٹ کرنے میں خرابی: $e' : 'Error logging out: $e');
      }
    }
  }

  Future<void> _toggleUserBlock(String userId, bool currentBlockedStatus) async {
    try {
      await _client.from('profiles').update({'is_blocked': !currentBlockedStatus}).eq('id', userId);
      _checkAdminAndLoadMetrics();
      _showSnackBar(!currentBlockedStatus
          ? (LanguageController.isUrdu ? 'صارف کو کامیابی سے غیر فعال/بلاک کر دیا گیا' : 'User successfully disabled/blocked')
          : (LanguageController.isUrdu ? 'صارف کو ان بلاک کر دیا گیا' : 'User unblocked'));
    } catch (e) {
      _showSnackBar(LanguageController.isUrdu ? 'صارف کی بلاک کی حیثیت کو اپ ڈیٹ کرنے میں ناکام: $e' : 'Failed to update user block status: $e');
    }
  }

  Future<void> _deleteRecord(String table, String idField, String idValue,
      String entityName) async {
    final isDark = ThemeController.isDarkMode;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text(LanguageController.isUrdu ? 'حذف کرنے کی تصدیق کریں' : 'Confirm Deletion',
            textDirection: LanguageController.contentTextDirection,
            style: TextStyle(color: isDark ? Colors.white : AppColors.oxfordBlue, fontWeight: FontWeight.bold)),
        content: Text(
            LanguageController.isUrdu ? 'کیا آپ واقعی اس $entityName کو مکمل طور پر حذف کرنا چاہتے ہیں؟' : 'Are you sure you want to completely delete this $entityName? This action cascades through dependent logs.',
            textDirection: LanguageController.contentTextDirection,
            style: TextStyle(color: isDark ? AppColors.lavender : Colors.grey.shade700)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LanguageController.isUrdu ? 'منسوخ کریں' : 'Cancel',
                textDirection: LanguageController.contentTextDirection,
                style: TextStyle(color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(LanguageController.isUrdu ? 'حذف کریں' : 'Delete', textDirection: LanguageController.contentTextDirection, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _client.from(table).delete().eq(idField, idValue);
        _checkAdminAndLoadMetrics();
        _showSnackBar(LanguageController.isUrdu ? '$entityName کامیابی کے ساتھ حذف ہو گیا' : '$entityName deleted successfully');
      } catch (e) {
        _showSnackBar(LanguageController.isUrdu ? '$entityName حذف کرنے میں خرابی: $e' : 'Error deleting $entityName: $e');
      }
    }
  }

  Future<void> _toggleBusinessApproval(String bizId, bool currentStatus) async {
    try {
      await _client
          .from('businesses')
          .update({'is_approved': !currentStatus})
          .eq('id', bizId);
      _checkAdminAndLoadMetrics();
      _showSnackBar(!currentStatus 
          ? (LanguageController.isUrdu ? 'کاروبار منظور ہو گیا' : 'Business approved') 
          : (LanguageController.isUrdu ? 'کاروبار کی منظوری واپس لے لی گئی' : 'Business approval revoked'));
    } catch (e) {
      _showSnackBar(LanguageController.isUrdu ? 'کاروبار کی حیثیت کو اپ ڈیٹ کرنے میں ناکام: $e' : 'Failed to update business status: $e');
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg, textDirection: LanguageController.contentTextDirection)));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isDark = ThemeController.isDarkMode;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.surface1,
      drawer: Drawer(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        child: _buildSidebarContent(),
      ),
      body: !_isAuthorized && !_isLoading
          ? _buildAccessDeniedView()
          : _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                      color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue))
              : Row(
                  textDirection: LanguageController.contentTextDirection,
                  children: [
                    if (isDesktop)
                      SizedBox(
                        width: 260,
                        child: _buildSidebarContent(),
                      ),
                    Expanded(
                      child: Scaffold(
                        backgroundColor: isDark ? AppColors.darkBackground : AppColors.surface1,
                        appBar: AppBar(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          leading: IconButton(
                            icon: Icon(Icons.menu_rounded,
                                color: isDark ? Colors.white : AppColors.oxfordBlue),
                            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                          ),
                          title: Text(
                            LanguageController.isUrdu ? 'سپر ایڈمن ماسٹر پینل' : 'Super Admin Master Panel',
                            textDirection: LanguageController.contentTextDirection,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          centerTitle: false,
                          actions: [
                            if (_isAuthorized) ...[
                              IconButton(
                                icon: Icon(
                                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                  color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue,
                                ),
                                onPressed: () {
                                  ThemeController.toggleTheme();
                                  setState(() {});
                                },
                                tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                              ),
                              IconButton(
                                icon: Icon(Icons.refresh_rounded,
                                    color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue),
                                onPressed: _checkAdminAndLoadMetrics,
                                tooltip: 'Refresh System Data',
                              ),
                              IconButton(
                                icon: const Icon(Icons.logout_rounded,
                                    color: AppColors.danger),
                                onPressed: _handleLogout,
                                tooltip: 'Logout Admin',
                              ),
                              const SizedBox(width: AppSpacing.md),
                            ],
                          ],
                        ),
                        body: SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            textDirection: LanguageController.contentTextDirection,
                            children: [
                              Text(
                                LanguageController.isUrdu ? 'صبح بخیر، ایڈمن 👋' : 'Good Morning, Admin 👋',
                                textDirection: LanguageController.contentTextDirection,
                                style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : AppColors.oxfordBlue),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                LanguageController.isUrdu ? 'آج آپ کے سسٹم میں یہ ہو رہا ہے' : 'Here\'s what\'s happening in your system today',
                                textDirection: LanguageController.contentTextDirection,
                                style: TextStyle(
                                    color: isDark 
                                        ? AppColors.lavender.withValues(alpha: 0.7) 
                                        : Colors.grey.shade600),
                              ),
                              const SizedBox(height: AppSpacing.xl),

                              _selectedTabIndex == 0
                                  ? _buildDashboardContent()
                                  : _selectedTabIndex == 1
                                      ? _buildUsersTab()
                                      : _selectedTabIndex == 2
                                          ? _buildBusinessesTab()
                                          : _selectedTabIndex == 3
                                              ? _buildSuppliersTab()
                                              : _selectedTabIndex == 4
                                                  ? _buildCustomersAndStaffTab()
                                                  : _buildInvoicesTab(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildAccessDeniedView() {
    final isDark = ThemeController.isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.surface1,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: LanguageController.contentTextDirection,
            children: [
              const Icon(Icons.lock_rounded,
                  size: 64, color: AppColors.danger),
              const SizedBox(height: AppSpacing.lg),
              Text(
                LanguageController.isUrdu ? 'رسائی مسترد کر دی گئی' : 'Access Denied',
                textDirection: LanguageController.contentTextDirection,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.oxfordBlue),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                LanguageController.isUrdu 
                    ? 'آپ کے پاس اس سسٹم کنٹرول سینٹر تک رسائی کے لیے سپر ایڈمن کلیئرنس کے اسناد نہیں ہیں۔' 
                    : 'You do not possess Super Admin clearance credentials to access this system control center.',
                textAlign: TextAlign.center,
                textDirection: LanguageController.contentTextDirection,
                style: TextStyle(
                    color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : Colors.grey.shade600),
              ),
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white),
                onPressed: _handleLogout,
                child: Text(LanguageController.isUrdu ? 'لاگ آؤٹ' : 'Logout', textDirection: LanguageController.contentTextDirection),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarContent() {
    final isDark = ThemeController.isDarkMode;
    return Container(
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: Column(
        textDirection: LanguageController.contentTextDirection,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              textDirection: LanguageController.contentTextDirection,
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 50,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.dashboard_rounded,
                          size: 40, color: isDark ? AppColors.jordyBlue : AppColors.yinMnBlue),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  LanguageController.isUrdu ? 'ڈیجیٹل کھاتہ' : 'Digital Khata',
                  textDirection: LanguageController.contentTextDirection,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.oxfordBlue),
                ),
                Text(
                  LanguageController.isUrdu ? 'ایڈمن' : 'Admin',
                  textDirection: LanguageController.contentTextDirection,
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.lavender : Colors.grey.shade600,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Divider(
              color: isDark ? AppColors.darkBorder : AppColors.lavender, thickness: 0.5, height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              children: _sidebarItems.map((item) {
                final isSelected = _selectedTabIndex == item.index;
                return _buildSidebarItem(item, isSelected);
              }).toList(),
            ),
          ),

          Divider(
              color: isDark ? AppColors.darkBorder : AppColors.lavender, thickness: 0.5, height: 1),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              textDirection: LanguageController.contentTextDirection,
              children: [
                Text(
                  LanguageController.isUrdu ? 'تہٖی کردہ' : 'Powered by',
                  textDirection: LanguageController.contentTextDirection,
                  style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.lavender.withValues(alpha: 0.6) : Colors.grey.shade500),
                ),
                const Text('ZenVyro Labs',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.jordyBlue)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(_SidebarItem item, bool isSelected) {
    final isDark = ThemeController.isDarkMode;
    final activeColor = isDark ? AppColors.jordyBlue : AppColors.yinMnBlue;
    final textColor = isDark ? AppColors.lavender : AppColors.oxfordBlue;
    final labelText = LanguageController.isUrdu ? item.urduLabel : item.label;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedTabIndex = item.index;
              _tabController.index = item.index > 0 ? item.index - 1 : 0;
            });
            if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
              Navigator.of(context).pop();
            }
          },
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              color: isSelected
                  ? activeColor.withValues(alpha: 0.15)
                  : Colors.transparent,
              border: Border.all(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.3)
                      : Colors.transparent,
                  width: 1),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            child: Row(
              textDirection: LanguageController.contentTextDirection,
              children: [
                Icon(item.icon,
                    size: 20,
                    color: isSelected
                        ? activeColor
                        : textColor),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    labelText,
                    textDirection: LanguageController.contentTextDirection,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? activeColor
                            : textColor),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = width > 1200 ? 3 : (width > 600 ? 2 : 1);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection: LanguageController.contentTextDirection,
          children: [
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              textDirection: LanguageController.contentTextDirection,
              children: [
                SizedBox(
                  width: crossAxisCount == 1 
                      ? double.infinity 
                      : (width - (AppSpacing.md * (crossAxisCount - 1))) / crossAxisCount,
                  child: _buildStatCard(
                    LanguageController.isUrdu ? 'کل صارفین' : 'Total Users', 
                    '$_totalUsers', 
                    Icons.people_rounded, 
                    AppColors.jordyBlue,
                  ),
                ),
                SizedBox(
                  width: crossAxisCount == 1 
                      ? double.infinity 
                      : (width - (AppSpacing.md * (crossAxisCount - 1))) / crossAxisCount,
                  child: _buildStatCard(
                    LanguageController.isUrdu ? 'کل آمدنی' : 'Total Revenue', 
                    'Rs. ${(_totalRevenue / 100000).toStringAsFixed(1)}L',
                    Icons.payments_rounded, 
                    Colors.greenAccent,
                  ),
                ),
                SizedBox(
                  width: crossAxisCount == 1 
                      ? double.infinity 
                      : (width - (AppSpacing.md * (crossAxisCount - 1))) / crossAxisCount,
                  child: _buildStatCard(
                    LanguageController.isUrdu ? 'فعال کاروبار' : 'Active Businesses', 
                    '$_totalBusinesses',
                    Icons.storefront_rounded, 
                    Colors.orangeAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            _buildChartContainer(
              title: LanguageController.isUrdu ? 'آمدنی کا رجحان (آخری 7 دن)' : 'Revenue Trend (Last 7 Days)',
              child: SizedBox(
                height: 250,
                child: _buildRevenueLineChart(),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            if (width > 900)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: LanguageController.contentTextDirection,
                children: [
                  Expanded(
                    child: _buildChartContainer(
                      title: LanguageController.isUrdu ? 'کاروبار کی تقسیم' : 'Business Distribution',
                      child: SizedBox(
                        height: 280,
                        child: _buildBusinessDistributionPie(),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: _buildChartContainer(
                      title: LanguageController.isUrdu ? 'سسٹم کی کارکردگی' : 'System Performance',
                      child: SizedBox(
                        height: 280,
                        child: _buildPerformanceBarChart(),
                      ),
                    ),
                  ),
                ],
              )
            else
              Column(
                textDirection: LanguageController.contentTextDirection,
                children: [
                  _buildChartContainer(
                    title: LanguageController.isUrdu ? 'کاروبار کی تقسیم' : 'Business Distribution',
                    child: SizedBox(
                      height: 280,
                      child: _buildBusinessDistributionPie(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildChartContainer(
                    title: LanguageController.isUrdu ? 'سسٹم کی کارکردگی' : 'System Performance',
                    child: SizedBox(
                      height: 280,
                      child: _buildPerformanceBarChart(),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.xl),

            if (width > 900)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: LanguageController.contentTextDirection,
                children: [
                  Expanded(
                    child: _buildChartContainer(
                      title: LanguageController.isUrdu ? 'انوائس کی حیثیت کی تقسیم' : 'Invoice Status Distribution',
                      child: SizedBox(
                        height: 250,
                        child: _buildInvoiceStatusPie(),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: _buildChartContainer(
                      title: LanguageController.isUrdu ? 'سسٹم کی صحت' : 'System Health',
                      child: SizedBox(
                        height: 250,
                        child: _buildHealthMetrics(),
                      ),
                    ),
                  ),
                ],
              )
            else
              Column(
                textDirection: LanguageController.contentTextDirection,
                children: [
                  _buildChartContainer(
                    title: LanguageController.isUrdu ? 'انوائس کی حیثیت کی تقسیم' : 'Invoice Status Distribution',
                    child: SizedBox(
                      height: 250,
                      child: _buildInvoiceStatusPie(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildChartContainer(
                    title: LanguageController.isUrdu ? 'سسٹم کی صحت' : 'System Health',
                    child: SizedBox(
                      height: 250,
                      child: _buildHealthMetrics(),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final isDark = ThemeController.isDarkMode;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? color.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isDark ? color.withValues(alpha: 0.2) : AppColors.lavender,
              width: 1.5,
            ),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            textDirection: LanguageController.contentTextDirection,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: AppSpacing.md),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? color : AppColors.oxfordBlue,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: LanguageController.contentTextDirection,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartContainer({required String title, required Widget child}) {
    final isDark = ThemeController.isDarkMode;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface.withValues(alpha: 0.4) : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: isDark ? AppColors.darkBorder.withValues(alpha: 0.3) : AppColors.lavender,
              width: 1,
            ),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: LanguageController.contentTextDirection,
            children: [
              Text(
                title,
                textDirection: LanguageController.contentTextDirection,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.oxfordBlue,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueLineChart() {
    final isDark = ThemeController.isDarkMode;
    final fakeRevenueTrend = [
      const FlSpot(0, 45000),
      const FlSpot(1, 52000),
      const FlSpot(2, 48000),
      const FlSpot(3, 61000),
      const FlSpot(4, 55000),
      const FlSpot(5, 72000),
      const FlSpot(6, 68000),
    ];

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10000,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : AppColors.lavender.withValues(alpha: 0.5),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                return Text(
                  days[value.toInt()],
                  style: TextStyle(
                    color: isDark ? AppColors.lavender.withValues(alpha: 0.6) : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20000,
              getTitlesWidget: (value, meta) {
                return Text(
                  'Rs.${(value / 1000).toStringAsFixed(0)}K',
                  style: TextStyle(
                    color: isDark ? AppColors.lavender.withValues(alpha: 0.6) : Colors.grey.shade600,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: fakeRevenueTrend,
            isCurved: true,
            gradient: const LinearGradient(
              colors: [AppColors.jordyBlue, Colors.greenAccent],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.jordyBlue,
                  strokeWidth: 2,
                  strokeColor: isDark ? Colors.white : AppColors.oxfordBlue,
                );
              },
            ),
          ),
        ],
        minY: 30000,
        maxY: 80000,
      ),
    );
  }

  Widget _buildBusinessDistributionPie() {
    final businessData = [
      PieChartSectionData(
        color: Colors.orangeAccent,
        value: 35,
        title: 'Retail\n35%',
        radius: 50,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      PieChartSectionData(
        color: Colors.greenAccent,
        value: 25,
        title: 'Services\n25%',
        radius: 50,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      PieChartSectionData(
        color: AppColors.jordyBlue,
        value: 20,
        title: 'F&B\n20%',
        radius: 50,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      PieChartSectionData(
        color: Colors.purpleAccent,
        value: 20,
        title: 'Other\n20%',
        radius: 50,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    ];

    return PieChart(
      PieChartData(
        sections: businessData,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildPerformanceBarChart() {
    final isDark = ThemeController.isDarkMode;
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const titles = ['API', 'DB', 'Auth', 'Cache'];
                return Text(
                  titles[value.toInt()],
                  style: TextStyle(
                    color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: TextStyle(
                    color: isDark ? AppColors.lavender.withValues(alpha: 0.6) : Colors.grey.shade600,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark ? AppColors.darkBorder.withValues(alpha: 0.2) : AppColors.lavender.withValues(alpha: 0.5),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: 95,
                color: Colors.greenAccent,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: 89,
                color: AppColors.jordyBlue,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: 92,
                color: Colors.orangeAccent,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          BarChartGroupData(
            x: 3,
            barRods: [
              BarChartRodData(
                toY: 88,
                color: Colors.purpleAccent,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceStatusPie() {
    final invoiceData = [
      PieChartSectionData(
        color: Colors.greenAccent,
        value: 60,
        title: 'Paid\n60%',
        radius: 50,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      PieChartSectionData(
        color: Colors.orangeAccent,
        value: 25,
        title: 'Pending\n25%',
        radius: 50,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      PieChartSectionData(
        color: AppColors.danger,
        value: 15,
        title: 'Overdue\n15%',
        radius: 50,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    ];

    return PieChart(
      PieChartData(
        sections: invoiceData,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildHealthMetrics() {
    return Column(
      textDirection: LanguageController.contentTextDirection,
      children: [
        _buildHealthMetricRow(
          LanguageController.isUrdu ? 'سسٹم اپ ٹائم' : 'System Uptime', 
          '99.8%', 
          Colors.greenAccent,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildHealthMetricRow(
          LanguageController.isUrdu ? 'فعال سیشنز' : 'Active Sessions', 
          '127', 
          AppColors.jordyBlue,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildHealthMetricRow(
          LanguageController.isUrdu ? 'اوسط ردعمل کا وقت' : 'Avg Response Time', 
          '142ms', 
          Colors.orangeAccent,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildHealthMetricRow(
          LanguageController.isUrdu ? 'خرابی کی شرح' : 'Error Rate', 
          '0.2%', 
          Colors.purpleAccent,
        ),
      ],
    );
  }

  Widget _buildHealthMetricRow(String label, String value, Color color) {
    final isDark = ThemeController.isDarkMode;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      textDirection: LanguageController.contentTextDirection,
      children: [
        Text(
          label,
          textDirection: LanguageController.contentTextDirection,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.lavender.withValues(alpha: 0.8) : Colors.grey.shade700,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            value,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTab() {
    final isDark = ThemeController.isDarkMode;
    if (_profiles.isEmpty) {
      return Center(
          child: Text(
              LanguageController.isUrdu ? 'کوئی رجسٹرڈ صارف نہیں ملا۔' : 'No registered users found.',
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(
                  color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : Colors.grey.shade600)));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _profiles.length,
      itemBuilder: (context, idx) {
        final profile = _profiles[idx];
        final isBlocked = profile['is_blocked'] as bool? ?? false;
        final isSuper = profile['is_super_admin'] as bool? ?? false;

        return _buildGlassmorphicCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              textDirection: LanguageController.contentTextDirection,
              children: [
                CircleAvatar(
                  backgroundColor: isSuper
                      ? AppColors.danger
                      : AppColors.jordyBlue,
                  child: Icon(
                      isSuper
                          ? Icons.admin_panel_settings
                          : Icons.person,
                      color: isDark ? AppColors.darkBackground : Colors.white),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: LanguageController.contentTextDirection,
                    children: [
                      Text(
                          profile['full_name'] ?? (LanguageController.isUrdu ? 'کوئی نام فراہم نہیں کیا گیا' : 'No Name Provided'),
                          textDirection: LanguageController.contentTextDirection,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.oxfordBlue,
                              fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(
                          'Email: ${profile['email'] ?? "N/A"}',
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                              color: isDark ? AppColors.lavender.withValues(alpha: 0.8) : Colors.grey.shade600,
                              fontSize: 12)),
                      Text(
                          'Phone: ${profile['phone'] ?? "N/A"} • Role: ${isSuper ? (LanguageController.isUrdu ? "سپر ایڈمن" : "Super Admin") : (LanguageController.isUrdu ? "صارف" : "User")}',
                          overflow: TextOverflow.ellipsis,
                          textDirection: LanguageController.contentTextDirection,
                          style: TextStyle(
                              color: isDark ? AppColors.lavender.withValues(alpha: 0.8) : Colors.grey.shade600,
                              fontSize: 12)),
                      if (isBlocked) ...[
                        const SizedBox(height: 4),
                        Text(
                            LanguageController.isUrdu ? '[غیر فعال / بلاک]' : '[DISABLED / BLOCKED]',
                            textDirection: LanguageController.contentTextDirection,
                            style: const TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.bold,
                                fontSize: 11)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  textDirection: LanguageController.contentTextDirection,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBlocked
                            ? Colors.green.shade700
                            : AppColors.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: const Size(80, 32),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.md)),
                      ),
                      onPressed: () =>
                          _toggleUserBlock(profile['id'], isBlocked),
                      icon: Icon(
                          isBlocked
                              ? Icons.check_circle_outline
                              : Icons.block,
                          size: 14),
                      label: Text(
                          isBlocked 
                              ? (LanguageController.isUrdu ? 'فعال کریں' : 'Enable') 
                              : (LanguageController.isUrdu ? 'غیر فعال کریں' : 'Disable'),
                          textDirection: LanguageController.contentTextDirection,
                          style: const TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(height: 6),
                    IconButton(
                      icon: const Icon(Icons.delete_rounded,
                          color: AppColors.danger, size: 20),
                      onPressed: () => _deleteRecord(
                          'profiles', 'id', profile['id'], LanguageController.isUrdu ? 'صارف پروفائل' : 'User Profile'),
                      tooltip: 'Delete User Account',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBusinessesTab() {
    final isDark = ThemeController.isDarkMode;
    if (_businesses.isEmpty) {
      return Center(
          child: Text(
              LanguageController.isUrdu ? 'کوئی رجسٹرڈ کاروبار نہیں ملا۔' : 'No registered businesses found.',
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(
                  color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : Colors.grey.shade600)));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _businesses.length,
      itemBuilder: (context, idx) {
        final biz = _businesses[idx];
        final isApproved = biz['is_approved'] as bool? ?? true;

        return _buildGlassmorphicCard(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            leading: const CircleAvatar(
              backgroundColor: Colors.orangeAccent,
              child: Icon(Icons.storefront_rounded,
                  color: AppColors.darkBackground),
            ),
            title: Text(
                biz['name'] ?? (LanguageController.isUrdu ? 'نامعلوم کاروبار' : 'Unnamed Business'),
                textDirection: LanguageController.contentTextDirection,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.oxfordBlue)),
            subtitle: Text(
                'Type: ${biz['business_type'] ?? "Retail"} • Currency: ${biz['currency'] ?? "PKR"}\nPhone: ${biz['phone'] ?? "N/A"}',
                textDirection: LanguageController.contentTextDirection,
                style: TextStyle(
                    color: isDark ? AppColors.lavender.withValues(alpha: 0.8) : Colors.grey.shade600,
                    fontSize: 12)),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: LanguageController.contentTextDirection,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_rounded,
                      color: AppColors.danger),
                  onPressed: () => _deleteRecord(
                      'businesses', 'id', biz['id'], LanguageController.isUrdu ? 'کاروبار' : 'Business'),
                  tooltip: 'Delete Business',
                ),
                Switch(
                  value: isApproved,
                  activeColor: Colors.greenAccent,
                  onChanged: (_) =>
                      _toggleBusinessApproval(biz['id'], isApproved),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuppliersTab() {
    final isDark = ThemeController.isDarkMode;
    if (_suppliers.isEmpty) {
      return Center(
          child: Text(
              LanguageController.isUrdu ? 'سسٹم میں کوئی سپلائر نہیں ملا۔' : 'No suppliers found in the system.',
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(
                  color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : Colors.grey.shade600)));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _suppliers.length,
      itemBuilder: (context, idx) {
        final supplier = _suppliers[idx];

        return _buildGlassmorphicCard(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),

            leading: const CircleAvatar(
              backgroundColor: Colors.tealAccent,
              child: Icon(Icons.local_shipping_rounded,
                  color: AppColors.darkBackground),
            ),
            title: Text(
                supplier['name'] ?? (LanguageController.isUrdu ? 'نامعلوم سپلائر' : 'Unnamed Supplier'),
                textDirection: LanguageController.contentTextDirection,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.oxfordBlue)),
            subtitle: Text(
                'Phone: ${supplier['phone'] ?? "N/A"} • Balance: Rs. ${supplier['balance'] ?? 0.0}',
                textDirection: LanguageController.contentTextDirection,
                style: TextStyle(
                    color: isDark ? AppColors.lavender.withValues(alpha: 0.8) : Colors.grey.shade600,
                    fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_forever_rounded,
                  color: AppColors.danger),
              onPressed: () => _deleteRecord(
                  'suppliers', 'id', supplier['id'], LanguageController.isUrdu ? 'سپلائر' : 'Supplier'),
              tooltip: 'Delete Supplier',
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomersAndStaffTab() {
    final isDark = ThemeController.isDarkMode;
    const headerColor = AppColors.jordyBlue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: LanguageController.contentTextDirection,
      children: [
        Text(
          LanguageController.isUrdu ? 'رجسترڈ گاہک' : 'Registered Customers',
          textDirection: LanguageController.contentTextDirection,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: headerColor),
        ),
        const SizedBox(height: AppSpacing.sm),
        _customers.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                    LanguageController.isUrdu ? 'کوئی گاہک نہیں ملا۔' : 'No customers found.',
                    textDirection: LanguageController.contentTextDirection,
                    style: TextStyle(
                        color:
                            isDark ? AppColors.lavender.withValues(alpha: 0.6) : Colors.grey.shade600)),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _customers.length,
                itemBuilder: (context, idx) {
                  final cust = _customers[idx];
                  return _buildGlassmorphicCard(
                    child: ListTile(
                      leading: const Icon(
                          Icons.person_outline_rounded,
                          color: Colors.purpleAccent),
                      title: Text(
                          cust['name'] ?? (LanguageController.isUrdu ? 'گاہک' : 'Customer'),
                          textDirection: LanguageController.contentTextDirection,
                          style: TextStyle(
                              color: isDark ? Colors.white : AppColors.oxfordBlue,
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          'Phone: ${cust['phone'] ?? "N/A"} • Balance: Rs. ${cust['opening_balance'] ?? 0.0}',
                          textDirection: LanguageController.contentTextDirection,
                          style: TextStyle(
                              color: isDark ? AppColors.lavender : Colors.grey.shade600, fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_rounded,
                            color: AppColors.danger, size: 20),
                        onPressed: () => _deleteRecord('customers', 'id',
                            cust['id'], LanguageController.isUrdu ? 'گاہک' : 'Customer'),
                      ),
                    ),
                  );
                },
              ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          LanguageController.isUrdu ? 'رجسترڈ ملازمین / اسٹاف' : 'Registered Employees / Staff',
          textDirection: LanguageController.contentTextDirection,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: headerColor),
        ),
        const SizedBox(height: AppSpacing.sm),
        _employees.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                    LanguageController.isUrdu ? 'اسٹاف کا کوئی ریکارڈ نہیں ملا۔' : 'No staff records found.',
                    textDirection: LanguageController.contentTextDirection,
                    style: TextStyle(
                        color:
                            isDark ? AppColors.lavender.withValues(alpha: 0.6) : Colors.grey.shade600)),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _employees.length,
                itemBuilder: (context, idx) {
                  final emp = _employees[idx];
                  return _buildGlassmorphicCard(
                    child: ListTile(
                      leading: const Icon(Icons.badge_outlined,
                          color: Colors.amberAccent),
                      title: Text(
                          emp['name'] ?? (LanguageController.isUrdu ? 'ملازم' : 'Employee'),
                          textDirection: LanguageController.contentTextDirection,
                          style: TextStyle(
                              color: isDark ? Colors.white : AppColors.oxfordBlue,
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          'Designation: ${emp['designation'] ?? "N/A"} • Phone: ${emp['phone'] ?? "N/A"}',
                          textDirection: LanguageController.contentTextDirection,
                          style: TextStyle(
                              color: isDark ? AppColors.lavender : Colors.grey.shade600, fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_rounded,
                            color: AppColors.danger, size: 20),
                        onPressed: () => _deleteRecord('employees', 'id',
                            emp['id'], LanguageController.isUrdu ? 'ملازم' : 'Employee'),
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildInvoicesTab() {
    final isDark = ThemeController.isDarkMode;
    if (_invoices.isEmpty) {
      return Center(
          child: Text(
              LanguageController.isUrdu ? 'سسٹم کی کوئی انوائس درج نہیں ہے۔' : 'No system invoices recorded.',
              textDirection: LanguageController.contentTextDirection,
              style: TextStyle(
                  color: isDark ? AppColors.lavender.withValues(alpha: 0.7) : Colors.grey.shade600)));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _invoices.length,
      itemBuilder: (context, idx) {
        final inv =
            _invoices.length > idx ? _invoices[idx] : null;
        if (inv == null) return const SizedBox.shrink();
        final amount =
            inv['total_amount'] ?? inv['amount'] ?? 0.0;

        return _buildGlassmorphicCard(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            leading: const CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.receipt_rounded,
                  color: Colors.white),
            ),
            title: Text(
                'Invoice #${inv['id'].toString().substring(0, 8).toUpperCase()}',
                textDirection: LanguageController.contentTextDirection,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.oxfordBlue)),
            subtitle: Text(
                'Amount: Rs. $amount • Date: ${inv['created_at']?.toString().split('T').first ?? "N/A"}',
                textDirection: LanguageController.contentTextDirection,
                style: TextStyle(
                    color: isDark ? AppColors.lavender.withValues(alpha: 0.8) : Colors.grey.shade600,
                    fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_forever_rounded,
                  color: AppColors.danger),
              onPressed: () => _deleteRecord(
                  'invoices', 'id', inv['id'], LanguageController.isUrdu ? 'انوائس کا ریکارڈ' : 'Invoice Record'),
              tooltip: 'Delete Invoice',
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassmorphicCard({required Widget child}) {
    final isDark = ThemeController.isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface.withValues(alpha: 0.4) : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: isDark ? AppColors.darkBorder.withValues(alpha: 0.3) : AppColors.lavender,
                width: 1,
              ),
              boxShadow: isDark ? [] : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SidebarItem {
  final IconData icon;
  final String label;
  final String urduLabel;
  final int index;

  _SidebarItem({
    required this.icon,
    required this.label,
    required this.urduLabel,
    required this.index,
  });
}