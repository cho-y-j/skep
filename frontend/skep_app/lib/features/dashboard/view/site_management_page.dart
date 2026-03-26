import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';

class SiteManagementPage extends StatefulWidget {
  const SiteManagementPage({Key? key}) : super(key: key);

  @override
  State<SiteManagementPage> createState() => _SiteManagementPageState();
}

class _SiteManagementPageState extends State<SiteManagementPage> {
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
      final response = await dioClient.get<dynamic>('/api/dispatch/sites');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List) {
          _sites = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['content'] is List) {
          _sites = (data['content'] as List).cast<Map<String, dynamic>>();
        } else {
          _sites = [];
        }
      }
    } catch (e) {
      _error = e.toString();
      _sites = [];
    }
    if (mounted) {
      setState(() => _isLoading = false);
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

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return const Color(0xFF16A34A);
      case 'INACTIVE':
        return const Color(0xFF94A3B8);
      case 'COMPLETED':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return '활성';
      case 'INACTIVE':
        return '비활성';
      case 'COMPLETED':
        return '완료';
      default:
        return status;
    }
  }

  String _boundaryTypeLabel(String? type) {
    switch (type?.toUpperCase()) {
      case 'CIRCLE':
        return '원형';
      case 'POLYGON':
        return '폴리곤';
      default:
        return type ?? '-';
    }
  }

  void _showCreateDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final descController = TextEditingController();
    final latController = TextEditingController();
    final lngController = TextEditingController();
    final radiusController = TextEditingController();
    final coordsController = TextEditingController();
    String boundaryType = 'CIRCLE';
    int? selectedBpCompanyId;
    List<Map<String, dynamic>> bpCompanies = [];
    bool loadingBp = true;

    showDialog(
      context: context,
      builder: (ctx) {
        // Load BP companies
        context.read<DioClient>().get<dynamic>(
          ApiEndpoints.companiesByType.replaceFirst('{type}', 'BP_COMPANY'),
        ).then((res) {
          if (res.data is List) {
            bpCompanies = (res.data as List).cast<Map<String, dynamic>>();
          } else if (res.data is Map && res.data['content'] is List) {
            bpCompanies = (res.data['content'] as List).cast<Map<String, dynamic>>();
          }
          loadingBp = false;
          if (ctx.mounted) (ctx as Element).markNeedsBuild();
        }).catchError((_) {
          loadingBp = false;
          if (ctx.mounted) (ctx as Element).markNeedsBuild();
        });

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('현장 등록'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: '현장명 *',
                          border: OutlineInputBorder(),
                        ),
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
                      loadingBp
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<int>(
                              value: selectedBpCompanyId,
                              decoration: const InputDecoration(
                                labelText: 'BP사 선택',
                                border: OutlineInputBorder(),
                              ),
                              items: bpCompanies.map((c) {
                                return DropdownMenuItem<int>(
                                  value: c['id'] as int?,
                                  child: Text(c['name']?.toString() ?? c['companyName']?.toString() ?? '-'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setDialogState(() => selectedBpCompanyId = val);
                              },
                            ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: boundaryType,
                        decoration: const InputDecoration(
                          labelText: '범위 유형',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'CIRCLE', child: Text('원형 (CIRCLE)')),
                          DropdownMenuItem(value: 'POLYGON', child: Text('폴리곤 (POLYGON)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => boundaryType = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      if (boundaryType == 'CIRCLE') ...[
                        TextField(
                          controller: latController,
                          decoration: const InputDecoration(
                            labelText: '위도',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: lngController,
                          decoration: const InputDecoration(
                            labelText: '경도',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: radiusController,
                          decoration: const InputDecoration(
                            labelText: '반경 (m)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ] else ...[
                        TextField(
                          controller: coordsController,
                          decoration: const InputDecoration(
                            labelText: '좌표 (JSON)',
                            hintText: '[[lat,lng],[lat,lng],...]',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: '설명',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
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
                    final body = <String, dynamic>{
                      'name': nameController.text.trim(),
                      'address': addressController.text.trim(),
                      'boundaryType': boundaryType,
                      'description': descController.text.trim(),
                    };
                    if (selectedBpCompanyId != null) {
                      body['bpCompanyId'] = selectedBpCompanyId;
                    }
                    if (boundaryType == 'CIRCLE') {
                      if (latController.text.isNotEmpty) body['latitude'] = double.tryParse(latController.text);
                      if (lngController.text.isNotEmpty) body['longitude'] = double.tryParse(lngController.text);
                      if (radiusController.text.isNotEmpty) body['radius'] = double.tryParse(radiusController.text);
                    } else {
                      if (coordsController.text.isNotEmpty) body['coordinates'] = coordsController.text.trim();
                    }
                    try {
                      final dioClient = context.read<DioClient>();
                      await dioClient.post<dynamic>('/api/dispatch/sites', data: body);
                      if (mounted) Navigator.of(ctx).pop();
                      await _loadData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('현장이 등록되었습니다'), backgroundColor: AppColors.success),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('현장 등록 실패: $e'), backgroundColor: AppColors.error),
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
                    const Text('현장 관리', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text('등록된 현장을 관리합니다.', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
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
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('현장 등록'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
              Text(_error!, style: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton(onPressed: _loadData, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }

    if (_sites.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.location_city_outlined, size: 56, color: Color(0xFFCBD5E1)),
              const SizedBox(height: 16),
              const Text('등록된 현장이 없습니다', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
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
          child: Text('총 ${_sites.length}건', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            headingTextStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            dataTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
            columns: const [
              DataColumn(label: Text('현장명')),
              DataColumn(label: Text('주소')),
              DataColumn(label: Text('BP사')),
              DataColumn(label: Text('범위유형')),
              DataColumn(label: Text('상태')),
              DataColumn(label: Text('생성일')),
            ],
            rows: _sites.map((s) {
              final status = s['status']?.toString() ?? 'ACTIVE';
              return DataRow(cells: [
                DataCell(Text(s['name']?.toString() ?? s['siteName']?.toString() ?? '-')),
                DataCell(Text(s['address']?.toString() ?? '-')),
                DataCell(Text(s['bpCompanyName']?.toString() ?? s['bpCompany']?['name']?.toString() ?? '-')),
                DataCell(Text(_boundaryTypeLabel(s['boundaryType']?.toString()))),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(color: _statusColor(status), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                )),
                DataCell(Text(_formatDate(s['createdAt'] ?? s['created_at']))),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}
