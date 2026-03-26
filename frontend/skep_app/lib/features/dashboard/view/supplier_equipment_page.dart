import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';
import 'package:skep_app/features/dashboard/view/document_type_master_page.dart';

/// 등록된 장비 모델
class RegisteredEquipment {
  final String vehicleNumber;
  final String equipmentType;
  final String modelName;
  final String manufacturer;
  final String manufacturingYear;
  final DateTime registeredAt;
  final Map<String, UploadedEquipmentDocument> documents;
  final List<MaintenanceRecord> maintenanceRecords;

  RegisteredEquipment({
    required this.vehicleNumber,
    required this.equipmentType,
    required this.modelName,
    required this.manufacturer,
    required this.manufacturingYear,
    required this.registeredAt,
    required this.documents,
    List<MaintenanceRecord>? maintenanceRecords,
  }) : maintenanceRecords = maintenanceRecords ?? [];

  int get completedDocCount =>
      documents.values.where((d) => d.fileName != null).length;
  int get totalDocCount => documents.length;
  bool get isDocComplete => completedDocCount == totalDocCount;

  /// 서류 상태 계산
  DocStatusType get docStatus {
    if (documents.isEmpty) return DocStatusType.incomplete;
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

    if (hasExpired) return DocStatusType.expired;
    if (hasMissing) return DocStatusType.incomplete;
    if (hasExpiringSoon) return DocStatusType.expiringSoon;
    return DocStatusType.complete;
  }
}

enum DocStatusType { complete, expiringSoon, incomplete, expired }

/// 업로드된 서류 모델
class UploadedEquipmentDocument {
  String? fileName;
  DateTime? uploadedAt;
  DateTime? expiryDate;
  Uint8List? fileBytes;
  EquipmentVerificationStatus verificationStatus;

  UploadedEquipmentDocument({
    this.fileName,
    this.uploadedAt,
    this.expiryDate,
    this.fileBytes,
    this.verificationStatus = EquipmentVerificationStatus.pending,
  });
}

enum EquipmentVerificationStatus {
  pending,
  verifying,
  verified,
  failed,
}

/// 정비 기록 모델
class MaintenanceRecord {
  final DateTime date;
  final String mileage;
  final String engineOil;
  final String hydraulicOil;
  final String coolant;
  final String fuelLevel;
  final String remarks;

  MaintenanceRecord({
    required this.date,
    this.mileage = '',
    this.engineOil = '',
    this.hydraulicOil = '',
    this.coolant = '',
    this.fuelLevel = '',
    this.remarks = '',
  });
}

/// 장비 유형 저장소 (싱글톤) - 장비 유형별 필수 서류 매핑
class EquipmentTypeRepository {
  EquipmentTypeRepository._();
  static final EquipmentTypeRepository instance = EquipmentTypeRepository._();

  final List<Map<String, dynamic>> _equipmentTypes = [
    {
      'code': 'TC',
      'type': '타워크레인',
      'documents': [
        '자동차 등록원부(갑)',
        '자동차등록증',
        '사업자등록증',
        '자동차보험 가입증명서',
        '안전인증서 (KCs)',
        '비파괴 검사서',
      ],
    },
    {
      'code': 'MC',
      'type': '이동식크레인',
      'documents': [
        '자동차 등록원부(갑)',
        '자동차등록증',
        '자동차보험 가입증명서',
        '장비 제원표',
      ],
    },
    {
      'code': 'EX',
      'type': '굴착기',
      'documents': [
        '자동차 등록원부(갑)',
        '자동차등록증',
        '자동차보험 가입증명서',
      ],
    },
    {
      'code': 'FL',
      'type': '지게차',
      'documents': [
        '자동차 등록원부(갑)',
        '자동차등록증',
        '자동차보험 가입증명서',
        '안전인증서 (KCs)',
      ],
    },
    {
      'code': 'AW',
      'type': '고소작업차',
      'documents': [
        '자동차 등록원부(갑)',
        '자동차등록증',
        '자동차보험 가입증명서',
        '안전인증서 (KCs)',
      ],
    },
    {
      'code': 'PD',
      'type': '항타기/항발기',
      'documents': [
        '자동차 등록원부(갑)',
        '자동차등록증',
        '자동차보험 가입증명서',
      ],
    },
    {
      'code': 'CP',
      'type': '콘크리트펌프카',
      'documents': [
        '자동차 등록원부(갑)',
        '자동차등록증',
        '사업자등록증',
        '자동차보험 가입증명서',
      ],
    },
  ];

