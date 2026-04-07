import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';

class EquipmentStatusPage extends StatefulWidget {
  const EquipmentStatusPage({Key? key}) : super(key: key);

  @override
  State<EquipmentStatusPage> createState() => _EquipmentStatusPageState();
}

class _EquipmentStatusPageState extends State<EquipmentStatusPage> {
  List<Map<String, dynamic>> _equipments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEquipments();
  }

  Future<void> _loadEquipments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dioClient = context.read<DioClient>();
      final response = await dioClient.get<dynamic>(ApiEndpoints.equipments);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List) {
          _equipments = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['equipments'] is List) {
          _equipments = (data['equipments'] as List).cast<Map<String, dynamic>>();
        } else {
          _equipments = [];
        }
      }
    } catch (e) {
      _error = e.toString();
      _equipments = [];
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _translateStatus(String? status) {
    switch (status) {
      case 'ACTIVE':
        return '가동중';
      case 'INACTIVE':
        return '미가동';
      case 'MAINTENANCE':
        return '정비중';
      case 'DEPLOYED':
        return '투입중';
      default:
        return status ?? '-';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'ACTIVE':
      case 'DEPLOYED':
        return AppColors.success;
      case 'INACTIVE':
        return AppColors.grey;
      case 'MAINTENANCE':
        return AppColors.warning;
      default:
        return AppColors.grey;
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
                    Text('장비 현황', style: AppTextStyles.headlineLarge),
                    const SizedBox(height: 4),
                    Text(
                      '등록된 장비 목록을 확인합니다.',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _loadEquipments,
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
                onPressed: _showAddEquipmentDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('장비 추가'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  void _showAddEquipmentDialog() {
    final vehicleNumberController = TextEditingController();
    final modelNameController = TextEditingController();
    final manufacturerController = TextEditingController();
    final yearController = TextEditingController(text: '2024');
    String selectedType = '';
    String? selectedSupplierId;
    List<Map<String, dynamic>> suppliers = [];
    List<Map<String, dynamic>> eqTypes = [];
    bool loadingData = true;

    // 공급사 + 장비타입 로드
    final dioClient = context.read<DioClient>();
    Future.wait([
      dioClient.get<dynamic>('/api/auth/companies/type/EQUIPMENT_SUPPLIER'),
      dioClient.get<dynamic>('/api/equipment/types'),
    ]).then((results) {
      final supData = results[0].data;
      final typeData = results[1].data;
      if (supData is List) suppliers = supData.cast<Map<String, dynamic>>();
      if (typeData is List) eqTypes = typeData.cast<Map<String, dynamic>>();
      loadingData = false;
      if (suppliers.isNotEmpty) selectedSupplierId = suppliers[0]['id']?.toString();
      if (eqTypes.isNotEmpty) selectedType = eqTypes[0]['name']?.toString() ?? '';
    }).catchError((_) { loadingData = false; });

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            // 데이터 로드 후 리빌드
            if (loadingData) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (ctx.mounted) setDialogState(() {});
              });
            }
            return AlertDialog(
              title: const Text('장비 추가'),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (suppliers.isNotEmpty)
                        DropdownButtonFormField<String>(
                          value: selectedSupplierId,
                          decoration: const InputDecoration(
                            labelText: '공급사 *',
                            border: OutlineInputBorder(),
                          ),
                          items: suppliers.map((s) => DropdownMenuItem<String>(
                            value: s['id']?.toString(),
                            child: Text(s['name']?.toString() ?? '-'),
                          )).toList(),
                          onChanged: (v) => setDialogState(() => selectedSupplierId = v),
                        ),
                      const SizedBox(height: 16),
                      if (eqTypes.isNotEmpty)
                        DropdownButtonFormField<String>(
                          value: eqTypes.any((t) => t['name'] == selectedType) ? selectedType : null,
                          decoration: const InputDecoration(
                            labelText: '장비 유형 *',
                            border: OutlineInputBorder(),
                          ),
                          items: eqTypes.map((t) => DropdownMenuItem<String>(
                            value: t['name']?.toString(),
                            child: Text(t['name']?.toString() ?? '-'),
                          )).toList(),
                          onChanged: (v) => setDialogState(() => selectedType = v ?? ''),
                        )
                      else
                        TextField(
                          decoration: const InputDecoration(
                            labelText: '장비 유형 *',
                            border: OutlineInputBorder(),
                            hintText: '예: 대형 크레인',
                          ),
                          onChanged: (v) => selectedType = v,
                        ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: vehicleNumberController,
                        decoration: const InputDecoration(
                          labelText: '차량번호 *',
                          border: OutlineInputBorder(),
                          hintText: '예: 서울11가1111',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: modelNameController,
                        decoration: const InputDecoration(
                          labelText: '모델명',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: manufacturerController,
                        decoration: const InputDecoration(
                          labelText: '제조사',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: yearController,
                        decoration: const InputDecoration(
                          labelText: '제조연도',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
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
                    if (vehicleNumberController.text.trim().isEmpty || selectedType.isEmpty) return;
                    try {
                      await dioClient.post<dynamic>(
                        ApiEndpoints.equipments,
                        data: {
                          'supplier_id': selectedSupplierId,
                          'equipment_type_name': selectedType.trim(),
                          'vehicle_number': vehicleNumberController.text.trim(),
                          'model_name': modelNameController.text.trim(),
                          'manufacturer': manufacturerController.text.trim(),
                          'manufacture_year': int.tryParse(yearController.text.trim()) ?? 2024,
                        },
                      );
                      if (mounted) Navigator.of(ctx).pop();
                      await _loadEquipments();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('장비가 추가되었습니다'), backgroundColor: AppColors.success),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('장비 추가 실패: $e'), backgroundColor: AppColors.error),
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
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                '데이터를 불러오는데 실패했습니다',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _loadEquipments,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    if (_equipments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.build_outlined, size: 48, color: AppColors.grey),
              const SizedBox(height: 12),
              Text(
                '데이터가 없습니다',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppColors.greyLight),
        columns: const [
          DataColumn(label: Text('장비명')),
          DataColumn(label: Text('장비 유형')),
          DataColumn(label: Text('모델/제조사')),
          DataColumn(label: Text('공급사')),
          DataColumn(label: Text('상태')),
          DataColumn(label: Text('등록일')),
        ],
        rows: _equipments.map((eq) {
          final status = eq['status']?.toString();
          return DataRow(
            cells: [
              DataCell(Text(eq['vehicle_number']?.toString() ?? eq['vehicleNumber']?.toString() ?? '-')),
              DataCell(Text(eq['equipment_type_name']?.toString() ?? eq['equipmentTypeName']?.toString() ?? '-')),
              DataCell(Text(
                '${eq['model_name']?.toString() ?? eq['modelName']?.toString() ?? '-'} / ${eq['manufacturer']?.toString() ?? '-'}',
              )),
              DataCell(Text(eq['supplier_name']?.toString() ?? eq['companyName']?.toString() ?? '-')),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _translateStatus(status),
                    style: TextStyle(
                      color: _statusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              DataCell(Text(_formatDate(eq['created_at'] ?? eq['createdAt']))),
            ],
          );
        }).toList(),
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
