import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skep_app/core/widgets/sidebar_layout.dart';
import 'package:skep_app/features/auth/bloc/auth_bloc.dart';
import 'package:skep_app/features/auth/bloc/auth_event.dart';
import 'package:skep_app/features/dashboard/view/admin_dashboard_home.dart';
import 'package:skep_app/features/dashboard/view/member_management_page.dart';
import 'package:skep_app/features/dashboard/view/admin_company_list_page.dart';
import 'package:skep_app/features/dashboard/view/document_type_master_page.dart';
import 'package:skep_app/features/dashboard/view/equipment_type_settings_page.dart';
import 'package:skep_app/features/dashboard/view/equipment_status_page.dart';
import 'package:skep_app/features/dashboard/view/personnel_type_settings_page.dart';
import 'package:skep_app/features/dashboard/view/admin_bp_management_page.dart';
import 'package:skep_app/features/dashboard/view/admin_deployment_page.dart';
import 'package:skep_app/features/dashboard/view/admin_document_management_page.dart';
import 'package:skep_app/features/dashboard/view/admin_inspection_page.dart';
import 'package:skep_app/features/dashboard/view/admin_settlement_page.dart';
import 'package:skep_app/features/dashboard/view/admin_statistics_page.dart';
import 'package:skep_app/features/dashboard/view/admin_notification_page.dart';
import 'package:skep_app/features/dashboard/view/realtime_location_page.dart';
import 'package:skep_app/features/dashboard/view/alert_notification_page.dart';
import 'package:skep_app/features/dashboard/view/site_management_page.dart';
import 'package:skep_app/features/dashboard/view/quotation_management_page.dart';
import 'package:skep_app/features/dashboard/view/checklist_management_page.dart';
import 'package:skep_app/features/dashboard/view/document_preview_page.dart';
import 'package:skep_app/features/dashboard/view/verification_page.dart';
import 'package:skep_app/features/dashboard/view/placeholder_page.dart';

class AdminDashboard extends StatefulWidget {
  final String? initialPage;

