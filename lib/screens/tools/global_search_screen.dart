import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
          'icon': Icons.person,
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
          'icon': Icons.inventory_2,
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
          'icon': Icons.receipt_long,
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: const InputDecoration(
            hintText: 'Search customers, products, invoices...',
            border: InputBorder.none,
          ),
          onChanged: _performGlobalSearch,
        ),
        actions: [
          if (_searchCtrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchCtrl.clear();
                _performGlobalSearch('');
              },
            ),
        ],
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('Type to search across your whole business.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _results.length,
                  itemBuilder: (context, idx) {
                    final item = _results[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFFF7A00).withValues(alpha: 0.15),
                          child: Icon(item['icon'] as IconData, color: const Color(0xFFFF7A00)),
                        ),
                        title: Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${item['type']} • ${item['subtitle']}'),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () => context.push(item['route'] as String),
                      ),
                    );
                  },
                ),
    );
  }
}