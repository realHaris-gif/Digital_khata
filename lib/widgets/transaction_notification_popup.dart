import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/notification_model.dart';

class TransactionDynamicIslandPopup extends StatefulWidget {
  final NotificationModel notification;
  final Duration duration;
  final VoidCallback? onDismiss;

  const TransactionDynamicIslandPopup({
    super.key,
    required this.notification,
    this.duration = const Duration(seconds: 5),
    this.onDismiss,
  });

  @override
  State<TransactionDynamicIslandPopup> createState() =>
      _TransactionDynamicIslandPopupState();
}

class _TransactionDynamicIslandPopupState
    extends State<TransactionDynamicIslandPopup> with TickerProviderStateMixin {
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
          _handleDismiss();
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
            child: TransactionNotificationCard(
              notification: widget.notification,
              onDismiss: _handleDismiss,
            ),
          ),
        ),
      ),
    );
  }
}

class TransactionNotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;

  const TransactionNotificationCard({
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
                (isDark ? Colors.grey[900] : Colors.white)!.withOpacity(0.9),
                (isDark ? Colors.grey[800] : Colors.grey[50])!.withOpacity(0.85),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Badge
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

              // Title & Message
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.title,
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                isDark ? Colors.grey[300] : Colors.grey[700],
                            fontSize: 12,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Action Buttons: Cancel & View
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cancel Button
                  GestureDetector(
                    onTap: onDismiss,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // View Button
                  GestureDetector(
                    onTap: () {
                      onDismiss();
                      Future.delayed(const Duration(milliseconds: 200), () {
                        context.push('/notifications');
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: notification.typeColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: notification.typeColor.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Text(
                        'View',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
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
