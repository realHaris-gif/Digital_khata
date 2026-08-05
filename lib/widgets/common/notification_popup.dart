import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import 'package:digital_khata/controller/language_controller.dart';

class OverlayNotificationManager {
  static final OverlayNotificationManager _instance =
      OverlayNotificationManager._internal();

  factory OverlayNotificationManager() {
    return _instance;
  }

  OverlayNotificationManager._internal();

  final List<OverlayEntry> _notifications = [];
  OverlayState? _overlayState;

  void setOverlayState(OverlayState overlayState) {
    _overlayState = overlayState;
  }

  void showNotification(
    BuildContext? context,
    NotificationModel notification, {
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    if (_overlayState == null) return;

    late final OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => PremiumNotificationPopup(
        notification: notification,
        duration: duration,
        onTap: onTap,
        onDismiss: () {
          _notifications.remove(overlayEntry);
          overlayEntry.remove();
        },
      ),
    );

    _notifications.add(overlayEntry);
    _overlayState!.insert(overlayEntry);
  }

  /// Helper method allowing background services to trigger the popup directly
  void showNotificationFromModel(
    NotificationModel notification, {
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    showNotification(null, notification, duration: duration, onTap: onTap);
  }

  void dismissAll() {
    for (var entry in _notifications) {
      entry.remove();
    }
    _notifications.clear();
  }
}

class PremiumNotificationPopup extends StatefulWidget {
  final NotificationModel notification;
  final Duration duration;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const PremiumNotificationPopup({
    super.key,
    required this.notification,
    this.duration = const Duration(seconds: 3),
    this.onTap,
    this.onDismiss,
  });

  @override
  State<PremiumNotificationPopup> createState() =>
      _PremiumNotificationPopupState();
}

class _PremiumNotificationPopupState extends State<PremiumNotificationPopup>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _dismissController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _dismissController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward().then((_) {
      Future.delayed(widget.duration, () {
        if (mounted) {
          _dismissController.forward().then((_) {
            widget.onDismiss?.call();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _dismissController.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    _dismissController.forward().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Positioned(
      top: MediaQuery.of(context).viewPadding.top + 16,
      left: isMobile ? 16 : null,
      right: isMobile ? 16 : 24,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: _slideAnimation.value,
          end: _dismissController.value > 0
              ? const Offset(0, -2)
              : _slideAnimation.value,
        ).animate(
          CurvedAnimation(
            parent: _dismissController,
            curve: Curves.easeInBack,
          ),
        ),
        child: FadeTransition(
          opacity: Tween<double>(
            begin: _opacityAnimation.value,
            end: _dismissController.value > 0 ? 0 : _opacityAnimation.value,
          ).animate(
            CurvedAnimation(
              parent: _dismissController,
              curve: Curves.easeOut,
            ),
          ),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: _scaleAnimation.value,
              end: 1.0,
            ).animate(_animationController),
            child: GestureDetector(
              onTap: () {
                widget.onTap?.call();
                _handleDismiss();
              },
              child: NotificationCard(
                notification: widget.notification,
                onDismiss: _handleDismiss,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 32,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (isDark ? Colors.grey[900] : Colors.white)!.withOpacity(0.85),
                (isDark ? Colors.grey[800] : Colors.grey[50])!.withOpacity(0.75),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: notification.typeColor.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: LanguageController.contentTextDirection,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      notification.typeColor.withOpacity(0.8),
                      notification.typeColor.withOpacity(0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: notification.typeColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  notification.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  textDirection: LanguageController.contentTextDirection,
                  children: [
                    Text(
                      notification.title,
                      textDirection: LanguageController.contentTextDirection,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      textDirection: LanguageController.contentTextDirection,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onDismiss,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: isDark ? Colors.white : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}