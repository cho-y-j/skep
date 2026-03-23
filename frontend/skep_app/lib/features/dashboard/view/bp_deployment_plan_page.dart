import 'package:flutter/material.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';

class BpDeploymentPlanPage extends StatefulWidget {
  const BpDeploymentPlanPage({Key? key}) : super(key: key);

  @override
  State<BpDeploymentPlanPage> createState() => _BpDeploymentPlanPageState();
}

class _BpDeploymentPlanPageState extends State<BpDeploymentPlanPage> {
  final List<Map<String, dynamic>> _receivedRequests = [
    {
      'supplier': '(주)한국크레인',
      'equipType': '25톤 크레인',
      'plateNo': '서울12가3456',
      'operator': '김운전',
      'period': '2026-04-01 ~ 2026-06-30',
      'status': '대기',
    },
    {
      'supplier': '삼성중장비',
      'equipType': '50톤 크레인',
      'plateNo': '경기34나5678',
      'operator': '이기사',
      'period': '2026-04-15 ~ 2026-07-31',
      'status': '대기',
    },
    {
      'supplier': '(주)한국크레인',
      'equipType': '굴삭기 0.7m3',
      'plateNo': '인천56다7890',
      'operator': '박기사',
      'period': '2026-03-01 ~ 2026-05-31',
      'status': '승인',
    },
    {
      'supplier': '대한건기',
      'equipType': '지게차 3톤',
      'plateNo': '부산78라1234',
      'operator': '최운전',
      'period': '2026-03-10 ~ 2026-04-30',
      'status': '반려',
    },
  ];

  Color _statusColor(String status) {
    switch (status) {
      case '승인':
        return AppColors.success;
      case '대기':
        return AppColors.warning;
      case '반려':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }

  void _approveRequest(int index) {
    setState(() {
      _receivedRequests[index]['status'] = '승인';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('투입 요청이 승인되었습니다.')),
    );
  }

  void _rejectRequest(int index) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('반려 사유 입력'),
        content: TextFormField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '반려 사유를 입력하세요',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _receivedRequests[index]['status'] = '반려';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('투입 요청이 반려되었습니다.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('반려'),
          ),
        ],
      ),
    );
  }

  void _showEquipmentRequestDialog() {
    String equipType = '';
    String qty = '';
    String period = '';
    String location = '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('장비 요청'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '장비 유형',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => equipType = v,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '수량',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => qty = v,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '기간 (예: 2026-04-01 ~ 2026-06-30)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => period = v,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '현장 위치',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => location = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('장비 요청이 전송되었습니다.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('요청'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    Text('투입 계획', style: AppTextStyles.headlineLarge),
                    const SizedBox(height: 4),
                    Text(
                      '공급사 투입 요청을 승인하고, 장비를 요청합니다.',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showEquipmentRequestDialog,
                icon: const Icon(Icons.add),
                label: const Text('장비 요청'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('수신된 투입 요청', style: AppTextStyles.headlineSmall),
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
                  DataColumn(label: Text('공급사명')),
                  DataColumn(label: Text('장비유형')),
                  DataColumn(label: Text('차량번호')),
                  DataColumn(label: Text('운전원')),
                  DataColumn(label: Text('기간')),
                  DataColumn(label: Text('상태')),
                  DataColumn(label: Text('작업')),
                ],
                rows: List.generate(_receivedRequests.length, (i) {
                  final r = _receivedRequests[i];
                  return DataRow(cells: [
                    DataCell(Text(r['supplier'])),
                    DataCell(Text(r['equipType'])),
                    DataCell(Text(r['plateNo'])),
                    DataCell(Text(r['operator'])),
                    DataCell(Text(r['period'])),
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
                                onPressed: () => _approveRequest(i),
                                style: TextButton.styleFrom(
                                    foregroundColor: AppColors.success),
                                child: const Text('승인'),
                              ),
                              TextButton(
                                onPressed: () => _rejectRequest(i),
                                style: TextButton.styleFrom(
                                    foregroundColor: AppColors.error),
                                child: const Text('반려'),
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
