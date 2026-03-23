import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';
import 'package:skep_app/features/auth/bloc/auth_bloc.dart';
import 'package:skep_app/features/auth/bloc/auth_event.dart';

/// 사이드바 메뉴 아이템 모델
class SidebarMenuItem {
  final String id;
  final IconData icon;
  final String label;
  final String? route;
  final List<SidebarMenuItem>? children;

  const SidebarMenuItem({
    required this.id,
    required this.icon,
    required this.label,
    this.route,
    this.children,
  });
}

/// 재사용 가능한 사이드바 + 콘텐츠 레이아웃 위젯
class SidebarLayout extends StatefulWidget {
  final String title;
  final String activeMenuId;
  final List<SidebarMenuItem> menuItems;
  final Widget body;

  const SidebarLayout({
    Key? key,
    required this.title,
    required this.activeMenuId,
    required this.menuItems,
    required this.body,
  }) : super(key: key);

  @override
  State<SidebarLayout> createState() => _SidebarLayoutState();
}

class _SidebarLayoutState extends State<SidebarLayout> {
  final Set<String> _expandedMenuIds = {};

  static const double _sidebarWidth = 260.0;
  static const double _mobileBreakpoint = 768.0;

  bool get _isMobile =>
      MediaQuery.of(context).size.width < _mobileBreakpoint;

  @override
  void initState() {
    super.initState();
    // 활성 메뉴가 하위 메뉴인 경우 부모를 자동 확장
    for (final item in widget.menuItems) {
      if (item.children != null) {
        for (final child in item.children!) {
          if (child.id == widget.activeMenuId) {
            _expandedMenuIds.add(item.id);
          }
        }
      }
    }
  }

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
    if (item.route != null) {
      context.go(item.route!);
      if (_isMobile) {
        Navigator.of(context).pop(); // drawer 닫기
      }
    }
  }

  void _handleLogout() {
    context.read<AuthBloc>().add(const AuthLogoutRequested());
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        drawer: Drawer(
          child: _buildSidebarContent(),
        ),
        body: widget.body,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: _sidebarWidth,
            child: _buildSidebarContent(),
          ),
          const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: widget.body),
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
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(widget.title, style: AppTextStyles.headlineMedium),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.greyDark),
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
          // 로고 헤더
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
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'S',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'SKEP',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF334155), height: 1),
          // 메뉴 아이템
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: widget.menuItems
                  .expand((item) => _buildMenuItemWidgets(item))
                  .toList(),
            ),
          ),
          // 로그아웃 버튼
          const Divider(color: Color(0xFF334155), height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFF94A3B8), size: 20),
            title: const Text(
              '로그아웃',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            ),
            dense: true,
            onTap: _handleLogout,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItemWidgets(SidebarMenuItem item) {
    final isActive = item.id == widget.activeMenuId;
    final hasChildren = item.children != null && item.children!.isNotEmpty;
    final isExpanded = _expandedMenuIds.contains(item.id);

    // 하위 메뉴 중 하나가 활성인지 확인
    final hasActiveChild = hasChildren &&
        item.children!.any((child) => child.id == widget.activeMenuId);

    final List<Widget> widgets = [];

    widgets.add(
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        decoration: BoxDecoration(
          color: (isActive || hasActiveChild)
              ? AppColors.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          dense: true,
          visualDensity: const VisualDensity(vertical: -2),
          leading: Icon(
            item.icon,
            color: (isActive || hasActiveChild)
                ? AppColors.primary
                : const Color(0xFF94A3B8),
            size: 20,
          ),
          title: Text(
            item.label,
            style: TextStyle(
              color: (isActive || hasActiveChild)
                  ? AppColors.primary
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
        final isChildActive = child.id == widget.activeMenuId;
        widgets.add(
          Container(
            margin: const EdgeInsets.only(left: 24, right: 8, top: 1, bottom: 1),
            decoration: BoxDecoration(
              color: isChildActive
                  ? AppColors.primary.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              dense: true,
              visualDensity: const VisualDensity(vertical: -3),
              leading: Icon(
                child.icon,
                color: isChildActive
                    ? AppColors.primary
                    : const Color(0xFF64748B),
                size: 16,
              ),
              title: Text(
                child.label,
                style: TextStyle(
                  color: isChildActive
                      ? AppColors.primary
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
