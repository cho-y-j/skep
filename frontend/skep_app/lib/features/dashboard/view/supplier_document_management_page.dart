import 'package:flutter/material.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';

class SupplierDocumentManagementPage extends StatefulWidget {
  const SupplierDocumentManagementPage({Key? key}) : super(key: key);

  @override
  State<SupplierDocumentManagementPage> createState() =>
      _SupplierDocumentManagementPageState();
}

class _SupplierDocumentManagementPageState
    extends State<SupplierDocumentManagementPage> {
  String _selectedType = '차량+운전수 세트';
  String _selectedEquipment = '';
  String _selectedPersonnel = '';
  String _bpCompany = '';

  final List<String> _submissionTypes = [
    '차량+운전수 세트',
    '차량만',
    '운전수만',
    '인력만',
  ];

  final List<Map<String, String>> _equipmentList = [
    {'id': 'E001', 'name': '25톤 크레인 (서울12가3456)'},
    {'id': 'E002', 'name': '50톤 크레인 (경기34나5678)'},
    {'id': 'E003', 'name': '굴삭기 0.7m3 (인천56다7890)'},
  ];

  final List<Map<String, String>> _personnelList = [
    {'id': 'P001', 'name': '김운전 (크레인 운전원)'},
    {'id': 'P002', 'name': '이기사 (굴삭기 운전원)'},
    {'id': 'P003', 'name': '박유도 (유도원)'},
  ];

  final List<Map<String, String>> _sendHistory = [
    {
      'date': '2026-03-20',
      'bp': '현대건설',
      'type': '차량+운전수 세트',
      'target': '25톤 크레인 / 김운전',
      'status': '승인',
    },
    {
      'date': '2026-03-18',
      'bp': '삼성물산',
      'type': '차량만',
      'target': '50톤 크레인',
      'status': '검토중',
    },
    {
      'date': '2026-03-15',
      'bp': 'GS건설',
      'type': '인력만',
      'target': '박유도 (유도원)',
      'status': '발송완료',
    },
    {
      'date': '2026-03-10',
      'bp': '대림산업',
      'type': '운전수만',
      'target': '이기사',
      'status': '반려',
    },
  ];

  final List<String> _documentThumbnails = [
    '사업자등록증',
    '건설기계등록증',
    '보험증권',
    '정기검사증',
    '운전면허증',
    '건강검진결과',
  ];

  Color _statusColor(String status) {
    switch (status) {
      case '승인':
        return AppColors.success;
      case '검토중':
        return AppColors.warning;
      case '발송완료':
        return AppColors.info;
      case '반려':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }

  void _simulateSendEmail() {
    if (_bpCompany.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('BP사를 입력해주세요.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$_bpCompany에 서류 이메일이 발송되었습니다. (시뮬레이션)')),
    );
  }

  void _simulateDownloadPdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF 다운로드가 시작되었습니다. (시뮬레이션)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('서류 관리', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 4),
          Text(
            'BP사에 사전 서류를 제출합니다.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: 24),
          // 제출 설정 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('서류 제출', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 16),
                // 제출 유형
                Text('제출 유형', style: AppTextStyles.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: _submissionTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedType = v ?? ''),
                ),
                const SizedBox(height: 16),
                // 장비 선택
                if (_selectedType != '인력만' && _selectedType != '운전수만') ...[
                  Text('장비 선택', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedEquipment.isEmpty
                        ? null
                        : _selectedEquipment,
                    hint: const Text('장비를 선택하세요'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: _equipmentList
                        .map((e) => DropdownMenuItem(
                            value: e['id'], child: Text(e['name']!)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedEquipment = v ?? ''),
                  ),
                  const SizedBox(height: 16),
                ],
                // 인력 선택
                if (_selectedType != '차량만') ...[
                  Text('인력 선택', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedPersonnel.isEmpty
                        ? null
                        : _selectedPersonnel,
                    hint: const Text('인력을 선택하세요'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: _personnelList
                        .map((p) => DropdownMenuItem(
                            value: p['id'], child: Text(p['name']!)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedPersonnel = v ?? ''),
                  ),
                  const SizedBox(height: 16),
                ],
                // BP사 입력
                Text('BP사', style: AppTextStyles.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'BP사명 입력 (추후 API 연동)',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (v) => _bpCompany = v,
                ),
                const SizedBox(height: 16),
                // 서류 패키지 썸네일
                Text('서류 패키지 미리보기', style: AppTextStyles.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _documentThumbnails
                      .map((doc) => Container(
                            width: 100,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.greyLight,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.description,
                                    color: AppColors.primary, size: 28),
                                const SizedBox(height: 4),
                                Text(doc,
                                    style: AppTextStyles.caption,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),
                // 버튼
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _simulateSendEmail,
                      icon: const Icon(Icons.email_outlined),
                      label: const Text('이메일 발송'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _simulateDownloadPdf,
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('PDF 다운로드'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // 발송 이력
          Text('발송 이력', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 16),
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
                  DataColumn(label: Text('발송일')),
                  DataColumn(label: Text('대상 BP사')),
                  DataColumn(label: Text('제출 유형')),
                  DataColumn(label: Text('장비/인력명')),
                  DataColumn(label: Text('상태')),
                ],
                rows: _sendHistory
                    .map((h) => DataRow(cells: [
                          DataCell(Text(h['date']!)),
                          DataCell(Text(h['bp']!)),
                          DataCell(Text(h['type']!)),
                          DataCell(Text(h['target']!)),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(h['status']!)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              h['status']!,
                              style: TextStyle(
                                color: _statusColor(h['status']!),
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
