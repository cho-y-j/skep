import 'package:flutter/material.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';

class AdminCompanyListPage extends StatefulWidget {
  const AdminCompanyListPage({Key? key}) : super(key: key);

  @override
  State<AdminCompanyListPage> createState() => _AdminCompanyListPageState();
}

class _AdminCompanyListPageState extends State<AdminCompanyListPage> {
  final List<Map<String, dynamic>> _companies = [
    {'name': '(주)한국크레인', 'bizNo': '123-45-67890', 'type': '공급사', 'ceo': '홍길동', 'status': '승인', 'joinDate': '2026-01-15', 'employees': 12, 'equipment': 8, 'personnel': 15},
    {'name': '삼성중장비', 'bizNo': '234-56-78901', 'type': '공급사', 'ceo': '김대표', 'status': '승인', 'joinDate': '2026-02-01', 'employees': 8, 'equipment': 5, 'personnel': 10},
    {'name': '현대건설', 'bizNo': '345-67-89012', 'type': 'BP사', 'ceo': '이사장', 'status': '승인', 'joinDate': '2026-01-10', 'employees': 25, 'equipment': 0, 'personnel': 0},
    {'name': 'GS건설', 'bizNo': '456-78-90123', 'type': 'BP사', 'ceo': '박대표', 'status': '정지', 'joinDate': '2026-03-01', 'employees': 15, 'equipment': 0, 'personnel': 0},
    {'name': '대한건기', 'bizNo': '567-89-01234', 'type': '공급사', 'ceo': '최기업', 'status': '승인', 'joinDate': '2026-03-05', 'employees': 5, 'equipment': 3, 'personnel': 6},
  ];

  int? _selectedIndex;

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

  Color _statusColor(String status) {
    return status == '승인' ? AppColors.success : AppColors.error;
  }

  Color _typeColor(String type) {
    return type == '공급사' ? AppColors.primary : AppColors.warning;
  }

  void _toggleStatus(int index) {
    setState(() {
      _companies[index]['status'] = _companies[index]['status'] == '승인' ? '정지' : '승인';
    });
  }

  List<Map<String, dynamic>> get _filteredCompanies {
    var list = List<Map<String, dynamic>>.from(_companies);

    if (_statusFilter != '전체') {
      if (_statusFilter == '공급사' || _statusFilter == 'BP사') {
        list = list.where((c) => c['type'] == _statusFilter).toList();
      } else {
        list = list.where((c) => c['status'] == _statusFilter).toList();
      }
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((c) {
        return (c['name'] as String).toLowerCase().contains(query) ||
            (c['bizNo'] as String).toLowerCase().contains(query) ||
            (c['ceo'] as String).toLowerCase().contains(query);
      }).toList();
    }

    if (_sortColumnIndex != null) {
      list.sort((a, b) {
        int result;
        switch (_sortColumnIndex) {
          case 0: result = (a['name'] as String).compareTo(b['name'] as String); break;
          case 1: result = (a['bizNo'] as String).compareTo(b['bizNo'] as String); break;
          case 2: result = (a['type'] as String).compareTo(b['type'] as String); break;
          case 3: result = (a['ceo'] as String).compareTo(b['ceo'] as String); break;
          case 4: result = (a['status'] as String).compareTo(b['status'] as String); break;
          case 5: result = (a['joinDate'] as String).compareTo(b['joinDate'] as String); break;
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
    final filtered = _filteredCompanies;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('회사 목록', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text('등록된 회사를 관리합니다.', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
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
                    hintText: '회사명, 사업자번호, 대표자로 검색...',
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
                    children: ['전체', '공급사', 'BP사', '승인', '정지'].map((label) {
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
          // 결과 카운트
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('총 ${filtered.length}건', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
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
                  DataColumn(label: const Text('회사명'), onSort: _onSort),
                  DataColumn(label: const Text('사업자번호'), onSort: _onSort),
                  DataColumn(label: const Text('유형'), onSort: _onSort),
                  DataColumn(label: const Text('대표자'), onSort: _onSort),
                  DataColumn(label: const Text('상태'), onSort: _onSort),
                  DataColumn(label: const Text('가입일'), onSort: _onSort),
                  const DataColumn(label: Text('상세')),
                ],
                rows: List.generate(filtered.length, (i) {
                  final c = filtered[i];
                  final originalIndex = _companies.indexOf(c);
                  return DataRow(
                    selected: _selectedIndex != null && originalIndex == _selectedIndex,
                    cells: [
                      DataCell(Text(c['name'])),
                      DataCell(Text(c['bizNo'])),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: _typeColor(c['type']).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text(c['type'], style: TextStyle(color: _typeColor(c['type']), fontSize: 12, fontWeight: FontWeight.w600)),
                      )),
                      DataCell(Text(c['ceo'])),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: _statusColor(c['status']).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text(c['status'], style: TextStyle(color: _statusColor(c['status']), fontSize: 12, fontWeight: FontWeight.w600)),
                      )),
                      DataCell(Text(c['joinDate'])),
                      DataCell(IconButton(
                        icon: const Icon(Icons.info_outline, size: 20),
                        onPressed: () {
                          setState(() {
                            _selectedIndex = _selectedIndex == originalIndex ? null : originalIndex;
                          });
                        },
                      )),
                    ],
                  );
                }),
              ),
            ),
          ),
          if (_selectedIndex != null) ...[
            const SizedBox(height: 16),
            _buildDetailCard(_companies[_selectedIndex!]),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailCard(Map<String, dynamic> company) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${company['name']} 상세정보', style: AppTextStyles.headlineSmall),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _toggleStatus(_selectedIndex!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: company['status'] == '승인' ? AppColors.error : AppColors.success,
                  foregroundColor: AppColors.white,
                ),
                child: Text(company['status'] == '승인' ? '정지' : '승인'),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),
          _infoRow('사업자번호', company['bizNo']),
          _infoRow('유형', company['type']),
          _infoRow('대표자', company['ceo']),
          _infoRow('가입일', company['joinDate']),
          _infoRow('소속 직원', '${company['employees']}명'),
          _infoRow('등록 장비', '${company['equipment']}대'),
          _infoRow('등록 인력', '${company['personnel']}명'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey))),
          Text(value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
