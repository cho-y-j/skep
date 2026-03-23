import 'package:flutter/material.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';

class AdminStatisticsPage extends StatelessWidget {
  const AdminStatisticsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('통계', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 4),
          Text(
            '전체 플랫폼 통계를 확인합니다.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: 24),
          // 장비 현황 카드
          Text('전체 장비 현황', style: AppTextStyles.headlineSmall),
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
                  _buildStatCard('등록', '24대', Icons.app_registration,
                      AppColors.primary),
                  _buildStatCard('투입중', '12대', Icons.engineering,
                      AppColors.success),
                  _buildStatCard('대기', '9대', Icons.hourglass_empty,
                      AppColors.warning),
                  _buildStatCard('만료', '3대', Icons.block, AppColors.error),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          // 인력 현황 카드
          Text('전체 인력 현황', style: AppTextStyles.headlineSmall),
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
                  _buildStatCard('등록', '31명', Icons.people_outline,
                      AppColors.primary),
                  _buildStatCard('투입중', '18명', Icons.person_pin,
                      AppColors.success),
                  _buildStatCard('대기', '11명', Icons.person_off_outlined,
                      AppColors.warning),
                  _buildStatCard('서류만료', '2명', Icons.warning_amber,
                      AppColors.error),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          // 공급사별 투입 현황
          Text('공급사별 투입 현황', style: AppTextStyles.headlineSmall),
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
                  DataColumn(label: Text('공급사')),
                  DataColumn(label: Text('등록장비'), numeric: true),
                  DataColumn(label: Text('투입장비'), numeric: true),
                  DataColumn(label: Text('등록인력'), numeric: true),
                  DataColumn(label: Text('투입인력'), numeric: true),
                  DataColumn(label: Text('투입률')),
                ],
                rows: [
                  _buildSupplierRow('(주)한국크레인', 8, 5, 15, 10, 62.5),
                  _buildSupplierRow('삼성중장비', 5, 3, 10, 6, 60.0),
                  _buildSupplierRow('대한건기', 3, 1, 6, 2, 33.3),
                  _buildSupplierRow('기타', 8, 3, 0, 0, 37.5),
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
                  DataColumn(label: Text('투입건수'), numeric: true),
                  DataColumn(label: Text('거래액'), numeric: true),
                  DataColumn(label: Text('지급완료'), numeric: true),
                  DataColumn(label: Text('미지급'), numeric: true),
                ],
                rows: const [
                  DataRow(cells: [
                    DataCell(Text('현대건설')),
                    DataCell(Text('5')),
                    DataCell(Text('78,000,000원')),
                    DataCell(Text('45,000,000원')),
                    DataCell(Text('33,000,000원')),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('삼성물산')),
                    DataCell(Text('3')),
                    DataCell(Text('29,250,000원')),
                    DataCell(Text('29,250,000원')),
                    DataCell(Text('0원')),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('GS건설')),
                    DataCell(Text('2')),
                    DataCell(Text('16,500,000원')),
                    DataCell(Text('0원')),
                    DataCell(Text('16,500,000원')),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // 서류 만료 현황
          Text('서류 만료 현황', style: AppTextStyles.headlineSmall),
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
                  DataColumn(label: Text('구분')),
                  DataColumn(label: Text('전체'), numeric: true),
                  DataColumn(label: Text('유효'), numeric: true),
                  DataColumn(label: Text('D-30 이내'), numeric: true),
                  DataColumn(label: Text('D-7 이내'), numeric: true),
                  DataColumn(label: Text('만료'), numeric: true),
                ],
                rows: const [
                  DataRow(cells: [
                    DataCell(Text('장비 서류')),
                    DataCell(Text('48')),
                    DataCell(Text('38')),
                    DataCell(Text('5')),
                    DataCell(Text('3')),
                    DataCell(Text('2')),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('인력 서류')),
                    DataCell(Text('62')),
                    DataCell(Text('54')),
                    DataCell(Text('4')),
                    DataCell(Text('2')),
                    DataCell(Text('2')),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildSupplierRow(String name, int regEquip, int depEquip,
      int regPer, int depPer, double rate) {
    return DataRow(cells: [
      DataCell(Text(name)),
      DataCell(Text('$regEquip')),
      DataCell(Text('$depEquip')),
      DataCell(Text('$regPer')),
      DataCell(Text('$depPer')),
      DataCell(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: rate >= 50
              ? AppColors.success.withOpacity(0.1)
              : AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${rate.toStringAsFixed(1)}%',
          style: TextStyle(
            color: rate >= 50 ? AppColors.success : AppColors.warning,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      )),
    ]);
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
