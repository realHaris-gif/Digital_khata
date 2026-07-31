import 'package:flutter/material.dart';
import '../../services/customer_service.dart';
import '../customer/customer_screen.dart';

class LoginAsCustomerScreen extends StatefulWidget {
  final VoidCallback? onTap;
  final VoidCallback? onregTap;

  const LoginAsCustomerScreen({
    Key? key,
    this.onTap,
    this.onregTap,
  }) : super(key: key);

  @override
  State<LoginAsCustomerScreen> createState() => _LoginAsCustomerScreenState();
}

class _LoginAsCustomerScreenState extends State<LoginAsCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uniqueIdController = TextEditingController();
  final CustomerService _customerService = CustomerService();
  bool _isLoading = false;

  void _loginCustomer() async {
  if (_formKey.currentState!.validate()) {
    setState(() => _isLoading = true);

    try {
      final uniqueId = _uniqueIdController.text.trim();
      // Call CustomerService statically
      final customer = await CustomerService.findCustomerByUniqueId(uniqueId);

      if (!mounted) return;

      if (customer != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerDetailScreen(
              customerId: customer['id'],
              customerName: customer['name'] ?? 'Customer',
              customerPhone: customer['phone'],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No customer found with this Unique ID'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

  @override
  void dispose() {
    _uniqueIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Portal'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Track Your Ledger',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your Unique ID provided by the shopkeeper to view your account statement.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _uniqueIdController,
                decoration: const InputDecoration(
                  labelText: 'Unique ID (e.g. CUST-12345)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Enter your Unique ID' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _loginCustomer,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'View Statement',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 24),

              // Navigation options back to merchant auth
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Are you a Merchant? "),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: Text(
                      'Login Here',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: widget.onregTap,
                    child: Text(
                      'Register Merchant',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
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