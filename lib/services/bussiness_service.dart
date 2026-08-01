import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessModel {
  final String id;
  final String userId;
  final String name;
  final String? businessType;
  final String? phone;
  final String? address;
  final String currency;
  final bool isActive;
  final bool isApproved;

  BusinessModel({
    required this.id,
    required this.userId,
    required this.name,
    this.businessType,
    this.phone,
    this.address,
    this.currency = 'PKR',
    this.isActive = true,
    this.isApproved = true,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? 'My Business',
      businessType: json['business_type'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      currency: json['currency'] as String? ?? 'PKR',
      isActive: json['is_active'] as bool? ?? true,
      isApproved: json['is_approved'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'user_id': userId,
        'name': name,
        'business_type': businessType,
        'phone': phone,
        'address': address,
        'currency': currency,
        'is_active': isActive,
        'is_approved': isApproved,
      };
}

class BusinessService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _activeBusinessKey = 'active_business_id';

  String get _userId => _client.auth.currentUser?.id ?? '';

  Future<List<BusinessModel>> getMyBusinesses() async {
    if (_userId.isEmpty) return [];
    final res = await _client
        .from('businesses')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: true);

    return (res as List).map((b) => BusinessModel.fromJson(b)).toList();
  }

  Future<String?> getActiveBusinessId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_activeBusinessKey);
    if (savedId != null && savedId.isNotEmpty) return savedId;

    final businesses = await getMyBusinesses();
    if (businesses.isNotEmpty) {
      await setActiveBusinessId(businesses.first.id);
      return businesses.first.id;
    }
    return null;
  }

  Future<void> setActiveBusinessId(String businessId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeBusinessKey, businessId);
  }

  Future<BusinessModel> createBusiness({
    required String name,
    String? businessType,
    String? phone,
    String? address,
  }) async {
    final res = await _client.from('businesses').insert({
      'user_id': _userId,
      'name': name,
      'business_type': businessType ?? 'retail',
      'phone': phone,
      'address': address,
    }).select().single();

    final newBiz = BusinessModel.fromJson(res);
    await setActiveBusinessId(newBiz.id);
    return newBiz;
  }
}