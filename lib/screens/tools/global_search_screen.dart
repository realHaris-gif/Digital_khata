import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:digital_khata/controller/theme_controller.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final SupabaseClient _client = Supabase.instance.client;

  bool _isSearching = false;
  List<Map<String, dynamic>> _results = [];

  // Blue Palette Constants
  static const Color oxfordBlue = Color(0xFF192338);
  static const Color spaceCadet = Color(0xFF1E2E4F);
  static const Color yinMnBlue  = Color(0xFF31487A);
  static const Color jordyBlue  = Color(0xFF8FB3E2);
  static const Color lavender   = Color(0xFFD9E1F2);

  String get _userId => _client.auth.currentUser?.id ?? '';

  Future<void> _performGlobalSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isSearching = true);
    final q = query.trim().toLowerCase();

    try {
      final List<Map<String, dynamic>> temp = [];

      // 1. Search Customers
      final custRes = await _client
          .from('customers')
          .select('id, name, phone')
          .eq('user_id', _userId)
          .ilike('name', '%$q%');
      for (var c in (custRes as List)) {
        temp.add({
          'type': 'Customer',
          'title': c['name'],
          'subtitle': c['phone'] ?? 'No phone',
          'icon': Icons.person_outline_rounded,
          'route': '/ledger',
        });
      }

      // 2. Search Inventory Products
      final prodRes = await _client
          .from('products')
          .select('id, name, selling_price')
          .eq('user_id', _userId)
          .ilike('name', '%$q%');
      for (var p in (prodRes as List)) {
        temp.add({
          'type': 'Product',
          'title': p['name'],
          'subtitle': 'Price: Rs. ${p['selling_price']}',
          'icon': Icons.inventory_2_rounded,
          'route': '/inventory',
        });
      }

      // 3. Search Invoices
      final invRes = await _client
          .from('invoices')
          .select('id, invoice_number, total')
          .eq('user_id', _userId)
          .ilike('invoice_number', '%$q%');
      for (var i in (invRes as List)) {
        temp.add({
          'type': 'Invoice',
          'title': 'Invoice #${i['invoice_number']}',
          'subtitle': 'Total: Rs. ${i['total']}',
          'icon': Icons.receipt_long_rounded,
          'route': '/bill-book',
        });
      }

      if (mounted) {
        setState(() => _results = temp);
      }
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(primary: yinMnBlue),
        scaffoldBackgroundColor: isDark ? oxfordBlue : const Color(0xFFF8FAFC),
      ),
      child: Scaffold(
        backgroundColor: isDark ? oxfordBlue : const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: isDark ? spaceCadet : Colors.white,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(
              Icons.chevron_left_rounded,
              size: 28,
              color: isDark ? jordyBlue : oxfordBlue,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: TextField(
            controller: _searchCtrl,
            autofocus: true,
            style: TextStyle(
              color: isDark ? Colors.white : oxfordBlue,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'Search customers, products, invoices...',
              hintStyle: TextStyle(
                color: isDark ? lavender.withOpacity(0.4) : Colors.grey.shade400,
                fontSize: 15,
              ),
              border: InputBorder.none,
            ),
            onChanged: _performGlobalSearch,
          ),
          actions: [
            if (_searchCtrl.text.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear_rounded, color: isDark ? jordyBlue : yinMnBlue),
                onPressed: () {
                  _searchCtrl.clear();
                  _performGlobalSearch('');
                },
              ),
          ],
        ),
        body: _isSearching
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(isDark ? jordyBlue : yinMnBlue),
                ),
              )
            : _results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: isDark ? lavender.withOpacity(0.4) : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Type to search across your whole business.',
                          style: TextStyle(
                            color: isDark ? lavender.withOpacity(0.7) : Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _results.length,
                    itemBuilder: (context, idx) {
                      final item = _results[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isDark ? spaceCadet.withOpacity(0.6) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? jordyBlue.withOpacity(0.15) : lavender,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (isDark ? jordyBlue : yinMnBlue).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              color: isDark ? jordyBlue : yinMnBlue,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            item['title'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? Colors.white : oxfordBlue,
                            ),
                          ),
                          subtitle: Text(
                            '${item['type']} • ${item['subtitle']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? lavender.withOpacity(0.6) : Colors.grey.shade600,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: isDark ? jordyBlue : yinMnBlue,
                          ),
                          onTap: () => context.push(item['route'] as String),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}