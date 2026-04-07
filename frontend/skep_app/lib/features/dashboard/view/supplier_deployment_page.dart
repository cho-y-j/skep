import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';

class SupplierDeploymentPage extends StatefulWidget {
  const SupplierDeploymentPage({Key? key}) : super(key: key);

  @override
  State<SupplierDeploymentPage> createState() => _SupplierDeploymentPageState();
}

class _SupplierDeploymentPageState extends State<SupplierDeploymentPage> {
  List<Map<String, dynamic>> _deployments = [];
  List<Map<String, dynamic>> _equipmentOptions = [];
  List<Map<String, dynamic>> _personnelOptions = [];
  List<Map<String, dynamic>> _bpCompanies = [];
  List<Map<String, dynamic>> _sites = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dioClient = context.read<DioClient>();
      final responses = await Future.wait([
        dioClient.get<dynamic>(ApiEndpoints.deploymentPlans),
        dioClient.get<dynamic>(ApiEndpoints.equipments),
        dioClient.get<dynamic>(ApiEndpoints.persons),
        dioClient.get<dynamic>(ApiEndpoints.companiesByType.replaceAll('{type}', 'BP_COMPANY')),
        dioClient.get<dynamic>(ApiEndpoints.sites),
      ]);

      // Parse deployment plans
      final plansData = responses[0].data;
      if (plansData is List) {
        _deployments = plansData.cast<Map<String, dynamic>>();
      } else if (plansData is Map && plansData['content'] is List) {
        _deployments = (plansData['content'] as List).cast<Map<String, dynamic>>();
      } else {
        _deployments = [];
      }

      // Parse equipment options
      final equipData = responses[1].data;
      if (equipData is List) {
        _equipmentOptions = equipData.cast<Map<String, dynamic>>();
      } else if (equipData is Map && equipData['content'] is List) {
        _equipmentOptions = (equipData['content'] as List).cast<Map<String, dynamic>>();
      } else {
        _equipmentOptions = [];
      }

      // Parse personnel options
      final persData = responses[2].data;
      if (persData is List) {
        _personnelOptions = persData.cast<Map<String, dynamic>>();
      } else if (persData is Map && persData['content'] is List) {
        _personnelOptions = (persData['content'] as List).cast<Map<String, dynamic>>();
      } else {
        _personnelOptions = [];
      }

      // Parse BP companies
      final bpData = responses[3].data;
      if (bpData is List) {
        _bpCompanies = bpData.cast<Map<String, dynamic>>();
      } else if (bpData is Map && bpData['content'] is List) {
        _bpCompanies = (bpData['content'] as List).cast<Map<String, dynamic>>();
      } else {
        _bpCompanies = [];
      }

      // Parse sites
      final siteData = responses[4].data;
      if (siteData is List) {
        _sites = siteData.cast<Map<String, dynamic>>();
      } else if (siteData is Map && siteData['content'] is List) {
        _sites = (siteData['content'] as List).cast<Map<String, dynamic>>();
      } else {
        _sites = [];
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _mapStatus(dynamic status) {
    final s = status?.toString().toUpperCase() ?? '';
    switch (s) {
      case 'IN_PROGRESS':
      case 'ACTIVE':
        return '진행중';
      case 'REQUESTED':
      case 'PENDING':
        return '요청중';
      case 'APPROVED':
        return '승인';
      case 'COMPLETED':
      case 'ENDED':
        return '종료';
      default:
        return status?.toString() ?? '';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case '진행중':
        return AppColors.success;
      case '요청중':
        return AppColors.warning;
      case '승인':
        return AppColors.info;
      case '종료':
        return AppColors.grey;
      default:
        return AppColors.grey;
    }
  }

  Widget _buildBadge(String label, bool ok) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: ok
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: ok ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }

