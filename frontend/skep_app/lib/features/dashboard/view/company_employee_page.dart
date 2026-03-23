import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';
import 'package:skep_app/core/network/dio_client.dart';
import 'package:skep_app/core/widgets/app_button.dart';
import 'package:skep_app/core/widgets/app_text_field.dart';

class CompanyEmployeePage extends StatefulWidget {
  const CompanyEmployeePage({Key? key}) : super(key: key);

  @override
  State<CompanyEmployeePage> createState() => _CompanyEmployeePageState();
}

class _CompanyEmployeePageState extends State<CompanyEmployeePage> {
  List<_Employee> _employees = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    try {
      // In a real app, fetch from API
      // final dioClient = context.read<DioClient>();
      // final response = await dioClient.get('/api/companies/employees');
      // For now, use empty list as placeholder
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('직원 목록 로딩 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showAddEmployeeDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    final positionController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.person_add_outlined,
                      color: AppColors.primary, size: 24),
                  const SizedBox(width: 8),
                  Text('직원 추가', style: AppTextStyles.headlineMedium),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppTextField(
                        label: '이름',
                        hint: '직원 이름을 입력하세요',
                        controller: nameController,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: '이메일',
                        hint: '이메일 주소를 입력하세요',
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: '비밀번호 (초기)',
                        hint: '초기 비밀번호를 설정하세요',
                        controller: passwordController,
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: '연락처',
                        hint: '010-0000-0000',
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: '직책',
                        hint: '직책을 입력하세요',
                        controller: positionController,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    '취소',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (nameController.text.isEmpty ||
                              emailController.text.isEmpty ||
                              passwordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('필수 항목을 모두 입력해주세요'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }
                          setDialogState(() => isSubmitting = true);

                          try {
                            final dioClient = context.read<DioClient>();
                            await dioClient.post(
                              ApiEndpoints.register,
                              data: {
                                'name': nameController.text,
                                'email': emailController.text,
                                'password': passwordController.text,
                                'phone': phoneController.text,
                                'position': positionController.text,
                                // company association is handled server-side
                                // via the authenticated admin's token
                              },
                            );

                            if (mounted) {
                              Navigator.of(dialogContext).pop();
                              setState(() {
                                _employees.add(_Employee(
                                  name: nameController.text,
                                  email: emailController.text,
                                  position: positionController.text.isEmpty
                                      ? '-'
                                      : positionController.text,
                                  phone: phoneController.text,
                                  status: '활성',
                                  createdAt: DateTime.now(),
                                ));
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('직원이 추가되었습니다'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('직원 추가 실패: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('추가'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      nameController.dispose();
      emailController.dispose();
      passwordController.dispose();
      phoneController.dispose();
      positionController.dispose();
    });
  }

  void _showEditEmployeeDialog(_Employee employee, int index) {
    final nameController = TextEditingController(text: employee.name);
    final emailController = TextEditingController(text: employee.email);
    final phoneController = TextEditingController(text: employee.phone);
    final positionController = TextEditingController(text: employee.position);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.edit_outlined,
                  color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text('직원 정보 수정', style: AppTextStyles.headlineMedium),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    label: '이름',
                    hint: '직원 이름',
                    controller: nameController,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: '이메일',
                    hint: '이메일 주소',
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: '연락처',
                    hint: '010-0000-0000',
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: '직책',
                    hint: '직책을 입력하세요',
                    controller: positionController,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                '취소',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _employees[index] = _Employee(
                    name: nameController.text,
                    email: emailController.text,
                    position: positionController.text.isEmpty
                        ? '-'
                        : positionController.text,
                    phone: phoneController.text,
                    status: employee.status,
                    createdAt: employee.createdAt,
                  );
                });
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('직원 정보가 수정되었습니다'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('저장'),
            ),
          ],
        );
      },
    ).then((_) {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      positionController.dispose();
    });
  }

  void _confirmDeleteEmployee(int index) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('직원 삭제', style: AppTextStyles.headlineMedium),
          content: Text(
            '${_employees[index].name} 직원을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                '취소',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _employees.removeAt(index);
                });
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('직원이 삭제되었습니다'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '직원 관리',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '회사 소속 직원을 관리합니다.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddEmployeeDialog,
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('직원 추가'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Table
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _employees.isEmpty
                    ? _buildEmptyState()
                    : _buildEmployeeTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '등록된 직원이 없습니다',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '"직원 추가" 버튼을 눌러 직원을 등록하세요',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          return _buildEmployeeCards();
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              headingTextStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
              dataTextStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1E293B),
              ),
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('이름')),
                DataColumn(label: Text('이메일')),
                DataColumn(label: Text('역할(직책)')),
                DataColumn(label: Text('연락처')),
                DataColumn(label: Text('상태')),
                DataColumn(label: Text('등록일')),
                DataColumn(label: Text('관리')),
              ],
              rows: List.generate(_employees.length, (index) {
                final emp = _employees[index];
                return DataRow(
                  cells: [
                    DataCell(Text(emp.name)),
                    DataCell(Text(emp.email)),
                    DataCell(Text(emp.position)),
                    DataCell(Text(emp.phone)),
                    DataCell(_buildStatusBadge(emp.status)),
                    DataCell(Text(_formatDate(emp.createdAt))),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              size: 18, color: AppColors.primary),
                          tooltip: '수정',
                          onPressed: () =>
                              _showEditEmployeeDialog(emp, index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: AppColors.error),
                          tooltip: '삭제',
                          onPressed: () => _confirmDeleteEmployee(index),
                        ),
                      ],
                    )),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmployeeCards() {
    return Column(
      children: List.generate(_employees.length, (index) {
        final emp = _employees[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: index < _employees.length - 1
                    ? const Color(0xFFE0E0E0)
                    : Colors.transparent,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      emp.name.isNotEmpty ? emp.name[0] : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(emp.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(emp.email,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  _buildStatusBadge(emp.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildInfoChip(Icons.work_outline, emp.position),
                  const SizedBox(width: 12),
                  _buildInfoChip(Icons.phone_outlined, emp.phone),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '등록일: ${_formatDate(emp.createdAt)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 18, color: AppColors.primary),
                    tooltip: '수정',
                    onPressed: () => _showEditEmployeeDialog(emp, index),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: AppColors.error),
                    tooltip: '삭제',
                    onPressed: () => _confirmDeleteEmployee(index),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case '활성':
        bgColor = AppColors.success.withOpacity(0.1);
        textColor = AppColors.success;
        break;
      case '비활성':
        bgColor = AppColors.error.withOpacity(0.1);
        textColor = AppColors.error;
        break;
      case '대기':
        bgColor = AppColors.warning.withOpacity(0.1);
        textColor = const Color(0xFFB8860B);
        break;
      default:
        bgColor = AppColors.grey.withOpacity(0.1);
        textColor = AppColors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}

class _Employee {
  final String name;
  final String email;
  final String position;
  final String phone;
  final String status;
  final DateTime createdAt;

  const _Employee({
    required this.name,
    required this.email,
    required this.position,
    required this.phone,
    required this.status,
    required this.createdAt,
  });
}
