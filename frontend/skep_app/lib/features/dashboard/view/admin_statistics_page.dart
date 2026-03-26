import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';

class AdminStatisticsPage extends StatefulWidget {
  const AdminStatisticsPage({Key? key}) : super(key: key);

  @override
  State<AdminStatisticsPage> createState() => _AdminStatisticsPageState();
}

class _AdminStatisticsPageState extends State<AdminStatisticsPage> {
  bool _isLoading = true;
  String? _error;

  int _equipmentTotal = 0;
  int _personnelTotal = 0;
  int _companyTotal = 0;
  List<Map<String, dynamic>> _equipments = [];
  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _settlements = [];

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
        dioClient.get<dynamic>(ApiEndpoints.equipments).catchError((_) => null),
        dioClient.get<dynamic>(ApiEndpoints.persons).catchError((_) => null),
        dioClient.get<dynamic>(ApiEndpoints.companies).catchError((_) => null),
        dioClient.get<dynamic>(ApiEndpoints.settlements).catchError((_) => null),
      ]);

      // Equipment
      _equipments = _extractList(results[0]?.data);
      _equipmentTotal = _equipments.length;

      // Personnel
      final personnelList = _extractList(results[1]?.data);
      _personnelTotal = personnelList.length;

      // Companies
      _companies = _extractList(results[2]?.data);
      _companyTotal = _companies.length;

      // Settlements
      _settlements = _extractList(results[3]?.data);
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
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

  int _countByStatus(List<Map<String, dynamic>> list, String status) {
    return list.where((item) {
      final s = (item['status'] ?? '').toString();
      return s == status;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
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
      );
    }

    final activeEquip = _countByStatus(_equipments, 'ACTIVE');
    final idleEquip = _countByStatus(_equipments, 'IDLE');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('통계', style: AppTextStyles.headlineLarge),
                    const SizedBox(height: 4),
                    Text(
                      '전체 플랫폼 통계를 확인합니다.',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
                    ),
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
          const SizedBox(height: 24),
          // 전체 현황 카드
          Text('전체 현황', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 2.0,
                children: [
                  _buildStatCard('등록 장비', '$_equipmentTotal대', Icons.build_circle_outlined, AppColors.primary),
                  _buildStatCard('등록 인력', '$_personnelTotal명', Icons.people_outline, AppColors.success),
                  _buildStatCard('등록 회사', '$_companyTotal개', Icons.business_outlined, AppColors.info),
                  _buildStatCard('정산 건수', '${_settlements.length}건', Icons.payments_outlined, AppColors.warning),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          // 장비 상태별 현황
          Text('장비 상태별 현황', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 2.0,
                children: [
                  _buildStatCard('전체', '$_equipmentTotal대', Icons.app_registration, AppColors.primary),
                  _buildStatCard('가동중', '$activeEquip대', Icons.engineering, AppColors.success),
                  _buildStatCard('대기', '$idleEquip대', Icons.hourglass_empty, AppColors.warning),
                  _buildStatCard('기타', '${_equipmentTotal - activeEquip - idleEquip}대', Icons.more_horiz, AppColors.grey),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          // 회사 목록
          Text('등록 회사 ($_companyTotal개)', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _companies.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('등록된 회사가 없습니다.', style: TextStyle(color: Color(0xFF94A3B8)))),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('회사명')),
                        DataColumn(label: Text('유형')),
                        DataColumn(label: Text('상태')),
                      ],
                      rows: _companies.take(10).map((c) {
                        final name = c['name']?.toString() ?? c['companyName']?.toString() ?? '-';
                        final type = c['type']?.toString() ?? c['companyType']?.toString() ?? '-';
                        final status = c['status']?.toString() ?? '-';
                        return DataRow(cells: [
                          DataCell(Text(name)),
                          DataCell(Text(type)),
                          DataCell(Text(status)),
                        ]);
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          // 정산 현황
          Text('정산 현황 (${_settlements.length}건)', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _settlements.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('정산 데이터가 없습니다.', style: TextStyle(color: Color(0xFF94A3B8)))),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('정산명')),
                        DataColumn(label: Text('기간')),
                        DataColumn(label: Text('금액')),
                        DataColumn(label: Text('상태')),
                      ],
                      rows: _settlements.take(10).map((s) {
                        return DataRow(cells: [
                          DataCell(Text(s['name']?.toString() ?? s['title']?.toString() ?? '-')),
                          DataCell(Text(s['period']?.toString() ?? s['month']?.toString() ?? '-')),
                          DataCell(Text(s['totalAmount']?.toString() ?? s['amount']?.toString() ?? '-')),
                          DataCell(Text(s['status']?.toString() ?? '-')),
                        ]);
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: AppTextStyles.displaySmall.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey)),
        ],
      ),
    );
  }
}
