import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';
import 'package:skep_app/features/dashboard/view/document_type_master_page.dart';

// TODO: Replace local mock data with backend API when personnel-type settings endpoint is available.
// Currently no dedicated endpoint exists for personnel type configurations.
// Candidate: GET/POST /api/equipment/persons/types (not yet in ApiEndpoints)

class PersonnelTypeSettingsPage extends StatefulWidget {
  const PersonnelTypeSettingsPage({Key? key}) : super(key: key);

  @override
  State<PersonnelTypeSettingsPage> createState() => _PersonnelTypeSettingsPageState();
}

class _PersonnelTypeSettingsPageState extends State<PersonnelTypeSettingsPage> {
  final DocumentTypeRepository _docRepo = DocumentTypeRepository.instance;

  late List<Map<String, dynamic>> _personnelTypes;

  @override
  void initState() {
    super.initState();
    _personnelTypes = [
      {
        'code': 'DR',
        'type': '장비 운전원',
        'documents': ['신분증 (주민등록증)', '운전면허증', '건설기계조종사 면허증', '기초안전보건교육 이수증', '특수형태근로자 교육 실시확인서', '건설기계조종사 안전교육 이수증', '배치건강진단서'],
      },
      {
        'code': 'GD',
        'type': '안전유도원',
        'documents': ['신분증 (주민등록증)', '운전면허증', '기초안전보건교육 이수증', '특수형태근로자 교육 실시확인서', '배치건강진단서'],
      },
      {
        'code': 'CR',
        'type': '크레인 운전원',
        'documents': ['신분증 (주민등록증)', '운전면허증', '건설기계조종사 면허증', '이동식크레인 조종자격 교육수료증', '기초안전보건교육 이수증', '특수형태근로자 교육 실시확인서', '건설기계조종사 안전교육 이수증', '배치건강진단서'],
      },
      {
        'code': 'AW',
        'type': '고소작업대 운전원',
        'documents': ['신분증 (주민등록증)', '운전면허증', '고소작업대 자격교육 수료증', '기초안전보건교육 이수증', '특수형태근로자 교육 실시확인서', '배치건강진단서'],
      },
    ];
  }

  DocumentType? _findDocType(String name) {
    final docs = _docRepo.getByCategory('인력서류');
    for (final d in docs) {
      if (d.name == name) return d;
    }
    return null;
  }

