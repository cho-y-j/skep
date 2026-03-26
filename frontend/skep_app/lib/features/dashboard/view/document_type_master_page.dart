import 'package:flutter/material.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';

/// 서류 유형 모델
class DocumentType {
  String name;
  String category; // '장비서류' or '인력서류'
  bool hasOcr;
  bool hasExpiryManagement;
  String expiryFieldName;
  bool hasVerification;
  String verificationProvider;

  DocumentType({
    required this.name,
    required this.category,
    this.hasOcr = false,
    this.hasExpiryManagement = false,
    this.expiryFieldName = '',
    this.hasVerification = false,
    this.verificationProvider = '',
  });

  DocumentType copyWith({
    String? name,
    String? category,
    bool? hasOcr,
    bool? hasExpiryManagement,
    String? expiryFieldName,
    bool? hasVerification,
    String? verificationProvider,
  }) {
    return DocumentType(
      name: name ?? this.name,
      category: category ?? this.category,
      hasOcr: hasOcr ?? this.hasOcr,
      hasExpiryManagement: hasExpiryManagement ?? this.hasExpiryManagement,
      expiryFieldName: expiryFieldName ?? this.expiryFieldName,
      hasVerification: hasVerification ?? this.hasVerification,
      verificationProvider: verificationProvider ?? this.verificationProvider,
    );
  }
}

/// 글로벌 서류 유형 저장소 (싱글톤)
class DocumentTypeRepository {
  DocumentTypeRepository._();
  static final DocumentTypeRepository instance = DocumentTypeRepository._();

