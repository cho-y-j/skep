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
    extends State<AdminDocumentManagementPage> {
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
  bool _isLoading = true;
  String? _error;

  final List<String> _expiryOptions = ['전체', 'D-7 이내', 'D-14 이내', 'D-30 이내', '만료'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _loadDocTypes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
    try {
      final dioClient = context.read<DioClient>();
      final response = await dioClient.get<dynamic>(ApiEndpoints.documentTypes);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<String> types = ['전체'];
        if (data is List) {
          for (var item in data) {
            if (item is String) {
              types.add(item);
            } else if (item is Map) {
              types.add(item['name']?.toString() ?? item['typeName']?.toString() ?? '');
            }
          }
        }
        if (mounted) {
          setState(() {
            _docTypes = types;
          });
        }
      }
    } catch (_) {
      // Keep default doc types
    }
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
                    Text('만료 임박 서류를 확인하고 관리합니다. (D-30 이내)', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _loadData,
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
          // 검색 & 필터
          Container(
            width: double.infinity,
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
                    hintText: '서류명, 소속, 공급사로 검색...',
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
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: _buildContent(filteredDocs),
          ),
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
            children: [
              const Icon(Icons.description_outlined, size: 56, color: Color(0xFFCBD5E1)),
              const SizedBox(height: 16),
              const Text('만료 임박 서류가 없습니다', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text('총 ${filteredDocs.length}건', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        ),
        SingleChildScrollView(
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
