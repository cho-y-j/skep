import 'package:flutter/material.dart';
import 'package:skep_app/core/constants/app_colors.dart';

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

  final List<String> _expiryOptions = ['전체', 'D-7 이내', 'D-14 이내', 'D-30 이내', '만료'];
  final List<String> _docTypes = ['전체', '건설기계등록증', '보험증권', '정기검사증', '면허증', '건강검진결과', '안전교육수료증'];
  final List<String> _suppliers = ['전체', '(주)한국크레인', '삼성중장비', '대한건기'];

  final List<Map<String, dynamic>> _documents = [
    {'docName': '건설기계등록증', 'owner': '25톤 크레인 (서울12가3456)', 'ownerType': '장비', 'supplier': '(주)한국크레인', 'expiryDate': '2026-04-05', 'dDay': 14, 'status': '만료임박'},
    {'docName': '보험증권', 'owner': '50톤 크레인 (경기34나5678)', 'ownerType': '장비', 'supplier': '(주)한국크레인', 'expiryDate': '2026-03-30', 'dDay': 8, 'status': '만료임박'},
    {'docName': '정기검사증', 'owner': '굴삭기 0.7m3 (인천56다7890)', 'ownerType': '장비', 'supplier': '삼성중장비', 'expiryDate': '2026-04-15', 'dDay': 24, 'status': '만료임박'},
    {'docName': '건강검진결과', 'owner': '김운전', 'ownerType': '인력', 'supplier': '(주)한국크레인', 'expiryDate': '2026-03-25', 'dDay': 3, 'status': '만료임박'},
    {'docName': '안전교육수료증', 'owner': '이기사', 'ownerType': '인력', 'supplier': '(주)한국크레인', 'expiryDate': '2026-03-20', 'dDay': -2, 'status': '만료'},
    {'docName': '면허증', 'owner': '박기사', 'ownerType': '인력', 'supplier': '삼성중장비', 'expiryDate': '2026-04-20', 'dDay': 29, 'status': '만료임박'},
    {'docName': '보험증권', 'owner': '지게차 3톤 (부산78라1234)', 'ownerType': '장비', 'supplier': '대한건기', 'expiryDate': '2026-03-18', 'dDay': -4, 'status': '만료'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      if (_filterSupplier != '전체' && d['supplier'] != _filterSupplier) return false;
      if (_filterDocType != '전체' && d['docName'] != _filterDocType) return false;
      if (_filterExpiry != '전체') {
        final dDay = d['dDay'] as int;
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
        if (_statusChipFilter == '만료') return (d['dDay'] as int) < 0;
        if (_statusChipFilter == '만료임박') return (d['dDay'] as int) >= 0;
        return true;
      }).toList();
    }

    // 검색 필터
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((d) {
        return (d['docName'] as String).toLowerCase().contains(query) ||
            (d['owner'] as String).toLowerCase().contains(query) ||
            (d['supplier'] as String).toLowerCase().contains(query);
      }).toList();
    }

    // 정렬
    if (_sortColumnIndex != null) {
      list = List.from(list);
      list.sort((a, b) {
        int result;
        switch (_sortColumnIndex) {
          case 0: result = (a['docName'] as String).compareTo(b['docName'] as String); break;
          case 1: result = (a['owner'] as String).compareTo(b['owner'] as String); break;
          case 2: result = (a['ownerType'] as String).compareTo(b['ownerType'] as String); break;
          case 3: result = (a['supplier'] as String).compareTo(b['supplier'] as String); break;
          case 4: result = (a['expiryDate'] as String).compareTo(b['expiryDate'] as String); break;
          case 5: result = (a['dDay'] as int).compareTo(b['dDay'] as int); break;
          default: result = 0;
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

  @override
  Widget build(BuildContext context) {
    final filteredDocs = _filtered;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('서류 관리', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text('만료 임박 서류를 확인하고 관리합니다. (D-30 이내)', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
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
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('총 ${filteredDocs.length}건', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: filteredDocs.isEmpty
                ? Padding(
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
                  )
                : SingleChildScrollView(
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
                      rows: filteredDocs.map((d) => DataRow(cells: [
                        DataCell(Text(d['docName'])),
                        DataCell(Text(d['owner'])),
                        DataCell(Text(d['ownerType'])),
                        DataCell(Text(d['supplier'])),
                        DataCell(Text(d['expiryDate'])),
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: _dDayColor(d['dDay']).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text(_dDayText(d['dDay']), style: TextStyle(color: _dDayColor(d['dDay']), fontSize: 12, fontWeight: FontWeight.bold)),
                        )),
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (d['dDay'] as int) < 0 ? AppColors.error.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(d['status'], style: TextStyle(color: (d['dDay'] as int) < 0 ? AppColors.error : AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600)),
                        )),
                      ])).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        value: value,
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
}