  void _showDeploymentRequestDialog() {
    String? selectedSite;
    String? selectedBp;
    String? selectedEquipment;
    String? selectedOperator;
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 90));
    TimeOfDay startTime = const TimeOfDay(hour: 7, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);
    final dayPriceCtrl = TextEditingController();
    final otPriceCtrl = TextEditingController();
    final nightPriceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('투입 요청'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: '현장명',
                      border: OutlineInputBorder(),
                    ),
                    items: _sites
                        .map((s) => DropdownMenuItem(
                            value: (s['id'] ?? s['name'] ?? '').toString(),
                            child: Text(s['name'] ?? s['siteName'] ?? s['id'].toString())))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedSite = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'BP사',
                      border: OutlineInputBorder(),
                    ),
                    items: _bpCompanies
                        .map((c) => DropdownMenuItem(
                            value: (c['id'] ?? c['name'] ?? '').toString(),
                            child: Text(c['name'] ?? c['companyName'] ?? c['id'].toString())))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedBp = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: '장비 선택',
                      border: OutlineInputBorder(),
                    ),
                    items: _equipmentOptions
                        .map((e) => DropdownMenuItem(
                            value: (e['id'] ?? '').toString(),
                            child: Text(e['vehicleNumber'] ?? e['name'] ?? e['id'].toString())))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedEquipment = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: '운전원 선택',
                      border: OutlineInputBorder(),
                    ),
                    items: _personnelOptions
                        .map((p) => DropdownMenuItem(
                            value: (p['id'] ?? '').toString(),
                            child: Text(p['name'] ?? p['id'].toString())))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedOperator = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: startDate,
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2030),
                            );
                            if (d != null) {
                              setDialogState(() => startDate = d);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: '시작일',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: endDate,
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2030),
                            );
                            if (d != null) {
                              setDialogState(() => endDate = d);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: '종료일',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final t = await showTimePicker(
                              context: ctx,
                              initialTime: startTime,
                            );
                            if (t != null) {
                              setDialogState(() => startTime = t);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: '시작시간',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final t = await showTimePicker(
                              context: ctx,
                              initialTime: endTime,
                            );
                            if (t != null) {
                              setDialogState(() => endTime = t);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: '종료시간',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('단가 입력', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 8),
                  _buildPriceField('주간일대', dayPriceCtrl),
                  _buildPriceField('주간O/T', otPriceCtrl),
                  _buildPriceField('야간', nightPriceCtrl),
                ],
              ),
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
                  final dioClient = context.read<DioClient>();
                  // Resolve siteName from selected site
                  String? siteName;
                  if (selectedSite != null) {
                    final matchedSite = _sites.where((s) => (s['id'] ?? s['name'] ?? '').toString() == selectedSite).toList();
                    if (matchedSite.isNotEmpty) {
                      siteName = matchedSite.first['name']?.toString() ?? matchedSite.first['siteName']?.toString();
                    }
                  }

                  await dioClient.post<dynamic>(
                    ApiEndpoints.deploymentPlans,
                    data: {
                      'supplierId': selectedOperator,
                      'bpCompanyId': selectedBp,
                      'siteName': siteName ?? '',
                      'equipmentId': selectedEquipment,
                      'startDate': '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
                      'startTime': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                      'endDate': '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
                      'endTime': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                      'rateDaily': dayPriceCtrl.text,
                      'rateOvertime': otPriceCtrl.text,
                      'rateNight': nightPriceCtrl.text,
                    },
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('투입 요청이 전송되었습니다.'), backgroundColor: AppColors.success),
                    );
                    _loadData();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('투입 요청 실패: $e'), backgroundColor: AppColors.error),
                    );
                  }
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
      ),
    );
  }

  Widget _buildPriceField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixText: '원',
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
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
                    Text('투입 현황', style: AppTextStyles.headlineLarge),
                    const SizedBox(height: 4),
                    Text(
                      '승인된 장비/인력의 투입을 관리합니다.',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showDeploymentRequestDialog,
                icon: const Icon(Icons.add),
                label: const Text('투입 요청'),
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
                  TextButton(onPressed: _loadData, child: const Text('다시 시도')),
                ],
              ),
            )
          else if (_deployments.isEmpty)
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
                  const Icon(Icons.inbox_outlined, size: 48, color: AppColors.grey),
                  const SizedBox(height: 12),
                  Text('투입 현황이 없습니다', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey)),
                ],
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
                    DataColumn(label: Text('현장명')),
                    DataColumn(label: Text('BP사')),
                    DataColumn(label: Text('장비')),
                    DataColumn(label: Text('운전원')),
                    DataColumn(label: Text('기간')),
                    DataColumn(label: Text('단가구분')),
                    DataColumn(label: Text('투입조건')),
                    DataColumn(label: Text('상태')),
                  ],
                  rows: _deployments
                      .map((d) {
                        final status = d['status'] ?? d['planStatus'] ?? '';
                        final statusLabel = _mapStatus(status);
                        final startDt = d['startDate'] ?? '';
                        final endDt = d['endDate'] ?? '';
                        final period = '$startDt ~ $endDt';
                        return DataRow(cells: [
                          DataCell(Text(d['siteName'] ?? d['site'] ?? '')),
                          DataCell(Text(d['bpCompanyName'] ?? d['bp'] ?? '')),
                          DataCell(Text(d['equipmentName'] ?? d['equipment'] ?? d['vehicleNumber'] ?? '')),
                          DataCell(Text(d['operatorName'] ?? d['operator'] ?? '')),
                          DataCell(Text(d['period'] ?? period)),
                          DataCell(Text(d['priceType'] ?? '')),
                          DataCell(Wrap(
                            children: [
                              _buildBadge('서류', d['docValid'] ?? d['documentValid'] ?? false),
                              _buildBadge('건강', d['healthCheck'] ?? d['healthCheckValid'] ?? false),
                              _buildBadge('교육', d['safetyEdu'] ?? d['safetyEducation'] ?? false),
                              _buildBadge('점검', d['preInspection'] ?? d['preInspectionDone'] ?? false),
                            ],
                          )),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(statusLabel)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: _statusColor(statusLabel),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )),
                        ]);
                      })
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
