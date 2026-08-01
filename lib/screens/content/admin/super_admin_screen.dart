import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  bool _isLoading = true;

  int _totalUsers = 0;
  int _totalBusinesses = 0;
  int _totalInvoices = 0;
  List<Map<String, dynamic>> _businesses = [];

  @override
  void initState() {
    super.initState();
    _loadAdminMetrics();
  }

  Future<void> _loadAdminMetrics() async {
    setState(() => _isLoading = true);
    try {
      final usersRes = await _client.from('profiles').select();
      final bizRes = await _client.from('businesses').select();
      final invRes = await _client.from('invoices').select();

      setState(() {
        _totalUsers = (usersRes as List).length;
        _businesses = List<Map<String, dynamic>>.from(bizRes);
        _totalBusinesses = _businesses.length;
        _totalInvoices = (invRes as List).length;
      });
    } catch (e) {
      debugPrint('Admin fetch error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBusinessApproval(String bizId, bool currentStatus) async {
    await _client
        .from('businesses')
        .update({'is_approved': !currentStatus})
        .eq('id', bizId);
    _loadAdminMetrics();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Super Admin Panel', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAdminMetrics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // System Metrics Grid
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.1,
                    children: [
                      _buildMetricTile('Users', '$_totalUsers', Icons.people_rounded, Colors.blue),
                      _buildMetricTile('Businesses', '$_totalBusinesses', Icons.store_rounded, const Color(0xFFFF7A00)),
                      _buildMetricTile('Invoices', '$_totalInvoices', Icons.receipt_long_rounded, Colors.purple),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text('Registered Businesses',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _businesses.length,
                    itemBuilder: (context, idx) {
                      final biz = _businesses[idx];
                      final isApproved = biz['is_approved'] as bool? ?? true;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(biz['name'] ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Type: ${biz['business_type'] ?? "Retail"} • Currency: ${biz['currency']}'),
                          trailing: Switch(
                            value: isApproved,
                            activeColor: Colors.green,
                            onChanged: (_) => _toggleBusinessApproval(biz['id'], isApproved),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricTile(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}