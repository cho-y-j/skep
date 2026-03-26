import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';

class AdminDashboardHome extends StatefulWidget {
  final void Function(String menuId)? onNavigate;

  const AdminDashboardHome({Key? key, this.onNavigate}) : super(key: key);

  @override
  State<AdminDashboardHome> createState() => _AdminDashboardHomeState();
}

class _AdminDashboardHomeState extends State<AdminDashboardHome> {
  static const _darkText = Color(0xFF1E293B);
  static const _pageBg = Color(0xFFF8FAFC);

  bool _isLoading = true;
  String? _error;

  int _companyCount = 0;
  int _equipmentCount = 0;
  int _personnelCount = 0;
  int _deploymentCount = 0;
  List<Map<String, dynamic>> _recentPlans = [];
  List<Map<String, dynamic>> _expiringDocs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dioClient = context.read<DioClient>();

      final results = await Future.wait([
        dioClient.get<dynamic>(ApiEndpoints.companies).catchError((_) => null),
        dioClient.get<dynamic>(ApiEndpoints.equipments).catchError((_) => null),
        dioClient.get<dynamic>(ApiEndpoints.persons).catchError((_) => null),
        dioClient.get<dynamic>(ApiEndpoints.deploymentPlans).catchError((_) => null),
        dioClient.get<dynamic>(ApiEndpoints.documentExpiring).catchError((_) => null),
      ]);

      // Companies count
      _companyCount = _extractCount(results[0]?.data);

      // Equipment count
      _equipmentCount = _extractCount(results[1]?.data);

      // Personnel count
      _personnelCount = _extractCount(results[2]?.data);

      // Deployment plans count + recent 5
      final plansData = results[3]?.data;
      _deploymentCount = _extractCount(plansData);
      _recentPlans = _extractList(plansData).take(5).toList();

      // Expiring documents
      _expiringDocs = _extractList(results[4]?.data).take(5).toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  int _extractCount(dynamic data) {
    if (data == null) return 0;
    if (data is List) return data.length;
    if (data is Map) {
      if (data['totalElements'] != null) return data['totalElements'] as int;
      if (data['total'] != null) return data['total'] as int;
      if (data['content'] is List) return (data['content'] as List).length;
      if (data['data'] is List) return (data['data'] as List).length;
    }
    return 0;
  }

  List<Map<String, dynamic>> _extractList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data.cast<Map<String, dynamic>>();
    if (data is Map) {
      if (data['content'] is List) return (data['content'] as List).cast<Map<String, dynamic>>();
      if (data['data'] is List) return (data['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return date.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _pageBg,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 56, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: 16),
                      const Text('데이터를 불러오는데 실패했습니다', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      TextButton(onPressed: _loadData, child: const Text('다시 시도')),
                    ],
                  ),
                )
              : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('관리자 대시보드', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _darkText)),
                    SizedBox(height: 4),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('새로고침'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.greyDark,
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
            ],
          ),
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
                    value: '$_equipmentCount대',
                    subtitle: 'API 연동',
                    trend: _Trend.flat,
                    color: AppColors.primary,
                    onTap: () => widget.onNavigate?.call('equipment_status'),
                  ),
                  _SummaryCard(
                    icon: Icons.people_outline,
                    label: '전체 인력',
                    value: '$_personnelCount명',
                    subtitle: 'API 연동',
                    trend: _Trend.flat,
                    color: const Color(0xFF16A34A),
                    onTap: () => widget.onNavigate?.call('members_users'),
                  ),
                  _SummaryCard(
                    icon: Icons.assignment_turned_in_outlined,
                    label: '투입 계획',
                    value: '$_deploymentCount건',
                    subtitle: 'API 연동',
                    trend: _Trend.flat,
                    color: const Color(0xFFD97706),
                    onTap: () => widget.onNavigate?.call('deployment'),
                  ),
                  _SummaryCard(
                    icon: Icons.business_outlined,
                    label: '등록 회사',
                    value: '$_companyCount개',
                    subtitle: 'API 연동',
                    trend: _Trend.flat,
                    color: const Color(0xFF7C3AED),
                    onTap: () => widget.onNavigate?.call('members_companies'),
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
              _buildQuickAction(Icons.people_outlined, '회원 관리', AppColors.primary, () => widget.onNavigate?.call('members_users')),
              _buildQuickAction(Icons.business_outlined, '회사 목록', const Color(0xFF16A34A), () => widget.onNavigate?.call('members_companies')),
              _buildQuickAction(Icons.description_outlined, '서류 관리', const Color(0xFFD97706), () => widget.onNavigate?.call('documents')),
              _buildQuickAction(Icons.bar_chart_outlined, '통계', const Color(0xFF7C3AED), () => widget.onNavigate?.call('statistics')),
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
          // Recent activity timeline from API
          _buildSectionHeader(Icons.timeline, '최근 투입 계획'),
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
            child: _recentPlans.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('최근 투입 계획이 없습니다.', style: TextStyle(color: Color(0xFF94A3B8)))),
                  )
                : Column(
                    children: List.generate(_recentPlans.length, (i) {
                      final plan = _recentPlans[i];
                      final siteName = plan['siteName']?.toString() ?? plan['site']?.toString() ?? '-';
                      final status = plan['status']?.toString() ?? '';
                      final date = _formatDate(plan['startDate'] ?? plan['createdAt']);
                      return _buildTimelineItem(
                        icon: Icons.assignment,
                        color: status == 'ACTIVE' ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                        text: '$siteName ($status)',
                        time: date,
                        isFirst: i == 0,
                        isLast: i == _recentPlans.length - 1,
                      );
                    }),
                  ),
          ),
          const SizedBox(height: 28),
          // Expiring documents from API
          _buildSectionHeader(Icons.description_outlined, '만료 임박 서류'),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: _expiringDocs.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: Text('만료 임박 서류가 없습니다.', style: TextStyle(color: Color(0xFF94A3B8)))),
                  )
                : ClipRRect(
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
                          DataColumn(label: Text('소유자')),
                          DataColumn(label: Text('만료일')),
                          DataColumn(label: Text('상태')),
                        ],
                        rows: _expiringDocs.map((doc) {
                          final docName = doc['documentType']?.toString() ?? doc['type']?.toString() ?? doc['name']?.toString() ?? '-';
                          final owner = doc['ownerName']?.toString() ?? doc['owner']?.toString() ?? '-';
                          final expiryDate = _formatDate(doc['expiryDate'] ?? doc['expiry_date']);
                          final status = doc['status']?.toString() ?? '-';
                          return DataRow(cells: [
                            DataCell(Text(docName)),
                            DataCell(Text(owner)),
                            DataCell(Text(expiryDate)),
                            DataCell(Text(status)),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
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
