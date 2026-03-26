import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/widgets/sidebar_layout.dart';
import 'package:skep_app/features/auth/bloc/auth_bloc.dart';
import 'package:skep_app/features/auth/bloc/auth_event.dart';
import 'package:skep_app/features/dashboard/view/company_employee_page.dart';
import 'package:skep_app/features/dashboard/view/supplier_equipment_page.dart';
import 'package:skep_app/features/dashboard/view/supplier_equipment_register_page.dart';
import 'package:skep_app/features/dashboard/view/supplier_personnel_page.dart';
import 'package:skep_app/features/dashboard/view/supplier_personnel_register_page.dart';
import 'package:skep_app/features/dashboard/view/supplier_document_management_page.dart';
import 'package:skep_app/features/dashboard/view/supplier_deployment_page.dart';
import 'package:skep_app/features/dashboard/view/matching_response_page.dart';
import 'package:skep_app/features/dashboard/view/attendance_page.dart';
import 'package:skep_app/features/dashboard/view/maintenance_check_page.dart';
import 'package:skep_app/features/dashboard/view/settlement_detail_page.dart';
import 'package:skep_app/features/dashboard/view/document_preview_page.dart';
import 'package:skep_app/features/dashboard/view/verification_page.dart';
import 'package:skep_app/features/dashboard/view/quotation_management_page.dart';
import 'package:skep_app/features/dashboard/view/placeholder_page.dart';

class SupplierDashboard extends StatefulWidget {
  const SupplierDashboard({Key? key}) : super(key: key);

  @override
  State<SupplierDashboard> createState() => _SupplierDashboardState();
}

