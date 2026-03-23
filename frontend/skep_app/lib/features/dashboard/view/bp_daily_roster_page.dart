import 'package:flutter/material.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';

class BpDailyRosterPage extends StatefulWidget {
  const BpDailyRosterPage({Key? key}) : super(key: key);

  @override
  State<BpDailyRosterPage> createState() => _BpDailyRosterPageState();
}

class _BpDailyRosterPageState extends State<BpDailyRosterPage> {
  late DateTime _selectedDate;

  final List<Map<String, dynamic>> _roster = [
    {
      'equipType': '25톤 크레인',
      'plateNo': '서울12가3456',
      'operator': '김운전',
      'guide': '박유도',
      'status': '대기',
    },
    {
      'equipType': '50톤 크레인',
      'plateNo': '경기34나5678',
      'operator': '이기사',
      'guide': '최유도',
      'status': '승인',
    },
    {
      'equipType': '굴삭기 0.7m3',
      'plateNo': '인천56다7890',
      'operator': '박기사',
      'guide': '김유도',
      'status': '대기',
    },
    {
      'equipType': '지게차 3톤',
      'plateNo': '부산78라1234',
      'operator': '최운전',
      'guide': '-',
      'status': '교체',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
  }

  Color _statusColor(String status) {
    switch (status) {
      case '승인':
        return AppColors.success;
      case '대기':
        return AppColors.warning;
      case '교체':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void _approveAll() {
    setState(() {
      for (final r in _roster) {
        if (r['status'] == '대기') {
          r['status'] = '승인';
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('전체 승인되었습니다.')),
    );
  }

  void _keepPrevious() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('이전 명단이 유지됩니다.')),
    );
  }

  void _approveOne(int index) {
    setState(() {
      _roster[index]['status'] = '승인';
    });
  }

  void _requestReplacement(int index) {
    setState(() {
      _roster[index]['status'] = '교체';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('교체 요청이 전송되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('일일 작업자 명단', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 4),
          Text(
            '익일 작업자 명단을 확인하고 승인합니다.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: 24),
          // 날짜 선택 + 버튼
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text('날짜: ', style: AppTextStyles.titleMedium),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) {
                      setState(() => _selectedDate = d);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_formatDate(_selectedDate),
                        style: AppTextStyles.bodyMedium),
                  ),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: _keepPrevious,
                  child: const Text('이전 명단 유지'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _approveAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('전체 승인'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 명단 테이블
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
                  DataColumn(label: Text('장비유형')),
                  DataColumn(label: Text('차량번호')),
                  DataColumn(label: Text('운전원')),
                  DataColumn(label: Text('유도원')),
                  DataColumn(label: Text('상태')),
                  DataColumn(label: Text('작업')),
                ],
                rows: List.generate(_roster.length, (i) {
                  final r = _roster[i];
                  return DataRow(cells: [
                    DataCell(Text(r['equipType'])),
                    DataCell(Text(r['plateNo'])),
                    DataCell(Text(r['operator'])),
                    DataCell(Text(r['guide'])),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(r['status']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        r['status'],
                        style: TextStyle(
                          color: _statusColor(r['status']),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )),
                    DataCell(r['status'] == '대기'
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () => _approveOne(i),
                                style: TextButton.styleFrom(
                                    foregroundColor: AppColors.success),
                                child: const Text('승인'),
                              ),
                              TextButton(
                                onPressed: () => _requestReplacement(i),
                                style: TextButton.styleFrom(
                                    foregroundColor: AppColors.error),
                                child: const Text('교체요청'),
                              ),
                            ],
                          )
                        : const Text('-')),
                  ]);
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
