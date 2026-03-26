import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/widgets/sidebar_layout.dart';
import 'package:skep_app/features/auth/bloc/auth_bloc.dart';
import 'package:skep_app/features/auth/bloc/auth_event.dart';
import 'package:skep_app/features/dashboard/view/company_employee_page.dart';
import 'package:skep_app/features/dashboard/view/bp_deployment_plan_page.dart';
import 'package:skep_app/features/dashboard/view/bp_daily_roster_page.dart';
import 'package:skep_app/features/dashboard/view/bp_inspection_status_page.dart';
import 'package:skep_app/features/dashboard/view/bp_settlement_page.dart';
import 'package:skep_app/features/dashboard/view/matching_request_page.dart';
import 'package:skep_app/features/dashboard/view/realtime_location_page.dart';
import 'package:skep_app/features/dashboard/view/work_confirmation_page.dart';
import 'package:skep_app/features/dashboard/view/site_management_page.dart';
import 'package:skep_app/features/dashboard/view/quotation_management_page.dart';
import 'package:skep_app/features/dashboard/view/checklist_management_page.dart';
import 'package:skep_app/features/dashboard/view/placeholder_page.dart';

class BPDashboard extends StatefulWidget {
  const BPDashboard({Key? key}) : super(key: key);

  @override
  State<BPDashboard> createState() => _BPDashboardState();
}

class _BPDashboardState extends State<BPDashboard> {
  String _activeMenuId = 'home';
  final Set<String> _expandedMenuIds = {};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const double _sidebarWidth = 260.0;
  static const double _mobileBreakpoint = 768.0;

  static const List<SidebarMenuItem> _menuItems = [
    SidebarMenuItem(
      id: 'home',
      icon: Icons.dashboard_outlined,
      label: '대시보드',
    ),
    SidebarMenuItem(
      id: 'deployment_plan',
      icon: Icons.assignment_outlined,
      label: '투입 계획',
    ),
    SidebarMenuItem(
      id: 'matching',
      icon: Icons.search_outlined,
      label: '장비 매칭',
    ),
    SidebarMenuItem(
      id: 'daily_roster',
      icon: Icons.schedule_outlined,
      label: '일일 작업자 명단',
    ),
    SidebarMenuItem(
      id: 'inspection',
      icon: Icons.verified_user_outlined,
      label: '안전점검 현황',
    ),
    SidebarMenuItem(
      id: 'settlement',
      icon: Icons.receipt_long_outlined,
      label: '정산 현황',
    ),
    SidebarMenuItem(
      id: 'location',
      icon: Icons.location_on_outlined,
      label: '실시간 위치',
    ),
    SidebarMenuItem(
      id: 'work_confirm',
      icon: Icons.fact_check_outlined,
      label: '작업확인서',
    ),
    SidebarMenuItem(
      id: 'sites',
      icon: Icons.location_city_outlined,
      label: '현장 관리',
    ),
    SidebarMenuItem(
      id: 'quotations',
      icon: Icons.request_quote_outlined,
      label: '견적 관리',
    ),
    SidebarMenuItem(
      id: 'checklist',
      icon: Icons.checklist_outlined,
      label: '투입 체크리스트',
    ),
    SidebarMenuItem(
      id: 'employees',
      icon: Icons.badge_outlined,
      label: '직원 관리',
    ),
  ];

  bool get _isMobile =>
      MediaQuery.of(context).size.width < _mobileBreakpoint;

  void _onMenuTap(SidebarMenuItem item) {
    if (item.children != null && item.children!.isNotEmpty) {
      setState(() {
        if (_expandedMenuIds.contains(item.id)) {
          _expandedMenuIds.remove(item.id);
        } else {
          _expandedMenuIds.add(item.id);
        }
      });
      return;
    }
    setState(() {
      _activeMenuId = item.id;
    });
    if (_isMobile) {
      Navigator.of(context).pop();
    }
  }

  void _handleLogout() {
    context.read<AuthBloc>().add(const AuthLogoutRequested());
    context.go('/login');
  }

