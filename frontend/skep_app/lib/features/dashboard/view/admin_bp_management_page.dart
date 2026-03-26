import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';

class AdminBpManagementPage extends StatefulWidget {
  const AdminBpManagementPage({Key? key}) : super(key: key);

  @override
  State<AdminBpManagementPage> createState() => _AdminBpManagementPageState();
}

class _AdminBpManagementPageState extends State<AdminBpManagementPage> {
  int? _expandedIndex;
  List<Map<String, dynamic>> _bpList = [];
  bool _isLoading = true;
  String? _error;

  // Sites cache per BP company
  Map<int, List<Map<String, dynamic>>> _sitesCache = {};
  Map<int, bool> _sitesLoading = {};

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
      final response = await dioClient.get<dynamic>(
        ApiEndpoints.companiesByType.replaceAll('{type}', 'BP_COMPANY'),
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List) {
          _bpList = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['companies'] is List) {
          _bpList = (data['companies'] as List).cast<Map<String, dynamic>>();
        } else if (data is Map && data['content'] is List) {
          _bpList = (data['content'] as List).cast<Map<String, dynamic>>();
        } else {
          _bpList = [];
        }
      }
    } catch (e) {
      _error = e.toString();
      _bpList = [];
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSites(int bpCompanyId) async {
    if (_sitesCache.containsKey(bpCompanyId)) return;
    setState(() {
      _sitesLoading[bpCompanyId] = true;
    });
    try {
      final dioClient = context.read<DioClient>();
      final response = await dioClient.get<dynamic>(
        '/api/dispatch/sites/bp/$bpCompanyId',
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List) {
          _sitesCache[bpCompanyId] = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['sites'] is List) {
          _sitesCache[bpCompanyId] = (data['sites'] as List).cast<Map<String, dynamic>>();
        } else {
          _sitesCache[bpCompanyId] = [];
        }
      }
    } catch (e) {
      _sitesCache[bpCompanyId] = [];
    }
    if (mounted) {
      setState(() {
        _sitesLoading[bpCompanyId] = false;
      });
    }
  }

  void _showAddBpDialog() {
    final nameController = TextEditingController();
    final bizNoController = TextEditingController();
    final ceoController = TextEditingController();
    final managerController = TextEditingController();
    final contactController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('BP사 등록'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: '회사명', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: bizNoController,
                    decoration: const InputDecoration(labelText: '사업자번호', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ceoController,
                    decoration: const InputDecoration(labelText: '대표자', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: managerController,
                    decoration: const InputDecoration(labelText: '담당자', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contactController,
                    decoration: const InputDecoration(labelText: '연락처', border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: '이메일', border: OutlineInputBorder(), hintText: 'example@company.com'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: '주소', border: OutlineInputBorder()),
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
                      'companyType': 'BP_COMPANY',
                      'phone': contactController.text.trim(),
                      'email': emailController.text.trim(),
                      'address': addressController.text.trim(),
                      'manager': managerController.text.trim(),
                    },
                  );
                  if (mounted) Navigator.of(ctx).pop();
                  await _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('BP사가 등록되었습니다'), backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('BP사 등록 실패: $e'), backgroundColor: AppColors.error),
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
  }

  String _getBpName(Map<String, dynamic> bp) {
    return bp['name']?.toString() ?? bp['companyName']?.toString() ?? '-';
  }

  String _getBpManager(Map<String, dynamic> bp) {
    return bp['manager']?.toString() ?? bp['managerName']?.toString() ?? bp['ceoName']?.toString() ?? bp['ceo_name']?.toString() ?? '-';
  }

  String _getBpContact(Map<String, dynamic> bp) {
    return bp['contact']?.toString() ?? bp['phone']?.toString() ?? bp['tel']?.toString() ?? '-';
  }

  int _getBpId(Map<String, dynamic> bp) {
    return bp['id'] is int ? bp['id'] : int.tryParse(bp['id']?.toString() ?? '0') ?? 0;
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
                    Text('BP사 관리', style: AppTextStyles.headlineLarge),
                    const SizedBox(height: 4),
                    Text(
                      'BP사 목록 및 투입 현황을 관리합니다.',
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
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showAddBpDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('BP사 등록'),
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildContent(),
          ),
          if (!_isLoading && _error == null && _expandedIndex != null && _expandedIndex! < _bpList.length) ...[
            const SizedBox(height: 16),
            _buildDetailPanel(_bpList[_expandedIndex!]),
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
              TextButton(onPressed: _loadData, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }

    if (_bpList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.business_outlined, size: 48, color: AppColors.grey),
              const SizedBox(height: 12),
              Text(
                '등록된 BP사가 없습니다',
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
        columns: const [
          DataColumn(label: Text('회사명')),
          DataColumn(label: Text('담당자')),
          DataColumn(label: Text('연락처')),
          DataColumn(label: Text('상세')),
        ],
        rows: List.generate(_bpList.length, (i) {
          final bp = _bpList[i];
          return DataRow(cells: [
            DataCell(Text(_getBpName(bp))),
            DataCell(Text(_getBpManager(bp))),
            DataCell(Text(_getBpContact(bp))),
            DataCell(IconButton(
              icon: Icon(
                _expandedIndex == i ? Icons.expand_less : Icons.expand_more,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _expandedIndex = _expandedIndex == i ? null : i;
                });
                if (_expandedIndex == i) {
                  final bpId = _getBpId(_bpList[i]);
                  if (bpId > 0) _loadSites(bpId);
                }
              },
            )),
          ]);
        }),
      ),
    );
  }

  Widget _buildDetailPanel(Map<String, dynamic> bp) {
    final bpId = _getBpId(bp);
    final sites = _sitesCache[bpId] ?? [];
    final isLoadingSites = _sitesLoading[bpId] == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_getBpName(bp)} - 현장 목록', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          if (isLoadingSites)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (sites.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('등록된 현장이 없습니다', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey)),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('현장명')),
                  DataColumn(label: Text('주소')),
                ],
                rows: sites
                    .map((s) => DataRow(cells: [
                          DataCell(Text(s['name']?.toString() ?? s['siteName']?.toString() ?? '-')),
                          DataCell(Text(s['address']?.toString() ?? '-')),
                        ]))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