  void _showAddEditDialog({Map<String, dynamic>? existing, int? index}) {
    final codeCtrl = TextEditingController(text: existing?['code']?.toString() ?? '');
    final typeCtrl = TextEditingController(text: existing?['type']?.toString() ?? '');
    final orderedDocs = List<String>.from(
      (existing?['documents'] as List<dynamic>?)?.cast<String>() ?? <String>[],
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final allDocs = _docRepo.getByCategory('인력서류');
            final unselectedDocs = allDocs.where((d) => !orderedDocs.contains(d.name)).toList();

            return AlertDialog(
              title: Text(existing == null ? '인력 유형 추가' : '인력 유형 수정'),
              content: SizedBox(
                width: 600,
                height: 600,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: '인력 유형 코드 *', hintText: '예: DR', border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: '인력 유형명 *', hintText: '예: 장비 운전원', border: OutlineInputBorder())),
                      const SizedBox(height: 24),
                      Row(children: [
                        const Text('선택된 서류 (순서 변경 가능)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const Spacer(),
                        Text('${orderedDocs.length}개', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 8),
                      if (orderedDocs.isEmpty)
                        Container(
                          width: double.infinity, padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
                          child: Text('아래에서 서류를 선택하세요', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                        ),
                      ...List.generate(orderedDocs.length, (i) {
                        final docName = orderedDocs[i];
                        final docType = _findDocType(docName);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.04), border: Border.all(color: AppColors.primary.withOpacity(0.2)), borderRadius: BorderRadius.circular(8)),
                          child: ListTile(
                            dense: true, visualDensity: const VisualDensity(vertical: -2),
                            leading: Container(width: 24, height: 24, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                              child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))),
                            title: Text(docName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            subtitle: _buildDocTags(docType),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              if (i > 0) IconButton(icon: const Icon(Icons.arrow_upward, size: 16), tooltip: '위로', onPressed: () { setDialogState(() { final t = orderedDocs[i-1]; orderedDocs[i-1] = orderedDocs[i]; orderedDocs[i] = t; }); }),
                              if (i < orderedDocs.length - 1) IconButton(icon: const Icon(Icons.arrow_downward, size: 16), tooltip: '아래로', onPressed: () { setDialogState(() { final t = orderedDocs[i+1]; orderedDocs[i+1] = orderedDocs[i]; orderedDocs[i] = t; }); }),
                              IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.red), tooltip: '제거', onPressed: () { setDialogState(() => orderedDocs.removeAt(i)); }),
                            ]),
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      const Text('서류 추가 (클릭하여 추가)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, runSpacing: 6, children: unselectedDocs.map((doc) => ActionChip(
                        avatar: const Icon(Icons.add, size: 14),
                        label: Text(doc.name, style: const TextStyle(fontSize: 12)),
                        onPressed: () => setDialogState(() => orderedDocs.add(doc.name)),
                      )).toList()),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('취소')),
                ElevatedButton(
                  onPressed: () {
                    if (codeCtrl.text.trim().isEmpty || typeCtrl.text.trim().isEmpty) return;
                    setState(() {
                      final entry = {'code': codeCtrl.text.trim(), 'type': typeCtrl.text.trim(), 'documents': List<String>.from(orderedDocs)};
                      if (index != null) { _personnelTypes[index] = entry; } else { _personnelTypes.add(entry); }
                    });
                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white),
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget? _buildDocTags(DocumentType? doc) {
    if (doc == null) return null;
    final items = <Widget>[];
    if (doc.hasExpiryManagement) items.add(_miniTag('📅 ${doc.expiryFieldName.isNotEmpty ? doc.expiryFieldName : "만료일"}', const Color(0xFFFF9800)));
    if (doc.hasVerification) items.add(_miniTag('✅ ${doc.verificationProvider}', const Color(0xFF4CAF50)));
    if (doc.hasOcr) items.add(_miniTag('OCR', const Color(0xFF2196F3)));
    if (items.isEmpty) return null;
    return Padding(padding: const EdgeInsets.only(top: 4), child: Wrap(spacing: 4, children: items));
  }

  Widget _miniTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
    );
  }

  void _showDeleteDialog(int index) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('삭제 확인'),
      content: Text('${_personnelTypes[index]['type']}을(를) 삭제하시겠습니까?'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('취소')),
        ElevatedButton(
          onPressed: () { setState(() => _personnelTypes.removeAt(index)); Navigator.of(ctx).pop(); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: AppColors.white),
          child: const Text('삭제'),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('인력 유형 설정', style: AppTextStyles.headlineLarge),
              const SizedBox(height: 4),
              Text('인력 유형별 필수 서류를 설정합니다. 서류 순서는 고객 업로드 순서와 동일합니다.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey)),
            ])),
            ElevatedButton.icon(
              onPressed: () => _showAddEditDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('인력 유형 추가'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white),
            ),
          ]),
          const SizedBox(height: 24),
          ...List.generate(_personnelTypes.length, (i) {
            final pt = _personnelTypes[i];
            final docs = (pt['documents'] as List).cast<String>();
            return Container(
              width: double.infinity, margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(pt['code'] as String, style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  Text(pt['type'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('서류 ${docs.length}개', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary), tooltip: '수정', onPressed: () => _showAddEditDialog(existing: pt, index: i)),
                  IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), tooltip: '삭제', onPressed: () => _showDeleteDialog(i)),
                ]),
                const SizedBox(height: 12), const Divider(height: 1), const SizedBox(height: 12),
                ...List.generate(docs.length, (j) {
                  final docName = docs[j];
                  final docType = _findDocType(docName);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Container(width: 22, height: 22,
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                        child: Center(child: Text('${j + 1}', style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)))),
                      const SizedBox(width: 10),
                      Text(docName, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      if (docType != null && docType.hasExpiryManagement) _miniTag('📅 ${docType.expiryFieldName.isNotEmpty ? docType.expiryFieldName : "만료일"}', const Color(0xFFFF9800)),
                      if (docType != null && docType.hasExpiryManagement) const SizedBox(width: 4),
                      if (docType != null && docType.hasVerification) _miniTag('✅ ${docType.verificationProvider}', const Color(0xFF4CAF50)),
                      if (docType != null && docType.hasVerification) const SizedBox(width: 4),
                      if (docType != null && docType.hasOcr) _miniTag('OCR', const Color(0xFF2196F3)),
                    ]),
                  );
                }),
              ]),
            );
          }),
        ],
      ),
    );
  }
}
