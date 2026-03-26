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
              DataCell(Text(eq['name']?.toString() ?? eq['equipment_name']?.toString() ?? '-')),
              DataCell(Text(eq['type']?.toString() ?? eq['equipment_type']?.toString() ?? '-')),
              DataCell(Text(
                '${eq['model']?.toString() ?? eq['manufacturer']?.toString() ?? '-'}',
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