  final List<DocumentType> _documentTypes = [
    // 장비서류
    DocumentType(
      name: '자동차 등록원부(갑)',
      category: '장비서류',
      hasOcr: true,
      hasExpiryManagement: true,
      expiryFieldName: '검사유효기간',
      hasVerification: true,
      verificationProvider: '정부24',
    ),
    DocumentType(
      name: '자동차등록증',
      category: '장비서류',
      hasOcr: true,
      hasExpiryManagement: true,
      expiryFieldName: '',
      hasVerification: false,
      verificationProvider: '',
    ),
    DocumentType(
      name: '사업자등록증',
      category: '장비서류',
      hasOcr: true,
      hasExpiryManagement: false,
      expiryFieldName: '',
      hasVerification: true,
      verificationProvider: '국세청',
    ),
    DocumentType(
      name: '자동차보험 가입증명서',
      category: '장비서류',
      hasOcr: true,
      hasExpiryManagement: true,
      expiryFieldName: '보험만료일',
      hasVerification: false,
      verificationProvider: '',
    ),
    DocumentType(
      name: '안전인증서 (KCs)',
      category: '장비서류',
      hasOcr: true,
      hasExpiryManagement: true,
      expiryFieldName: '',
      hasVerification: true,
      verificationProvider: '대한산업안전협회',
    ),
    DocumentType(
      name: '장비 제원표',
      category: '장비서류',
      hasOcr: true,
      hasExpiryManagement: false,
      expiryFieldName: '',
      hasVerification: false,
      verificationProvider: '',
    ),
    DocumentType(
      name: '비파괴 검사서',
      category: '장비서류',
      hasOcr: true,
      hasExpiryManagement: true,
      expiryFieldName: '검사유효기간',
      hasVerification: false,
      verificationProvider: '',
    ),
    // 건설기계 관련 장비서류
    DocumentType(
      name: '건설기계 검사증',
      category: '장비서류',
      hasOcr: true,
      hasExpiryManagement: true,
      expiryFieldName: '검사유효기간',
      hasVerification: false,
      verificationProvider: '',
    ),
    DocumentType(
      name: '건설기계등록원부',
      category: '장비서류',
      hasOcr: true,
      hasExpiryManagement: false,
      expiryFieldName: '',
      hasVerification: true,
      verificationProvider: '정부24',
    ),
    DocumentType(
      name: '건설기계 안전검사 성적서',
      category: '장비서류',
      hasOcr: true,
      hasExpiryManagement: true,
      expiryFieldName: '검사유효기간',
      hasVerification: false,
      verificationProvider: '',
    ),
    DocumentType(
      name: '건설기계 정기검사 확인서',
      category: '장비서류',
      hasOcr: true,
      hasExpiryManagement: true,
      expiryFieldName: '검사만료일',
      hasVerification: false,
      verificationProvider: '',
    ),
    DocumentType(
      name: '건설기계 보험가입 증명서',
      category: '장비서류',
      hasOcr: true,
      hasExpiryManagement: true,
      expiryFieldName: '보험만료일',
      hasVerification: false,
      verificationProvider: '',
    ),
    DocumentType(
      name: '특수건설기계 조종사 면허증',
      category: '장비서류',
      hasOcr: true,
      hasExpiryManagement: true,
      expiryFieldName: '면허유효기간',
      hasVerification: true,
      verificationProvider: '경찰청',
    ),
    DocumentType(
      name: '안전점검표',
      category: '장비서류',
      hasOcr: false,
      hasExpiryManagement: false,
      expiryFieldName: '',
      hasVerification: false,
      verificationProvider: '',
    ),
    // 인력서류
    DocumentType(
      name: '신분증 (주민등록증)',
      category: '인력서류',
      hasOcr: true,
      hasExpiryManagement: false,
      expiryFieldName: '',
      hasVerification: false,
      verificationProvider: '',
    ),
    DocumentType(
      name: '운전면허증',
      category: '인력서류',
      hasOcr: true,
      hasExpiryManagement: true,
      expiryFieldName: '적성검사만료일',
      hasVerification: true,
      verificationProvider: '경찰청',
    ),
    DocumentType(
      name: '기초안전보건교육 이수증',
      category: '인력서류',
      hasOcr: true,
      hasExpiryManagement: true,
      expiryFieldName: '교육유효기간',
      hasVerification: false,
      verificationProvider: '',
    ),
    DocumentType(
      name: '화물운송 종사자격증',
      category: '인력서류',
      hasOcr: true,
      hasExpiryManagement: false,
      expiryFieldName: '',
      hasVerification: true,
      verificationProvider: '한국교통안전공단',
    ),
    DocumentType(
      name: '조종자격 수료증',
      category: '인력서류',
      hasOcr: true,
      hasExpiryManagement: false,
      expiryFieldName: '',
      hasVerification: false,
      verificationProvider: '',
    ),
    DocumentType(
      name: '건설기계조종사 면허증',
      category: '인력서류',
      hasOcr: true,
      hasExpiryManagement: true,
      expiryFieldName: '면허유효기간',
      hasVerification: true,
      verificationProvider: '경찰청',
    ),
    DocumentType(
      name: '이동식크레인 조종자격 교육수료증',
      category: '인력서류',
      hasOcr: true,
      hasExpiryManagement: false,
      expiryFieldName: '',
      hasVerification: false,
      verificationProvider: '',
    ),
    DocumentType(
      name: '고소작업대 자격교육 수료증',
      category: '인력서류',
      hasOcr: true,
      hasExpiryManagement: false,
      expiryFieldName: '',
      hasVerification: false,
      verificationProvider: '',
    ),
    DocumentType(
      name: '건설기계조종사 안전교육 이수증',
      category: '인력서류',
      hasOcr: true,
      hasExpiryManagement: true,
      expiryFieldName: '교육유효기간',
      hasVerification: true,
      verificationProvider: '안전보건공단',
    ),
    DocumentType(
      name: '배치건강진단서',
      category: '인력서류',
      hasOcr: true,
      hasExpiryManagement: true,
      expiryFieldName: '유효기간',
      hasVerification: false,
      verificationProvider: '',
    ),
    DocumentType(
      name: '특수형태근로자 교육 실시확인서',
      category: '인력서류',
      hasOcr: true,
      hasExpiryManagement: true,
      expiryFieldName: '연1회',
      hasVerification: true,
      verificationProvider: '안전보건공단',
    ),
    DocumentType(
      name: '건강검진 결과서',
      category: '인력서류',
      hasOcr: true,
      hasExpiryManagement: true,
      expiryFieldName: '',
      hasVerification: false,
      verificationProvider: '',
    ),
  ];

