import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared design tokens for all Add/Edit data-entry forms.
class AppFormTokens {
  AppFormTokens._();

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusXl = 22;

  static const double fieldHeight = 56;
  static const double spacingXs = 6;
  static const double spacingSm = 10;
  static const double spacingMd = 16;
  static const double spacingLg = 20;
  static const double spacingXl = 28;

  static const double maxContentWidth = 640;
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(20, 12, 20, 24);
  static const EdgeInsets sectionPadding = EdgeInsets.all(18);
}

/// Consistent InputDecoration used across all forms.
InputDecoration appInputDecoration(
  BuildContext context, {
  String? labelText,
  String? hintText,
  String? helperText,
  String? errorText,
  String? prefixText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  int? maxLines,
  bool filled = true,
}) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;

  final borderRadius = BorderRadius.circular(AppFormTokens.radiusMd);
  final fill = isDark
      ? cs.surface.withValues(alpha: 0.55)
      : cs.surfaceContainerHighest.withValues(alpha: 0.45);

  OutlineInputBorder outline(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    helperText: helperText,
    errorText: errorText,
    prefixText: prefixText,
    prefixIcon: prefixIcon == null
        ? null
        : IconTheme(
            data: IconThemeData(
              color: cs.onSurfaceVariant.withValues(alpha: 0.85),
              size: 22,
            ),
            child: prefixIcon,
          ),
    suffixIcon: suffixIcon,
    filled: filled,
    fillColor: fill,
    contentPadding: EdgeInsets.symmetric(
      horizontal: 16,
      vertical: (maxLines != null && maxLines > 1) ? 16 : 14,
    ),
    labelStyle: TextStyle(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w500,
      fontSize: 14,
    ),
    hintStyle: TextStyle(
      color: cs.onSurfaceVariant.withValues(alpha: 0.65),
      fontWeight: FontWeight.w400,
      fontSize: 14,
    ),
    helperStyle: TextStyle(
      color: cs.onSurfaceVariant.withValues(alpha: 0.75),
      fontSize: 12,
      height: 1.3,
    ),
    errorStyle: TextStyle(
      color: cs.error,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    border: outline(cs.outline.withValues(alpha: 0.35)),
    enabledBorder: outline(cs.outline.withValues(alpha: 0.28)),
    focusedBorder: outline(cs.primary, width: 1.6),
    errorBorder: outline(cs.error.withValues(alpha: 0.7)),
    focusedErrorBorder: outline(cs.error, width: 1.6),
    disabledBorder: outline(cs.outline.withValues(alpha: 0.15)),
  );
}

/// Premium AppBar used on form screens.
PreferredSizeWidget formAppBar(
  BuildContext context, {
  required String title,
  String? subtitle,
  List<Widget>? actions,
  bool centerTitle = true,
}) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;

  return AppBar(
    centerTitle: centerTitle,
    elevation: 0,
    scrolledUnderElevation: 0.5,
    backgroundColor: theme.scaffoldBackgroundColor,
    surfaceTintColor: Colors.transparent,
    titleSpacing: 0,
    title: subtitle == null
        ? Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          )
        : Column(
            crossAxisAlignment:
                centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
    actions: actions,
  );
}

/// Full-screen form shell: dismiss keyboard on tap, scroll, optional sticky actions.
class FormScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final List<Widget> children;
  final Widget? bottomBar;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;
  final CrossAxisAlignment crossAxisAlignment;
  final Widget? floatingActionButton;

  const FormScaffold({
    super.key,
    this.appBar,
    required this.children,
    this.bottomBar,
    this.isLoading = false,
    this.padding,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppFormTokens.maxContentWidth),
        child: SingleChildScrollView(
          padding: padding ??
              EdgeInsets.fromLTRB(
                AppFormTokens.pagePadding.left,
                AppFormTokens.pagePadding.top,
                AppFormTokens.pagePadding.right,
                bottomBar != null ? 12 : 120,
              ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: crossAxisAlignment,
            children: children,
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(child: content),
                  if (bottomBar != null) bottomBar!,
                ],
              ),
      ),
    );
  }
}

