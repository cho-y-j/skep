import 'package:flutter/material.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';

class AdminSettlementPage extends StatefulWidget {
  const AdminSettlementPage({Key? key}) : super(key: key);

  @override
  State<AdminSettlementPage> createState() => _AdminSettlementPageState();
}

class _AdminSettlementPageState extends State<AdminSettlementPage> {
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('정산', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 4),
          Text(
            '전체 정산 현황을 확인합니다.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: 24),
          // 월간 거래 합계 카드
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
                    '월간 총 거래액',
                    '${_formatMoney(123750000)}원',
                    AppColors.primary,
                    Icons.account_balance_outlined,
                  ),
                  _buildSummaryCard(
                    '지급 완료',
                    '${_formatMoney(74250000)}원',
                    AppColors.success,
                    Icons.check_circle_outline,
                  ),
                  _buildSummaryCard(
                    '미지급',
                    '${_formatMoney(49500000)}원',
                    AppColors.error,
                    Icons.pending_outlined,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          // 공급사 x BP사 정산 매트릭스
          Text('공급사 x BP사 정산 매트릭스', style: AppTextStyles.headlineSmall),
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
                  DataColumn(label: Text('공급사 \\ BP사')),
                  DataColumn(label: Text('현대건설'), numeric: true),
                  DataColumn(label: Text('삼성물산'), numeric: true),
                  DataColumn(label: Text('GS건설'), numeric: true),
                  DataColumn(label: Text('합계'), numeric: true),
                ],
                rows: [
                  DataRow(cells: [
                    const DataCell(Text('(주)한국크레인')),
                    DataCell(Text('${_formatMoney(45000000)}원')),
                    DataCell(Text('${_formatMoney(29250000)}원')),
                    const DataCell(Text('-')),
                    DataCell(Text('${_formatMoney(74250000)}원')),
                  ]),
                  DataRow(cells: [
                    const DataCell(Text('삼성중장비')),
                    DataCell(Text('${_formatMoney(33000000)}원')),
                    const DataCell(Text('-')),
                    const DataCell(Text('-')),
                    DataCell(Text('${_formatMoney(33000000)}원')),
                  ]),
                  DataRow(cells: [
                    const DataCell(Text('대한건기')),
                    const DataCell(Text('-')),
                    const DataCell(Text('-')),
                    DataCell(Text('${_formatMoney(16500000)}원')),
                    DataCell(Text('${_formatMoney(16500000)}원')),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // BP사별 결제 현황
          Text('BP사별 결제 현황', style: AppTextStyles.headlineSmall),
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
                  DataColumn(label: Text('BP사')),
                  DataColumn(label: Text('공급사수'), numeric: true),
                  DataColumn(label: Text('총 거래액'), numeric: true),
                  DataColumn(label: Text('지급완료'), numeric: true),
                  DataColumn(label: Text('미지급'), numeric: true),
                  DataColumn(label: Text('결제율')),
                ],
                rows: [
                  DataRow(cells: [
                    const DataCell(Text('현대건설')),
                    const DataCell(Text('2')),
                    DataCell(Text('${_formatMoney(78000000)}원')),
                    DataCell(Text('${_formatMoney(45000000)}원')),
                    DataCell(Text('${_formatMoney(33000000)}원')),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '57.7%',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )),
                  ]),
                  DataRow(cells: [
                    const DataCell(Text('삼성물산')),
                    const DataCell(Text('1')),
                    DataCell(Text('${_formatMoney(29250000)}원')),
                    DataCell(Text('${_formatMoney(29250000)}원')),
                    const DataCell(Text('0원')),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '100%',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )),
                  ]),
                  DataRow(cells: [
                    const DataCell(Text('GS건설')),
                    const DataCell(Text('1')),
                    DataCell(Text('${_formatMoney(16500000)}원')),
                    const DataCell(Text('0원')),
                    DataCell(Text('${_formatMoney(16500000)}원')),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '0%',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )),
                  ]),
                ],
              ),
            ),
          ),
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
