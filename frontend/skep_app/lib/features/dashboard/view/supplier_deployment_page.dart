import 'package:flutter/material.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';

class SupplierDeploymentPage extends StatefulWidget {
  const SupplierDeploymentPage({Key? key}) : super(key: key);

  @override
  State<SupplierDeploymentPage> createState() => _SupplierDeploymentPageState();
}

class _SupplierDeploymentPageState extends State<SupplierDeploymentPage> {
  final List<Map<String, dynamic>> _deployments = [
    {
      'site': '강남 현장 A',
      'bp': '현대건설',
      'equipment': '25톤 크레인 (서울12가3456)',
      'operator': '김운전',
      'period': '2026-03-01 ~ 2026-06-30',
      'priceType': '주간일대',
      'status': '진행중',
      'docValid': true,
      'healthCheck': true,
      'safetyEdu': true,
      'preInspection': true,
    },
    {
      'site': '송파 현장 B',
      'bp': '삼성물산',
      'equipment': '50톤 크레인 (경기34나5678)',
      'operator': '이기사',
      'period': '2026-04-01 ~ 2026-07-31',
      'priceType': '주간O/T',
      'status': '요청중',
      'docValid': true,
      'healthCheck': true,
      'safetyEdu': false,
      'preInspection': true,
    },
    {
      'site': '분당 현장 C',
      'bp': 'GS건설',
      'equipment': '굴삭기 0.7m3 (인천56다7890)',
      'operator': '박기사',
      'period': '2026-02-01 ~ 2026-03-31',
      'priceType': '야간',
      'status': '종료',
      'docValid': true,
      'healthCheck': true,
      'safetyEdu': true,
      'preInspection': true,
    },
    {
      'site': '일산 현장 D',
      'bp': '대림산업',
      'equipment': '25톤 크레인 (서울12가3456)',
      'operator': '김운전',
      'period': '2026-05-01 ~ 2026-08-31',
      'priceType': '철야',
      'status': '승인',
      'docValid': true,
      'healthCheck': false,
      'safetyEdu': true,
      'preInspection': false,
    },
  ];

  final List<Map<String, String>> _equipmentOptions = [
    {'id': 'E001', 'name': '25톤 크레인 (서울12가3456)'},
    {'id': 'E002', 'name': '50톤 크레인 (경기34나5678)'},
    {'id': 'E003', 'name': '굴삭기 0.7m3 (인천56다7890)'},
  ];

  final List<Map<String, String>> _personnelOptions = [
    {'id': 'P001', 'name': '김운전'},
    {'id': 'P002', 'name': '이기사'},
    {'id': 'P003', 'name': '박기사'},
  ];

  Color _statusColor(String status) {
    switch (status) {
      case '진행중':
        return AppColors.success;
      case '요청중':
        return AppColors.warning;
      case '승인':
        return AppColors.info;
      case '종료':
        return AppColors.grey;
      default:
        return AppColors.grey;
    }
  }

  Widget _buildBadge(String label, bool ok) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: ok
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: ok ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }

  void _showDeploymentRequestDialog() {
    String site = '';
    String bp = '';
    String? selectedEquipment;
    String? selectedOperator;
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 90));
    final dayPriceCtrl = TextEditingController();
    final otPriceCtrl = TextEditingController();
    final earlyPriceCtrl = TextEditingController();
    final nightPriceCtrl = TextEditingController();
    final allNightPriceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('투입 요청'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: '현장명',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => site = v,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'BP사',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => bp = v,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: '장비 선택',
                      border: OutlineInputBorder(),
                    ),
                    items: _equipmentOptions
                        .map((e) => DropdownMenuItem(
                            value: e['id'], child: Text(e['name']!)))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedEquipment = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: '운전원 선택',
                      border: OutlineInputBorder(),
                    ),
                    items: _personnelOptions
                        .map((p) => DropdownMenuItem(
                            value: p['id'], child: Text(p['name']!)))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedOperator = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: startDate,
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2030),
                            );
                            if (d != null) {
                              setDialogState(() => startDate = d);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: '시작일',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: endDate,
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2030),
                            );
                            if (d != null) {
                              setDialogState(() => endDate = d);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: '종료일',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('단가 입력', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 8),
                  _buildPriceField('주간일대', dayPriceCtrl),
                  _buildPriceField('주간O/T', otPriceCtrl),
                  _buildPriceField('조출', earlyPriceCtrl),
                  _buildPriceField('야간', nightPriceCtrl),
                  _buildPriceField('철야', allNightPriceCtrl),
                ],
              ),
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
                  const SnackBar(content: Text('투입 요청이 전송되었습니다.')),
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
      ),
    );
  }

  Widget _buildPriceField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixText: '원',
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
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
                    Text('투입 현황', style: AppTextStyles.headlineLarge),
                    const SizedBox(height: 4),
                    Text(
                      '승인된 장비/인력의 투입을 관리합니다.',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showDeploymentRequestDialog,
                icon: const Icon(Icons.add),
                label: const Text('투입 요청'),
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
                  DataColumn(label: Text('현장명')),
                  DataColumn(label: Text('BP사')),
                  DataColumn(label: Text('장비')),
                  DataColumn(label: Text('운전원')),
                  DataColumn(label: Text('기간')),
                  DataColumn(label: Text('단가구분')),
                  DataColumn(label: Text('투입조건')),
                  DataColumn(label: Text('상태')),
                ],
                rows: _deployments
                    .map((d) => DataRow(cells: [
                          DataCell(Text(d['site'])),
                          DataCell(Text(d['bp'])),
                          DataCell(Text(d['equipment'])),
                          DataCell(Text(d['operator'])),
                          DataCell(Text(d['period'])),
                          DataCell(Text(d['priceType'])),
                          DataCell(Wrap(
                            children: [
                              _buildBadge('서류', d['docValid']),
                              _buildBadge('건강', d['healthCheck']),
                              _buildBadge('교육', d['safetyEdu']),
                              _buildBadge('점검', d['preInspection']),
                            ],
                          )),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(d['status'])
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              d['status'],
                              style: TextStyle(
                                color: _statusColor(d['status']),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
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
}
