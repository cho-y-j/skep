import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';
import 'package:skep_app/features/dashboard/view/document_type_master_page.dart';

/// 등록된 인력 모델
class RegisteredPersonnel {
  final String personnelType;
  final String name;
  final String phone;
  final String birthDate;
  final DateTime registeredAt;
  final Map<String, UploadedPersonnelDocument> documents;

  RegisteredPersonnel({
    required this.personnelType,
    required this.name,
    required this.phone,
    required this.birthDate,
    required this.registeredAt,
    required this.documents,
  });

  int get completedDocCount =>
      documents.values.where((d) => d.fileName != null).length;
  int get totalDocCount => documents.length;
  bool get isDocComplete => completedDocCount == totalDocCount;

  /// 서류 상태 계산
  PersonnelDocStatus get docStatus {
    if (documents.isEmpty) return PersonnelDocStatus.incomplete;
    final now = DateTime.now();
    bool hasExpired = false;
    bool hasExpiringSoon = false;
    bool hasMissing = false;

    for (final entry in documents.entries) {
      final doc = entry.value;
      if (doc.fileName == null) {
        hasMissing = true;
        continue;
      }
      if (doc.expiryDate != null) {
        final daysLeft = doc.expiryDate!.difference(now).inDays;
        if (daysLeft < 0) {
          hasExpired = true;
        } else if (daysLeft <= 30) {
          hasExpiringSoon = true;
        }
      }
    }

    if (hasExpired) return PersonnelDocStatus.expired;
    if (hasMissing) return PersonnelDocStatus.incomplete;
    if (hasExpiringSoon) return PersonnelDocStatus.expiringSoon;
    return PersonnelDocStatus.complete;
  }
}

enum PersonnelDocStatus { complete, expiringSoon, incomplete, expired }

/// 업로드된 서류 모델
class UploadedPersonnelDocument {
  String? fileName;
  DateTime? uploadedAt;
  DateTime? expiryDate;
  Uint8List? fileBytes;
  PersonnelVerificationStatus verificationStatus;

  UploadedPersonnelDocument({
    this.fileName,
    this.uploadedAt,
    this.expiryDate,
    this.fileBytes,
    this.verificationStatus = PersonnelVerificationStatus.pending,
  });
}

enum PersonnelVerificationStatus {
  pending,
  verifying,
  verified,
  failed,
}

/// 인력 유형 저장소 (싱글톤)
class PersonnelTypeRepository {
  PersonnelTypeRepository._();
  static final PersonnelTypeRepository instance = PersonnelTypeRepository._();

  final List<Map<String, dynamic>> _personnelTypes = [
    {
      'code': 'DR',
      'type': '장비 운전원',
      'documents': [
        '운전면허증',
        '기초안전보건교육 이수증',
        '화물운송 종사자격증',
        '조종자격 수료증',
        '특수형태근로자 교육 실시확인서',
        '건강검진 결과서',
      ],
    },
    {
      'code': 'GD',
      'type': '안전유도원',
      'documents': [
        '운전면허증',
        '기초안전보건교육 이수증',
        '특수형태근로자 교육 실시확인서',
        '건강검진 결과서',
      ],
    },
  ];

  List<Map<String, dynamic>> get all => List.unmodifiable(_personnelTypes);

  List<String> get typeNames =>
      _personnelTypes.map((e) => e['type'] as String).toList();

  List<String> getRequiredDocuments(String typeName) {
    for (final pt in _personnelTypes) {
      if (pt['type'] == typeName) {
        return List<String>.from(pt['documents'] as List);
      }
    }
    return [];
  }
}

/// 전역 인력 목록 (공급사 대시보드에서 공유)
class PersonnelListStore {
  PersonnelListStore._();
  static final PersonnelListStore instance = PersonnelListStore._();
  final List<RegisteredPersonnel> personnelList = [];
}

/// 공급사 인력 관리 페이지 (목록 + 상세)
class SupplierPersonnelPage extends StatefulWidget {
  const SupplierPersonnelPage({Key? key}) : super(key: key);

  @override
  State<SupplierPersonnelPage> createState() => _SupplierPersonnelPageState();
}

class _SupplierPersonnelPageState extends State<SupplierPersonnelPage> {
  final DocumentTypeRepository _docRepo = DocumentTypeRepository.instance;
  List<RegisteredPersonnel> get _personnelList =>
      PersonnelListStore.instance.personnelList;

  int? _expandedIndex;

