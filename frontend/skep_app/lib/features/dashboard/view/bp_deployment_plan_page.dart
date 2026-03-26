import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';

class BpDeploymentPlanPage extends StatefulWidget {
  const BpDeploymentPlanPage({Key? key}) : super(key: key);

  @override
  State<BpDeploymentPlanPage> createState() => _BpDeploymentPlanPageState();
}

class _BpDeploymentPlanPageState extends State<BpDeploymentPlanPage> {
  List<Map<String, dynamic>> _receivedRequests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlans());
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dioClient = context.read<DioClient>();
      final response = await dioClient.get<dynamic>(ApiEndpoints.deploymentPlans);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List) {
          _receivedRequests = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['content'] is List) {
          _receivedRequests = (data['content'] as List).cast<Map<String, dynamic>>();
        } else {
          _receivedRequests = [];
        }
      }
    } catch (e) {
      _error = e.toString();
      _receivedRequests = [];
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _translateStatus(String? status) {
    switch (status) {
      case 'APPROVED': return '승인';
      case 'PENDING': return '대기';
      case 'REJECTED': return '반려';
      default: return status ?? '-';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case '승인':
      case 'APPROVED':
        return AppColors.success;
      case '대기':
      case 'PENDING':
        return AppColors.warning;
      case '반려':
      case 'REJECTED':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }

  Future<void> _approveRequest(int index) async {
    final id = _receivedRequests[index]['id'];
    try {
      final dioClient = context.read<DioClient>();
      if (id != null) {
        await dioClient.put<dynamic>(
          ApiEndpoints.deploymentPlan.replaceAll('{id}', id.toString()),
          data: {'status': 'APPROVED'},
        );
      }
      setState(() {
        _receivedRequests[index]['status'] = '승인';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('투입 요청이 승인되었습니다.')),
      );
      _loadPlans();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('승인 실패: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _rejectRequest(int index) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('반려 사유 입력'),
        content: TextFormField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '반려 사유를 입력하세요',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final id = _receivedRequests[index]['id'];
              try {
                final dioClient = context.read<DioClient>();
                if (id != null) {
                  await dioClient.put<dynamic>(
                    ApiEndpoints.deploymentPlan.replaceAll('{id}', id.toString()),
                    data: {'status': 'REJECTED', 'reason': reasonCtrl.text},
                  );
                }
                setState(() {
                  _receivedRequests[index]['status'] = '반려';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('투입 요청이 반려되었습니다.')),
                );
                _loadPlans();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('반려 실패: $e'), backgroundColor: AppColors.error),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('반려'),
          ),
        ],
      ),
    );
  }

  void _showEquipmentRequestDialog() {
    String equipType = '';
    String qty = '';
    String period = '';
    String location = '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('장비 요청'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '장비 유형',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => equipType = v,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '수량',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => qty = v,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '기간 (예: 2026-04-01 ~ 2026-06-30)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => period = v,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '현장 위치',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => location = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                // Parse period "YYYY-MM-DD ~ YYYY-MM-DD" into startDate/endDate
                String? startDate;
                String? endDate;
                if (period.contains('~')) {
                  final parts = period.split('~').map((s) => s.trim()).toList();
                  if (parts.length == 2) {
                    startDate = parts[0];
                    endDate = parts[1];
                  }
                }
                final dioClient = context.read<DioClient>();
                await dioClient.post<dynamic>(
                  ApiEndpoints.quotationRequests,
                  data: {
                    'equipmentType': equipType,
                    'quantity': int.tryParse(qty) ?? 1,
                    'startDate': startDate ?? period,
                    'endDate': endDate,
                    'location': location,
                    'title': '$equipType ${qty}대 요청',
                    'description': '현장: $location',
                  },
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('장비 요청이 전송되었습니다.')),
                );
                _loadPlans();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('요청 실패: $e'), backgroundColor: AppColors.error),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('요청'),
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('투입 계획', style: AppTextStyles.headlineLarge),
                    const SizedBox(height: 4),
                    Text(
                      '공급사 투입 요청을 승인하고, 장비를 요청합니다.',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _loadPlans,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('새로고침'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showEquipmentRequestDialog,
                icon: const Icon(Icons.add),
                label: const Text('장비 요청'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('수신된 투입 요청', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text('데이터를 불러오는데 실패했습니다', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
                    const SizedBox(height: 8),
                    Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey)),
                    const SizedBox(height: 16),
                    TextButton(onPressed: _loadPlans, child: const Text('다시 시도')),
                  ],
                ),
              ),
            )
          else if (_receivedRequests.isEmpty)
            Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.inbox_outlined, size: 48, color: AppColors.grey),
                    const SizedBox(height: 12),
                    Text('수신된 투입 요청이 없습니다', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey)),
                  ],
                ),
              ),
            )
          else
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('공급사명')),
                  DataColumn(label: Text('장비유형')),
                  DataColumn(label: Text('차량번호')),
                  DataColumn(label: Text('운전원')),
                  DataColumn(label: Text('기간')),
                  DataColumn(label: Text('상태')),
                  DataColumn(label: Text('작업')),
                ],
                rows: List.generate(_receivedRequests.length, (i) {
                  final r = _receivedRequests[i];
                  return DataRow(cells: [
                    DataCell(Text((r['supplier'] ?? r['supplierName'] ?? r['companyName'] ?? '-').toString())),
                    DataCell(Text((r['equipType'] ?? r['equipmentType'] ?? r['equipment_type'] ?? '-').toString())),
                    DataCell(Text((r['plateNo'] ?? r['vehicleNumber'] ?? r['vehicle_number'] ?? '-').toString())),
                    DataCell(Text((r['operator'] ?? r['operatorName'] ?? '-').toString())),
                    DataCell(Text((r['period'] ?? '${r['startDate'] ?? '-'} ~ ${r['endDate'] ?? '-'}').toString())),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(r['status']?.toString()).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _translateStatus(r['status']?.toString()),
                        style: TextStyle(
                          color: _statusColor(r['status']?.toString()),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )),
                    DataCell(r['status'] == '대기' || r['status'] == 'PENDING'
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () => _approveRequest(i),
                                style: TextButton.styleFrom(
                                    foregroundColor: AppColors.success),
                                child: const Text('승인'),
                              ),
                              TextButton(
                                onPressed: () => _rejectRequest(i),
                                style: TextButton.styleFrom(
                                    foregroundColor: AppColors.error),
                                child: const Text('반려'),
                              ),
                            ],
                          )
                        : const Text('-')),
                  ]);
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
