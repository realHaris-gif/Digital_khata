import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/store_model.dart';
import 'store_dashboard_screen.dart';

class StoreSettingsScreen extends ConsumerStatefulWidget {
  final StoreModel? store;

  const StoreSettingsScreen({super.key, this.store});

  @override
  ConsumerState<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends ConsumerState<StoreSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _slugCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;

  File? _logoFile;
  File? _bannerFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.store;
    _nameCtrl = TextEditingController(text: s?.storeName ?? '');
    _slugCtrl = TextEditingController(text: s?.slug ?? '');
    _descCtrl = TextEditingController(text: s?.description ?? '');
    _phoneCtrl = TextEditingController(text: s?.phone ?? '');
    _emailCtrl = TextEditingController(text: s?.email ?? '');
    _addressCtrl = TextEditingController(text: s?.address ?? '');
  }

  Future<void> _pickImage(bool isLogo) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isLogo) {
          _logoFile = File(picked.path);
        } else {
          _bannerFile = File(picked.path);
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final service = ref.read(storeServiceProvider);
      await service.saveStore(
        storeName: _nameCtrl.text.trim(),
        slug: _slugCtrl.text.trim().isEmpty
            ? _nameCtrl.text.trim().toLowerCase().replaceAll(' ', '-')
            : _slugCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        logoFile: _logoFile,
        bannerFile: _bannerFile,
        currentLogoUrl: widget.store?.logoUrl,
        currentBannerUrl: widget.store?.bannerUrl,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving store: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.store != null ? 'Store Settings' : 'Setup Digital Store')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Picker
              GestureDetector(
                onTap: () => _pickImage(false),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                    image: _bannerFile != null
                        ? DecorationImage(image: FileImage(_bannerFile!), fit: BoxFit.cover)
                        : (widget.store?.bannerUrl != null
                            ? DecorationImage(image: NetworkImage(widget.store!.bannerUrl!), fit: BoxFit.cover)
                            : null),
                  ),
                  child: _bannerFile == null && widget.store?.bannerUrl == null
                      ? const Center(child: Text('Tap to upload Store Banner'))
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // Logo Picker
              Center(
                child: GestureDetector(
                  onTap: () => _pickImage(true),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundImage: _logoFile != null
                        ? FileImage(_logoFile!)
                        : (widget.store?.logoUrl != null ? NetworkImage(widget.store!.logoUrl!) : null)
                            as ImageProvider?,
                    child: _logoFile == null && widget.store?.logoUrl == null
                        ? const Icon(Icons.camera_alt, size: 28)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Store Name *', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Enter store name' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _slugCtrl,
                decoration: const InputDecoration(
                  labelText: 'Store URL Slug (e.g. my-store)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'WhatsApp / Phone', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(labelText: 'Store Address', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Store Description', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFFFF7A00),
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Store Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}