  // 검색 & 필터 & 정렬
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = '전체';
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RegisteredPersonnel> get _filteredList {
    var list = List<RegisteredPersonnel>.from(_personnelList);

    // 상태 필터
    if (_statusFilter != '전체') {
      list = list.where((p) {
        switch (_statusFilter) {
          case '완료':
            return p.docStatus == PersonnelDocStatus.complete;
          case '만료임박':
            return p.docStatus == PersonnelDocStatus.expiringSoon;
          case '서류미비':
            return p.docStatus == PersonnelDocStatus.incomplete;
          case '만료':
            return p.docStatus == PersonnelDocStatus.expired;
          default:
            return true;
        }
      }).toList();
    }

    // 검색 필터
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.personnelType.toLowerCase().contains(query) ||
            p.phone.toLowerCase().contains(query);
      }).toList();
    }

    // 정렬
    if (_sortColumnIndex != null) {
      list.sort((a, b) {
        int result;
        switch (_sortColumnIndex) {
          case 0:
            result = a.name.compareTo(b.name);
            break;
          case 1:
            result = a.personnelType.compareTo(b.personnelType);
            break;
          case 2:
            result = a.phone.compareTo(b.phone);
            break;
          case 3:
            result = a.docStatus.index.compareTo(b.docStatus.index);
            break;
          case 4:
            result = a.registeredAt.compareTo(b.registeredAt);
            break;
          default:
            result = 0;
        }
        return _sortAscending ? result : -result;
      });
    }

    return list;
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  void _deletePersonnel(int originalIndex) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Text("'${_personnelList[originalIndex].name}' 인력을 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _personnelList.removeAt(originalIndex));
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
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
          // 헤더
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('인력 관리', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
              const SizedBox(height: 4),
              Text('등록된 인력 목록을 확인하고 상세 정보를 관리하세요.', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 20),
          // 검색 & 필터
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '이름, 인력유형, 연락처로 검색...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['전체', '완료', '만료임박', '서류미비', '만료'].map((label) {
                      final isSelected = _statusFilter == label;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _statusFilter = label),
                          selectedColor: AppColors.primary.withOpacity(0.15),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? AppColors.primary : const Color(0xFF64748B)),
                          side: BorderSide(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_personnelList.isEmpty)
            _buildEmptyState()
          else if (_filteredList.isEmpty)
            _buildNoResultState()
          else
            _buildPersonnelList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          const Icon(Icons.people_outlined, size: 56, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          const Text('등록된 인력이 없습니다', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
          const SizedBox(height: 8),
          Text('인력 등록 메뉴에서 인력을 등록해 주세요.', style: TextStyle(fontSize: 13, color: const Color(0xFFCBD5E1))),
        ],
      ),
    );
  }

  Widget _buildNoResultState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 56, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          const Text('검색 결과가 없습니다', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
          const SizedBox(height: 8),
          Text('다른 검색어나 필터를 시도해 주세요.', style: TextStyle(fontSize: 13, color: const Color(0xFFCBD5E1))),
        ],
      ),
    );
  }

  Widget _buildPersonnelList() {
    final filtered = _filteredList;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text('총 ${filtered.length}건', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
              if (_statusFilter != '전체' || _searchQuery.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text('(필터 적용됨)', style: TextStyle(fontSize: 12, color: AppColors.primary)),
              ],
            ],
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              headingTextStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              dataTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
              columns: [
                DataColumn(label: const Text('이름'), onSort: _onSort),
                DataColumn(label: const Text('인력유형'), onSort: _onSort),
                DataColumn(label: const Text('연락처'), onSort: _onSort),
                DataColumn(label: const Text('서류상태'), onSort: _onSort),
                DataColumn(label: const Text('등록일'), onSort: _onSort),
                const DataColumn(label: Text('관리')),
              ],
              rows: List.generate(filtered.length, (i) {
                final p = filtered[i];
                final originalIndex = _personnelList.indexOf(p);
                return DataRow(
                  selected: _expandedIndex != null && originalIndex == _expandedIndex,
                  onSelectChanged: (_) {
                    setState(() {
                      _expandedIndex = _expandedIndex == originalIndex ? null : originalIndex;
                    });
                  },
                  cells: [
                    DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text(p.personnelType)),
                    DataCell(Text(p.phone)),
                    DataCell(_buildDocStatusBadge(p)),
                    DataCell(Text(
                      '${p.registeredAt.year}.${p.registeredAt.month.toString().padLeft(2, '0')}.${p.registeredAt.day.toString().padLeft(2, '0')}',
                    )),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(_expandedIndex == originalIndex ? Icons.expand_less : Icons.expand_more, size: 18, color: AppColors.primary),
                            tooltip: '상세보기',
                            onPressed: () {
                              setState(() {
                                _expandedIndex = _expandedIndex == originalIndex ? null : originalIndex;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                            tooltip: '삭제',
                            onPressed: () => _deletePersonnel(originalIndex),
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
        if (_expandedIndex != null && _expandedIndex! < _personnelList.length)
          _buildPersonnelDetail(_personnelList[_expandedIndex!]),
      ],
    );
  }

  Widget _buildDocStatusBadge(RegisteredPersonnel p) {
    final status = p.docStatus;
    String label;
    Color color;

    switch (status) {
      case PersonnelDocStatus.complete:
        label = '완료';
        color = AppColors.success;
        break;
      case PersonnelDocStatus.expiringSoon:
        label = '만료임박';
        color = const Color(0xFFFF9800);
        break;
      case PersonnelDocStatus.incomplete:
        label = '서류미비';
        color = AppColors.error;
        break;
      case PersonnelDocStatus.expired:
        label = '만료';
        color = const Color(0xFFD32F2F);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Widget _buildPersonnelDetail(RegisteredPersonnel p) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_outlined, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Text('${p.personnelType} - ${p.name}', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.primary)),
                  const Spacer(),
                  _buildDocStatusBadge(p),
                ],
              ),
            ),
            const TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.grey,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: '기본정보'),
                Tab(text: '서류현황'),
                Tab(text: '투입이력'),
              ],
            ),
            SizedBox(
              height: 350,
              child: TabBarView(
                children: [
                  _buildBasicInfoTab(p),
                  _buildDocumentsTab(p),
                  _buildDeploymentTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab(RegisteredPersonnel p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('이름', p.name),
          _buildInfoRow('인력유형', p.personnelType),
          _buildInfoRow('연락처', p.phone),
          _buildInfoRow('생년월일', p.birthDate.isEmpty ? '-' : p.birthDate),
          _buildInfoRow('등록일', '${p.registeredAt.year}.${p.registeredAt.month.toString().padLeft(2, '0')}.${p.registeredAt.day.toString().padLeft(2, '0')}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey))),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab(RegisteredPersonnel p) {
    final now = DateTime.now();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: p.documents.entries.map((entry) {
          final docName = entry.key;
          final doc = entry.value;
          final hasFile = doc.fileName != null;

          String? dDayText;
          Color? dDayColor;
          if (doc.expiryDate != null) {
            final daysLeft = doc.expiryDate!.difference(now).inDays;
            if (daysLeft < 0) {
              dDayText = 'D+${-daysLeft} (만료)';
              dDayColor = const Color(0xFFD32F2F);
            } else if (daysLeft <= 30) {
              dDayText = 'D-$daysLeft';
              dDayColor = const Color(0xFFFF9800);
            } else {
              dDayText = 'D-$daysLeft';
              dDayColor = AppColors.success;
            }
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasFile ? AppColors.success.withOpacity(0.03) : AppColors.error.withOpacity(0.03),
              border: Border.all(color: hasFile ? AppColors.success.withOpacity(0.2) : AppColors.error.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (hasFile && doc.fileBytes != null)
                  GestureDetector(
                    onTap: () => _showImageDialog(doc),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: _isImageFile(doc.fileName!)
                          ? Image.memory(doc.fileBytes!, width: 48, height: 48, fit: BoxFit.cover)
                          : Container(width: 48, height: 48, color: Colors.grey[200], child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 24)),
                    ),
                  )
                else
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                    child: Icon(Icons.insert_drive_file_outlined, color: Colors.grey[400], size: 24),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(docName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      if (hasFile) ...[
                        const SizedBox(height: 2),
                        Text(
                          '업로드: ${doc.uploadedAt!.year}.${doc.uploadedAt!.month.toString().padLeft(2, '0')}.${doc.uploadedAt!.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 11, color: AppColors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
                if (dDayText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: dDayColor!.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(dDayText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: dDayColor)),
                  ),
                const SizedBox(width: 8),
                if (hasFile) _buildVerifyBadge(doc.verificationStatus),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  bool _isImageFile(String fileName) {
    final lower = fileName.toLowerCase();
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png');
  }

  void _showImageDialog(UploadedPersonnelDocument doc) {
    if (doc.fileBytes == null) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(doc.fileName ?? '미리보기'),
              automaticallyImplyLeading: false,
              actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop())],
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 500, maxWidth: 600),
              child: _isImageFile(doc.fileName ?? '')
                  ? Image.memory(doc.fileBytes!, fit: BoxFit.contain)
                  : const Center(child: Padding(padding: EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.picture_as_pdf, size: 64, color: Colors.red), SizedBox(height: 12), Text('PDF 파일은 미리보기가 지원되지 않습니다.')]))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyBadge(PersonnelVerificationStatus status) {
    String label;
    Color color;
    switch (status) {
      case PersonnelVerificationStatus.pending:
        label = '대기';
        color = AppColors.warning;
        break;
      case PersonnelVerificationStatus.verifying:
        label = '검증중';
        color = AppColors.primary;
        break;
      case PersonnelVerificationStatus.verified:
        label = '완료';
        color = AppColors.success;
        break;
      case PersonnelVerificationStatus.failed:
        label = '실패';
        color = AppColors.error;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildDeploymentTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment_outlined, size: 56, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          const Text('투입 이력이 없습니다', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
          const SizedBox(height: 8),
          Text('투입 현황 메뉴에서 확인하세요.', style: TextStyle(fontSize: 13, color: const Color(0xFFCBD5E1))),
        ],
      ),
    );
  }

  DocumentType? _findDocType(String name) {
    final docs = _docRepo.getByCategory('인력서류');
    for (final d in docs) {
      if (d.name == name) return d;
    }
    return null;
  }
}
