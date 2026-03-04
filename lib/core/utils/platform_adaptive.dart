import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Helper to determine if the current platform is iOS/macOS (Cupertino)
bool get isCupertino {
  try {
    return Platform.isIOS || Platform.isMacOS;
  } catch (_) {
    // Web or unsupported — default to Material
    return false;
  }
}

/// Adaptive scaffold that uses CupertinoPageScaffold on iOS, Scaffold on Android
class AdaptiveScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final Widget? trailing;
  final Widget? leading;
  final Color? backgroundColor;
  final bool useSliverAppBar;

  const AdaptiveScaffold({
    super.key,
    this.title,
    required this.body,
    this.trailing,
    this.leading,
    this.backgroundColor,
    this.useSliverAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCupertino) {
      return CupertinoPageScaffold(
        backgroundColor:
            backgroundColor ?? CupertinoTheme.of(context).scaffoldBackgroundColor,
        navigationBar: title != null
            ? CupertinoNavigationBar(
                middle: Text(title!),
                trailing: trailing,
                leading: leading,
                backgroundColor:
                    backgroundColor ?? CupertinoTheme.of(context).barBackgroundColor,
              )
            : null,
        child: SafeArea(child: body),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: title != null
          ? AppBar(
              title: Text(title!),
              leading: leading,
              actions: trailing != null ? [trailing!] : null,
            )
          : null,
      body: body,
    );
  }
}

/// Adaptive button that uses CupertinoButton on iOS, ElevatedButton on Android
class AdaptiveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool filled;

  const AdaptiveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isCupertino) {
      return filled
          ? CupertinoButton.filled(onPressed: onPressed, child: child)
          : CupertinoButton(onPressed: onPressed, child: child);
    }
    return filled
        ? ElevatedButton(onPressed: onPressed, child: child)
        : OutlinedButton(onPressed: onPressed, child: child);
  }
}

/// Adaptive text field
class AdaptiveTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final String? labelText;
  final Widget? prefix;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;

  const AdaptiveTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.labelText,
    this.prefix,
    this.suffix,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isCupertino) {
      return CupertinoTextField(
        controller: controller,
        placeholder: placeholder ?? labelText,
        prefix: prefix != null
            ? Padding(
                padding: const EdgeInsets.only(left: 8), child: prefix)
            : null,
        suffix: suffix != null
            ? Padding(
                padding: const EdgeInsets.only(right: 8), child: suffix)
            : null,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        onChanged: onChanged,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: placeholder,
        labelText: labelText,
        prefixIcon: prefix,
        suffixIcon: suffix,
      ),
    );
  }
}

/// Show an adaptive dialog (CupertinoAlertDialog on iOS, AlertDialog on Android)
Future<T?> showAdaptiveConfirmDialog<T>({
  required BuildContext context,
  required String title,
  required String content,
  String cancelLabel = 'Cancel',
  String confirmLabel = 'Confirm',
  bool isDestructive = false,
}) {
  if (isCupertino) {
    return showCupertinoDialog<T>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false as T),
            child: Text(cancelLabel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: isDestructive,
            onPressed: () => Navigator.of(ctx).pop(true as T),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  return showDialog<T>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false as T),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true as T),
          style: isDestructive
              ? TextButton.styleFrom(foregroundColor: Colors.red)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

/// Show an adaptive bottom sheet (CupertinoActionSheet style on iOS)
Future<void> showAdaptiveBottomSheet({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  if (isCupertino) {
    return showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: CupertinoTheme.of(ctx).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(child: builder(ctx)),
        ),
      ),
    );
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: builder,
  );
}

/// Adaptive activity indicator
class AdaptiveProgressIndicator extends StatelessWidget {
  const AdaptiveProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    if (isCupertino) {
      return const CupertinoActivityIndicator();
    }
    return const CircularProgressIndicator.adaptive();
  }
}

/// Adaptive refresh control — returns appropriate sliver for pull-to-refresh
class AdaptiveRefreshControl extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const AdaptiveRefreshControl({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (isCupertino) {
      return CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: onRefresh),
          SliverToBoxAdapter(child: child),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: child,
      ),
    );
  }
}

/// Adaptive switch
class AdaptiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const AdaptiveSwitch({
    super.key,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isCupertino) {
      return CupertinoSwitch(value: value, onChanged: onChanged);
    }
    return Switch.adaptive(value: value, onChanged: onChanged);
  }
}
