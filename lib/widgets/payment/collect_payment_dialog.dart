import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Add `qr_flutter: ^4.1.0` to pubspec if displaying QR

class CollectPaymentModal extends StatefulWidget {
  final bool isPOS; // true = POS terminal style, false = QR Code style

  const CollectPaymentModal({super.key, required this.isPOS});

  @override
  State<CollectPaymentModal> createState() => _CollectPaymentModalState();
}

class _CollectPaymentModalState extends State<CollectPaymentModal> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedAccountId;
  List<Map<String, dynamic>> _accounts = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final res = await Supabase.instance.client
        .from('accounts')
        .select('id, name, balance')
        .eq('user_id', userId);

    if (mounted) {
      setState(() {
        _accounts = List<Map<String, dynamic>>.from(res as List);
        if (_accounts.isNotEmpty) {
          _selectedAccountId = _accounts.first['id'].toString();
        }
      });
    }
  }

  Future<void> _processPayment() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0 || _selectedAccountId == null) return;

    setState(() => _isProcessing = true);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final client = Supabase.instance.client;

    try {
      // 1. Get current balance of target account
      final accRes = await client
          .from('accounts')
          .select('balance')
          .eq('id', _selectedAccountId!)
          .single();
      final currentBalance = (accRes['balance'] as num).toDouble();

      // 2. Update Account Balance (Money In)
      await client.from('accounts').update({
        'balance': currentBalance + amount,
      }).eq('id', _selectedAccountId!);

      // 3. Record in Cash Book / Transactions as Cash Entry
      await client.from('cash_book').insert({
        'user_id': userId,
        'account_id': _selectedAccountId,
        'type': 'in', // Money In
        'amount': amount,
        'category': widget.isPOS ? 'POS Collection' : 'QR Payment',
        'notes': _noteController.text.trim().isEmpty
            ? (widget.isPOS ? 'Collected via POS' : 'Collected via QR Code')
            : _noteController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rs. ${amount.toStringAsFixed(2)} successfully credited to account!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment collection failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 24,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.isPOS
                        ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                        : const Color(0xFFFF5757).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.isPOS ? Icons.point_of_sale : Icons.qr_code_2_rounded,
                    color: widget.isPOS
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFFFF5757),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isPOS ? 'Accept POS Payment' : 'Collect via QR',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.isPOS
                            ? 'Accept card payments on your phone'
                            : 'Scan & credit cash directly to your ledger',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (!widget.isPOS) ...[
              // QR Code Display Section
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Icon(
                    Icons.qr_code_2_rounded,
                    size: 140,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount (Rs.) *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (_accounts.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedAccountId,
                decoration: InputDecoration(
                  labelText: 'Deposit Into Account',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                items: _accounts.map((acc) {
                  return DropdownMenuItem<String>(
                    value: acc['id'].toString(),
                    child: Text(
                        '${acc['name']} (Rs. ${(acc['balance'] as num).toStringAsFixed(0)})'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedAccountId = val),
              ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Note / Order Ref (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: widget.isPOS
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFFFF5757),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _isProcessing ? null : _processPayment,
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      widget.isPOS ? 'Confirm POS Payment' : 'Collect Cash',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}