import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';

class ChecklistManagementPage extends StatefulWidget {
  const ChecklistManagementPage({Key? key}) : super(key: key);

  @override
  State<ChecklistManagementPage> createState() => _ChecklistManagementPageState();
}

class _ChecklistManagementPageState extends State<ChecklistManagementPage> {
  List<Map<String, dynamic>> _plans = [];
  bool _isLoadingPlans = true;
  String? _errorPlans;

  int? _selectedPlanId;
  Map<String, dynamic>? _checklist;
  bool _isLoadingChecklist = false;
  String? _errorChecklist;

  // Checklist item states
  bool _quotationConfirmed = false;
  bool _documentsVerified = false;
  bool _licenseVerified = false;
  bool _safetyInspectionPassed = false;
  bool _healthCheckCompleted = false;
  bool _personnelAssigned = false;
  bool _equipmentAssigned = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlans());
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoadingPlans = true;
      _errorPlans = null;
    });
    try {
      final dioClient = context.read<DioClient>();
      final response = await dioClient.get<dynamic>(ApiEndpoints.deploymentPlans);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List) {
          _plans = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['content'] is List) {
          _plans = (data['content'] as List).cast<Map<String, dynamic>>();
        } else {
          _plans = [];
        }
      }
    } catch (e) {
      _errorPlans = e.toString();
      _plans = [];
    }
    if (mounted) setState(() => _isLoadingPlans = false);
  }

  Future<void> _loadChecklist(int planId) async {
    setState(() {
      _isLoadingChecklist = true;
      _errorChecklist = null;
      _checklist = null;
    });
    try {
      final dioClient = context.read<DioClient>();
      final response = await dioClient.get<dynamic>('/api/dispatch/checklists/plan/$planId');
      if (response.statusCode == 200 && response.data != null) {
        _checklist = response.data is Map<String, dynamic> ? response.data : null;
        if (_checklist != null) {
          _quotationConfirmed = _checklist!['quotationConfirmed'] == true;
          _documentsVerified = _checklist!['documentsVerified'] == true;
          _licenseVerified = _checklist!['licenseVerified'] == true;
          _safetyInspectionPassed = _checklist!['safetyInspectionPassed'] == true;
          _healthCheckCompleted = _checklist!['healthCheckCompleted'] == true;
          _personnelAssigned = _checklist!['personnelAssigned'] == true;
          _equipmentAssigned = _checklist!['equipmentAssigned'] == true;
        }
      }
    } catch (e) {
      _errorChecklist = e.toString();
    }
    if (mounted) setState(() => _isLoadingChecklist = false);
  }

  Future<void> _updateChecklist() async {
    if (_checklist == null) return;
    final checklistId = _checklist!['id'];
    if (checklistId == null) return;

    try {
      final dioClient = context.read<DioClient>();
      await dioClient.put<dynamic>(
        '/api/dispatch/checklists/$checklistId/update',
        data: {
          'quotationConfirmed': _quotationConfirmed,
          'documentsVerified': _documentsVerified,
          'licenseVerified': _licenseVerified,
          'safetyInspectionPassed': _safetyInspectionPassed,
          'healthCheckCompleted': _healthCheckCompleted,
          'personnelAssigned': _personnelAssigned,
          'equipmentAssigned': _equipmentAssigned,
        },
      );
      if (_selectedPlanId != null) await _loadChecklist(_selectedPlanId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('체크리스트가 저장되었습니다'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _updateSingleItem(String field, bool value) async {
    if (_checklist == null) return;
    final checklistId = _checklist!['id'];
    if (checklistId == null) return;

    try {
      final dioClient = context.read<DioClient>();
      await dioClient.put<dynamic>(
        '/api/dispatch/checklists/$checklistId/update',
        data: {
          'quotationConfirmed': _quotationConfirmed,
          'documentsVerified': _documentsVerified,
          'licenseVerified': _licenseVerified,
          'safetyInspectionPassed': _safetyInspectionPassed,
          'healthCheckCompleted': _healthCheckCompleted,
          'personnelAssigned': _personnelAssigned,
          'equipmentAssigned': _equipmentAssigned,
        },
      );
      if (_selectedPlanId != null) await _loadChecklist(_selectedPlanId!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('업데이트 실패: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showOverrideDialog() {
    if (_checklist == null) return;
    final checklistId = _checklist!['id'];
    if (checklistId == null) return;

    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('강제 통과'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('체크리스트를 강제로 통과시킵니다. 사유를 입력하세요.'),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: '사유 *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) return;
                try {
                  final dioClient = context.read<DioClient>();
                  await dioClient.put<dynamic>(
                    '/api/dispatch/checklists/$checklistId/override',
                    data: {'reason': reasonController.text.trim()},
                  );
                  if (mounted) Navigator.of(ctx).pop();
                  if (_selectedPlanId != null) await _loadChecklist(_selectedPlanId!);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('강제 통과 처리되었습니다'), backgroundColor: AppColors.info),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('강제 통과 실패: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: AppColors.white,
              ),
              child: const Text('강제 통과'),
            ),
          ],
        );
      },
    );
  }

  Color _overallStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFFD97706);
      case 'PASSED':
        return const Color(0xFF16A34A);
      case 'OVERRIDDEN':
        return const Color(0xFF2196F3);
      case 'FAILED':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _overallStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return '대기';
      case 'PASSED':
        return '통과';
      case 'OVERRIDDEN':
        return '강제통과';
      case 'FAILED':
        return '실패';
      default:
        return status;
    }
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
                    const Text('투입 체크리스트', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text('배차 계획별 투입 체크리스트를 관리합니다.', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _loadPlans,
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
          // Plan selector
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: _buildPlanSelector(),
          ),
          const SizedBox(height: 20),
          // Checklist content
          if (_selectedPlanId != null) _buildChecklistContent(),
        ],
      ),
    );
  }

  Widget _buildPlanSelector() {
    if (_isLoadingPlans) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorPlans != null) {
      return Column(
        children: [
          const Icon(Icons.error_outline, size: 40, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 8),
          Text('계획 목록 로딩 실패: $_errorPlans', style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
          const SizedBox(height: 8),
          TextButton(onPressed: _loadPlans, child: const Text('다시 시도')),
        ],
      );
    }
    if (_plans.isEmpty) {
      return const Center(
        child: Column(
          children: [
            Icon(Icons.assignment_outlined, size: 40, color: Color(0xFFCBD5E1)),
            SizedBox(height: 8),
            Text('등록된 배차 계획이 없습니다', style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedPlanId,
      decoration: const InputDecoration(
        labelText: '배차 계획 선택',
        border: OutlineInputBorder(),
      ),
      items: _plans.map((p) {
        final id = p['id'];
        final name = p['title']?.toString() ?? p['planName']?.toString() ?? p['siteName']?.toString() ?? '계획 #$id';
        return DropdownMenuItem<int>(
          value: id is int ? id : int.tryParse(id.toString()),
          child: Text(name),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() => _selectedPlanId = val);
          _loadChecklist(val);
        }
      },
    );
  }

  Widget _buildChecklistContent() {
    if (_isLoadingChecklist) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorChecklist != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 56, color: Color(0xFFCBD5E1)),
              const SizedBox(height: 16),
              const Text('체크리스트를 불러오는데 실패했습니다', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
              const SizedBox(height: 8),
              Text(_errorChecklist!, style: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton(onPressed: () => _loadChecklist(_selectedPlanId!), child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }

    if (_checklist == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.checklist_outlined, size: 56, color: Color(0xFFCBD5E1)),
              SizedBox(height: 16),
              Text('해당 계획의 체크리스트가 없습니다', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
      );
    }

    final overallStatus = _checklist!['status']?.toString() ?? _checklist!['overallStatus']?.toString() ?? 'PENDING';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('체크리스트 항목', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _overallStatusColor(overallStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _overallStatusLabel(overallStatus),
                  style: TextStyle(color: _overallStatusColor(overallStatus), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          _buildCheckItem('견적 확정', _quotationConfirmed, (v) {
            setState(() => _quotationConfirmed = v!);
            _updateSingleItem('quotationConfirmed', v!);
          }),
          _buildCheckItem('서류 검증', _documentsVerified, (v) {
            setState(() => _documentsVerified = v!);
            _updateSingleItem('documentsVerified', v!);
          }),
          _buildCheckItem('면허 검증', _licenseVerified, (v) {
            setState(() => _licenseVerified = v!);
            _updateSingleItem('licenseVerified', v!);
          }),
          _buildCheckItem('안전점검 통과', _safetyInspectionPassed, (v) {
            setState(() => _safetyInspectionPassed = v!);
            _updateSingleItem('safetyInspectionPassed', v!);
          }),
          _buildCheckItem('건강검진 완료', _healthCheckCompleted, (v) {
            setState(() => _healthCheckCompleted = v!);
            _updateSingleItem('healthCheckCompleted', v!);
          }),
          _buildCheckItem('인력 배정', _personnelAssigned, (v) {
            setState(() => _personnelAssigned = v!);
            _updateSingleItem('personnelAssigned', v!);
          }),
          _buildCheckItem('장비 배정', _equipmentAssigned, (v) {
            setState(() => _equipmentAssigned = v!);
            _updateSingleItem('equipmentAssigned', v!);
          }),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: _showOverrideDialog,
                icon: const Icon(Icons.warning_amber_outlined, size: 18),
                label: const Text('강제 통과'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD97706),
                  side: const BorderSide(color: Color(0xFFD97706)),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _updateChecklist,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('저장'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String label, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: CheckboxListTile(
        title: Text(label, style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B))),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
