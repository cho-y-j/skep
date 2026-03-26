import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';
import 'package:skep_app/features/dashboard/view/document_type_master_page.dart';

class EquipmentTypeSettingsPage extends StatefulWidget {
  const EquipmentTypeSettingsPage({Key? key}) : super(key: key);

  @override
  State<EquipmentTypeSettingsPage> createState() =>
      _EquipmentTypeSettingsPageState();
}

class _EquipmentTypeSettingsPageState extends State<EquipmentTypeSettingsPage> {
  final DocumentTypeRepository _docRepo = DocumentTypeRepository.instance;

  List<Map<String, dynamic>> _equipmentTypes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEquipmentTypes());
  }

  Future<void> _loadEquipmentTypes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dioClient = context.read<DioClient>();
      final response = await dioClient.get<dynamic>(ApiEndpoints.equipmentTypes);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List) {
          _equipmentTypes = data.map((item) {
            if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            return <String, dynamic>{};
          }).toList();
        } else if (data is Map && data['content'] is List) {
          _equipmentTypes = (data['content'] as List).map((item) {
            if (item is Map) return Map<String, dynamic>.from(item);
            return <String, dynamic>{};
          }).toList();
        } else {
          _equipmentTypes = [];
        }
      }
    } catch (e) {
      _error = e.toString();
      _equipmentTypes = [];
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  DocumentType? _findDocType(String name) {
    final docs = _docRepo.getByCategory('장비서류');
    for (final d in docs) {
      if (d.name == name) return d;
    }
    return null;
  }

  void _showAddEditDialog({Map<String, dynamic>? existing}) {
    final codeCtrl = TextEditingController(text: existing?['code']?.toString() ?? '');
    final typeCtrl = TextEditingController(text: existing?['type']?.toString() ?? existing?['name']?.toString() ?? '');
    // 순서가 있는 리스트
    final orderedDocs = List<String>.from(
      (existing?['documents'] as List<dynamic>?)?.cast<String>() ?? <String>[],
    );
    final existingId = existing?['id']?.toString() ?? '';
    bool _isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final allDocs = _docRepo.getByCategory('장비서류');
            final unselectedDocs = allDocs.where((d) => !orderedDocs.contains(d.name)).toList();

            return AlertDialog(
              title: Text(existing == null ? '장비 유형 추가' : '장비 유형 수정'),
              content: SizedBox(
                width: 600,
                height: 600,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: codeCtrl,
                        decoration: const InputDecoration(
                          labelText: '장비 유형 코드 *',
                          hintText: '예: TC',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: typeCtrl,
                        decoration: const InputDecoration(
                          labelText: '장비 유형명 *',
                          hintText: '예: 타워크레인',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 선택된 서류 (순서 변경 가능)
                      Row(
                        children: [
                          const Text('선택된 서류 (순서 변경 가능)',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          const Spacer(),
                          Text('${orderedDocs.length}개',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (orderedDocs.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('아래에서 서류를 선택하세요',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                        ),
                      ...List.generate(orderedDocs.length, (i) {
                        final docName = orderedDocs[i];
                        final docType = _findDocType(docName);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.04),
                            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            dense: true,
                            visualDensity: const VisualDensity(vertical: -2),
                            leading: Container(
                              width: 24, height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(child: Text('${i + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                            ),
                            title: Text(docName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            subtitle: _buildDocTags(docType),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (i > 0)
                                  IconButton(
                                    icon: const Icon(Icons.arrow_upward, size: 16),
                                    tooltip: '위로',
                                    onPressed: () {
                                      setDialogState(() {
                                        final tmp = orderedDocs[i - 1];
                                        orderedDocs[i - 1] = orderedDocs[i];
                                        orderedDocs[i] = tmp;
                                      });
                                    },
                                  ),
                                if (i < orderedDocs.length - 1)
                                  IconButton(
                                    icon: const Icon(Icons.arrow_downward, size: 16),
                                    tooltip: '아래로',
                                    onPressed: () {
                                      setDialogState(() {
                                        final tmp = orderedDocs[i + 1];
                                        orderedDocs[i + 1] = orderedDocs[i];
                                        orderedDocs[i] = tmp;
                                      });
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                  tooltip: '제거',
                                  onPressed: () {
                                    setDialogState(() => orderedDocs.removeAt(i));
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 20),
                      const Text('서류 추가 (클릭하여 추가)',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: unselectedDocs.map((doc) {
                          return ActionChip(
                            avatar: const Icon(Icons.add, size: 14),
                            label: Text(doc.name, style: const TextStyle(fontSize: 12)),
                            onPressed: () {
                              setDialogState(() => orderedDocs.add(doc.name));
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: _isSaving ? null : () async {
                    if (codeCtrl.text.trim().isEmpty || typeCtrl.text.trim().isEmpty) return;
                    setDialogState(() => _isSaving = true);
                    try {
                      final dioClient = context.read<DioClient>();
                      final body = {
                        'code': codeCtrl.text.trim(),
                        'type': typeCtrl.text.trim(),
                        'name': typeCtrl.text.trim(),
                        'documents': List<String>.from(orderedDocs),
                      };
                      if (existing != null && existingId.isNotEmpty) {
                        final url = ApiEndpoints.equipmentTypeUpdate.replaceAll('{id}', existingId);
                        await dioClient.put<dynamic>(url, data: body);
                      } else {
                        await dioClient.post<dynamic>(ApiEndpoints.equipmentTypeCreate, data: body);
                      }
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(existing == null ? '장비 유형이 추가되었습니다.' : '장비 유형이 수정되었습니다.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        _loadEquipmentTypes();
                      }
                    } catch (e) {
                      setDialogState(() => _isSaving = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('저장 실패: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('저장'),
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
    if (doc.hasExpiryManagement) {
      items.add(_miniTag('${doc.expiryFieldName.isNotEmpty ? doc.expiryFieldName : "만료일"}', const Color(0xFFFF9800)));
    }
    if (doc.hasVerification) {
      items.add(_miniTag('${doc.verificationProvider}', const Color(0xFF4CAF50)));
    }
    if (doc.hasOcr) {
      items.add(_miniTag('OCR', const Color(0xFF2196F3)));
    }
    if (items.isEmpty) return null;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(spacing: 4, children: items),
    );
  }

  Widget _miniTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> et) {
    final name = et['type']?.toString() ?? et['name']?.toString() ?? '알 수 없음';
    final typeId = et['id']?.toString() ?? '';
    bool _isDeleting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('삭제 확인'),
          content: Text('$name을(를) 삭제하시겠습니까?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('취소')),
            ElevatedButton(
              onPressed: _isDeleting ? null : () async {
                setDialogState(() => _isDeleting = true);
                try {
                  final dioClient = context.read<DioClient>();
                  final url = ApiEndpoints.equipmentTypeDelete.replaceAll('{id}', typeId);
                  await dioClient.delete<dynamic>(url);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('장비 유형이 삭제되었습니다.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    _loadEquipmentTypes();
                  }
                } catch (e) {
                  setDialogState(() => _isDeleting = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('삭제 실패: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: AppColors.white),
              child: _isDeleting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('삭제'),
            ),
          ],
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
                    Text('장비 유형 설정', style: AppTextStyles.headlineLarge),
                    const SizedBox(height: 4),
                    Text('장비 유형별 필수 서류를 설정합니다. 서류 순서는 고객 업로드 순서와 동일합니다.',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _loadEquipmentTypes,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('새로고침'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.greyDark,
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showAddEditDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('장비 유형 추가'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Color(0xFFCBD5E1)),
                    const SizedBox(height: 12),
                    const Text('데이터를 불러오는데 실패했습니다', style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    TextButton(onPressed: _loadEquipmentTypes, child: const Text('다시 시도')),
                  ],
                ),
              ),
            )
          else if (_equipmentTypes.isEmpty)
            Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.construction_outlined, size: 48, color: Color(0xFFCBD5E1)),
                    const SizedBox(height: 12),
                    const Text('등록된 장비 유형이 없습니다', style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 8),
                    TextButton(onPressed: _loadEquipmentTypes, child: const Text('다시 불러오기')),
                  ],
                ),
              ),
            )
          else
            // 카드 리스트
            ...List.generate(_equipmentTypes.length, (i) {
              final et = _equipmentTypes[i];
              final docs = ((et['documents'] as List?)?.cast<String>()) ?? <String>[];
              final code = et['code']?.toString() ?? '';
              final typeName = et['type']?.toString() ?? et['name']?.toString() ?? '-';
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 헤더
                    Row(
                      children: [
                        if (code.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(code,
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        if (code.isNotEmpty) const SizedBox(width: 12),
                        Text(typeName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Text('서류 ${docs.length}개',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                          tooltip: '수정',
                          onPressed: () => _showAddEditDialog(existing: et),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          tooltip: '삭제',
                          onPressed: () => _showDeleteDialog(et),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    // 서류 목록 (순서대로)
                    ...List.generate(docs.length, (j) {
                      final docName = docs[j];
                      final docType = _findDocType(docName);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(child: Text('${j + 1}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600))),
                            ),
                            const SizedBox(width: 10),
                            Text(docName, style: const TextStyle(fontSize: 13)),
                            const SizedBox(width: 8),
                            if (docType != null && docType.hasExpiryManagement)
                              _miniTag('${docType.expiryFieldName.isNotEmpty ? docType.expiryFieldName : "만료일"}', const Color(0xFFFF9800)),
                            if (docType != null && docType.hasExpiryManagement) const SizedBox(width: 4),
                            if (docType != null && docType.hasVerification)
                              _miniTag('${docType.verificationProvider}', const Color(0xFF4CAF50)),
                            if (docType != null && docType.hasVerification) const SizedBox(width: 4),
                            if (docType != null && docType.hasOcr)
                              _miniTag('OCR', const Color(0xFF2196F3)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
