import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';

class AdminDocumentManagementPage extends StatefulWidget {
  const AdminDocumentManagementPage({Key? key}) : super(key: key);

  @override
  State<AdminDocumentManagementPage> createState() =>
      _AdminDocumentManagementPageState();
}

class _AdminDocumentManagementPageState
    extends State<AdminDocumentManagementPage>
    with SingleTickerProviderStateMixin {
  String _filterExpiry = '전체';
  String _filterDocType = '전체';
  String _filterSupplier = '전체';

  // 검색 & 정렬
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusChipFilter = '전체';
  int? _sortColumnIndex;
  bool _sortAscending = true;

  // API data
  List<Map<String, dynamic>> _documents = [];
  List<String> _docTypes = ['전체'];
  List<Map<String, dynamic>> _documentTypeObjects = [];
  bool _isLoading = true;
  bool _isLoadingTypes = false;
  String? _error;

  final List<String> _expiryOptions = ['전체', 'D-7 이내', 'D-14 이내', 'D-30 이내', '만료'];

  // Tab controller for main sections
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _loadDocTypes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dioClient = context.read<DioClient>();
      final response = await dioClient.get<dynamic>(ApiEndpoints.documentExpiring);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List) {
          _documents = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['documents'] is List) {
          _documents = (data['documents'] as List).cast<Map<String, dynamic>>();
        } else if (data is Map && data['content'] is List) {
          _documents = (data['content'] as List).cast<Map<String, dynamic>>();
        } else {
          _documents = [];
        }
        // Compute dDay and status for each document
        final now = DateTime.now();
        for (var doc in _documents) {
          final expiryStr = doc['expiryDate']?.toString() ?? doc['expiry_date']?.toString() ?? doc['expirationDate']?.toString();
          if (expiryStr != null) {
            try {
              final expiry = DateTime.parse(expiryStr);
              final diff = expiry.difference(now).inDays;
              doc['_dDay'] = diff;
              doc['_status'] = diff < 0 ? '만료' : '만료임박';
              doc['_expiryDate'] = expiryStr;
            } catch (_) {
              doc['_dDay'] = 999;
              doc['_status'] = '-';
              doc['_expiryDate'] = expiryStr;
            }
          } else {
            doc['_dDay'] = 999;
            doc['_status'] = '-';
            doc['_expiryDate'] = '-';
          }
        }
      }
    } catch (e) {
      _error = e.toString();
      _documents = [];
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDocTypes() async {
    setState(() => _isLoadingTypes = true);
    try {
      final dioClient = context.read<DioClient>();
      final response = await dioClient.get<dynamic>(ApiEndpoints.documentTypes);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<String> types = ['전체'];
        List<Map<String, dynamic>> typeObjects = [];
        if (data is List) {
          for (var item in data) {
            if (item is String) {
              types.add(item);
              typeObjects.add({'name': item});
            } else if (item is Map) {
              final name = item['name']?.toString() ?? item['typeName']?.toString() ?? '';
              if (name.isNotEmpty) types.add(name);
              typeObjects.add(Map<String, dynamic>.from(item));
            }
          }
        }
        if (mounted) {
          setState(() {
            _docTypes = types;
            _documentTypeObjects = typeObjects;
          });
        }
      }
    } catch (_) {
      // Keep default doc types
    }
    if (mounted) setState(() => _isLoadingTypes = false);
  }

  String _getDocName(Map<String, dynamic> d) {
    return d['docName']?.toString() ?? d['documentName']?.toString() ?? d['document_name']?.toString() ?? d['typeName']?.toString() ?? d['type']?.toString() ?? '-';
  }

  String _getOwner(Map<String, dynamic> d) {
    return d['owner']?.toString() ?? d['ownerName']?.toString() ?? d['owner_name']?.toString() ?? '-';
  }

  String _getOwnerType(Map<String, dynamic> d) {
    final type = d['ownerType']?.toString() ?? d['owner_type']?.toString() ?? '';
    switch (type) {
      case 'EQUIPMENT': return '장비';
      case 'PERSON': return '인력';
      default: return type.isNotEmpty ? type : '-';
    }
  }

  String _getSupplier(Map<String, dynamic> d) {
    return d['supplier']?.toString() ?? d['companyName']?.toString() ?? d['company_name']?.toString() ?? '-';
  }

  int _getDDay(Map<String, dynamic> d) {
    return d['_dDay'] as int? ?? d['dDay'] as int? ?? 999;
  }

  String _getExpiryDate(Map<String, dynamic> d) {
    return _formatDate(d['_expiryDate'] ?? d['expiryDate'] ?? d['expiry_date'] ?? d['expirationDate']);
  }

  String _getStatus(Map<String, dynamic> d) {
    return d['_status']?.toString() ?? d['status']?.toString() ?? '-';
  }

  Color _dDayColor(int dDay) {
    if (dDay < 0) return AppColors.error;
    if (dDay <= 7) return AppColors.error;
    if (dDay <= 14) return AppColors.warning;
    return AppColors.info;
  }

  String _dDayText(int dDay) {
    if (dDay < 0) return 'D+${-dDay}';
    if (dDay == 0) return 'D-Day';
    return 'D-$dDay';
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _documents.where((d) {
      final supplier = _getSupplier(d);
      final docName = _getDocName(d);
      final dDay = _getDDay(d);

      if (_filterSupplier != '전체' && supplier != _filterSupplier) return false;
      if (_filterDocType != '전체' && docName != _filterDocType) return false;
      if (_filterExpiry != '전체') {
        switch (_filterExpiry) {
          case 'D-7 이내': if (dDay > 7) return false; break;
          case 'D-14 이내': if (dDay > 14) return false; break;
          case 'D-30 이내': if (dDay > 30) return false; break;
          case '만료': if (dDay >= 0) return false; break;
        }
      }
      return true;
    }).toList();

    // 상태 칩 필터
    if (_statusChipFilter != '전체') {
      list = list.where((d) {
        final dDay = _getDDay(d);
        if (_statusChipFilter == '만료') return dDay < 0;
        if (_statusChipFilter == '만료임박') return dDay >= 0;
        return true;
      }).toList();
    }

    // 검색 필터
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((d) {
        return _getDocName(d).toLowerCase().contains(query) ||
            _getOwner(d).toLowerCase().contains(query) ||
            _getSupplier(d).toLowerCase().contains(query);
      }).toList();
    }

    // 정렬
    if (_sortColumnIndex != null) {
      list = List.from(list);
      list.sort((a, b) {
        int result;
        switch (_sortColumnIndex) {
          case 0: result = _getDocName(a).compareTo(_getDocName(b)); break;
          case 1: result = _getOwner(a).compareTo(_getOwner(b)); break;
          case 2: result = _getOwnerType(a).compareTo(_getOwnerType(b)); break;
          case 3: result = _getSupplier(a).compareTo(_getSupplier(b)); break;
          case 4: result = _getExpiryDate(a).compareTo(_getExpiryDate(b)); break;
          case 5: result = _getDDay(a).compareTo(_getDDay(b)); break;
          default: result = 0;
        }
        return _sortAscending ? result : -result;
      });
    }

    return list;
  }

  // Build unique supplier list from loaded data
  List<String> get _suppliers {
    final supplierSet = <String>{'전체'};
    for (var d in _documents) {
      final s = _getSupplier(d);
      if (s != '-') supplierSet.add(s);
    }
    return supplierSet.toList();
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  // ==================== Document Type CRUD ====================
  void _showAddTypeDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool ocrRequired = false;
    bool validationRequired = false;
    bool expiryManaged = false;
    bool _isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('서류 유형 추가'),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: '유형명',
                          hintText: '예: 건설기계 등록증',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: '설명',
                          hintText: '서류 유형에 대한 설명',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('OCR 필요 여부', style: TextStyle(fontSize: 14)),
                        subtitle: const Text('업로드 시 OCR 자동 인식', style: TextStyle(fontSize: 12)),
                        value: ocrRequired,
                        onChanged: (v) => setDialogState(() => ocrRequired = v),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        title: const Text('검증 필요 여부', style: TextStyle(fontSize: 14)),
                        subtitle: const Text('관리자 승인 후 유효 처리', style: TextStyle(fontSize: 12)),
                        value: validationRequired,
                        onChanged: (v) => setDialogState(() => validationRequired = v),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        title: const Text('만료일 관리', style: TextStyle(fontSize: 14)),
                        subtitle: const Text('만료일 추적 및 알림', style: TextStyle(fontSize: 12)),
                        value: expiryManaged,
                        onChanged: (v) => setDialogState(() => expiryManaged = v),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
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
                    if (nameCtrl.text.trim().isEmpty) return;
                    setDialogState(() => _isSaving = true);
                    try {
                      final dioClient = context.read<DioClient>();
                      await dioClient.post<dynamic>(
                        ApiEndpoints.documentTypeCreate,
                        data: {
                          'name': nameCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'ocrRequired': ocrRequired,
                          'validationRequired': validationRequired,
                          'expiryManaged': expiryManaged,
                        },
                      );
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('서류 유형이 추가되었습니다.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        _loadDocTypes();
                      }
                    } catch (e) {
                      setDialogState(() => _isSaving = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('추가 실패: $e'),
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
                      : const Text('추가'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditTypeDialog(Map<String, dynamic> typeObj) {
    final nameCtrl = TextEditingController(text: typeObj['name']?.toString() ?? typeObj['typeName']?.toString() ?? '');
    final descCtrl = TextEditingController(text: typeObj['description']?.toString() ?? '');
    bool ocrRequired = typeObj['ocrRequired'] == true;
    bool validationRequired = typeObj['validationRequired'] == true;
    bool expiryManaged = typeObj['expiryManaged'] == true || typeObj['hasExpiry'] == true;
    bool _isSaving = false;
    final typeId = typeObj['id']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('서류 유형 수정'),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: '유형명',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: '설명',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('OCR 필요 여부', style: TextStyle(fontSize: 14)),
                        value: ocrRequired,
                        onChanged: (v) => setDialogState(() => ocrRequired = v),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        title: const Text('검증 필요 여부', style: TextStyle(fontSize: 14)),
                        value: validationRequired,
                        onChanged: (v) => setDialogState(() => validationRequired = v),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        title: const Text('만료일 관리', style: TextStyle(fontSize: 14)),
                        value: expiryManaged,
                        onChanged: (v) => setDialogState(() => expiryManaged = v),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
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
                    if (nameCtrl.text.trim().isEmpty) return;
                    setDialogState(() => _isSaving = true);
                    try {
                      final dioClient = context.read<DioClient>();
                      final url = ApiEndpoints.documentTypeUpdate.replaceAll('{id}', typeId);
                      await dioClient.put<dynamic>(
                        url,
                        data: {
                          'name': nameCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'ocrRequired': ocrRequired,
                          'validationRequired': validationRequired,
                          'expiryManaged': expiryManaged,
                        },
                      );
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('서류 유형이 수정되었습니다.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        _loadDocTypes();
                      }
                    } catch (e) {
                      setDialogState(() => _isSaving = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('수정 실패: $e'),
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

  void _showDeleteTypeDialog(Map<String, dynamic> typeObj) {
    final name = typeObj['name']?.toString() ?? typeObj['typeName']?.toString() ?? '알 수 없음';
    final typeId = typeObj['id']?.toString() ?? '';
    bool _isDeleting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('서류 유형 삭제'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("'$name' 유형을 삭제하시겠습니까?"),
                  const SizedBox(height: 8),
                  const Text(
                    '이 유형에 속한 서류가 있는 경우 삭제할 수 없습니다.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: _isDeleting ? null : () async {
                    setDialogState(() => _isDeleting = true);
                    try {
                      final dioClient = context.read<DioClient>();
                      final url = ApiEndpoints.documentTypeDelete.replaceAll('{id}', typeId);
                      await dioClient.delete<dynamic>(url);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('서류 유형이 삭제되었습니다.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        _loadDocTypes();
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.white,
                  ),
                  child: _isDeleting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('삭제'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredDocs = _filtered;
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
                    const Text('서류 관리', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text('만료 임박 서류를 확인하고 관리합니다.', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _loadData();
                  _loadDocTypes();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('새로고침'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.greyDark,
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Tabs: 서류 유형 관리 | 만료 서류 목록
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.grey,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: '서류 유형 관리'),
                    Tab(text: '만료 서류 목록'),
                  ],
                  onTap: (_) => setState(() {}),
                ),
                const Divider(height: 1),
                AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    if (_tabController.index == 0) {
                      return _buildDocTypeManagement();
                    } else {
                      return _buildDocumentListSection(filteredDocs);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Document Type Management ====================
  Widget _buildDocTypeManagement() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '서류 유형 관리',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showAddTypeDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('유형 추가'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingTypes)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_documentTypeObjects.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.category_outlined, size: 48, color: Color(0xFFCBD5E1)),
                    const SizedBox(height: 12),
                    const Text('등록된 서류 유형이 없습니다', style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loadDocTypes,
                      child: const Text('다시 불러오기'),
                    ),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: _documentTypeObjects.length,
                  itemBuilder: (context, index) {
                    final typeObj = _documentTypeObjects[index];
                    return _buildTypeCard(typeObj);
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(Map<String, dynamic> typeObj) {
    final name = typeObj['name']?.toString() ?? typeObj['typeName']?.toString() ?? '-';
    final desc = typeObj['description']?.toString() ?? '';
    final hasOcr = typeObj['ocrRequired'] == true;
    final hasValidation = typeObj['validationRequired'] == true;
    final hasExpiry = typeObj['expiryManaged'] == true || typeObj['hasExpiry'] == true;
    final code = typeObj['code']?.toString() ?? typeObj['id']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.description_outlined, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF94A3B8)),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('수정')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 16, color: AppColors.error), SizedBox(width: 8), Text('삭제', style: TextStyle(color: AppColors.error))])),
                ],
                onSelected: (val) {
                  if (val == 'edit') _showEditTypeDialog(typeObj);
                  if (val == 'delete') _showDeleteTypeDialog(typeObj);
                },
              ),
            ],
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
          if (code.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('코드: $code', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ],
          const Spacer(),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (hasOcr) _buildBadge('OCR', AppColors.info),
              if (hasValidation) _buildBadge('검증', AppColors.warning),
              if (hasExpiry) _buildBadge('만료관리', AppColors.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  // ==================== Document List Section ====================
  Widget _buildDocumentListSection(List<Map<String, dynamic>> filteredDocs) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 검색 & 필터
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '서류명, 소속, 공급사로 검색...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: AppColors.white,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['전체', '만료임박', '만료'].map((label) {
                      final isSelected = _statusChipFilter == label;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _statusChipFilter = label),
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
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _buildFilter('만료 상태', _filterExpiry, _expiryOptions, (v) => setState(() => _filterExpiry = v ?? '전체')),
                    _buildFilter('서류 유형', _filterDocType, _docTypes, (v) => setState(() => _filterDocType = v ?? '전체')),
                    _buildFilter('공급사', _filterSupplier, _suppliers, (v) => setState(() => _filterSupplier = v ?? '전체')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildContent(filteredDocs),
        ],
      ),
    );
  }

  Widget _buildContent(List<Map<String, dynamic>> filteredDocs) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 56, color: Color(0xFFCBD5E1)),
              const SizedBox(height: 16),
              const Text('데이터를 불러오는데 실패했습니다', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton(onPressed: _loadData, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }

    if (_documents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: const [
              Icon(Icons.description_outlined, size: 56, color: Color(0xFFCBD5E1)),
              SizedBox(height: 16),
              Text('만료 임박 서류가 없습니다', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
      );
    }

    if (filteredDocs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.search_off, size: 56, color: Color(0xFFCBD5E1)),
              const SizedBox(height: 16),
              const Text('검색 결과가 없습니다', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
              const SizedBox(height: 8),
              Text('다른 검색어나 필터를 시도해 주세요.', style: TextStyle(fontSize: 13, color: const Color(0xFFCBD5E1))),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('총 ${filteredDocs.length}건', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
                DataColumn(label: const Text('서류명'), onSort: _onSort),
                DataColumn(label: const Text('소속'), onSort: _onSort),
                DataColumn(label: const Text('구분'), onSort: _onSort),
                DataColumn(label: const Text('공급사'), onSort: _onSort),
                DataColumn(label: const Text('만료일'), onSort: _onSort),
                DataColumn(label: const Text('D-Day'), onSort: _onSort),
                const DataColumn(label: Text('상태')),
              ],
              rows: filteredDocs.map((d) {
                final dDay = _getDDay(d);
                final status = _getStatus(d);
                return DataRow(cells: [
                  DataCell(Text(_getDocName(d))),
                  DataCell(Text(_getOwner(d))),
                  DataCell(Text(_getOwnerType(d))),
                  DataCell(Text(_getSupplier(d))),
                  DataCell(Text(_getExpiryDate(d))),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _dDayColor(dDay).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(_dDayText(dDay), style: TextStyle(color: _dDayColor(dDay), fontSize: 12, fontWeight: FontWeight.bold)),
                  )),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: dDay < 0 ? AppColors.error.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(status, style: TextStyle(color: dDay < 0 ? AppColors.error : AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600)),
                  )),
                ]);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilter(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    // Ensure current value is in options, otherwise reset to '전체'
    final safeValue = options.contains(value) ? value : '전체';
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        value: safeValue,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return date.toString();
    }
  }
}
