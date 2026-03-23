import 'package:flutter/material.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';

class AdminBpManagementPage extends StatefulWidget {
  const AdminBpManagementPage({Key? key}) : super(key: key);

  @override
  State<AdminBpManagementPage> createState() => _AdminBpManagementPageState();
}

class _AdminBpManagementPageState extends State<AdminBpManagementPage> {
  int? _expandedIndex;

  final List<Map<String, dynamic>> _bpList = [
    {
      'name': '현대건설',
      'siteCount': 3,
      'equipCount': 12,
      'manager': '이건설',
      'contact': '02-1234-5678',
      'sites': [
        {'name': '강남 현장 A', 'address': '서울시 강남구', 'equipCount': 5},
        {'name': '송파 현장 B', 'address': '서울시 송파구', 'equipCount': 4},
        {'name': '분당 현장 C', 'address': '경기도 성남시', 'equipCount': 3},
      ],
      'deployments': [
        {'supplier': '(주)한국크레인', 'equip': '25톤 크레인', 'operator': '김운전', 'status': '진행중'},
        {'supplier': '삼성중장비', 'equip': '굴삭기 0.7m3', 'operator': '박기사', 'status': '진행중'},
      ],
    },
    {
      'name': '삼성물산',
      'siteCount': 2,
      'equipCount': 8,
      'manager': '김물산',
      'contact': '02-2345-6789',
      'sites': [
        {'name': '일산 현장 D', 'address': '경기도 고양시', 'equipCount': 5},
        {'name': '판교 현장 E', 'address': '경기도 성남시', 'equipCount': 3},
      ],
      'deployments': [
        {'supplier': '(주)한국크레인', 'equip': '50톤 크레인', 'operator': '이기사', 'status': '진행중'},
      ],
    },
    {
      'name': 'GS건설',
      'siteCount': 1,
      'equipCount': 4,
      'manager': '박건설',
      'contact': '02-3456-7890',
      'sites': [
        {'name': '용인 현장 F', 'address': '경기도 용인시', 'equipCount': 4},
      ],
      'deployments': [
        {'supplier': '대한건기', 'equip': '지게차 3톤', 'operator': '최운전', 'status': '종료'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BP사 관리', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 4),
          Text(
            'BP사 목록 및 투입 현황을 관리합니다.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
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
                  DataColumn(label: Text('회사명')),
                  DataColumn(label: Text('현장수'), numeric: true),
                  DataColumn(label: Text('투입장비수'), numeric: true),
                  DataColumn(label: Text('담당자')),
                  DataColumn(label: Text('연락처')),
                  DataColumn(label: Text('상세')),
                ],
                rows: List.generate(_bpList.length, (i) {
                  final bp = _bpList[i];
                  return DataRow(cells: [
                    DataCell(Text(bp['name'])),
                    DataCell(Text('${bp['siteCount']}')),
                    DataCell(Text('${bp['equipCount']}')),
                    DataCell(Text(bp['manager'])),
                    DataCell(Text(bp['contact'])),
                    DataCell(IconButton(
                      icon: Icon(
                        _expandedIndex == i
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _expandedIndex = _expandedIndex == i ? null : i;
                        });
                      },
                    )),
                  ]);
                }),
              ),
            ),
          ),
          if (_expandedIndex != null) ...[
            const SizedBox(height: 16),
            _buildDetailPanel(_bpList[_expandedIndex!]),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailPanel(Map<String, dynamic> bp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${bp['name']} - 현장 목록', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('현장명')),
                DataColumn(label: Text('주소')),
                DataColumn(label: Text('투입장비'), numeric: true),
              ],
              rows: (bp['sites'] as List<Map<String, dynamic>>)
                  .map((s) => DataRow(cells: [
                        DataCell(Text(s['name'])),
                        DataCell(Text(s['address'])),
                        DataCell(Text('${s['equipCount']}대')),
                      ]))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          Text('투입 현황', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('공급사')),
                DataColumn(label: Text('장비')),
                DataColumn(label: Text('운전원')),
                DataColumn(label: Text('상태')),
              ],
              rows: (bp['deployments'] as List<Map<String, dynamic>>)
                  .map((d) => DataRow(cells: [
                        DataCell(Text(d['supplier'])),
                        DataCell(Text(d['equip'])),
                        DataCell(Text(d['operator'])),
                        DataCell(Text(d['status'])),
                      ]))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
