import 'package:flutter/material.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';

/// 아직 구현되지 않은 메뉴에 사용하는 플레이스홀더 페이지
class PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderPage({
    Key? key,
    required this.title,
    this.icon = Icons.construction_outlined,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.grey),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '준비 중입니다',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}
