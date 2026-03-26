import 'package:flutter/material.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double? height;
  final Icon? icon;
  final EdgeInsets? padding;

  const AppButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height,
    this.icon,
    this.padding,
  }) : super(key: key);

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height ?? 48,
      child: ElevatedButton(
        onPressed: widget.isEnabled && !widget.isLoading
            ? widget.onPressed
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.backgroundColor ?? AppColors.primary,
          foregroundColor: widget.foregroundColor ?? AppColors.white,
          disabledBackgroundColor: AppColors.grey,
          padding: widget.padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: widget.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.white,
                  ),
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    widget.icon!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: AppTextStyles.button,
                  ),
                ],
              ),
      ),
    );
  }
}

class AppOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Color? borderColor;
  final Color? foregroundColor;
  final double? width;
  final double? height;

  const AppOutlinedButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.borderColor,
    this.foregroundColor,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? 48,
      child: OutlinedButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: borderColor ?? AppColors.primary,
            width: 1.5,
          ),
          foregroundColor: foregroundColor ?? AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: foregroundColor ?? AppColors.primary,
                ),
              ),
      ),
    );
  }
}

class AppTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? textColor;

  const AppTextButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color: textColor ?? AppColors.primary,
        ),
      ),
    );
  }
}
