import 'package:flutter/material.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';

class AdminInspectionPage extends StatefulWidget {
  const AdminInspectionPage({Key? key}) : super(key: key);

  @override
  State<AdminInspectionPage> createState() => _AdminInspectionPageState();
}

class _AdminInspectionPageState extends State<AdminInspectionPage> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  final int _totalEquipment = 12;
  final int _completedCount = 9;
  final int _issueCount = 2;

  final List<Map<String, dynamic>> _incompleteEquipments = [
    {
      'plateNo': '인천56다7890',
      'equipType': '굴삭기 0.7m3',
      'supplier': '삼성중장비',
      'site': '송파 현장 B',
    },
    {
      'plateNo': '부산78라1234',
      'equipType': '지게차 3톤',
      'supplier': '대한건기',
      'site': '용인 현장 F',
    },
    {
      'plateNo': '대전90마5678',
      'equipType': '펌프카 36m',
      'supplier': '(주)한국크레인',
      'site': '분당 현장 C',
    },
  ];

  final List<Map<String, dynamic>> _inspectionHistory = [
    {'date': '2026-03-22', 'total': 12, 'completed': 9, 'issues': 2},
    {'date': '2026-03-21', 'total': 12, 'completed': 12, 'issues': 1},
    {'date': '2026-03-20', 'total': 11, 'completed': 11, 'issues': 0},
    {'date': '2026-03-19', 'total': 11, 'completed': 10, 'issues': 3},
    {'date': '2026-03-18', 'total': 10, 'completed': 10, 'issues': 0},
  ];

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
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
          Text('안전점검', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 4),
          Text(
            '전체 안전점검 현황을 확인합니다.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: 24),
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
          // 날짜 선택
          Row(
            children: [
              Text('날짜: ', style: AppTextStyles.titleMedium),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );
                  if (d != null) setState(() => _selectedDate = d);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_formatDate(_selectedDate)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 미완료 장비 목록
          Text('미완료 장비', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
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
                  DataColumn(label: Text('차량번호')),
                  DataColumn(label: Text('장비유형')),
                  DataColumn(label: Text('공급사')),
                  DataColumn(label: Text('현장')),
                ],
                rows: _incompleteEquipments
                    .map((e) => DataRow(cells: [
                          DataCell(Text(e['plateNo'],
                              style: const TextStyle(color: AppColors.error))),
                          DataCell(Text(e['equipType'])),
                          DataCell(Text(e['supplier'])),
                          DataCell(Text(e['site'])),
                        ]))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // 날짜별 점검 이력
          Text('날짜별 점검 이력', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('날짜')),
                  DataColumn(label: Text('전체'), numeric: true),
                  DataColumn(label: Text('완료'), numeric: true),
                  DataColumn(label: Text('완료율')),
                  DataColumn(label: Text('이상건수'), numeric: true),
                ],
                rows: _inspectionHistory
                    .map((h) => DataRow(cells: [
                          DataCell(Text(h['date'])),
                          DataCell(Text('${h['total']}')),
                          DataCell(Text('${h['completed']}')),
                          DataCell(Text(
                            '${(h['completed'] / h['total'] * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: h['completed'] == h['total']
                                  ? AppColors.success
                                  : AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          )),
                          DataCell(Text(
                            '${h['issues']}',
                            style: TextStyle(
                              color: h['issues'] > 0
                                  ? AppColors.error
                                  : AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          )),
                        ]))
                    .toList(),
              ),
            ),
          ),
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