/// Card section used to group related fields.
class FormSectionCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const FormSectionCard({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    required this.children,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: AppFormTokens.spacingMd),
      decoration: BoxDecoration(
        color: isDark ? cs.surface.withValues(alpha: 0.9) : cs.surface,
        borderRadius: BorderRadius.circular(AppFormTokens.radiusLg),
        border: Border.all(
          color: cs.outline.withValues(alpha: isDark ? 0.18 : 0.10),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Padding(
        padding: padding ?? AppFormTokens.sectionPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.10),
                        borderRadius:
                            BorderRadius.circular(AppFormTokens.radiusSm),
                      ),
                      child: Icon(icon, size: 18, color: cs.primary),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title!,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppFormTokens.spacingMd),
            ],
            ..._withGaps(children),
          ],
        ),
      ),
    );
  }

  List<Widget> _withGaps(List<Widget> items) {
    if (items.isEmpty) return items;
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      out.add(items[i]);
      if (i != items.length - 1) {
        out.add(const SizedBox(height: AppFormTokens.spacingMd));
      }
    }
    return out;
  }
}

/// Sticky bottom action bar for Save / Cancel.
class FormBottomBar extends StatelessWidget {
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool isLoading;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final IconData? primaryIcon;

  const FormBottomBar({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.isLoading = false,
    this.secondaryLabel,
    this.onSecondary,
    this.primaryIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? cs.surface : cs.surface,
        border: Border(
          top: BorderSide(color: cs.outline.withValues(alpha: 0.12)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomInset),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppFormTokens.maxContentWidth),
            child: Row(
              children: [
                if (secondaryLabel != null) ...[
                  Expanded(
                    child: FormSecondaryButton(
                      label: secondaryLabel!,
                      onPressed: isLoading ? null : onSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: secondaryLabel != null ? 2 : 1,
                  child: FormPrimaryButton(
                    label: primaryLabel,
                    onPressed: onPrimary,
                    isLoading: isLoading,
                    icon: primaryIcon,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FormPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const FormPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          disabledBackgroundColor: cs.primary.withValues(alpha: 0.45),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppFormTokens.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: cs.onPrimary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class FormSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const FormSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.onSurface,
          side: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppFormTokens.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

/// Premium text field wrapper with consistent styling.
class AppFormTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? prefixText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool readOnly;
  final bool autofocus;
  final bool enabled;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final void Function()? onTap;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;

  const AppFormTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.prefixText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.readOnly = false,
    this.autofocus = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
    this.onSaved,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.focusNode,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: enabled,
      readOnly: readOnly,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      validator: validator,
      onSaved: onSaved,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      onTap: onTap,
      autofillHints: autofillHints,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            height: 1.25,
          ),
      decoration: appInputDecoration(
        context,
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        prefixText: prefixText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
        maxLines: maxLines,
      ),
    );
  }
}

/// Premium dropdown with matching decoration.
class AppFormDropdown<T> extends StatelessWidget {
  final T? value;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final IconData? prefixIcon;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final bool isExpanded;

  const AppFormDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelText,
    this.hintText,
    this.helperText,
    this.prefixIcon,
    this.validator,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: isExpanded,
      items: items,
      onChanged: onChanged,
      validator: validator,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      decoration: appInputDecoration(
        context,
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      ),
      borderRadius: BorderRadius.circular(AppFormTokens.radiusMd),
      dropdownColor: Theme.of(context).colorScheme.surface,
    );
  }
}

/// Subtle helper / info banner inside forms.
class FormInfoBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? color;

  const FormInfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = color ?? cs.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppFormTokens.radiusMd),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state box used inside forms (e.g. no invoice items).
class FormEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const FormEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppFormTokens.radiusMd),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

/// Professional success / error snackbars for forms.
void showFormSnackBar(
  BuildContext context, {
  required String message,
  bool isError = false,
}) {
  final cs = Theme.of(context).colorScheme;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppFormTokens.radiusMd),
      ),
      backgroundColor: isError ? cs.error : cs.primary,
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: isError ? cs.onError : cs.onPrimary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? cs.onError : cs.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}

/// Compact section header used between cards when needed.
class FormSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const FormSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