  List<Map<String, dynamic>> get all => List.unmodifiable(_equipmentTypes);

  List<String> get typeNames =>
      _equipmentTypes.map((e) => e['type'] as String).toList();

  List<String> getRequiredDocuments(String typeName) {
    for (final et in _equipmentTypes) {
      if (et['type'] == typeName) {
        return List<String>.from(et['documents'] as List);
      }
    }
    return [];
  }
}

/// 전역 장비 목록 (공급사 대시보드에서 공유)
class EquipmentListStore {
  EquipmentListStore._();
  static final EquipmentListStore instance = EquipmentListStore._();
  final List<RegisteredEquipment> equipmentList = [];
}

/// 공급사 장비 관리 페이지 (목록 + 상세)
class SupplierEquipmentPage extends StatefulWidget {
  const SupplierEquipmentPage({Key? key}) : super(key: key);

  @override
  State<SupplierEquipmentPage> createState() => _SupplierEquipmentPageState();
}

class _SupplierEquipmentPageState extends State<SupplierEquipmentPage> {
  final DocumentTypeRepository _docRepo = DocumentTypeRepository.instance;
  List<Map<String, dynamic>> _apiEquipments = [];
  bool _isLoading = true;
  String? _error;

  int? _expandedIndex;

  // 검색 & 필터 & 정렬
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = '전체';
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEquipments());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEquipments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dioClient = context.read<DioClient>();
      final response = await dioClient.get<dynamic>(ApiEndpoints.equipments);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List) {
          _apiEquipments = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['content'] is List) {
          _apiEquipments = (data['content'] as List).cast<Map<String, dynamic>>();
        } else {
          _apiEquipments = [];
        }
      }
    } catch (e) {
      _error = e.toString();
      _apiEquipments = [];
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEquipmentApi(int index) async {
    final eq = _apiEquipments[index];
    final id = eq['id'];
    if (id == null) return;
    try {
      final dioClient = context.read<DioClient>();
      await dioClient.delete<dynamic>(
        ApiEndpoints.equipment.replaceAll('{id}', id.toString()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('장비가 삭제되었습니다.'), backgroundColor: AppColors.success),
      );
      _loadEquipments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredList {
    var list = List<Map<String, dynamic>>.from(_apiEquipments);

    // 상태 필터
    if (_statusFilter != '전체') {
      list = list.where((eq) {
        final status = eq['status']?.toString();
        switch (_statusFilter) {
          case '완료':
            return status == 'ACTIVE' || status == 'DEPLOYED';
          case '만료임박':
            return status == 'EXPIRING_SOON';
          case '서류미비':
            return status == 'INCOMPLETE';
          case '만료':
            return status == 'EXPIRED' || status == 'INACTIVE';
          default:
            return true;
        }
      }).toList();
    }

    // 검색 필터
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((eq) {
        final vehicleNumber = (eq['vehicleNumber'] ?? eq['vehicle_number'] ?? '').toString().toLowerCase();
        final equipmentType = (eq['type'] ?? eq['equipment_type'] ?? eq['equipmentType'] ?? '').toString().toLowerCase();
        final modelName = (eq['model'] ?? eq['modelName'] ?? eq['model_name'] ?? '').toString().toLowerCase();
        final manufacturer = (eq['manufacturer'] ?? '').toString().toLowerCase();
        return vehicleNumber.contains(query) ||
            equipmentType.contains(query) ||
            modelName.contains(query) ||
            manufacturer.contains(query);
      }).toList();
    }

    // 정렬
    if (_sortColumnIndex != null) {
      list.sort((a, b) {
        int result;
        switch (_sortColumnIndex) {
          case 0:
            result = (a['vehicleNumber'] ?? a['vehicle_number'] ?? '').toString().compareTo((b['vehicleNumber'] ?? b['vehicle_number'] ?? '').toString());
            break;
          case 1:
            result = (a['type'] ?? a['equipment_type'] ?? '').toString().compareTo((b['type'] ?? b['equipment_type'] ?? '').toString());
            break;
          case 2:
            result = (a['model'] ?? a['modelName'] ?? '').toString().compareTo((b['model'] ?? b['modelName'] ?? '').toString());
            break;
          case 3:
            result = (a['status'] ?? '').toString().compareTo((b['status'] ?? '').toString());
            break;
          case 4:
            result = (a['createdAt'] ?? a['created_at'] ?? '').toString().compareTo((b['createdAt'] ?? b['created_at'] ?? '').toString());
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

  void _deleteEquipment(int originalIndex) {
    final eq = _apiEquipments[originalIndex];
    final name = eq['vehicleNumber'] ?? eq['vehicle_number'] ?? eq['name'] ?? '장비';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Text("'$name' 장비를 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteEquipmentApi(originalIndex);
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('장비 관리', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text('등록된 장비 목록을 확인하고 상세 정보를 관리하세요.', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _loadEquipments,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('새로고침'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
              ),
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
                    hintText: '차량번호, 장비유형, 모델명으로 검색...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
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
                          labelStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? AppColors.primary : const Color(0xFF64748B),
                          ),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                          ),
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
          if (_isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text('데이터를 불러오는데 실패했습니다', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
                  const SizedBox(height: 8),
                  Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  TextButton(onPressed: _loadEquipments, child: const Text('다시 시도')),
                ],
              ),
            )
          else if (_apiEquipments.isEmpty)
            _buildEmptyState()
          else if (_filteredList.isEmpty)
            _buildNoResultState()
          else
            _buildEquipmentList(),
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
          const Icon(Icons.build_outlined, size: 56, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          const Text('등록된 장비가 없습니다', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
          const SizedBox(height: 8),
          Text('장비 등록 메뉴에서 장비를 등록해 주세요.', style: TextStyle(fontSize: 13, color: const Color(0xFFCBD5E1))),
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

  String _translateStatus(String? status) {
    switch (status) {
      case 'ACTIVE': return '가동중';
      case 'INACTIVE': return '미가동';
      case 'MAINTENANCE': return '정비중';
      case 'DEPLOYED': return '투입중';
      case 'EXPIRED': return '만료';
      case 'EXPIRING_SOON': return '만료임박';
      case 'INCOMPLETE': return '서류미비';
      default: return status ?? '-';
    }
  }

  Color _apiStatusColor(String? status) {
    switch (status) {
      case 'ACTIVE':
      case 'DEPLOYED':
        return AppColors.success;
      case 'INACTIVE':
      case 'EXPIRED':
        return AppColors.error;
      case 'MAINTENANCE':
      case 'EXPIRING_SOON':
        return const Color(0xFFFF9800);
      case 'INCOMPLETE':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return date.toString();
    }
  }

  Widget _buildEquipmentList() {
    final filtered = _filteredList;
    return Column(
      children: [
        // 결과 카운트
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
        // 테이블
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
                DataColumn(label: const Text('차량번호'), onSort: _onSort),
                DataColumn(label: const Text('장비유형'), onSort: _onSort),
                DataColumn(label: const Text('모델명'), onSort: _onSort),
                DataColumn(label: const Text('상태'), onSort: _onSort),
                DataColumn(label: const Text('등록일'), onSort: _onSort),
                const DataColumn(label: Text('관리')),
              ],
              rows: List.generate(filtered.length, (i) {
                final eq = filtered[i];
                final originalIndex = _apiEquipments.indexOf(eq);
                final status = eq['status']?.toString();
                return DataRow(
                  selected: _expandedIndex != null && originalIndex == _expandedIndex,
                  onSelectChanged: (_) {
                    setState(() {
                      _expandedIndex = _expandedIndex == originalIndex ? null : originalIndex;
                    });
                  },
                  cells: [
                    DataCell(Text(
                      (eq['vehicleNumber'] ?? eq['vehicle_number'] ?? eq['name'] ?? '-').toString(),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    )),
                    DataCell(Text((eq['type'] ?? eq['equipment_type'] ?? eq['equipmentType'] ?? '-').toString())),
                    DataCell(Text((eq['model'] ?? eq['modelName'] ?? eq['model_name'] ?? '-').toString())),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _apiStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _translateStatus(status),
                        style: TextStyle(color: _apiStatusColor(status), fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    )),
                    DataCell(Text(_formatDate(eq['createdAt'] ?? eq['created_at']))),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _expandedIndex == originalIndex
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            tooltip: '상세보기',
                            onPressed: () {
                              setState(() {
                                _expandedIndex =
                                    _expandedIndex == originalIndex ? null : originalIndex;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: AppColors.error),
                            tooltip: '삭제',
                            onPressed: () => _deleteEquipment(originalIndex),
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
        // 상세 패널 (API data)
        if (_expandedIndex != null &&
            _expandedIndex! < _apiEquipments.length)
          _buildApiEquipmentDetail(_apiEquipments[_expandedIndex!]),
      ],
    );
  }

  Widget _buildApiEquipmentDetail(Map<String, dynamic> eq) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.build_outlined, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                '${eq['type'] ?? eq['equipment_type'] ?? '-'} - ${eq['vehicleNumber'] ?? eq['vehicle_number'] ?? eq['name'] ?? '-'}',
                style: AppTextStyles.headlineSmall.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('차량번호', (eq['vehicleNumber'] ?? eq['vehicle_number'] ?? '-').toString()),
          _buildInfoRow('장비유형', (eq['type'] ?? eq['equipment_type'] ?? '-').toString()),
          _buildInfoRow('모델명', (eq['model'] ?? eq['modelName'] ?? '-').toString()),
          _buildInfoRow('제조사', (eq['manufacturer'] ?? '-').toString()),
          _buildInfoRow('상태', _translateStatus(eq['status']?.toString())),
          _buildInfoRow('등록일', _formatDate(eq['createdAt'] ?? eq['created_at'])),
        ],
      ),
    );
  }

  Widget _buildDocStatusBadge(RegisteredEquipment eq) {
    final status = eq.docStatus;
    String label;
    Color color;

    switch (status) {
      case DocStatusType.complete:
        label = '완료';
        color = AppColors.success;
        break;
      case DocStatusType.expiringSoon:
        label = '만료임박';
        color = const Color(0xFFFF9800);
        break;
      case DocStatusType.incomplete:
        label = '서류미비';
        color = AppColors.error;
        break;
      case DocStatusType.expired:
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
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  /// 장비 상세 뷰 (탭 사용)
  Widget _buildEquipmentDetail(RegisteredEquipment eq) {
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
        length: 4,
        child: Column(
          children: [
            // 장비 헤더
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  Icon(Icons.build_outlined,
                      color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    '${eq.equipmentType} - ${eq.vehicleNumber}',
                    style: AppTextStyles.headlineSmall
                        .copyWith(color: AppColors.primary),
                  ),
                  const Spacer(),
                  _buildDocStatusBadge(eq),
                ],
              ),
            ),
            // 탭바
            const TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.grey,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: '기본정보'),
                Tab(text: '서류현황'),
                Tab(text: '정비이력'),
                Tab(text: '투입이력'),
              ],
            ),
            // 탭 내용
            SizedBox(
              height: 400,
              child: TabBarView(
                children: [
                  _buildBasicInfoTab(eq),
                  _buildDocumentsTab(eq),
                  _buildMaintenanceTab(eq),
                  _buildDeploymentTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab(RegisteredEquipment eq) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('차량번호', eq.vehicleNumber),
          _buildInfoRow('장비유형', eq.equipmentType),
          _buildInfoRow('모델명', eq.modelName),
          _buildInfoRow('제조사', eq.manufacturer.isEmpty ? '-' : eq.manufacturer),
          _buildInfoRow('제조년도', eq.manufacturingYear.isEmpty ? '-' : eq.manufacturingYear),
          _buildInfoRow(
            '등록일',
            '${eq.registeredAt.year}.${eq.registeredAt.month.toString().padLeft(2, '0')}.${eq.registeredAt.day.toString().padLeft(2, '0')}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey)),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab(RegisteredEquipment eq) {
    final now = DateTime.now();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: eq.documents.entries.map((entry) {
          final docName = entry.key;
          final doc = entry.value;
          final hasFile = doc.fileName != null;

          // D-day 계산
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
              color: hasFile
                  ? AppColors.success.withOpacity(0.03)
                  : AppColors.error.withOpacity(0.03),
              border: Border.all(
                color: hasFile
                    ? AppColors.success.withOpacity(0.2)
                    : AppColors.error.withOpacity(0.2),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // 썸네일
                if (hasFile && doc.fileBytes != null)
                  GestureDetector(
                    onTap: () => _showImageDialog(doc),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: _isImageFile(doc.fileName!)
                          ? Image.memory(
                              doc.fileBytes!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 48,
                              height: 48,
                              color: Colors.grey[200],
                              child: const Icon(Icons.picture_as_pdf,
                                  color: Colors.red, size: 24),
                            ),
                    ),
                  )
                else
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(Icons.insert_drive_file_outlined,
                        color: Colors.grey[400], size: 24),
                  ),
                const SizedBox(width: 12),
                // 서류 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(docName,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      if (hasFile) ...[
                        const SizedBox(height: 2),
                        Text(
                          '업로드: ${doc.uploadedAt!.year}.${doc.uploadedAt!.month.toString().padLeft(2, '0')}.${doc.uploadedAt!.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
                // 만료일 D-day
                if (dDayText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: dDayColor!.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dDayText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: dDayColor,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                // 검증 상태
                if (hasFile)
                  _buildVerifyBadge(doc.verificationStatus),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  bool _isImageFile(String fileName) {
    final lower = fileName.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png');
  }

  void _showImageDialog(UploadedEquipmentDocument doc) {
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
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 500, maxWidth: 600),
              child: _isImageFile(doc.fileName ?? '')
                  ? Image.memory(doc.fileBytes!, fit: BoxFit.contain)
                  : const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.picture_as_pdf,
                                size: 64, color: Colors.red),
                            SizedBox(height: 12),
                            Text('PDF 파일은 미리보기가 지원되지 않습니다.'),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyBadge(EquipmentVerificationStatus status) {
    String label;
    Color color;
    switch (status) {
      case EquipmentVerificationStatus.pending:
        label = '대기';
        color = AppColors.warning;
        break;
      case EquipmentVerificationStatus.verifying:
        label = '검증중';
        color = AppColors.primary;
        break;
      case EquipmentVerificationStatus.verified:
        label = '완료';
        color = AppColors.success;
        break;
      case EquipmentVerificationStatus.failed:
        label = '실패';
        color = AppColors.error;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildMaintenanceTab(RegisteredEquipment eq) {
    if (eq.maintenanceRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.build_circle_outlined, size: 56, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            const Text('정비 이력이 없습니다',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
            const SizedBox(height: 8),
            Text('정비 점검 메뉴에서 기록을 추가하세요.', style: TextStyle(fontSize: 13, color: const Color(0xFFCBD5E1))),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          columns: const [
            DataColumn(label: Text('날짜')),
            DataColumn(label: Text('키로수')),
            DataColumn(label: Text('엔진오일')),
            DataColumn(label: Text('유압오일')),
            DataColumn(label: Text('냉각수')),
            DataColumn(label: Text('연료잔량')),
            DataColumn(label: Text('특이사항')),
          ],
          rows: eq.maintenanceRecords.map((r) {
            return DataRow(cells: [
              DataCell(Text(
                  '${r.date.year}.${r.date.month.toString().padLeft(2, '0')}.${r.date.day.toString().padLeft(2, '0')}')),
              DataCell(Text(r.mileage)),
              DataCell(Text(r.engineOil)),
              DataCell(Text(r.hydraulicOil)),
              DataCell(Text(r.coolant)),
              DataCell(Text(r.fuelLevel)),
              DataCell(Text(r.remarks)),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDeploymentTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment_outlined, size: 56, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          const Text('투입 이력이 없습니다',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
          const SizedBox(height: 8),
          Text('투입 현황 메뉴에서 확인하세요.', style: TextStyle(fontSize: 13, color: const Color(0xFFCBD5E1))),
        ],
      ),
    );
  }

  DocumentType? _findDocType(String name) {
    final docs = _docRepo.getByCategory('장비서류');
    for (final d in docs) {
      if (d.name == name) return d;
    }
    return null;
  }
}
