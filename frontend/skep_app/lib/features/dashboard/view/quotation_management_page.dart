import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';

class QuotationManagementPage extends StatefulWidget {
  const QuotationManagementPage({Key? key}) : super(key: key);

  @override
  State<QuotationManagementPage> createState() => _QuotationManagementPageState();
}

class _QuotationManagementPageState extends State<QuotationManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _quotations = [];
  bool _isLoadingRequests = true;
  bool _isLoadingQuotations = true;
  String? _errorRequests;
  String? _errorQuotations;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRequests();
      _loadQuotations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoadingRequests = true;
      _errorRequests = null;
    });
    try {
      final dioClient = context.read<DioClient>();
      final response = await dioClient.get<dynamic>('/api/dispatch/quotations/requests');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List) {
          _requests = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['content'] is List) {
          _requests = (data['content'] as List).cast<Map<String, dynamic>>();
        } else {
          _requests = [];
        }
      }
    } catch (e) {
      _errorRequests = e.toString();
      _requests = [];
    }
    if (mounted) setState(() => _isLoadingRequests = false);
  }

  Future<void> _loadQuotations() async {
    setState(() {
      _isLoadingQuotations = true;
      _errorQuotations = null;
    });
    try {
      final dioClient = context.read<DioClient>();
      // Load all quotations - try the base endpoint
      final response = await dioClient.get<dynamic>('/api/dispatch/quotations');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List) {
          _quotations = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['content'] is List) {
          _quotations = (data['content'] as List).cast<Map<String, dynamic>>();
        } else {
          _quotations = [];
        }
      }
    } catch (e) {
      _errorQuotations = e.toString();
      _quotations = [];
    }
    if (mounted) setState(() => _isLoadingQuotations = false);
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

  Color _requestStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFFD97706);
      case 'QUOTED':
        return const Color(0xFF2196F3);
      case 'ACCEPTED':
        return const Color(0xFF16A34A);
      case 'REJECTED':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _requestStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return '대기';
      case 'QUOTED':
        return '견적완료';
      case 'ACCEPTED':
        return '승인';
      case 'REJECTED':
        return '거절';
      default:
        return status;
    }
  }

  Color _quotationStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return const Color(0xFF94A3B8);
      case 'SUBMITTED':
        return const Color(0xFF2196F3);
      case 'ACCEPTED':
        return const Color(0xFF16A34A);
      case 'REJECTED':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _quotationStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return '초안';
      case 'SUBMITTED':
        return '제출';
      case 'ACCEPTED':
        return '승인';
      case 'REJECTED':
        return '거절';
      default:
        return status;
    }
  }

  void _showCreateRequestDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();
    int? selectedSiteId;
    List<Map<String, dynamic>> sites = [];
    bool loadingSites = true;

    showDialog(
      context: context,
      builder: (ctx) {
        context.read<DioClient>().get<dynamic>('/api/dispatch/sites').then((res) {
          if (res.data is List) {
            sites = (res.data as List).cast<Map<String, dynamic>>();
          } else if (res.data is Map && res.data['content'] is List) {
            sites = (res.data['content'] as List).cast<Map<String, dynamic>>();
          }
          loadingSites = false;
          if (ctx.mounted) (ctx as Element).markNeedsBuild();
        }).catchError((_) {
          loadingSites = false;
          if (ctx.mounted) (ctx as Element).markNeedsBuild();
        });

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('견적 요청'),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      loadingSites
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<int>(
                              value: selectedSiteId,
                              decoration: const InputDecoration(
                                labelText: '현장 선택',
                                border: OutlineInputBorder(),
                              ),
                              items: sites.map((s) {
                                return DropdownMenuItem<int>(
                                  value: s['id'] as int?,
                                  child: Text(s['name']?.toString() ?? s['siteName']?.toString() ?? '-'),
                                );
                              }).toList(),
                              onChanged: (val) => setDialogState(() => selectedSiteId = val),
                            ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: '제목 *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: '설명',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: startDateController,
                        decoration: const InputDecoration(
                          labelText: '시작일 (YYYY-MM-DD)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: endDateController,
                        decoration: const InputDecoration(
                          labelText: '종료일 (YYYY-MM-DD)',
                          border: OutlineInputBorder(),
                        ),
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
                    if (titleController.text.trim().isEmpty) return;
                    try {
                      final dioClient = context.read<DioClient>();
                      await dioClient.post<dynamic>(
                        '/api/dispatch/quotations/requests',
                        data: {
                          'siteId': selectedSiteId,
                          'title': titleController.text.trim(),
                          'description': descController.text.trim(),
                          'startDate': startDateController.text.trim(),
                          'endDate': endDateController.text.trim(),
                        },
                      );
                      if (mounted) Navigator.of(ctx).pop();
                      await _loadRequests();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('견적 요청이 생성되었습니다'), backgroundColor: AppColors.success),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('견적 요청 실패: $e'), backgroundColor: AppColors.error),
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
            );
          },
        );
      },
    );
  }

  void _showCreateQuotationDialog() {
    final supplierController = TextEditingController();
    int? selectedRequestId;
    final items = <Map<String, dynamic>>[];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('견적서 작성'),
              content: SizedBox(
                width: 550,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        value: selectedRequestId,
                        decoration: const InputDecoration(
                          labelText: '견적 요청 선택',
                          border: OutlineInputBorder(),
                        ),
                        items: _requests.map((r) {
                          return DropdownMenuItem<int>(
                            value: r['id'] as int?,
                            child: Text(r['title']?.toString() ?? '요청 #${r['id']}'),
                          );
                        }).toList(),
                        onChanged: (val) => setDialogState(() => selectedRequestId = val),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: supplierController,
                        decoration: const InputDecoration(
                          labelText: '공급사명',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('품목', style: TextStyle(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                items.add({
                                  'equipmentTypeName': '',
                                  'quantity': 1,
                                  'rateDaily': 0,
                                  'laborIncluded': false,
                                });
                              });
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('추가'),
                          ),
                        ],
                      ),
                      ...items.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        decoration: const InputDecoration(
                                          labelText: '장비유형',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                        onChanged: (v) => item['equipmentTypeName'] = v,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 70,
                                      child: TextField(
                                        decoration: const InputDecoration(
                                          labelText: '수량',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) => item['quantity'] = int.tryParse(v) ?? 1,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 100,
                                      child: TextField(
                                        decoration: const InputDecoration(
                                          labelText: '일당(원)',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) => item['rateDaily'] = int.tryParse(v) ?? 0,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: item['laborIncluded'] == true,
                                      onChanged: (v) => setDialogState(() => item['laborIncluded'] = v),
                                    ),
                                    const Text('인력 포함'),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                      onPressed: () => setDialogState(() => items.removeAt(i)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
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
                    if (selectedRequestId == null) return;
                    try {
                      final dioClient = context.read<DioClient>();
                      await dioClient.post<dynamic>(
                        '/api/dispatch/quotations',
                        data: {
                          'requestId': selectedRequestId,
                          'supplierName': supplierController.text.trim(),
                          'items': items,
                        },
                      );
                      if (mounted) Navigator.of(ctx).pop();
                      await _loadQuotations();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('견적서가 생성되었습니다'), backgroundColor: AppColors.success),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('견적서 생성 실패: $e'), backgroundColor: AppColors.error),
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

  Future<void> _submitQuotation(int id) async {
    try {
      final dioClient = context.read<DioClient>();
      await dioClient.put<dynamic>('/api/dispatch/quotations/$id/submit');
      await _loadQuotations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('견적서가 제출되었습니다'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('제출 실패: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _acceptQuotation(int id) async {
    try {
      final dioClient = context.read<DioClient>();
      await dioClient.put<dynamic>('/api/dispatch/quotations/$id/accept');
      await _loadQuotations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('견적서가 승인되었습니다'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('승인 실패: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _rejectQuotation(int id) async {
    try {
      final dioClient = context.read<DioClient>();
      await dioClient.put<dynamic>('/api/dispatch/quotations/$id/reject');
      await _loadQuotations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('견적서가 거절되었습니다'), backgroundColor: AppColors.info),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('거절 실패: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('견적 관리', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text('견적 요청 및 견적서를 관리합니다.', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _loadRequests();
                  _loadQuotations();
                },
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
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: '견적 요청'),
              Tab(text: '견적서'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRequestsTab(),
              _buildQuotationsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: _showCreateRequestDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('견적 요청'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
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
            child: _buildRequestsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsContent() {
    if (_isLoadingRequests) {
      return const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()));
    }
    if (_errorRequests != null) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(children: [
            const Icon(Icons.error_outline, size: 56, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            const Text('데이터를 불러오는데 실패했습니다', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
            const SizedBox(height: 8),
            Text(_errorRequests!, style: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(onPressed: _loadRequests, child: const Text('다시 시도')),
          ]),
        ),
      );
    }
    if (_requests.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: Column(children: [
          Icon(Icons.request_quote_outlined, size: 56, color: Color(0xFFCBD5E1)),
          SizedBox(height: 16),
          Text('견적 요청이 없습니다', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
        ])),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text('총 ${_requests.length}건', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            headingTextStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            dataTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
            columns: const [
              DataColumn(label: Text('제목')),
              DataColumn(label: Text('현장')),
              DataColumn(label: Text('BP사')),
              DataColumn(label: Text('상태')),
              DataColumn(label: Text('요청일')),
            ],
            rows: _requests.map((r) {
              final status = r['status']?.toString() ?? 'PENDING';
              return DataRow(cells: [
                DataCell(Text(r['title']?.toString() ?? '-')),
                DataCell(Text(r['siteName']?.toString() ?? r['site']?['name']?.toString() ?? '-')),
                DataCell(Text(r['bpCompanyName']?.toString() ?? '-')),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _requestStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_requestStatusLabel(status), style: TextStyle(color: _requestStatusColor(status), fontSize: 12, fontWeight: FontWeight.w600)),
                )),
                DataCell(Text(_formatDate(r['createdAt'] ?? r['requestDate']))),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuotationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: _showCreateQuotationDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('견적서 작성'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
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
            child: _buildQuotationsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationsContent() {
    if (_isLoadingQuotations) {
      return const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()));
    }
    if (_errorQuotations != null) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(children: [
            const Icon(Icons.error_outline, size: 56, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            const Text('데이터를 불러오는데 실패했습니다', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
            const SizedBox(height: 8),
            Text(_errorQuotations!, style: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(onPressed: _loadQuotations, child: const Text('다시 시도')),
          ]),
        ),
      );
    }
    if (_quotations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: Column(children: [
          Icon(Icons.description_outlined, size: 56, color: Color(0xFFCBD5E1)),
          SizedBox(height: 16),
          Text('견적서가 없습니다', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
        ])),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text('총 ${_quotations.length}건', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            headingTextStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            dataTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
            columns: const [
              DataColumn(label: Text('요청')),
              DataColumn(label: Text('공급사')),
              DataColumn(label: Text('금액')),
              DataColumn(label: Text('상태')),
              DataColumn(label: Text('생성일')),
              DataColumn(label: Text('작업')),
            ],
            rows: _quotations.map((q) {
              final status = q['status']?.toString() ?? 'DRAFT';
              final id = q['id'];
              return DataRow(cells: [
                DataCell(Text(q['requestTitle']?.toString() ?? '요청 #${q['requestId'] ?? '-'}')),
                DataCell(Text(q['supplierName']?.toString() ?? q['supplier']?['name']?.toString() ?? '-')),
                DataCell(Text(q['totalAmount']?.toString() ?? '-')),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _quotationStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_quotationStatusLabel(status), style: TextStyle(color: _quotationStatusColor(status), fontSize: 12, fontWeight: FontWeight.w600)),
                )),
                DataCell(Text(_formatDate(q['createdAt']))),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status.toUpperCase() == 'DRAFT')
                      TextButton(
                        onPressed: () => _submitQuotation(id),
                        child: const Text('제출', style: TextStyle(fontSize: 12)),
                      ),
                    if (status.toUpperCase() == 'SUBMITTED') ...[
                      TextButton(
                        onPressed: () => _acceptQuotation(id),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFF16A34A)),
                        child: const Text('승인', style: TextStyle(fontSize: 12)),
                      ),
                      TextButton(
                        onPressed: () => _rejectQuotation(id),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                        child: const Text('거절', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}
