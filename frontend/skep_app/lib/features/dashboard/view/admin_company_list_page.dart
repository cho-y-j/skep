import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';

class AdminCompanyListPage extends StatefulWidget {
  const AdminCompanyListPage({Key? key}) : super(key: key);

  @override
  State<AdminCompanyListPage> createState() => _AdminCompanyListPageState();
}

class _AdminCompanyListPageState extends State<AdminCompanyListPage> {
  List<Map<String, dynamic>> _companies = [];
  bool _isLoading = true;
  String? _error;

  int? _selectedIndex;

  // 검색 & 필터 & 정렬
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = '전체';
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
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
      final response = await dioClient.get<dynamic>(ApiEndpoints.companies);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List) {
          _companies = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['companies'] is List) {
          _companies = (data['companies'] as List).cast<Map<String, dynamic>>();
        } else if (data is Map && data['content'] is List) {
          _companies = (data['content'] as List).cast<Map<String, dynamic>>();
        } else {
          _companies = [];
        }
      }
    } catch (e) {
      _error = e.toString();
      _companies = [];
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getCompanyName(Map<String, dynamic> c) {
    return c['name']?.toString() ?? c['companyName']?.toString() ?? '-';
  }

  String _getBizNo(Map<String, dynamic> c) {
    return c['bizNo']?.toString() ?? c['businessNumber']?.toString() ?? c['business_number']?.toString() ?? '-';
  }

  String _getType(Map<String, dynamic> c) {
    final type = c['type']?.toString() ?? c['companyType']?.toString() ?? c['company_type']?.toString() ?? '';
    switch (type) {
      case 'EQUIPMENT_SUPPLIER': return '공급사';
      case 'BP_COMPANY': return 'BP사';
      default: return type.isNotEmpty ? type : '-';
    }
  }

  String _getCeo(Map<String, dynamic> c) {
    return c['ceo']?.toString() ?? c['ceoName']?.toString() ?? c['ceo_name']?.toString() ?? c['representative']?.toString() ?? '-';
  }

  String _getStatus(Map<String, dynamic> c) {
    final status = c['status']?.toString() ?? '';
    switch (status) {
      case 'ACTIVE': return '승인';
      case 'SUSPENDED': return '정지';
      case 'INACTIVE': return '정지';
      default: return status.isNotEmpty ? status : '승인';
    }
  }

  String _getJoinDate(Map<String, dynamic> c) {
    return _formatDate(c['joinDate'] ?? c['createdAt'] ?? c['created_at']);
  }

  Color _statusColor(String status) {
    return status == '승인' ? AppColors.success : AppColors.error;
  }

  Color _typeColor(String type) {
    return type == '공급사' ? AppColors.primary : AppColors.warning;
  }

  Future<void> _toggleStatus(int index) async {
    final company = _companies[index];
    final companyId = company['id']?.toString();
    if (companyId == null) return;

    final currentStatus = _getStatus(company);
    final newStatus = currentStatus == '승인' ? 'SUSPENDED' : 'ACTIVE';

    try {
      final dioClient = context.read<DioClient>();
      await dioClient.put<dynamic>(
        '${ApiEndpoints.companies}/$companyId/status',
        data: {'status': newStatus},
      );
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('상태 변경 실패: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showAddCompanyDialog() {
    final nameController = TextEditingController();
    final bizNoController = TextEditingController();
    final ceoController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    String selectedType = 'EQUIPMENT_SUPPLIER';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('회사 추가'),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: '회사명',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: bizNoController,
                        decoration: const InputDecoration(
                          labelText: '사업자번호',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: ceoController,
                        decoration: const InputDecoration(
                          labelText: '대표자',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: '연락처',
                          border: OutlineInputBorder(),
                          hintText: '02-0000-0000',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: '이메일',
                          border: OutlineInputBorder(),
                          hintText: 'example@company.com',
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: '주소',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(
                          labelText: '유형',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'EQUIPMENT_SUPPLIER', child: Text('공급사')),
                          DropdownMenuItem(value: 'BP_COMPANY', child: Text('BP사')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedType = val);
                          }
                        },
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
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    try {
                      final dioClient = context.read<DioClient>();
                      await dioClient.post<dynamic>(
                        ApiEndpoints.companies,
                        data: {
                          'name': nameController.text.trim(),
                          'businessNumber': bizNoController.text.trim(),
                          'representative': ceoController.text.trim(),
                          'phone': phoneController.text.trim(),
                          'email': emailController.text.trim(),
                          'address': addressController.text.trim(),
                          'companyType': selectedType,
                        },
                      );
                      if (mounted) Navigator.of(ctx).pop();
                      await _loadData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('회사가 추가되었습니다'), backgroundColor: AppColors.success),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('회사 추가 실패: $e'), backgroundColor: AppColors.error),
                        );
                      }
                    }
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

  List<Map<String, dynamic>> get _filteredCompanies {
    var list = List<Map<String, dynamic>>.from(_companies);

    if (_statusFilter != '전체') {
      if (_statusFilter == '공급사' || _statusFilter == 'BP사') {
        list = list.where((c) => _getType(c) == _statusFilter).toList();
      } else {
        list = list.where((c) => _getStatus(c) == _statusFilter).toList();
      }
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((c) {
        return _getCompanyName(c).toLowerCase().contains(query) ||
            _getBizNo(c).toLowerCase().contains(query) ||
            _getCeo(c).toLowerCase().contains(query);
      }).toList();
    }

    if (_sortColumnIndex != null) {
      list.sort((a, b) {
        int result;
        switch (_sortColumnIndex) {
          case 0: result = _getCompanyName(a).compareTo(_getCompanyName(b)); break;
          case 1: result = _getBizNo(a).compareTo(_getBizNo(b)); break;
          case 2: result = _getType(a).compareTo(_getType(b)); break;
          case 3: result = _getCeo(a).compareTo(_getCeo(b)); break;
          case 4: result = _getStatus(a).compareTo(_getStatus(b)); break;
          case 5: result = _getJoinDate(a).compareTo(_getJoinDate(b)); break;
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
                    const Text('회사 목록', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text('등록된 회사를 관리합니다.', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
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
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showAddCompanyDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('회사 추가'),
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
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: _buildContent(),
          ),
          if (!_isLoading && _error == null && _selectedIndex != null && _selectedIndex! < _companies.length) ...[
            const SizedBox(height: 16),
            _buildDetailCard(_companies[_selectedIndex!]),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
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

    if (_companies.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.business_outlined, size: 56, color: Color(0xFFCBD5E1)),
              const SizedBox(height: 16),
              const Text('등록된 회사가 없습니다', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredCompanies;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text('총 ${filtered.length}건', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
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
              final type = _getType(c);
              final status = _getStatus(c);
              return DataRow(
                selected: _selectedIndex != null && originalIndex == _selectedIndex,
                cells: [
                  DataCell(Text(_getCompanyName(c))),
                  DataCell(Text(_getBizNo(c))),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _typeColor(type).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(type, style: TextStyle(color: _typeColor(type), fontSize: 12, fontWeight: FontWeight.w600)),
                  )),
                  DataCell(Text(_getCeo(c))),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(status, style: TextStyle(color: _statusColor(status), fontSize: 12, fontWeight: FontWeight.w600)),
                  )),
                  DataCell(Text(_getJoinDate(c))),
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
      ],
    );
  }

  Widget _buildDetailCard(Map<String, dynamic> company) {
    final status = _getStatus(company);
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
              Text('${_getCompanyName(company)} 상세정보', style: AppTextStyles.headlineSmall),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _toggleStatus(_selectedIndex!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: status == '승인' ? AppColors.error : AppColors.success,
                  foregroundColor: AppColors.white,
                ),
                child: Text(status == '승인' ? '정지' : '승인'),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),
          _infoRow('사업자번호', _getBizNo(company)),
          _infoRow('유형', _getType(company)),
          _infoRow('대표자', _getCeo(company)),
          _infoRow('가입일', _getJoinDate(company)),
          _infoRow('소속 직원', '${company['employeeCount'] ?? company['employees'] ?? '-'}'),
          _infoRow('등록 장비', '${company['equipmentCount'] ?? company['equipment'] ?? '-'}'),
          _infoRow('등록 인력', '${company['personnelCount'] ?? company['personnel'] ?? '-'}'),
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
