import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../repository/notfication_repository.dart';
import '../widgets/common/notification_popup.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final _repository = NotificationRepository();

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  /// Helper method to save to database and immediately trigger the Apple-style floating popup
  Future<void> _createAndShow({
    required String title,
    required String message,
    required NotificationType type,
    required NotificationCategory category,
    required String icon,
    String? actionRoute,
    Map<String, dynamic>? metadata,
  }) async {
    if (_userId == null) return;

    // 1. Save to Supabase repository
    await _repository.createNotification(
      userId: _userId!,
      title: title,
      message: message,
      type: type,
      category: category,
      icon: icon,
      actionRoute: actionRoute,
      metadata: metadata,
    );

    // 2. Map string icon name to a proper IconData object
    IconData iconData = Icons.notifications_rounded;
    switch (icon) {
      case 'check_circle': iconData = Icons.check_circle_rounded; break;
      case 'info': iconData = Icons.info_rounded; break;
      case 'person_add': iconData = Icons.person_add_rounded; break;
      case 'person': iconData = Icons.person_rounded; break;
      case 'trending_up': iconData = Icons.trending_up_rounded; break;
      case 'trending_down': iconData = Icons.trending_down_rounded; break;
      case 'credit_card': iconData = Icons.credit_card_rounded; break;
      case 'payment': iconData = Icons.payment_rounded; break;
      case 'receipt': iconData = Icons.receipt_rounded; break;
      case 'package': iconData = Icons.inventory_2_rounded; break;
      case 'warning': iconData = Icons.warning_rounded; break;
      case 'business': iconData = Icons.business_rounded; break;
      case 'sync': iconData = Icons.sync_rounded; break;
      case 'backup': iconData = Icons.backup_rounded; break;
      case 'security': iconData = Icons.security_rounded; break;
      case 'error': iconData = Icons.error_rounded; break;
    }

    // 3. Construct the local model instance with the required IconData
    final notificationModel = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _userId!,
      title: title,
      message: message,
      type: type,
      category: category,
      icon: iconData,
      createdAt: DateTime.now(),
      isRead: false,
      actionRoute: actionRoute,
      metadata: metadata,
    );

    // 4. Trigger the Apple-style popup banner manager safely
    OverlayNotificationManager().showNotificationFromModel(notificationModel);
  }

  Future<void> notifyLogin(String userEmail) async {
    await _createAndShow(
      title: 'Welcome Back',
      message: 'You have successfully logged in to Digital Khata',
      type: NotificationType.success,
      category: NotificationCategory.system,
      icon: 'check_circle',
      metadata: {'email': userEmail},
    );
  }

  Future<void> notifyLogout() async {
    await _createAndShow(
      title: 'Logged Out',
      message: 'You have been logged out from Digital Khata',
      type: NotificationType.information,
      category: NotificationCategory.system,
      icon: 'info',
    );
  }

  // Customer Events
  Future<void> notifyCustomerAdded(String customerName) async {
    await _createAndShow(
      title: 'Customer Added',
      message: '$customerName has been added to your customers',
      type: NotificationType.success,
      category: NotificationCategory.customers,
      icon: 'person_add',
      actionRoute: '/customers',
      metadata: {'customerName': customerName},
    );
  }

  Future<void> notifyCustomerUpdated(String customerName) async {
    await _createAndShow(
      title: 'Customer Updated',
      message: 'Customer $customerName has been updated',
      type: NotificationType.information,
      category: NotificationCategory.customers,
      icon: 'person',
      actionRoute: '/customers',
      metadata: {'customerName': customerName},
    );
  }

  Future<void> notifyCustomerDeleted(String customerName) async {
    await _createAndShow(
      title: 'Customer Deleted',
      message: 'Customer $customerName has been removed',
      type: NotificationType.warning,
      category: NotificationCategory.customers,
      icon: 'person',
      metadata: {'customerName': customerName},
    );
  }

  // Transaction Events (e.g., POS / Cash Collection)
  Future<void> notifyCreditAdded(double amount, String? description) async {
    await _createAndShow(
      title: 'Credit Added',
      message: 'Rs. ${amount.toStringAsFixed(2)} has been added',
      type: NotificationType.success,
      category: NotificationCategory.transactions,
      icon: 'trending_up',
      actionRoute: '/accounts',
      metadata: {'amount': amount, 'description': description},
    );
  }

  Future<void> notifyDebitAdded(double amount, String? description) async {
    await _createAndShow(
      title: 'Debit Added',
      message: 'Rs. ${amount.toStringAsFixed(2)} has been debited',
      type: NotificationType.warning,
      category: NotificationCategory.transactions,
      icon: 'trending_down',
      actionRoute: '/accounts',
      metadata: {'amount': amount, 'description': description},
    );
  }

  Future<void> notifyPaymentReceived(double amount, String customerName) async {
    await _createAndShow(
      title: 'Payment Received',
      message: 'Rs. ${amount.toStringAsFixed(2)} received from $customerName',
      type: NotificationType.success,
      category: NotificationCategory.transactions,
      icon: 'credit_card',
      actionRoute: '/accounts',
      metadata: {'amount': amount, 'customerName': customerName},
    );
  }

  Future<void> notifyPaymentSent(double amount, String recipientName) async {
    await _createAndShow(
      title: 'Payment Sent',
      message: 'Rs. ${amount.toStringAsFixed(2)} sent to $recipientName',
      type: NotificationType.information,
      category: NotificationCategory.transactions,
      icon: 'payment',
      actionRoute: '/accounts',
      metadata: {'amount': amount, 'recipientName': recipientName},
    );
  }

  // Invoice Events
  Future<void> notifyInvoiceCreated(String invoiceNumber) async {
    await _createAndShow(
      title: 'Invoice Created',
      message: 'Invoice #$invoiceNumber has been created',
      type: NotificationType.success,
      category: NotificationCategory.invoices,
      icon: 'receipt',
      actionRoute: '/bill-book',
      metadata: {'invoiceNumber': invoiceNumber},
    );
  }

  Future<void> notifyInvoicePaid(String invoiceNumber, double amount) async {
    await _createAndShow(
      title: 'Invoice Paid',
      message: 'Invoice #$invoiceNumber for Rs. ${amount.toStringAsFixed(2)} has been paid',
      type: NotificationType.success,
      category: NotificationCategory.invoices,
      icon: 'payment',
      actionRoute: '/bill-book',
      metadata: {'invoiceNumber': invoiceNumber, 'amount': amount},
    );
  }

  Future<void> notifyInvoiceCancelled(String invoiceNumber) async {
    await _createAndShow(
      title: 'Invoice Cancelled',
      message: 'Invoice #$invoiceNumber has been cancelled',
      type: NotificationType.warning,
      category: NotificationCategory.invoices,
      icon: 'receipt',
      metadata: {'invoiceNumber': invoiceNumber},
    );
  }

  // Inventory Events
  Future<void> notifyProductAdded(String productName) async {
    await _createAndShow(
      title: 'Product Added',
      message: '$productName has been added to inventory',
      type: NotificationType.success,
      category: NotificationCategory.inventory,
      icon: 'package',
      actionRoute: '/inventory',
      metadata: {'productName': productName},
    );
  }

  Future<void> notifyLowStock(String productName, int quantity) async {
    await _createAndShow(
      title: 'Low Stock Alert',
      message: '$productName has only $quantity items left',
      type: NotificationType.warning,
      category: NotificationCategory.inventory,
      icon: 'warning',
      actionRoute: '/inventory',
      metadata: {'productName': productName, 'quantity': quantity},
    );
  }

  Future<void> notifyStockIncreased(String productName, int quantity) async {
    await _createAndShow(
      title: 'Stock Increased',
      message: '$productName stock increased by $quantity units',
      type: NotificationType.success,
      category: NotificationCategory.inventory,
      icon: 'trending_up',
      actionRoute: '/inventory',
      metadata: {'productName': productName, 'quantity': quantity},
    );
  }

  Future<void> notifyStockDecreased(String productName, int quantity) async {
    await _createAndShow(
      title: 'Stock Decreased',
      message: '$productName stock decreased by $quantity units',
      type: NotificationType.information,
      category: NotificationCategory.inventory,
      icon: 'trending_down',
      actionRoute: '/inventory',
      metadata: {'productName': productName, 'quantity': quantity},
    );
  }

  // Expense Events
  Future<void> notifyExpenseAdded(double amount, String category) async {
    await _createAndShow(
      title: 'Expense Added',
      message: 'Rs. ${amount.toStringAsFixed(2)} expense added to $category',
      type: NotificationType.information,
      category: NotificationCategory.expenses,
      icon: 'trending_down',
      actionRoute: '/expense_screen',
      metadata: {'amount': amount, 'category': category},
    );
  }

  // Supplier Events
  Future<void> notifySupplierAdded(String supplierName) async {
    await _createAndShow(
      title: 'Supplier Added',
      message: '$supplierName has been added to suppliers',
      type: NotificationType.success,
      category: NotificationCategory.suppliers,
      icon: 'business',
      actionRoute: '/suppliers',
      metadata: {'supplierName': supplierName},
    );
  }

  Future<void> notifySupplierPayment(String supplierName, double amount) async {
    await _createAndShow(
      title: 'Supplier Payment',
      message: 'Rs. ${amount.toStringAsFixed(2)} paid to $supplierName',
      type: NotificationType.information,
      category: NotificationCategory.suppliers,
      icon: 'payment',
      actionRoute: '/suppliers',
      metadata: {'supplierName': supplierName, 'amount': amount},
    );
  }

  // Employee Events
  Future<void> notifyEmployeeAdded(String employeeName) async {
    await _createAndShow(
      title: 'Employee Added',
      message: '$employeeName has been added to staff',
      type: NotificationType.success,
      category: NotificationCategory.employees,
      icon: 'person_add',
      actionRoute: '/staff',
      metadata: {'employeeName': employeeName},
    );
  }

  Future<void> notifySalaryPaid(String employeeName, double amount) async {
    await _createAndShow(
      title: 'Salary Paid',
      message: 'Rs. ${amount.toStringAsFixed(2)} salary paid to $employeeName',
      type: NotificationType.success,
      category: NotificationCategory.employees,
      icon: 'payment',
      actionRoute: '/staff',
      metadata: {'employeeName': employeeName, 'amount': amount},
    );
  }

  // System Events
  Future<void> notifySyncComplete() async {
    await _createAndShow(
      title: 'Sync Complete',
      message: 'Your data has been successfully synced',
      type: NotificationType.success,
      category: NotificationCategory.system,
      icon: 'sync',
    );
  }

  Future<void> notifyBackupComplete() async {
    await _createAndShow(
      title: 'Backup Complete',
      message: 'Your backup has been successfully completed',
      type: NotificationType.success,
      category: NotificationCategory.backup,
      icon: 'backup',
    );
  }

  Future<void> notifySecurityAlert(String message) async {
    await _createAndShow(
      title: 'Security Alert',
      message: message,
      type: NotificationType.error,
      category: NotificationCategory.security,
      icon: 'security',
    );
  }

  Future<void> notifyError(String title, String message, {String? actionRoute}) async {
    await _createAndShow(
      title: title,
      message: message,
      type: NotificationType.error,
      category: NotificationCategory.system,
      icon: 'error',
      actionRoute: actionRoute,
    );
  }
}