  const AdminDashboard({Key? key, this.initialPage}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late String _activeMenuId;
  final Set<String> _expandedMenuIds = {};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const double _sidebarWidth = 260.0;
  static const double _mobileBreakpoint = 768.0;

  static const List<SidebarMenuItem> _menuItems = [
    SidebarMenuItem(
      id: 'home',
      icon: Icons.dashboard_outlined,
      label: '대시보드 (홈)',
    ),
    SidebarMenuItem(
      id: 'members',
      icon: Icons.people_outlined,
      label: '회원 관리',
      children: [
        SidebarMenuItem(
          id: 'members_users',
          icon: Icons.person_outline,
          label: '사용자 목록',
        ),
        SidebarMenuItem(
          id: 'members_companies',
          icon: Icons.business_outlined,
          label: '회사 목록',
        ),
      ],
    ),
    SidebarMenuItem(
      id: 'document_types',
      icon: Icons.folder_outlined,
      label: '서류 유형 관리',
    ),
    SidebarMenuItem(
      id: 'equipment_types',
      icon: Icons.settings_outlined,
      label: '장비 유형 설정',
    ),
    SidebarMenuItem(
      id: 'personnel_types',
      icon: Icons.badge_outlined,
      label: '인력 유형 설정',
    ),
    SidebarMenuItem(
      id: 'bp_management',
      icon: Icons.business_center_outlined,
      label: 'BP사 관리',
    ),
    SidebarMenuItem(
      id: 'equipment_status',
      icon: Icons.build_outlined,
      label: '장비 현황',
    ),
    SidebarMenuItem(
      id: 'deployment',
      icon: Icons.assignment_outlined,
      label: '투입 관리',
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
      id: 'documents',
      icon: Icons.description_outlined,
      label: '서류 관리',
    ),
    SidebarMenuItem(
      id: 'inspection',
      icon: Icons.verified_user_outlined,
      label: '안전점검',
    ),
    SidebarMenuItem(
      id: 'settlement',
      icon: Icons.receipt_long_outlined,
      label: '정산',
    ),
    SidebarMenuItem(
      id: 'statistics',
      icon: Icons.bar_chart_outlined,
      label: '통계',
    ),
    SidebarMenuItem(
      id: 'notifications',
      icon: Icons.notifications_outlined,
      label: '알림/메시지',
    ),
    SidebarMenuItem(
      id: 'location',
      icon: Icons.location_on_outlined,
      label: '실시간 위치',
    ),
    SidebarMenuItem(
      id: 'document_preview',
      icon: Icons.preview_outlined,
      label: '서류 미리보기',
    ),
    SidebarMenuItem(
      id: 'verification',
      icon: Icons.verified_outlined,
      label: '검증 관리',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _activeMenuId = widget.initialPage ?? 'home';
    // 활성 메뉴가 하위 메뉴인 경우 부모를 자동 확장
    _expandParentOfActive();
  }

  void _expandParentOfActive() {
    for (final item in _menuItems) {
      if (item.children != null) {
        for (final child in item.children!) {
          if (child.id == _activeMenuId) {
            _expandedMenuIds.add(item.id);
          }
        }
      }
    }
  }

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
        return AdminDashboardHome(onNavigate: (menuId) {
          setState(() {
            _activeMenuId = menuId;
            _expandParentOfActive();
          });
        });
      case 'members_users':
        return const MemberManagementPage();
      case 'members_companies':
        return const AdminCompanyListPage();
      case 'document_types':
        return const DocumentTypeMasterPage();
      case 'equipment_types':
        return const EquipmentTypeSettingsPage();
      case 'personnel_types':
        return const PersonnelTypeSettingsPage();
      case 'bp_management':
        return const AdminBpManagementPage();
      case 'equipment_status':
        return const EquipmentStatusPage();
      case 'deployment':
        return const AdminDeploymentPage();
      case 'sites':
        return const SiteManagementPage();
      case 'quotations':
        return const QuotationManagementPage();
      case 'checklist':
        return const ChecklistManagementPage();
      case 'documents':
        return const AdminDocumentManagementPage();
      case 'inspection':
        return const AdminInspectionPage();
      case 'settlement':
        return const AdminSettlementPage();
      case 'statistics':
        return const AdminStatisticsPage();
      case 'notifications':
        return const AlertNotificationPage();
      case 'location':
        return const RealtimeLocationPage();
      case 'document_preview':
        return const DocumentPreviewPage();
      case 'verification':
        return const VerificationPage();
      default:
        return const AdminDashboardHome();
    }
  }

  String _getTitle() {
    switch (_activeMenuId) {
      case 'home':
        return '관리자 대시보드';
      case 'members_users':
        return '회원 관리 - 사용자 목록';
      case 'members_companies':
        return '회원 관리 - 회사 목록';
      case 'document_types':
        return '서류 유형 관리';
      case 'equipment_types':
        return '장비 유형 설정';
      case 'personnel_types':
        return '인력 유형 설정';
      case 'bp_management':
        return 'BP사 관리';
      case 'equipment_status':
        return '장비 현황';
      case 'deployment':
        return '투입 관리';
      case 'sites':
        return '현장 관리';
      case 'quotations':
        return '견적 관리';
      case 'checklist':
        return '투입 체크리스트';
      case 'documents':
        return '서류 관리';
      case 'inspection':
        return '안전점검';
      case 'settlement':
        return '정산';
      case 'statistics':
        return '통계';
      case 'notifications':
        return '알림/메시지';
      case 'location':
        return '실시간 위치';
      case 'document_preview':
        return '서류 미리보기';
      case 'verification':
        return '검증 관리';
      default:
        return '관리자 대시보드';
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
          // SKEP 로고
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
          // 메뉴
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: _menuItems
                  .expand((item) => _buildMenuWidgets(item))
                  .toList(),
            ),
          ),
          // 로그아웃
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