class _SupplierDashboardState extends State<SupplierDashboard> {
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
      id: 'equipment_mgmt',
      icon: Icons.build_outlined,
      label: '장비 관리',
    ),
    SidebarMenuItem(
      id: 'equipment_reg',
      icon: Icons.add_circle_outline,
      label: '장비 등록',
    ),
    SidebarMenuItem(
      id: 'personnel_mgmt',
      icon: Icons.people_outlined,
      label: '인력 관리',
    ),
    SidebarMenuItem(
      id: 'personnel_reg',
      icon: Icons.person_add_outlined,
      label: '인력 등록',
    ),
    SidebarMenuItem(
      id: 'documents',
      icon: Icons.description_outlined,
      label: '서류 관리',
    ),
    SidebarMenuItem(
      id: 'deployment',
      icon: Icons.assignment_outlined,
      label: '투입 현황',
    ),
    SidebarMenuItem(
      id: 'matching_response',
      icon: Icons.notifications_active_outlined,
      label: '매칭 요청',
    ),
    SidebarMenuItem(
      id: 'attendance',
      icon: Icons.schedule_outlined,
      label: '출근 관리',
    ),
    SidebarMenuItem(
      id: 'maintenance',
      icon: Icons.engineering_outlined,
      label: '정비 점검',
    ),
    SidebarMenuItem(
      id: 'settlement',
      icon: Icons.receipt_long_outlined,
      label: '정산/거래명세서',
    ),
    SidebarMenuItem(
      id: 'quotations',
      icon: Icons.request_quote_outlined,
      label: '견적 관리',
    ),
    SidebarMenuItem(
      id: 'employees',
      icon: Icons.badge_outlined,
      label: '직원 관리',
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
        return _SupplierHome(onNavigate: (menuId) {
          setState(() => _activeMenuId = menuId);
        });
      case 'equipment_mgmt':
        return const SupplierEquipmentPage();
      case 'equipment_reg':
        return const SupplierEquipmentRegisterPage();
      case 'personnel_mgmt':
        return const SupplierPersonnelPage();
      case 'personnel_reg':
        return const SupplierPersonnelRegisterPage();
      case 'documents':
        return const SupplierDocumentManagementPage();
      case 'deployment':
        return const SupplierDeploymentPage();
      case 'matching_response':
        return const MatchingResponsePage();
      case 'attendance':
        return const AttendancePage();
      case 'maintenance':
        return const MaintenanceCheckPage();
      case 'settlement':
        return const SettlementDetailPage();
      case 'quotations':
        return const QuotationManagementPage();
      case 'employees':
        return const CompanyEmployeePage();
      case 'document_preview':
        return const DocumentPreviewPage();
      case 'verification':
        return const VerificationPage();
      default:
        return const _SupplierHome();
    }
  }

  String _getTitle() {
    switch (_activeMenuId) {
      case 'home':
        return '장비공급사 대시보드';
      case 'equipment_mgmt':
        return '장비 관리';
      case 'equipment_reg':
        return '장비 등록';
      case 'personnel_mgmt':
        return '인력 관리';
      case 'personnel_reg':
        return '인력 등록';
      case 'documents':
        return '서류 관리';
      case 'deployment':
        return '투입 현황';
      case 'matching_response':
        return '매칭 요청';
      case 'attendance':
        return '출근 관리';
      case 'maintenance':
        return '정비 점검';
      case 'settlement':
        return '정산/거래명세서';
      case 'quotations':
        return '견적 관리';
      case 'employees':
        return '직원 관리';
      case 'document_preview':
        return '서류 미리보기';
      case 'verification':
        return '검증 관리';
      default:
        return '장비공급사 대시보드';
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

/// 공급사 홈 페이지 콘텐츠
class _SupplierHome extends StatelessWidget {
  final void Function(String menuId)? onNavigate;
  const _SupplierHome({this.onNavigate});

  static const _darkText = Color(0xFF1E293B);
  static const _pageBg = Color(0xFFF8FAFC);
  static const _cardShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
  ];

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
            const Text(
              '장비공급사 대시보드',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _darkText),
            ),
            const SizedBox(height: 4),
            Text(
              '장비 및 인력 현황을 확인하세요.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            // Summary cards
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.6,
                  children: [
                    _buildClickableSummaryCard('내 장비', '${eqCount > 0 ? eqCount : 8}대', Icons.build_outlined, AppColors.primary, '가동 중 5대', () => onNavigate?.call('equipment_mgmt')),
                    _buildClickableSummaryCard('등록 인력', '${pCount > 0 ? pCount : 15}명', Icons.people_outlined, const Color(0xFF16A34A), '투입 가능 10명', () => onNavigate?.call('personnel_mgmt')),
                    _buildClickableSummaryCard('투입 중', '5건', Icons.assignment_outlined, const Color(0xFFD97706), '이번 주 +1건', () => onNavigate?.call('deployment')),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            // Equipment / Personnel quick status
            _buildSectionHeader(Icons.speed_outlined, '장비 / 인력 현황'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: _cardShadow,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 500) {
                    return Row(
                      children: [
                        Expanded(child: _buildStatusColumn('장비 현황', [
                          _StatusRow('가동 중', '5대', const Color(0xFF16A34A)),
                          _StatusRow('대기', '2대', const Color(0xFFD97706)),
                          _StatusRow('정비 중', '1대', const Color(0xFFDC2626)),
                        ])),
                        Container(width: 1, height: 80, color: const Color(0xFFE2E8F0)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildStatusColumn('인력 현황', [
                          _StatusRow('투입 중', '8명', const Color(0xFF16A34A)),
                          _StatusRow('대기', '5명', const Color(0xFFD97706)),
                          _StatusRow('교육 필요', '2명', const Color(0xFFDC2626)),
                        ])),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _buildStatusColumn('장비 현황', [
                        _StatusRow('가동 중', '5대', const Color(0xFF16A34A)),
                        _StatusRow('대기', '2대', const Color(0xFFD97706)),
                        _StatusRow('정비 중', '1대', const Color(0xFFDC2626)),
                      ]),
                      const Divider(height: 24, color: Color(0xFFE2E8F0)),
                      _buildStatusColumn('인력 현황', [
                        _StatusRow('투입 중', '8명', const Color(0xFF16A34A)),
                        _StatusRow('대기', '5명', const Color(0xFFD97706)),
                        _StatusRow('교육 필요', '2명', const Color(0xFFDC2626)),
                      ]),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
            // Quick action buttons
            _buildSectionHeader(Icons.flash_on_outlined, '빠른 실행'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildClickableQuickAction(Icons.add_circle_outline, '빠른 장비 등록', AppColors.primary, () => onNavigate?.call('equipment_reg')),
                _buildClickableQuickAction(Icons.person_add_outlined, '빠른 인력 등록', const Color(0xFF16A34A), () => onNavigate?.call('personnel_reg')),
                _buildClickableQuickAction(Icons.upload_file_outlined, '서류 업로드', const Color(0xFF7C3AED), () => onNavigate?.call('documents')),
              ],
            ),
            const SizedBox(height: 28),
            // Expiring documents
            _buildSectionHeader(Icons.warning_amber_outlined, '만료 임박 서류'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: _cardShadow,
              ),
              child: Column(
                children: [
                  _buildExpiryItem('보험증권 - 50톤 크레인', 'D-8', const Color(0xFFDC2626)),
                  const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),
                  _buildExpiryItem('건강검진결과 - 김운전', 'D-3', const Color(0xFFDC2626)),
                  const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),
                  _buildExpiryItem('건설기계등록증 - 25톤 크레인', 'D-14', const Color(0xFFD97706)),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Recent activity
            _buildSectionHeader(Icons.history, '최근 활동'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: _cardShadow,
              ),
              child: Column(
                children: [
                  _buildActivityItem(Icons.build, AppColors.primary, '25톤 크레인 장비 등록 완료', '2026-03-20'),
                  const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),
                  _buildActivityItem(Icons.person_add, const Color(0xFF16A34A), '김운전 인력 등록 완료', '2026-03-19'),
                  const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),
                  _buildActivityItem(Icons.assignment, const Color(0xFFD97706), '강남 현장 A 투입 승인됨', '2026-03-18'),
                ],
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

  static Widget _buildStatusColumn(String title, List<_StatusRow> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _darkText)),
        const SizedBox(height: 12),
        ...rows.map((row) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: row.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(row.label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              const Spacer(),
              Text(row.value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: row.color)),
            ],
          ),
        )),
      ],
    );
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

  static Widget _buildExpiryItem(String text, String dDay, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.warning_amber, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14, color: _darkText)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              dDay,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildActivityItem(IconData icon, Color color, String text, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14, color: _darkText)),
          ),
          Text(date, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

class _StatusRow {
  final String label;
  final String value;
  final Color color;
  const _StatusRow(this.label, this.value, this.color);
}
