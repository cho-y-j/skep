import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';

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
  bool _isLoading = true;
  String? _error;

  final List<String> _submissionTypes = [
    '차량+운전수 세트',
    '차량만',
    '운전수만',
    '인력만',
  ];

  List<Map<String, dynamic>> _equipmentList = [];
  List<Map<String, dynamic>> _personnelList = [];
  List<Map<String, dynamic>> _expiringDocs = [];
  List<Map<String, dynamic>> _sendHistory = [];

  final List<String> _documentThumbnails = [
    '사업자등록증',
    '건설기계등록증',
    '보험증권',
    '정기검사증',
    '운전면허증',
    '건강검진결과',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dioClient = context.read<DioClient>();
      final responses = await Future.wait([
        dioClient.get<dynamic>(ApiEndpoints.documentExpiring),
        dioClient.get<dynamic>(ApiEndpoints.equipments),
        dioClient.get<dynamic>(ApiEndpoints.persons),
      ]);

      // Parse expiring documents
      final docData = responses[0].data;
      if (docData is List) {
        _expiringDocs = docData.cast<Map<String, dynamic>>();
      } else if (docData is Map && docData['content'] is List) {
        _expiringDocs = (docData['content'] as List).cast<Map<String, dynamic>>();
      } else {
        _expiringDocs = [];
      }

      // Build send history from expiring docs
      _sendHistory = _expiringDocs.map((doc) => <String, dynamic>{
        'date': doc['expiryDate'] ?? doc['createdAt'] ?? '',
        'bp': doc['bpCompanyName'] ?? '',
        'type': doc['documentType'] ?? doc['type'] ?? '',
        'target': doc['ownerName'] ?? doc['equipmentName'] ?? '',
        'status': doc['status'] ?? '',
      }).toList();

      // Parse equipment list
      final equipData = responses[1].data;
      if (equipData is List) {
        _equipmentList = equipData.cast<Map<String, dynamic>>();
      } else if (equipData is Map && equipData['content'] is List) {
        _equipmentList = (equipData['content'] as List).cast<Map<String, dynamic>>();
      } else {
        _equipmentList = [];
      }

      // Parse personnel list
      final persData = responses[2].data;
      if (persData is List) {
        _personnelList = persData.cast<Map<String, dynamic>>();
      } else if (persData is Map && persData['content'] is List) {
        _personnelList = (persData['content'] as List).cast<Map<String, dynamic>>();
      } else {
        _personnelList = [];
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    final s = status.toUpperCase();
    switch (s) {
      case '승인':
      case 'APPROVED':
      case 'VALID':
        return AppColors.success;
      case '검토중':
      case 'PENDING':
      case 'REVIEWING':
        return AppColors.warning;
      case '발송완료':
      case 'SENT':
        return AppColors.info;
      case '반려':
      case 'REJECTED':
      case 'EXPIRED':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }

  String _mapDocStatus(String status) {
    final s = status.toUpperCase();
    switch (s) {
      case 'APPROVED':
      case 'VALID':
        return '승인';
      case 'PENDING':
      case 'REVIEWING':
        return '검토중';
      case 'SENT':
        return '발송완료';
      case 'REJECTED':
        return '반려';
      case 'EXPIRED':
        return '만료';
      default:
        return status;
    }
  }

  Future<void> _sendEmail() async {
    if (_bpCompany.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('BP사를 입력해주세요.')),
      );
      return;
    }
    // TODO: Connect to email sending endpoint when available
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$_bpCompany에 서류 이메일 발송 기능은 준비 중입니다.')),
    );
  }

  Future<void> _downloadPdf() async {
    // TODO: Connect to PDF download endpoint when available
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF 다운로드 기능은 준비 중입니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(48),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('데이터를 불러오는데 실패했습니다', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
              const SizedBox(height: 8),
              Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton(onPressed: _loadData, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }
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
                            value: (e['id'] ?? '').toString(),
                            child: Text(e['vehicleNumber'] ?? e['name'] ?? e['id'].toString())))
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
                            value: (p['id'] ?? '').toString(),
                            child: Text(p['name'] ?? p['id'].toString())))
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
                      onPressed: _sendEmail,
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
                      onPressed: _downloadPdf,
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
                    .map((h) {
                      final status = _mapDocStatus(h['status']?.toString() ?? '');
                      return DataRow(cells: [
                        DataCell(Text(h['date']?.toString() ?? '')),
                        DataCell(Text(h['bp']?.toString() ?? '')),
                        DataCell(Text(h['type']?.toString() ?? '')),
                        DataCell(Text(h['target']?.toString() ?? '')),
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(status)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: _statusColor(status),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )),
                      ]);
                    })
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
