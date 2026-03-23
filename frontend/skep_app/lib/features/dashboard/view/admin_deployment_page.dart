import 'package:flutter/material.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';

class AdminDeploymentPage extends StatefulWidget {
  const AdminDeploymentPage({Key? key}) : super(key: key);

  @override
  State<AdminDeploymentPage> createState() => _AdminDeploymentPageState();
}

class _AdminDeploymentPageState extends State<AdminDeploymentPage> {
  String _filterPeriod = '전체';
  String _filterSupplier = '전체';
  String _filterBp = '전체';
  String _filterStatus = '전체';

  final List<String> _periods = ['전체', '이번달', '지난달', '최근3개월'];
  final List<String> _suppliers = ['전체', '(주)한국크레인', '삼성중장비', '대한건기'];
  final List<String> _bps = ['전체', '현대건설', '삼성물산', 'GS건설'];
  final List<String> _statuses = ['전체', '요청중', '승인', '진행중', '종료'];

  final List<Map<String, String>> _deployments = [
    {
      'site': '강남 현장 A',
      'supplier': '(주)한국크레인',
      'equip': '25톤 크레인',
      'personnel': '김운전',
      'bp': '현대건설',
      'period': '2026-03-01 ~ 2026-06-30',
      'price': '1,500,000원/일',
      'status': '진행중',
    },
    {
      'site': '송파 현장 B',
      'supplier': '삼성중장비',
      'equip': '굴삭기 0.7m3',
      'personnel': '박기사',
      'bp': '현대건설',
      'period': '2026-03-01 ~ 2026-05-31',
      'price': '1,200,000원/일',
      'status': '진행중',
    },
    {
      'site': '일산 현장 D',
      'supplier': '(주)한국크레인',
      'equip': '50톤 크레인',
      'personnel': '이기사',
      'bp': '삼성물산',
      'period': '2026-04-01 ~ 2026-07-31',
      'price': '2,200,000원/일',
      'status': '승인',
    },
    {
      'site': '용인 현장 F',
      'supplier': '대한건기',
      'equip': '지게차 3톤',
      'personnel': '최운전',
      'bp': 'GS건설',
      'period': '2026-02-01 ~ 2026-03-31',
      'price': '800,000원/일',
      'status': '종료',
    },
    {
      'site': '판교 현장 E',
      'supplier': '(주)한국크레인',
      'equip': '25톤 크레인',
      'personnel': '김운전',
      'bp': '삼성물산',
      'period': '2026-05-01 ~ 2026-08-31',
      'price': '1,500,000원/일',
      'status': '요청중',
    },
  ];

  Color _statusColor(String status) {
    switch (status) {
      case '진행중':
        return AppColors.success;
      case '승인':
        return AppColors.info;
      case '요청중':
        return AppColors.warning;
      case '종료':
        return AppColors.grey;
      default:
        return AppColors.grey;
    }
  }

  List<Map<String, String>> get _filteredDeployments {
    return _deployments.where((d) {
      if (_filterSupplier != '전체' && d['supplier'] != _filterSupplier) {
        return false;
      }
      if (_filterBp != '전체' && d['bp'] != _filterBp) return false;
      if (_filterStatus != '전체' && d['status'] != _filterStatus) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('투입 관리', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 4),
          Text(
            '전체 투입 현황을 관리합니다.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: 24),
          // 필터
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _buildFilter('기간', _filterPeriod, _periods,
                    (v) => setState(() => _filterPeriod = v ?? '전체')),
                _buildFilter('공급사', _filterSupplier, _suppliers,
                    (v) => setState(() => _filterSupplier = v ?? '전체')),
                _buildFilter('BP사', _filterBp, _bps,
                    (v) => setState(() => _filterBp = v ?? '전체')),
                _buildFilter('상태', _filterStatus, _statuses,
                    (v) => setState(() => _filterStatus = v ?? '전체')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 매트릭스 요약
          Text('공급사 x BP사 매트릭스', style: AppTextStyles.headlineSmall),
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
                ],
                rows: const [
                  DataRow(cells: [
                    DataCell(Text('(주)한국크레인')),
                    DataCell(Text('1')),
                    DataCell(Text('2')),
                    DataCell(Text('0')),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('삼성중장비')),
                    DataCell(Text('1')),
                    DataCell(Text('0')),
                    DataCell(Text('0')),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('대한건기')),
                    DataCell(Text('0')),
                    DataCell(Text('0')),
                    DataCell(Text('1')),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('투입 목록', style: AppTextStyles.headlineSmall),
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
                  DataColumn(label: Text('현장')),
                  DataColumn(label: Text('공급사')),
                  DataColumn(label: Text('장비')),
                  DataColumn(label: Text('인력')),
                  DataColumn(label: Text('BP사')),
                  DataColumn(label: Text('기간')),
                  DataColumn(label: Text('단가')),
                  DataColumn(label: Text('상태')),
                ],
                rows: _filteredDeployments
                    .map((d) => DataRow(cells: [
                          DataCell(Text(d['site']!)),
                          DataCell(Text(d['supplier']!)),
                          DataCell(Text(d['equip']!)),
                          DataCell(Text(d['personnel']!)),
                          DataCell(Text(d['bp']!)),
                          DataCell(Text(d['period']!)),
                          DataCell(Text(d['price']!)),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(d['status']!)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              d['status']!,
                              style: TextStyle(
                                color: _statusColor(d['status']!),
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

  Widget _buildFilter(String label, String value, List<String> options,
      ValueChanged<String?> onChanged) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
