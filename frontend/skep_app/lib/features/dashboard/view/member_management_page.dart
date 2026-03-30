import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/network/dio_client.dart';

class MemberManagementPage extends StatefulWidget {
  const MemberManagementPage({Key? key}) : super(key: key);

  @override
  State<MemberManagementPage> createState() => _MemberManagementPageState();
}

class _MemberManagementPageState extends State<MemberManagementPage> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;

  // 검색 & 필터 & 정렬
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = '전체';
  int? _sortColumnIndex;
  bool _sortAscending = true;

  static const Map<String, String> _roleMap = {
    'PLATFORM_ADMIN': '관리자',
    'EQUIPMENT_SUPPLIER': '장비공급사',
    'BP_COMPANY': 'BP사',
    'DRIVER': '운전원',
    'GUIDE': '유도원',
    'SAFETY_INSPECTOR': '안전점검원',
  };

  static const List<String> _roleKeys = [
    'PLATFORM_ADMIN',
    'EQUIPMENT_SUPPLIER',
    'BP_COMPANY',
    'DRIVER',
    'GUIDE',
    'SAFETY_INSPECTOR',
  ];

  static const List<String> _statusOptions = ['활성', '비활성', '정지'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dioClient = context.read<DioClient>();
      final response = await dioClient.get<dynamic>('/api/auth/users');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List) {
          _users = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['users'] is List) {
          _users = (data['users'] as List).cast<Map<String, dynamic>>();
        } else {
          _users = [];
        }
      }
    } catch (e) {
      _error = e.toString();
      _users = [];
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _translateRole(String role) {
    return _roleMap[role] ?? role;
  }

  String _translateStatus(dynamic user) {
    final isActive = user['is_active'] ?? user['isActive'] ?? true;
    final status = user['status']?.toString();
    if (status == '정지' || status == 'SUSPENDED') return '정지';
    if (isActive == true) return '활성';
    return '비활성';
  }

  String _roleKeyFromKorean(String korean) {
    for (final entry in _roleMap.entries) {
      if (entry.value == korean) return entry.key;
    }
    return korean;
  }

  List<Map<String, dynamic>> get _filteredUsers {
    var list = List<Map<String, dynamic>>.from(_users);

    // 상태 필터
    if (_statusFilter != '전체') {
      list = list.where((u) => _translateStatus(u) == _statusFilter).toList();
    }

    // 검색 필터
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((u) {
        final name = (u['name']?.toString() ?? '').toLowerCase();
        final email = (u['email']?.toString() ?? '').toLowerCase();
        final role = _translateRole(u['role']?.toString() ?? '').toLowerCase();
        final company = (u['company_name']?.toString() ?? u['companyName']?.toString() ?? '').toLowerCase();
        return name.contains(query) || email.contains(query) || role.contains(query) || company.contains(query);
      }).toList();
    }

    // 정렬
    if (_sortColumnIndex != null) {
      list.sort((a, b) {
        int result;
        switch (_sortColumnIndex) {
          case 0:
            result = (a['name']?.toString() ?? '').compareTo(b['name']?.toString() ?? '');
            break;
          case 1:
            result = (a['email']?.toString() ?? '').compareTo(b['email']?.toString() ?? '');
            break;
          case 2:
            result = _translateRole(a['role']?.toString() ?? '').compareTo(_translateRole(b['role']?.toString() ?? ''));
            break;
          case 3:
            result = (a['company_name']?.toString() ?? '').compareTo(b['company_name']?.toString() ?? '');
            break;
          case 4:
            result = _translateStatus(a).compareTo(_translateStatus(b));
            break;
          case 5:
            result = (a['created_at']?.toString() ?? '').compareTo(b['created_at']?.toString() ?? '');
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

  void _showEditDialog(int index) {
    final user = _users[index];
    final nameController =
        TextEditingController(text: user['name']?.toString() ?? '');
    final emailController =
        TextEditingController(text: user['email']?.toString() ?? '');
    String selectedRole = user['role']?.toString() ?? 'DRIVER';
    String selectedStatus = _translateStatus(user);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('사용자 수정'),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: '이름',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: '이메일',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _roleKeys.contains(selectedRole)
                            ? selectedRole
                            : _roleKeys.first,
                        decoration: const InputDecoration(
                          labelText: '역할',
                          border: OutlineInputBorder(),
                        ),
                        items: _roleKeys.map((key) {
                          return DropdownMenuItem(
                            value: key,
                            child: Text(_roleMap[key]!),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedRole = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _statusOptions.contains(selectedStatus)
                            ? selectedStatus
                            : '활성',
                        decoration: const InputDecoration(
                          labelText: '상태',
                          border: OutlineInputBorder(),
                        ),
                        items: _statusOptions.map((s) {
                          return DropdownMenuItem(value: s, child: Text(s));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedStatus = val;
                            });
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
                  onPressed: () {
                    setState(() {
                      _users[index] = {
                        ..._users[index],
                        'name': nameController.text.trim(),
                        'email': emailController.text.trim(),
                        'role': selectedRole,
                        'is_active': selectedStatus == '활성',
                        'status': selectedStatus,
                      };
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

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('삭제 확인'),
          content: const Text('정말 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _users.removeAt(index);
                });
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

  void _showAddDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = 'DRIVER';
    String selectedStatus = '활성';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('사용자 추가'),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: '이름',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: '이메일',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: '비밀번호',
                          hintText: '4자 이상',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: '전화번호',
                          hintText: '010-0000-0000',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: const InputDecoration(
                          labelText: '역할',
                          border: OutlineInputBorder(),
                        ),
                        items: _roleKeys.map((key) {
                          return DropdownMenuItem(
                            value: key,
                            child: Text(_roleMap[key]!),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedRole = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: '상태',
                          border: OutlineInputBorder(),
                        ),
                        items: _statusOptions.map((s) {
                          return DropdownMenuItem(value: s, child: Text(s));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedStatus = val;
                            });
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
                    if (nameController.text.trim().isEmpty ||
                        emailController.text.trim().isEmpty ||
                        passwordController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('이름, 이메일, 비밀번호는 필수입니다'), backgroundColor: AppColors.error),
                      );
                      return;
                    }
                    try {
                      final dioClient = context.read<DioClient>();
                      await dioClient.post<dynamic>(
                        '/api/auth/register',
                        data: {
                          'name': nameController.text.trim(),
                          'email': emailController.text.trim(),
                          'password': passwordController.text.trim(),
                          'phone': phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : '010-0000-0000',
                          'role': selectedRole,
                        },
                      );
                      if (mounted) Navigator.of(ctx).pop();
                      await _loadUsers();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('사용자가 추가되었습니다'), backgroundColor: AppColors.success),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('추가 실패: $e'), backgroundColor: AppColors.error),
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
                    const Text('회원 관리', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text('등록된 사용자 목록을 관리합니다.', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _loadUsers,
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
                onPressed: _showAddDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('사용자 추가'),
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
                    hintText: '이름, 이메일, 역할, 회사명으로 검색...',
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
                    children: ['전체', '활성', '비활성', '정지'].map((label) {
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
              Text(_error!, style: TextStyle(fontSize: 13, color: const Color(0xFFCBD5E1)), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton(onPressed: _loadUsers, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }

    if (_users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.people_outline, size: 56, color: Color(0xFFCBD5E1)),
              const SizedBox(height: 16),
              const Text('등록된 사용자가 없습니다', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
              const SizedBox(height: 8),
              Text('사용자 추가 버튼을 눌러 추가하세요.', style: TextStyle(fontSize: 13, color: const Color(0xFFCBD5E1))),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredUsers;

    if (filtered.isEmpty) {
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
              DataColumn(label: const Text('이름'), onSort: _onSort),
              DataColumn(label: const Text('이메일'), onSort: _onSort),
              DataColumn(label: const Text('역할'), onSort: _onSort),
              DataColumn(label: const Text('회사명'), onSort: _onSort),
              DataColumn(label: const Text('상태'), onSort: _onSort),
              DataColumn(label: const Text('가입일'), onSort: _onSort),
              const DataColumn(label: Text('관리')),
            ],
            rows: List.generate(filtered.length, (i) {
              final user = filtered[i];
              final originalIndex = _users.indexOf(user);
              final status = _translateStatus(user);
              Color statusColor;
              switch (status) {
                case '활성':
                  statusColor = AppColors.success;
                  break;
                case '정지':
                  statusColor = AppColors.warning;
                  break;
                default:
                  statusColor = AppColors.error;
              }

              return DataRow(
                cells: [
                  DataCell(Text(user['name']?.toString() ?? '-')),
                  DataCell(Text(user['email']?.toString() ?? '-')),
                  DataCell(Text(_translateRole(user['role']?.toString() ?? ''))),
                  DataCell(Text(user['company_name']?.toString() ?? user['companyName']?.toString() ?? '-')),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  DataCell(Text(_formatDate(user['created_at'] ?? user['createdAt']))),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                          tooltip: '수정',
                          onPressed: () => _showEditDialog(originalIndex),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                          tooltip: '삭제',
                          onPressed: () => _showDeleteDialog(originalIndex),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
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
