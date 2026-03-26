import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';

class AdminInspectionPage extends StatefulWidget {
  const AdminInspectionPage({Key? key}) : super(key: key);

  @override
  State<AdminInspectionPage> createState() => _AdminInspectionPageState();
}

class _AdminInspectionPageState extends State<AdminInspectionPage> {
  late DateTime _selectedDate;
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _inspections = [];
  int _totalEquipment = 0;
  int _completedCount = 0;
  int _issueCount = 0;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dioClient = context.read<DioClient>();
      final response = await dioClient.get<dynamic>(ApiEndpoints.safetyInspections);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List) {
          _inspections = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['content'] is List) {
          _inspections = (data['content'] as List).cast<Map<String, dynamic>>();
        } else if (data is Map && data['data'] is List) {
          _inspections = (data['data'] as List).cast<Map<String, dynamic>>();
        } else {
          _inspections = [];
        }
      }
      _totalEquipment = _inspections.length;
      _completedCount = _inspections.where((i) {
        final status = (i['status'] ?? '').toString();
        return status == 'COMPLETED' || status == 'completed';
      }).length;
      _issueCount = _inspections.where((i) {
        final hasIssue = i['hasIssue'] ?? i['issueFound'] ?? false;
        return hasIssue == true;
      }).length;
    } catch (e) {
      _error = e.toString();
      _inspections = [];
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _formatApiDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = DateTime.parse(date.toString());
      return _formatDate(dt);
    } catch (_) {
      return date.toString();
    }
  }

  List<Map<String, dynamic>> get _incompleteInspections {
    return _inspections.where((i) {
      final status = (i['status'] ?? '').toString();
      return status != 'COMPLETED' && status != 'completed';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final completionRate = _totalEquipment > 0
        ? (_completedCount / _totalEquipment * 100).toStringAsFixed(0)
        : '0';

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
                    Text('안전점검', style: AppTextStyles.headlineLarge),
                    const SizedBox(height: 4),
                    Text(
                      '전체 안전점검 현황을 확인합니다.',
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
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Column(
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
              ),
            )
          else ...[
            // 요약 카드
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
                    _buildCard('점검 완료율', '$completionRate%',
                        Icons.pie_chart_outline, AppColors.primary),
                    _buildCard('점검 완료', '$_completedCount건',
                        Icons.check_circle_outline, AppColors.success),
                    _buildCard('미완료', '${_totalEquipment - _completedCount}건',
                        Icons.cancel_outlined, AppColors.error),
                    _buildCard('이상 발견', '$_issueCount건',
                        Icons.warning_amber_outlined, AppColors.warning),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            // 미완료 장비 목록
            Text('미완료 점검 (${_incompleteInspections.length}건)', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            if (_incompleteInspections.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('모든 점검이 완료되었습니다.', style: TextStyle(color: Color(0xFF94A3B8)))),
              )
            else
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('장비')),
                      DataColumn(label: Text('점검자')),
                      DataColumn(label: Text('상태')),
                      DataColumn(label: Text('날짜')),
                    ],
                    rows: _incompleteInspections.map((e) => DataRow(cells: [
                      DataCell(Text(
                        e['equipmentName']?.toString() ?? e['equipmentId']?.toString() ?? '-',
                        style: const TextStyle(color: AppColors.error),
                      )),
                      DataCell(Text(e['inspectorName']?.toString() ?? e['inspector']?.toString() ?? '-')),
                      DataCell(Text(e['status']?.toString() ?? '-')),
                      DataCell(Text(_formatApiDate(e['inspectionDate'] ?? e['createdAt']))),
                    ])).toList(),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // 전체 점검 이력
            Text('전체 점검 이력 (${_inspections.length}건)', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _inspections.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('점검 이력이 없습니다.', style: TextStyle(color: Color(0xFF94A3B8)))),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('날짜')),
                          DataColumn(label: Text('장비')),
                          DataColumn(label: Text('점검자')),
                          DataColumn(label: Text('상태')),
                          DataColumn(label: Text('이상')),
                        ],
                        rows: _inspections.map((h) {
                          final status = (h['status'] ?? '').toString();
                          final isCompleted = status == 'COMPLETED' || status == 'completed';
                          final hasIssue = h['hasIssue'] == true || h['issueFound'] == true;
                          return DataRow(cells: [
                            DataCell(Text(_formatApiDate(h['inspectionDate'] ?? h['createdAt']))),
                            DataCell(Text(h['equipmentName']?.toString() ?? h['equipmentId']?.toString() ?? '-')),
                            DataCell(Text(h['inspectorName']?.toString() ?? h['inspector']?.toString() ?? '-')),
                            DataCell(Text(
                              isCompleted ? '완료' : status,
                              style: TextStyle(
                                color: isCompleted ? AppColors.success : AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            )),
                            DataCell(Text(
                              hasIssue ? '이상' : '정상',
                              style: TextStyle(
                                color: hasIssue ? AppColors.error : AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard(String label, String value, IconData icon, Color color) {
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