  List<DocumentType> get all => List.unmodifiable(_documentTypes);

  List<DocumentType> getByCategory(String category) =>
      _documentTypes.where((d) => d.category == category).toList();

  void add(DocumentType doc) => _documentTypes.add(doc);

  void update(int index, DocumentType doc) {
    if (index >= 0 && index < _documentTypes.length) {
      _documentTypes[index] = doc;
    }
  }

  void removeAt(int index) {
    if (index >= 0 && index < _documentTypes.length) {
      _documentTypes.removeAt(index);
    }
  }
}

/// 서류 유형 관리 페이지
class DocumentTypeMasterPage extends StatefulWidget {
  const DocumentTypeMasterPage({Key? key}) : super(key: key);

  @override
  State<DocumentTypeMasterPage> createState() => _DocumentTypeMasterPageState();
}

class _DocumentTypeMasterPageState extends State<DocumentTypeMasterPage> {
  final DocumentTypeRepository _repo = DocumentTypeRepository.instance;
  String _selectedTab = '전체';

  static const List<String> _verificationProviders = [
    '정부24',
    '국세청',
    '경찰청',
    '한국교통안전공단',
    '대한산업안전협회',
    '안전보건공단',
  ];

  List<DocumentType> get _filteredList {
    if (_selectedTab == '전체') return _repo.all;
    return _repo.getByCategory(_selectedTab);
  }

  int _getGlobalIndex(DocumentType doc) {
    return _repo.all.indexOf(doc);
  }

