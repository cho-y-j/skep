import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';

class AdminDeploymentPage extends StatefulWidget {
  const AdminDeploymentPage({Key? key}) : super(key: key);

  @override
  State<AdminDeploymentPage> createState() => _AdminDeploymentPageState();
}

class _AdminDeploymentPageState extends State<AdminDeploymentPage> {
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _deployments = [];

  String _filterStatus = '전체';
  final List<String> _statuses = ['전체', 'REQUESTED', 'APPROVED', 'ACTIVE', 'COMPLETED'];

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
      final response = await dioClient.get<dynamic>(ApiEndpoints.deploymentPlans);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List) {
          _deployments = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['content'] is List) {
          _deployments = (data['content'] as List).cast<Map<String, dynamic>>();
        } else if (data is Map && data['data'] is List) {
          _deployments = (data['data'] as List).cast<Map<String, dynamic>>();
        } else {
          _deployments = [];
        }
      }
    } catch (e) {
      _error = e.toString();
      _deployments = [];
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _getField(Map<String, dynamic> d, List<String> keys, [String fallback = '-']) {
    for (final k in keys) {
      if (d[k] != null) return d[k].toString();
    }
    return fallback;
  }

  String _getStatus(Map<String, dynamic> d) {
    return _getField(d, ['status', 'planStatus']);
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'REQUESTED': return '요청중';
      case 'APPROVED': return '승인';
      case 'ACTIVE': return '진행중';
      case 'COMPLETED': return '종료';
      default: return status.isNotEmpty ? status : '-';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE': return AppColors.success;
      case 'APPROVED': return AppColors.info;
      case 'REQUESTED': return AppColors.warning;
      case 'COMPLETED': return AppColors.grey;
      default: return AppColors.grey;
    }
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

  List<Map<String, dynamic>> get _filteredDeployments {
    if (_filterStatus == '전체') return _deployments;
    return _deployments.where((d) => _getStatus(d) == _filterStatus).toList();
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
                    Text('투입 관리', style: AppTextStyles.headlineLarge),
                    const SizedBox(height: 4),
                    Text(
                      '전체 투입 현황을 관리합니다.',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
                    ),
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
            ],
          ),
          const SizedBox(height: 24),
          // 필터
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _buildFilter('상태', _filterStatus, _statuses,
                    (v) => setState(() => _filterStatus = v ?? '전체')),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('투입 목록 (${_filteredDeployments.length}건)', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          _buildContent(),
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

    if (_filteredDeployments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.assignment_outlined, size: 56, color: Color(0xFFCBD5E1)),
              const SizedBox(height: 16),
              const Text('투입 계획이 없습니다', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
      );
    }

    return Container(
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
            DataColumn(label: Text('현장')),
            DataColumn(label: Text('장비')),
            DataColumn(label: Text('인력')),
            DataColumn(label: Text('시작일')),
            DataColumn(label: Text('종료일')),
            DataColumn(label: Text('상태')),
          ],
          rows: _filteredDeployments.map((d) {
            final status = _getStatus(d);
            return DataRow(cells: [
              DataCell(Text(_getField(d, ['siteName', 'site', 'siteId']))),
              DataCell(Text(_getField(d, ['equipmentName', 'equipment', 'equipmentId']))),
              DataCell(Text(_getField(d, ['personnelName', 'personnel', 'personnelId']))),
              DataCell(Text(_formatDate(d['startDate'] ?? d['start_date']))),
              DataCell(Text(_formatDate(d['endDate'] ?? d['end_date']))),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusLabel(status),
                  style: TextStyle(
                    color: _statusColor(status),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFilter(String label, String value, List<String> options,
      ValueChanged<String?> onChanged) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o == '전체' ? '전체' : _getStatusLabel(o))))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
