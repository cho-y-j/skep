import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/network/dio_client.dart';
import 'package:skep_app/features/auth/bloc/auth_bloc.dart';
import 'package:skep_app/features/auth/bloc/auth_event.dart';
import 'package:skep_app/features/auth/bloc/auth_state.dart';
import 'package:skep_app/features/dashboard/view/attendance_page.dart';
import 'package:skep_app/features/dashboard/view/work_confirmation_page.dart';
import 'package:skep_app/features/dashboard/view/safety_inspection_page.dart';
import 'package:skep_app/features/dashboard/view/maintenance_check_page.dart';
import 'package:skep_app/features/dashboard/view/realtime_location_page.dart';

class WorkerDashboard extends StatefulWidget {
  const WorkerDashboard({Key? key}) : super(key: key);

  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {
  String _selectedMenu = 'home';

  String get _userRole {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) return authState.user.role;
    return 'DRIVER';
  }

  String get _userName {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) return authState.user.name;
    return '';
  }

  List<_MenuItem> get _menuItems {
    final role = _userRole;
    final items = <_MenuItem>[
      const _MenuItem(id: 'home', label: '대시보드', icon: Icons.home),
      const _MenuItem(id: 'attendance', label: '출근 관리', icon: Icons.access_time),
    ];

    if (role == 'DRIVER' || role == 'GUIDE') {
      items.add(const _MenuItem(id: 'work_confirm', label: '작업확인서', icon: Icons.assignment_turned_in));
    }
    if (role == 'SAFETY_INSPECTOR') {
      items.add(const _MenuItem(id: 'safety_inspection', label: '안전점검', icon: Icons.safety_check));
      items.add(const _MenuItem(id: 'maintenance', label: '정비 점검', icon: Icons.build));
    }
    if (role == 'SITE_OWNER') {
      items.add(const _MenuItem(id: 'location', label: '실시간 위치', icon: Icons.map));
    }

    return items;
  }

  String _getTitle() {
    switch (_selectedMenu) {
      case 'home': return '대시보드';
      case 'attendance': return '출근 관리';
      case 'work_confirm': return '작업확인서';
      case 'safety_inspection': return '안전점검';
      case 'maintenance': return '정비 점검';
      case 'location': return '실시간 위치';
      default: return '대시보드';
    }
  }

  Widget _buildBody() {
    switch (_selectedMenu) {
      case 'home': return _buildHome();
      case 'attendance': return const AttendancePage();
      case 'work_confirm': return const WorkConfirmationPage();
      case 'safety_inspection': return const SafetyInspectionPage();
      case 'maintenance': return const MaintenanceCheckPage();
      case 'location': return const RealtimeLocationPage();
      default: return _buildHome();
    }
  }

  Widget _buildHome() {
    final role = _userRole;
    String roleLabel;
    switch (role) {
      case 'DRIVER': roleLabel = '운전원'; break;
      case 'GUIDE': roleLabel = '안내원'; break;
      case 'SAFETY_INSPECTOR': roleLabel = '안전점검원'; break;
      case 'SITE_OWNER': roleLabel = '현장소장'; break;
      default: roleLabel = role;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          Text('안녕하세요, $_userName님', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('$roleLabel 대시보드', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          const SizedBox(height: 32),
          Text('왼쪽 메뉴에서 기능을 선택하세요', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 240,
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(child: Text('S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                      ),
                      const SizedBox(width: 12),
                      const Text('SKEP', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF334155), height: 1),
                // Menu items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: _menuItems.map((item) {
                      final selected = _selectedMenu == item.id;
                      return ListTile(
                        leading: Icon(item.icon, color: selected ? Colors.white : const Color(0xFF94A3B8), size: 20),
                        title: Text(item.label, style: TextStyle(color: selected ? Colors.white : const Color(0xFF94A3B8), fontSize: 14)),
                        selected: selected,
                        selectedTileColor: AppColors.primary.withOpacity(0.2),
                        onTap: () => setState(() => _selectedMenu = item.id),
                      );
                    }).toList(),
                  ),
                ),
                // Logout
                const Divider(color: Color(0xFF334155), height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Color(0xFF94A3B8), size: 20),
                  title: const Text('로그아웃', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                  onTap: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    children: [
                      Text(_getTitle(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(_userName, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    ],
                  ),
                ),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final String id;
  final String label;
  final IconData icon;
  const _MenuItem({required this.id, required this.label, required this.icon});
}