  void _showAddEditDialog({DocumentType? existing, int? globalIndex}) {
    final nameController =
        TextEditingController(text: existing?.name ?? '');
    String category = existing?.category ?? '장비서류';
    bool hasOcr = existing?.hasOcr ?? true;
    bool hasExpiryManagement = existing?.hasExpiryManagement ?? false;
    final expiryFieldController =
        TextEditingController(text: existing?.expiryFieldName ?? '');
    bool hasVerification = existing?.hasVerification ?? false;
    String verificationProvider = existing?.verificationProvider ?? '';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? '서류 유형 추가' : '서류 유형 수정'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: '서류명',
                          hintText: '예: 자동차등록증',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('분류',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('장비서류'),
                            selected: category == '장비서류',
                            onSelected: (val) {
                              if (val) {
                                setDialogState(() => category = '장비서류');
                              }
                            },
                            selectedColor:
                                AppColors.primary.withOpacity(0.2),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('인력서류'),
                            selected: category == '인력서류',
                            onSelected: (val) {
                              if (val) {
                                setDialogState(() => category = '인력서류');
                              }
                            },
                            selectedColor:
                                const Color(0xFF4CAF50).withOpacity(0.2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('OCR 지원'),
                        value: hasOcr,
                        onChanged: (val) =>
                            setDialogState(() => hasOcr = val),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('만료일 관리'),
                        value: hasExpiryManagement,
                        onChanged: (val) =>
                            setDialogState(() => hasExpiryManagement = val),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      if (hasExpiryManagement) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: expiryFieldController,
                          decoration: const InputDecoration(
                            labelText: '만료일 필드명 (선택)',
                            hintText: '예: 검사유효기간, 보험만료일',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      const Divider(),
                      SwitchListTile(
                        title: const Text('검증/진위확인'),
                        value: hasVerification,
                        onChanged: (val) =>
                            setDialogState(() => hasVerification = val),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      if (hasVerification) ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: verificationProvider.isEmpty
                              ? null
                              : verificationProvider,
                          decoration: const InputDecoration(
                            labelText: '검증기관',
                            border: OutlineInputBorder(),
                          ),
                          items: _verificationProviders
                              .map((p) => DropdownMenuItem(
                                  value: p, child: Text(p)))
                              .toList(),
                          onChanged: (val) {
                            setDialogState(
                                () => verificationProvider = val ?? '');
                          },
                        ),
                      ],
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
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    final doc = DocumentType(
                      name: nameController.text.trim(),
                      category: category,
                      hasOcr: hasOcr,
                      hasExpiryManagement: hasExpiryManagement,
                      expiryFieldName: expiryFieldController.text.trim(),
                      hasVerification: hasVerification,
                      verificationProvider: verificationProvider,
                    );
                    setState(() {
                      if (globalIndex != null) {
                        _repo.update(globalIndex, doc);
                      } else {
                        _repo.add(doc);
                      }
                    });
                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(int globalIndex) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('삭제 확인'),
          content: Text(
              "'${_repo.all[globalIndex].name}' 서류 유형을 삭제하시겠습니까?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _repo.removeAt(globalIndex));
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
              ),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryBadge(String category) {
    final isEquipment = category == '장비서류';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isEquipment
            ? AppColors.primary.withOpacity(0.1)
            : const Color(0xFF4CAF50).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isEquipment ? '장비' : '인력',
        style: TextStyle(
          color: isEquipment ? AppColors.primary : const Color(0xFF4CAF50),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildCheckCell(bool value, {String? detail}) {
    if (!value) {
      return const Text('--',
          style: TextStyle(color: AppColors.grey, fontSize: 13));
    }
    if (detail != null && detail.isNotEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('\u2705', style: TextStyle(fontSize: 14)),
          Text(detail,
              style: const TextStyle(fontSize: 11, color: AppColors.greyDark)),
        ],
      );
    }
    return const Text('\u2705', style: TextStyle(fontSize: 14));
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredList;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('서류 유형 관리', style: AppTextStyles.headlineLarge),
                    const SizedBox(height: 4),
                    Text(
                      '장비/인력에 사용되는 서류 유형 마스터 데이터를 관리합니다.',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('서류 유형 추가'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 탭 필터
          Row(
            children: [
              _buildTabChip('전체', _repo.all.length),
              const SizedBox(width: 8),
              _buildTabChip('장비서류', _repo.getByCategory('장비서류').length),
              const SizedBox(width: 8),
              _buildTabChip('인력서류', _repo.getByCategory('인력서류').length),
            ],
          ),
          const SizedBox(height: 20),
          // 테이블
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(AppColors.greyLight),
                columns: const [
                  DataColumn(label: Text('서류명')),
                  DataColumn(label: Text('분류')),
                  DataColumn(label: Text('OCR')),
                  DataColumn(label: Text('만료일 관리')),
                  DataColumn(label: Text('진위확인')),
                  DataColumn(label: Text('관리')),
                ],
                rows: List.generate(filteredList.length, (i) {
                  final doc = filteredList[i];
                  final globalIdx = _getGlobalIndex(doc);
                  return DataRow(
                    cells: [
                      DataCell(Text(doc.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500))),
                      DataCell(_buildCategoryBadge(doc.category)),
                      DataCell(Text(doc.hasOcr ? '\u2705' : '\u274C',
                          style: const TextStyle(fontSize: 14))),
                      DataCell(_buildCheckCell(doc.hasExpiryManagement,
                          detail: doc.expiryFieldName)),
                      DataCell(_buildCheckCell(doc.hasVerification,
                          detail: doc.verificationProvider)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  size: 18, color: AppColors.primary),
                              tooltip: '수정',
                              onPressed: () => _showAddEditDialog(
                                  existing: doc,
                                  globalIndex: globalIdx),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: AppColors.error),
                              tooltip: '삭제',
                              onPressed: () =>
                                  _showDeleteDialog(globalIdx),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(String label, int count) {
    final isSelected = _selectedTab == label;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedTab = label),
      selectedColor: AppColors.primary.withOpacity(0.15),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.greyDark,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
    );
  }
}
