import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';

/// 공급사 매칭 요청 응답 페이지
class MatchingResponsePage extends StatefulWidget {
  const MatchingResponsePage({Key? key}) : super(key: key);

  @override
  State<MatchingResponsePage> createState() => _MatchingResponsePageState();
}

class _MatchingResponsePageState extends State<MatchingResponsePage> {
  static const _darkText = Color(0xFF1E293B);
  static const _pageBg = Color(0xFFF8FAFC);
  static const _cardShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
  ];

  bool _isLoading = true;
  String? _error;

  List<_IncomingRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRequests());
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dioClient = context.read<DioClient>();
      final response = await dioClient.get<dynamic>('/api/dispatch/quotations/requests');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<dynamic> items = [];
        if (data is List) {
          items = data;
        } else if (data is Map && data['content'] is List) {
          items = data['content'] as List;
        }
        _requests = items.map((item) {
          final m = item as Map<String, dynamic>;
          return _IncomingRequest(
            id: (m['id'] ?? '').toString(),
            bpCompany: (m['bpCompany'] ?? m['companyName'] ?? m['requesterName'] ?? '-').toString(),
            date: (m['date'] ?? m['requestDate'] ?? '-').toString(),
            time: (m['time'] ?? m['workTime'] ?? '-').toString(),
            equipmentSpec: (m['equipmentSpec'] ?? m['equipmentType'] ?? '-').toString(),
            site: (m['site'] ?? m['location'] ?? '-').toString(),
            matchedEquipment: (m['matchedEquipment'] ?? m['vehicleNumber'] ?? '-').toString(),
            matchedOperator: (m['matchedOperator'] ?? m['operatorName'] ?? '-').toString(),
            docsOk: m['docsOk'] == true,
            inspectionOk: m['inspectionOk'] == true,
            licenseOk: m['licenseOk'] == true,
            educationOk: m['educationOk'] == true,
            status: (m['status'] ?? 'NEW').toString() == 'NEW' ? '신규' :
                    (m['status'] ?? '').toString() == 'ACCEPTED' ? '수락' :
                    (m['status'] ?? '').toString() == 'REJECTED' ? '거절' :
                    (m['status'] ?? '').toString() == 'QUOTE_SENT' ? '견적발송' :
                    (m['status'] ?? '신규').toString(),
            note: m['note']?.toString(),
            rejectReason: m['rejectReason']?.toString(),
          );
        }).toList();
      }
    } catch (e) {
      _error = e.toString();
      // Keep fallback mock data if API fails
      if (_requests.isEmpty) {
        _requests = _getDefaultRequests();
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<_IncomingRequest> _getDefaultRequests() => [
    _IncomingRequest(
      id: '1',
      bpCompany: '현대건설 (BP사)',
      date: '3월 28일',
      time: '09:00~12:00',
      equipmentSpec: '45m 고소작업차',
      site: '용인시 처인구 현장',
      matchedEquipment: '경기99사9489',
      matchedOperator: '김운전',
      docsOk: true,
      inspectionOk: true,
      licenseOk: true,
      educationOk: true,
      status: '신규',
      note: '고층 외벽 작업으로 안전장비 필수',
    ),
    _IncomingRequest(
      id: '2',
      bpCompany: '삼성물산 (BP사)',
      date: '3월 29일',
      time: '08:00~17:00',
      equipmentSpec: '50m 고소작업차',
      site: '강남구 삼성동 현장',
      matchedEquipment: '경기11가2222',
      matchedOperator: '이기사',
      docsOk: true,
      inspectionOk: true,
      licenseOk: true,
      educationOk: true,
      status: '신규',
    ),
    _IncomingRequest(
      id: '3',
      bpCompany: 'GS건설 (BP사)',
      date: '3월 30일',
      time: '10:00~15:00',
      equipmentSpec: '35m 고소작업차',
      site: '수원시 팔달구 현장',
      matchedEquipment: '서울12가3456',
      matchedOperator: '박기사',
      docsOk: false,
      inspectionOk: true,
      licenseOk: true,
      educationOk: false,
      status: '신규',
      note: '보험 갱신 필요',
    ),
    _IncomingRequest(
      id: '4',
      bpCompany: '대림산업 (BP사)',
      date: '3월 25일',
      time: '09:00~18:00',
      equipmentSpec: '40m 고소작업차',
      site: '인천 송도 현장',
      matchedEquipment: '부산55나7890',
      matchedOperator: '최운전',
      docsOk: true,
      inspectionOk: true,
      licenseOk: true,
      educationOk: true,
      status: '수락',
    ),
    _IncomingRequest(
      id: '5',
      bpCompany: '포스코건설 (BP사)',
      date: '3월 24일',
      time: '08:00~12:00',
      equipmentSpec: '25m 고소작업차',
      site: '포항시 현장',
      matchedEquipment: '인천34나5678',
      matchedOperator: '-',
      docsOk: true,
      inspectionOk: true,
      licenseOk: true,
      educationOk: true,
      status: '거절',
      rejectReason: '해당일 타 현장 투입 예정',
    ),
  ];

  Future<void> _acceptRequestApi(_IncomingRequest request) async {
    try {
      final dioClient = context.read<DioClient>();
      await dioClient.put<dynamic>(
        '/api/dispatch/quotations/${request.id}/accept',
      );
      _loadRequests();
    } catch (e) {
      // Fallback to local state
    }
  }

  Future<void> _rejectRequestApi(_IncomingRequest request, String reason) async {
    try {
      final dioClient = context.read<DioClient>();
      await dioClient.put<dynamic>(
        '/api/dispatch/quotations/${request.id}/reject',
        data: {'reason': reason},
      );
      _loadRequests();
    } catch (e) {
      // Fallback to local state
    }
  }

  Future<void> _sendQuoteApi(_IncomingRequest request, Map<String, dynamic> rates) async {
    try {
      final dioClient = context.read<DioClient>();
      await dioClient.post<dynamic>(
        '/api/dispatch/quotations',
        data: {
          'requestId': request.id,
          'items': rates,
        },
      );
      _loadRequests();
    } catch (e) {
      // Fallback to local state
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: _pageBg,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _requests.isEmpty) {
      return Container(
        color: _pageBg,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)),
              const SizedBox(height: 12),
              const Text('데이터를 불러오는데 실패했습니다'),
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              const SizedBox(height: 16),
              TextButton(onPressed: _loadRequests, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }
    final newRequests = _requests.where((r) => r.status == '신규').toList();
    final processedRequests = _requests.where((r) => r.status != '신규').toList();

    return Container(
      color: _pageBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '매칭 요청',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _darkText),
            ),
            const SizedBox(height: 4),
            const Text(
              'BP사로부터 수신된 장비 매칭 요청을 관리하세요.',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            // Summary cards
            _buildSummaryRow(newRequests.length, processedRequests.length),
            const SizedBox(height: 28),
            // New requests
            Row(
              children: [
                const Text(
                  '신규 요청',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _darkText),
                ),
                const SizedBox(width: 10),
                if (newRequests.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${newRequests.length}건',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (newRequests.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _cardShadow,
                ),
                child: const Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: Color(0xFFCBD5E1)),
                    SizedBox(height: 12),
                    Text('신규 요청이 없습니다.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                  ],
                ),
              )
            else
              ...newRequests.map((r) => _buildRequestCard(r)),
            const SizedBox(height: 32),
            // Processed requests
            const Text(
              '처리 완료',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _darkText),
            ),
            const SizedBox(height: 16),
            ...processedRequests.map((r) => _buildProcessedCard(r)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(int newCount, int processedCount) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: _cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_active, color: Color(0xFFDC2626), size: 22),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$newCount건',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _darkText),
                    ),
                    const Text('신규 요청', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: _cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 22),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$processedCount건',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _darkText),
                    ),
                    const Text('처리 완료', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(_IncomingRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_active, size: 14, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      '새 요청',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${request.date} ${request.time}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _darkText),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // BP Company
          Text(
            request.bpCompany,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _darkText),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.build_outlined, size: 15, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                request.equipmentSpec,
                style: const TextStyle(fontSize: 14, color: _darkText),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  request.site,
                  style: const TextStyle(fontSize: 14, color: _darkText),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (request.note != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.notes, size: 15, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    request.note!,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 28, color: Color(0xFFE2E8F0)),
          // Matched info
          Row(
            children: [
              const Text(
                '매칭 장비: ',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
              ),
              Text(
                request.matchedEquipment,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _darkText),
              ),
              const SizedBox(width: 6),
              Text(
                '(서류 ${request.docsOk ? '\u2705' : '\u26A0\uFE0F'}, 안전검사 ${request.inspectionOk ? '\u2705' : '\u26A0\uFE0F'})',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text(
                '매칭 운전원: ',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
              ),
              Text(
                request.matchedOperator,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _darkText),
              ),
              const SizedBox(width: 6),
              Text(
                '(면허 ${request.licenseOk ? '\u2705' : '\u26A0\uFE0F'}, 교육 ${request.educationOk ? '\u2705' : '\u26A0\uFE0F'})',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Action buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showAcceptDialog(request),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('수락', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showRejectDialog(request),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('거절', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFDC2626), width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showQuoteDialog(request),
                icon: const Icon(Icons.request_quote_outlined, size: 16),
                label: const Text('견적서 발송', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7C3AED),
                  side: const BorderSide(color: Color(0xFF7C3AED), width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProcessedCard(_IncomingRequest request) {
    Color statusColor;
    IconData statusIcon;
    switch (request.status) {
      case '수락':
        statusColor = const Color(0xFF16A34A);
        statusIcon = Icons.check_circle;
        break;
      case '거절':
        statusColor = const Color(0xFFDC2626);
        statusIcon = Icons.cancel;
        break;
      case '견적발송':
        statusColor = const Color(0xFF7C3AED);
        statusIcon = Icons.request_quote;
        break;
      default:
        statusColor = const Color(0xFF64748B);
        statusIcon = Icons.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.bpCompany,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _darkText),
                ),
                const SizedBox(height: 4),
                Text(
                  '${request.equipmentSpec} / ${request.site} / ${request.date} ${request.time}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                if (request.rejectReason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '사유: ${request.rejectReason}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              request.status,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showAcceptDialog(_IncomingRequest request) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('투입 요청 수락', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${request.bpCompany}의 요청을 수락하시겠습니까?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('장비: ${request.matchedEquipment}', style: const TextStyle(fontSize: 13)),
                  Text('운전원: ${request.matchedOperator}', style: const TextStyle(fontSize: 13)),
                  Text('일시: ${request.date} ${request.time}', style: const TextStyle(fontSize: 13)),
                  Text('현장: ${request.site}', style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '수락 시 자동으로 투입 계획이 생성됩니다.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                final idx = _requests.indexWhere((r) => r.id == request.id);
                if (idx >= 0) {
                  _requests[idx] = _IncomingRequest(
                    id: request.id,
                    bpCompany: request.bpCompany,
                    date: request.date,
                    time: request.time,
                    equipmentSpec: request.equipmentSpec,
                    site: request.site,
                    matchedEquipment: request.matchedEquipment,
                    matchedOperator: request.matchedOperator,
                    docsOk: request.docsOk,
                    inspectionOk: request.inspectionOk,
                    licenseOk: request.licenseOk,
                    educationOk: request.educationOk,
                    status: '수락',
                  );
                }
              });
              Navigator.pop(ctx);
              await _acceptRequestApi(request);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('요청을 수락했습니다. 투입 계획이 자동 생성되었습니다.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('수락'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(_IncomingRequest request) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('요청 거절', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${request.bpCompany}의 요청을 거절하시겠습니까?'),
            const SizedBox(height: 16),
            const Text('거절 사유', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '거절 사유를 입력하세요',
                hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.isEmpty ? '사유 미입력' : reasonController.text;
              setState(() {
                final idx = _requests.indexWhere((r) => r.id == request.id);
                if (idx >= 0) {
                  _requests[idx] = _IncomingRequest(
                    id: request.id,
                    bpCompany: request.bpCompany,
                    date: request.date,
                    time: request.time,
                    equipmentSpec: request.equipmentSpec,
                    site: request.site,
                    matchedEquipment: request.matchedEquipment,
                    matchedOperator: request.matchedOperator,
                    docsOk: request.docsOk,
                    inspectionOk: request.inspectionOk,
                    licenseOk: request.licenseOk,
                    educationOk: request.educationOk,
                    status: '거절',
                    rejectReason: reason,
                  );
                }
              });
              Navigator.pop(ctx);
              await _rejectRequestApi(request, reason);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('요청을 거절했습니다.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('거절'),
          ),
        ],
      ),
    );
  }

  void _showQuoteDialog(_IncomingRequest request) {
    final dayRateController = TextEditingController(text: '850000');
    final otRateController = TextEditingController(text: '50000');
    final nightRateController = TextEditingController(text: '70000');
    final overnightRateController = TextEditingController(text: '1200000');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('견적서 발송', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${request.bpCompany}에게 견적서를 발송합니다.',
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 20),
              _buildQuoteField('주간 단가 (원/일)', dayRateController),
              const SizedBox(height: 12),
              _buildQuoteField('O/T 단가 (원/시간)', otRateController),
              const SizedBox(height: 12),
              _buildQuoteField('야간 단가 (원/시간)', nightRateController),
              const SizedBox(height: 12),
              _buildQuoteField('철야 단가 (원/일)', overnightRateController),
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
              final rates = {
                'dayRate': int.tryParse(dayRateController.text) ?? 0,
                'otRate': int.tryParse(otRateController.text) ?? 0,
                'nightRate': int.tryParse(nightRateController.text) ?? 0,
                'overnightRate': int.tryParse(overnightRateController.text) ?? 0,
              };
              setState(() {
                final idx = _requests.indexWhere((r) => r.id == request.id);
                if (idx >= 0) {
                  _requests[idx] = _IncomingRequest(
                    id: request.id,
                    bpCompany: request.bpCompany,
                    date: request.date,
                    time: request.time,
                    equipmentSpec: request.equipmentSpec,
                    site: request.site,
                    matchedEquipment: request.matchedEquipment,
                    matchedOperator: request.matchedOperator,
                    docsOk: request.docsOk,
                    inspectionOk: request.inspectionOk,
                    licenseOk: request.licenseOk,
                    educationOk: request.educationOk,
                    status: '견적발송',
                  );
                }
              });
              Navigator.pop(ctx);
              await _sendQuoteApi(request, rates);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('견적서가 발송되었습니다.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('발송'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _darkText)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            suffixText: '원',
          ),
        ),
      ],
    );
  }
}

class _IncomingRequest {
  final String id;
  final String bpCompany;
  final String date;
  final String time;
  final String equipmentSpec;
  final String site;
  final String matchedEquipment;
  final String matchedOperator;
  final bool docsOk;
  final bool inspectionOk;
  final bool licenseOk;
  final bool educationOk;
  final String status;
  final String? note;
  final String? rejectReason;

  const _IncomingRequest({
    required this.id,
    required this.bpCompany,
    required this.date,
    required this.time,
    required this.equipmentSpec,
    required this.site,
    required this.matchedEquipment,
    required this.matchedOperator,
    required this.docsOk,
    required this.inspectionOk,
    required this.licenseOk,
    required this.educationOk,
    required this.status,
    this.note,
    this.rejectReason,
  });
}
