import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A stats summary card matching the Bento aesthetic with generous 24px radius
class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isPrimary;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.primary : AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.bentoRadius),
        border: Border.all(
          color: isPrimary ? Colors.transparent : AppColors.border,
          width: 1,
        ),
        boxShadow: isPrimary ? AppColors.lavenderShadow : AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.bentoRadius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPrimary
                            ? Colors.white.withValues(alpha: 0.25)
                            : color.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        icon,
                        color: isPrimary ? Colors.white : color,
                        size: 20,
                      ),
                    ),
                    Icon(
                      Icons.arrow_outward_rounded,
                      size: 18,
                      color: isPrimary
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.secondaryText,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: isPrimary ? Colors.white : AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: isPrimary
                            ? Colors.white.withValues(alpha: 0.85)
                            : AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Semantic status pill badge: In Stock / Low Stock / Out of Stock
class StatusChip extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;
  final Color? backgroundColor;

  const StatusChip({
    super.key,
    required this.label,
    this.color,
    this.textColor,
    this.backgroundColor,
  });

  factory StatusChip.inStock() => const StatusChip(
        label: 'In Stock',
        textColor: AppColors.inStockText,
        backgroundColor: AppColors.inStockBg,
      );

  factory StatusChip.lowStock() => const StatusChip(
        label: 'Low Stock',
        textColor: AppColors.lowStockText,
        backgroundColor: AppColors.lowStockBg,
      );

  factory StatusChip.outOfStock() => const StatusChip(
        label: 'Out of Stock',
        textColor: AppColors.outOfStockText,
        backgroundColor: AppColors.outOfStockBg,
      );

  @override
  Widget build(BuildContext context) {
    final fg = textColor ?? color ?? AppColors.text;
    final bg = backgroundColor ??
        (color != null ? color!.withValues(alpha: 0.12) : AppColors.primaryActive);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}

/// Search field with pill/rounded aesthetic and clear button
class SearchField extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const SearchField({
    super.key,
    this.hint = 'Search...',
    required this.onChanged,
    this.controller,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x041A1A1A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.text,
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(
            fontSize: 13,
            color: AppColors.secondaryText,
          ),
          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.secondaryText),
          suffixIcon: ValueListenableBuilder(
            valueListenable: _controller,
            builder: (_, value, __) => value.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18, color: AppColors.secondaryText),
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged('');
                    },
                  )
                : const SizedBox.shrink(),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

/// Generic confirm/alert dialog
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color? confirmColor;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.confirmColor,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Delete',
    Color? confirmColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => ConfirmDialog(
            title: title,
            message: message,
            confirmLabel: confirmLabel,
            confirmColor: confirmColor ?? AppColors.danger,
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.card,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.secondaryText,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.secondaryText,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            ),
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor ?? AppColors.danger,
            foregroundColor: Colors.white,
            minimumSize: const Size(96, 42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            ),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

/// Empty state with icon and message
class EmptyState extends StatelessWidget {
  final String message;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.message,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFF0F1F5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.secondaryText),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Section header with optional trailing widget
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppColors.text,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// +/- quantity stepper with pill/rounded aesthetic
class QuantityStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const QuantityStepper({
    super.key,
    required this.value,
    this.min = 1,
    this.max = 9999,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove,
            onTap: value > min ? () => onChanged(value - 1) : null,
          ),
          Container(
            width: 52,
            alignment: Alignment.center,
            child: Text(
              '$value',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add,
            onTap: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 18,
            color: onTap != null ? AppColors.text : AppColors.secondaryText.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
