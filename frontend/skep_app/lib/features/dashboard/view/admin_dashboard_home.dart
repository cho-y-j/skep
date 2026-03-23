import 'package:flutter/material.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/features/dashboard/view/supplier_equipment_page.dart';
import 'package:skep_app/features/dashboard/view/supplier_personnel_page.dart';

class AdminDashboardHome extends StatelessWidget {
  final void Function(String menuId)? onNavigate;

  const AdminDashboardHome({Key? key, this.onNavigate}) : super(key: key);

  static const _darkText = Color(0xFF1E293B);
  static const _pageBg = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    final eqCount = EquipmentListStore.instance.equipmentList.length;
    final pCount = PersonnelListStore.instance.personnelList.length;

    return Container(
      color: _pageBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('관리자 대시보드', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _darkText)),
            const SizedBox(height: 4),
            Text('플랫폼 전체 현황을 한눈에 확인하세요.', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 24),
            // Summary cards
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: constraints.maxWidth > 800 ? 1.6 : 1.5,
                  children: [
                    _SummaryCard(
                      icon: Icons.build_circle_outlined,
                      label: '전체 장비',
                      value: '${eqCount > 0 ? eqCount : 24}대',
                      subtitle: '이번 주 +3대',
                      trend: _Trend.up,
                      color: AppColors.primary,
                      onTap: () => onNavigate?.call('equipment_status'),
                    ),
                    _SummaryCard(
                      icon: Icons.people_outline,
                      label: '전체 인력',
                      value: '${pCount > 0 ? pCount : 31}명',
                      subtitle: '이번 주 +2명',
                      trend: _Trend.up,
                      color: const Color(0xFF16A34A),
                      onTap: () => onNavigate?.call('members_users'),
                    ),
                    _SummaryCard(
                      icon: Icons.assignment_turned_in_outlined,
                      label: '투입 중',
                      value: '12건',
                      subtitle: '전주 대비 동일',
                      trend: _Trend.flat,
                      color: const Color(0xFFD97706),
                      onTap: () => onNavigate?.call('deployment'),
                    ),
                    _SummaryCard(
                      icon: Icons.warning_amber_outlined,
                      label: '서류 만료 임박',
                      value: '7건',
                      subtitle: '긴급 3건 포함',
                      trend: _Trend.down,
                      color: const Color(0xFFDC2626),
                      onTap: () => onNavigate?.call('documents'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            // 빠른 실행
            _buildSectionHeader(Icons.flash_on_outlined, '빠른 실행'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildQuickAction(Icons.people_outlined, '회원 관리', AppColors.primary, () => onNavigate?.call('members_users')),
                _buildQuickAction(Icons.business_outlined, '회사 목록', const Color(0xFF16A34A), () => onNavigate?.call('members_companies')),
                _buildQuickAction(Icons.description_outlined, '서류 관리', const Color(0xFFD97706), () => onNavigate?.call('documents')),
                _buildQuickAction(Icons.bar_chart_outlined, '통계', const Color(0xFF7C3AED), () => onNavigate?.call('statistics')),
              ],
            ),
            const SizedBox(height: 28),
            // 서버 상태
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  const Text('서버 상태: 정상', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF16A34A))),
                  const Spacer(),
                  Text('마지막 확인: ${TimeOfDay.now().format(context)}', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Recent activity timeline
            _buildSectionHeader(Icons.timeline, '최근 활동'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  _buildTimelineItem(icon: Icons.person_add, color: AppColors.primary, text: '대한건기가 신규 가입했습니다.', time: '2026-03-20 14:00', isFirst: true),
                  _buildTimelineItem(icon: Icons.build, color: const Color(0xFF16A34A), text: '(주)한국크레인이 25톤 크레인을 등록했습니다.', time: '2026-03-20 11:30'),
                  _buildTimelineItem(icon: Icons.assignment, color: const Color(0xFFD97706), text: '삼성중장비 -> 현대건설 투입 요청이 접수되었습니다.', time: '2026-03-19 16:00'),
                  _buildTimelineItem(icon: Icons.notifications, color: const Color(0xFFDC2626), text: '건강검진 만료 알림이 발송되었습니다. (김운전)', time: '2026-03-19 09:00'),
                  _buildTimelineItem(icon: Icons.verified_user, color: AppColors.info, text: '강남 현장 A 안전점검에서 이상이 발견되었습니다.', time: '2026-03-18 15:30', isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Expiring documents
            _buildSectionHeader(Icons.description_outlined, '만료 임박 서류 Top 5'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    headingTextStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _darkText),
                    dataTextStyle: const TextStyle(fontSize: 13, color: _darkText),
                    columnSpacing: 32,
                    horizontalMargin: 20,
                    columns: const [
                      DataColumn(label: Text('서류명')),
                      DataColumn(label: Text('소속')),
                      DataColumn(label: Text('공급사')),
                      DataColumn(label: Text('만료일')),
                      DataColumn(label: Text('D-Day')),
                    ],
                    rows: const [
                      DataRow(cells: [DataCell(Text('안전교육수료증')), DataCell(Text('이기사')), DataCell(Text('(주)한국크레인')), DataCell(Text('2026-03-20')), DataCell(_DDayBadge(dDay: -2))]),
                      DataRow(cells: [DataCell(Text('건강검진결과')), DataCell(Text('김운전')), DataCell(Text('(주)한국크레인')), DataCell(Text('2026-03-25')), DataCell(_DDayBadge(dDay: 3))]),
                      DataRow(cells: [DataCell(Text('보험증권')), DataCell(Text('지게차 3톤')), DataCell(Text('대한건기')), DataCell(Text('2026-03-18')), DataCell(_DDayBadge(dDay: -4))]),
                      DataRow(cells: [DataCell(Text('보험증권')), DataCell(Text('50톤 크레인')), DataCell(Text('(주)한국크레인')), DataCell(Text('2026-03-30')), DataCell(_DDayBadge(dDay: 8))]),
                      DataRow(cells: [DataCell(Text('건설기계등록증')), DataCell(Text('25톤 크레인')), DataCell(Text('(주)한국크레인')), DataCell(Text('2026-04-05')), DataCell(_DDayBadge(dDay: 14))]),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF64748B).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: const Color(0xFF64748B), size: 18),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _darkText)),
      ],
    );
  }

  static Widget _buildQuickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildTimelineItem({
    required IconData icon,
    required Color color,
    required String text,
    required String time,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                if (!isFirst) Container(width: 2, height: 8, color: const Color(0xFFE2E8F0)),
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 16),
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: const Color(0xFFE2E8F0))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(text, style: const TextStyle(fontSize: 14, color: _darkText)),
                  const SizedBox(height: 4),
                  Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Trend { up, down, flat }

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final _Trend trend;
  final Color color;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.trend,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                  _buildTrendIndicator(),
                ],
              ),
              const SizedBox(height: 14),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 11, color: _trendColor)),
            ],
          ),
        ),
      ),
    );
  }

  Color get _trendColor {
    switch (trend) {
      case _Trend.up: return const Color(0xFF16A34A);
      case _Trend.down: return const Color(0xFFDC2626);
      case _Trend.flat: return const Color(0xFF64748B);
    }
  }

  Widget _buildTrendIndicator() {
    IconData trendIcon;
    switch (trend) {
      case _Trend.up: trendIcon = Icons.trending_up; break;
      case _Trend.down: trendIcon = Icons.trending_down; break;
      case _Trend.flat: trendIcon = Icons.trending_flat; break;
    }
    return Icon(trendIcon, color: _trendColor, size: 20);
  }
}

class _DDayBadge extends StatelessWidget {
  final int dDay;
  const _DDayBadge({required this.dDay});

  Color get _color {
    if (dDay < 0) return const Color(0xFFDC2626);
    if (dDay <= 7) return const Color(0xFFDC2626);
    if (dDay <= 14) return const Color(0xFFD97706);
    return AppColors.info;
  }

  String get _text {
    if (dDay < 0) return 'D+${-dDay}';
    if (dDay == 0) return 'D-Day';
    return 'D-$dDay';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(_text, style: TextStyle(color: _color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
