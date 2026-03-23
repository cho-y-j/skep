import 'package:flutter/material.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';

class BpSettlementPage extends StatefulWidget {
  const BpSettlementPage({Key? key}) : super(key: key);

  @override
  State<BpSettlementPage> createState() => _BpSettlementPageState();
}

class _BpSettlementPageState extends State<BpSettlementPage> {
  int? _expandedSupplierIndex;

  final List<Map<String, dynamic>> _supplierSettlements = [
    {
      'supplier': '(주)한국크레인',
      'equipCount': 2,
      'days': 45,
      'amount': 67500000,
      'tax': 6750000,
      'total': 74250000,
      'payStatus': '지급완료',
      'daily': [
        {'date': '2026-03-01', 'equip': '25톤 크레인', 'day': 8, 'ot': 2, 'night': 0, 'allNight': 0, 'amount': 1500000},
        {'date': '2026-03-02', 'equip': '25톤 크레인', 'day': 8, 'ot': 0, 'night': 4, 'allNight': 0, 'amount': 1800000},
        {'date': '2026-03-03', 'equip': '50톤 크레인', 'day': 8, 'ot': 3, 'night': 0, 'allNight': 0, 'amount': 2200000},
        {'date': '2026-03-04', 'equip': '25톤 크레인', 'day': 8, 'ot': 0, 'night': 0, 'allNight': 12, 'amount': 2500000},
      ],
    },
    {
      'supplier': '삼성중장비',
      'equipCount': 1,
      'days': 20,
      'amount': 30000000,
      'tax': 3000000,
      'total': 33000000,
      'payStatus': '미지급',
      'daily': [
        {'date': '2026-03-01', 'equip': '굴삭기 0.7m3', 'day': 8, 'ot': 1, 'night': 0, 'allNight': 0, 'amount': 1200000},
        {'date': '2026-03-02', 'equip': '굴삭기 0.7m3', 'day': 8, 'ot': 0, 'night': 0, 'allNight': 0, 'amount': 1000000},
      ],
    },
    {
      'supplier': '대한건기',
      'equipCount': 1,
      'days': 15,
      'amount': 15000000,
      'tax': 1500000,
      'total': 16500000,
      'payStatus': '지급중',
      'daily': [
        {'date': '2026-03-01', 'equip': '지게차 3톤', 'day': 8, 'ot': 0, 'night': 0, 'allNight': 0, 'amount': 800000},
      ],
    },
  ];

  String _formatMoney(num amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write(',');
      }
    }
    return buffer.toString().split('').reversed.join();
  }

  Color _payStatusColor(String status) {
    switch (status) {
      case '지급완료':
        return AppColors.success;
      case '미지급':
        return AppColors.error;
      case '지급중':
        return AppColors.warning;
      default:
        return AppColors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _supplierSettlements.fold<num>(
        0, (sum, s) => sum + (s['total'] as num));
    final paidAmount = _supplierSettlements
        .where((s) => s['payStatus'] == '지급완료')
        .fold<num>(0, (sum, s) => sum + (s['total'] as num));
    final unpaidAmount = totalAmount - paidAmount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('정산 현황', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 4),
          Text(
            '월별 정산 내역을 확인합니다.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: 24),
          // 요약 카드
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 3 : 1;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 2.5,
                children: [
                  _buildSummaryCard(
                    '총 투입액',
                    '${_formatMoney(totalAmount)}원',
                    AppColors.primary,
                    Icons.account_balance_wallet_outlined,
                  ),
                  _buildSummaryCard(
                    '정산 완료',
                    '${_formatMoney(paidAmount)}원',
                    AppColors.success,
                    Icons.check_circle_outline,
                  ),
                  _buildSummaryCard(
                    '미정산',
                    '${_formatMoney(unpaidAmount)}원',
                    AppColors.error,
                    Icons.pending_outlined,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text('공급사별 정산', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          // 공급사별 정산 테이블
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
                  DataColumn(label: Text('장비수'), numeric: true),
                  DataColumn(label: Text('투입일수'), numeric: true),
                  DataColumn(label: Text('금액'), numeric: true),
                  DataColumn(label: Text('세액'), numeric: true),
                  DataColumn(label: Text('합계'), numeric: true),
                  DataColumn(label: Text('지급상태')),
                  DataColumn(label: Text('상세')),
                ],
                rows: List.generate(_supplierSettlements.length, (i) {
                  final s = _supplierSettlements[i];
                  return DataRow(cells: [
                    DataCell(Text(s['supplier'])),
                    DataCell(Text('${s['equipCount']}')),
                    DataCell(Text('${s['days']}일')),
                    DataCell(Text('${_formatMoney(s['amount'])}원')),
                    DataCell(Text('${_formatMoney(s['tax'])}원')),
                    DataCell(Text('${_formatMoney(s['total'])}원')),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _payStatusColor(s['payStatus'])
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        s['payStatus'],
                        style: TextStyle(
                          color: _payStatusColor(s['payStatus']),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )),
                    DataCell(IconButton(
                      icon: Icon(
                        _expandedSupplierIndex == i
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _expandedSupplierIndex =
                              _expandedSupplierIndex == i ? null : i;
                        });
                      },
                    )),
                  ]);
                }),
              ),
            ),
          ),
          // 상세 일별 내역
          if (_expandedSupplierIndex != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_supplierSettlements[_expandedSupplierIndex!]['supplier']} - 일별 상세 내역',
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('날짜')),
                        DataColumn(label: Text('장비')),
                        DataColumn(label: Text('주간(h)'), numeric: true),
                        DataColumn(label: Text('O/T(h)'), numeric: true),
                        DataColumn(label: Text('야간(h)'), numeric: true),
                        DataColumn(label: Text('철야(h)'), numeric: true),
                        DataColumn(label: Text('금액'), numeric: true),
                      ],
                      rows: (_supplierSettlements[_expandedSupplierIndex!]
                              ['daily'] as List<Map<String, dynamic>>)
                          .map((d) => DataRow(cells: [
                                DataCell(Text(d['date'])),
                                DataCell(Text(d['equip'])),
                                DataCell(Text('${d['day']}')),
                                DataCell(Text('${d['ot']}')),
                                DataCell(Text('${d['night']}')),
                                DataCell(Text('${d['allNight']}')),
                                DataCell(
                                    Text('${_formatMoney(d['amount'])}원')),
                              ]))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey)),
                const SizedBox(height: 4),
                Text(value,
                    style: AppTextStyles.titleLarge.copyWith(color: color),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