  Widget _buildBody() {
    switch (_activeMenuId) {
      case 'home':
        return _BPHome(onNavigate: (menuId) {
          setState(() => _activeMenuId = menuId);
        });
      case 'deployment_plan':
        return const BpDeploymentPlanPage();
      case 'matching':
        return const MatchingRequestPage();
      case 'daily_roster':
        return const BpDailyRosterPage();
      case 'inspection':
        return const BpInspectionStatusPage();
      case 'settlement':
        return const BpSettlementPage();
      case 'location':
        return const RealtimeLocationPage();
      case 'work_confirm':
        return const WorkConfirmationPage();
      case 'sites':
        return const SiteManagementPage();
      case 'quotations':
        return const QuotationManagementPage();
      case 'checklist':
        return const ChecklistManagementPage();
      case 'employees':
        return const CompanyEmployeePage();
      default:
        return const _BPHome();
    }
  }

  String _getTitle() {
    switch (_activeMenuId) {
      case 'home':
        return 'BP사 대시보드';
      case 'deployment_plan':
        return '투입 계획';
      case 'matching':
        return '장비 매칭';
      case 'daily_roster':
        return '일일 작업자 명단';
      case 'inspection':
        return '안전점검 현황';
      case 'settlement':
        return '정산 현황';
      case 'location':
        return '실시간 위치';
      case 'work_confirm':
        return '작업확인서';
      case 'sites':
        return '현장 관리';
      case 'quotations':
        return '견적 관리';
      case 'checklist':
        return '투입 체크리스트';
      case 'employees':
        return '직원 관리';
      default:
        return 'BP사 대시보드';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isMobile) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(_getTitle()),
          backgroundColor: const Color(0xFF1E293B),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        drawer: Drawer(
          child: _buildSidebarContent(),
        ),
        body: _buildBody(),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: _sidebarWidth,
            child: _buildSidebarContent(),
          ),
          const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE0E0E0)),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: Container(
                    color: const Color(0xFFFAFAFA),
                    child: _buildBody(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(_getTitle(), style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          )),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF424242)),
            tooltip: '알림',
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent() {
    return Container(
      color: const Color(0xFF1E293B),
      child: Column(
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('S', style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    )),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('SKEP', style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                )),
              ],
            ),
          ),
          const Divider(color: Color(0xFF334155), height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: _menuItems
                  .expand((item) => _buildMenuWidgets(item))
                  .toList(),
            ),
          ),
          const Divider(color: Color(0xFF334155), height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFF94A3B8), size: 20),
            title: const Text('로그아웃', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
            dense: true,
            onTap: _handleLogout,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  List<Widget> _buildMenuWidgets(SidebarMenuItem item) {
    final isActive = item.id == _activeMenuId;
    final hasChildren = item.children != null && item.children!.isNotEmpty;
    final isExpanded = _expandedMenuIds.contains(item.id);
    final hasActiveChild = hasChildren &&
        item.children!.any((child) => child.id == _activeMenuId);

    final widgets = <Widget>[];

    widgets.add(
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        decoration: BoxDecoration(
          color: (isActive || hasActiveChild)
              ? const Color(0xFF2196F3).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          dense: true,
          visualDensity: const VisualDensity(vertical: -2),
          leading: Icon(
            item.icon,
            color: (isActive || hasActiveChild)
                ? const Color(0xFF2196F3)
                : const Color(0xFF94A3B8),
            size: 20,
          ),
          title: Text(
            item.label,
            style: TextStyle(
              color: (isActive || hasActiveChild)
                  ? const Color(0xFF2196F3)
                  : const Color(0xFFCBD5E1),
              fontSize: 14,
              fontWeight: (isActive || hasActiveChild)
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
          trailing: hasChildren
              ? Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFF94A3B8),
                  size: 18,
                )
              : null,
          onTap: () => _onMenuTap(item),
        ),
      ),
    );

    if (hasChildren && isExpanded) {
      for (final child in item.children!) {
        final isChildActive = child.id == _activeMenuId;
        widgets.add(
          Container(
            margin: const EdgeInsets.only(left: 24, right: 8, top: 1, bottom: 1),
            decoration: BoxDecoration(
              color: isChildActive
                  ? const Color(0xFF2196F3).withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              dense: true,
              visualDensity: const VisualDensity(vertical: -3),
              leading: Icon(
                child.icon,
                color: isChildActive
                    ? const Color(0xFF2196F3)
                    : const Color(0xFF64748B),
                size: 16,
              ),
              title: Text(
                child.label,
                style: TextStyle(
                  color: isChildActive
                      ? const Color(0xFF2196F3)
                      : const Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: isChildActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              onTap: () => _onMenuTap(child),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}

/// BP사 홈 페이지 콘텐츠
class _BPHome extends StatelessWidget {
  final void Function(String menuId)? onNavigate;
  const _BPHome({this.onNavigate});

  static const _darkText = Color(0xFF1E293B);
  static const _pageBg = Color(0xFFF8FAFC);
  static const _cardShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _pageBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BP사 대시보드',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _darkText),
            ),
            const SizedBox(height: 4),
            Text(
              '투입 현황 및 안전점검 상태를 확인하세요.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
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
                    _buildClickableSummaryCard('투입 장비', '12대', Icons.build_outlined, AppColors.primary, '전주 대비 +2대', () => onNavigate?.call('deployment_plan')),
                    _buildClickableSummaryCard('금일 작업자', '18명', Icons.people_outlined, const Color(0xFF16A34A), '정상 투입', () => onNavigate?.call('daily_roster')),
                    _buildClickableSummaryCard('안전점검 완료', '9건', Icons.verified_user_outlined, const Color(0xFFD97706), '미완료 3건', () => onNavigate?.call('inspection')),
                    _buildClickableSummaryCard('미정산', '2건', Icons.receipt_long_outlined, const Color(0xFFDC2626), '총 4,200만원', () => onNavigate?.call('settlement')),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            // Quick actions
            _buildSectionHeader(Icons.flash_on_outlined, '빠른 실행'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildClickableQuickAction(Icons.search_outlined, '장비 매칭', AppColors.primary, () => onNavigate?.call('matching')),
                _buildClickableQuickAction(Icons.assignment_outlined, '투입 계획 생성', const Color(0xFF16A34A), () => onNavigate?.call('deployment_plan')),
                _buildClickableQuickAction(Icons.list_alt_outlined, '일일 명단 확인', const Color(0xFF7C3AED), () => onNavigate?.call('daily_roster')),
              ],
            ),
            const SizedBox(height: 28),
            // Pending approval requests
            _buildSectionHeader(Icons.pending_actions, '대기 중 승인 요청'),
            const SizedBox(height: 16),
            _buildClickableRequestCard(
              '(주)한국크레인',
              '25톤 크레인 투입 요청',
              '2026-04-01 ~ 2026-06-30',
              '대기중',
              const Color(0xFFD97706),
              () => onNavigate?.call('deployment_plan'),
            ),
            const SizedBox(height: 12),
            _buildClickableRequestCard(
              '삼성중장비',
              '50톤 크레인 투입 요청',
              '2026-04-15 ~ 2026-07-31',
              '대기중',
              const Color(0xFFD97706),
              () => onNavigate?.call('deployment_plan'),
            ),
            const SizedBox(height: 12),
            _buildClickableRequestCard(
              '대한건기',
              '일일 명단 변경 요청',
              '2026-03-23',
              '확인필요',
              AppColors.info,
              () => onNavigate?.call('daily_roster'),
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
          decoration: BoxDecoration(
            color: const Color(0xFF64748B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF64748B), size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _darkText),
        ),
      ],
    );
  }

  static Widget _buildClickableSummaryCard(String label, String value, IconData icon, Color color, String subtitle, VoidCallback onTap) {
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 14),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _darkText)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildSummaryCard(String label, String value, IconData icon, Color color, String subtitle) {
    return _buildClickableSummaryCard(label, value, icon, color, subtitle, () {});
  }

  static Widget _buildClickableQuickAction(IconData icon, String label, Color color, VoidCallback onTap) {
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

  static Widget _buildQuickAction(IconData icon, String label, Color color) {
    return _buildClickableQuickAction(icon, label, color, () {});
  }

  static Widget _buildClickableRequestCard(
      String supplier, String request, String period, String statusLabel, Color statusColor, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: _buildRequestCardContent(supplier, request, period, statusLabel, statusColor),
      ),
    );
  }

  static Widget _buildRequestCard(
      String supplier, String request, String period, String statusLabel, Color statusColor) {
    return _buildRequestCardContent(supplier, request, period, statusLabel, statusColor);
  }

  static Widget _buildRequestCardContent(
      String supplier, String request, String period, String statusLabel, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.pending_actions, color: statusColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supplier,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _darkText),
                ),
                const SizedBox(height: 4),
                Text(request, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                const SizedBox(height: 2),
                Text(period, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }
}
