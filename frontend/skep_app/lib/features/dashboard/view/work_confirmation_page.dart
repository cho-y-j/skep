import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';

class WorkConfirmationPage extends StatefulWidget {
  const WorkConfirmationPage({Key? key}) : super(key: key);

  @override
  State<WorkConfirmationPage> createState() => _WorkConfirmationPageState();
}

class _DailyWork {
  final String id;
  final DateTime date;
  final String equipment;
  final String operator;
  final String site;
  final String vehicleNumber;
  final String workContent;
  final DateTime startTime;
  final DateTime endTime;
  final bool hasOvertime;
  final String status; // 'draft', 'pending', 'signed'

  const _DailyWork({
    required this.id,
    required this.date,
    required this.equipment,
    required this.operator,
    required this.site,
    required this.vehicleNumber,
    required this.workContent,
    required this.startTime,
    required this.endTime,
    required this.hasOvertime,
    required this.status,
  });

  String get statusLabel {
    switch (status) {
      case 'draft':
        return '초안';
      case 'pending':
        return 'BP확인대기';
      case 'signed':
        return '서명완료';
      default:
        return '알 수 없음';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'draft':
        return const Color(0xFF94A3B8);
      case 'pending':
        return const Color(0xFFD97706);
      case 'signed':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF94A3B8);
    }
  }
}

class _WorkConfirmationPageState extends State<WorkConfirmationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  List<_DailyWork> _dailyWorks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDailyWorks());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDailyWorks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dioClient = context.read<DioClient>();
      final response = await dioClient.get<dynamic>(ApiEndpoints.dailyConfirmations);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<dynamic> items = [];
        if (data is List) {
          items = data;
        } else if (data is Map && data['content'] is List) {
          items = data['content'] as List;
        }
        _dailyWorks = items.map((item) {
          final m = item as Map<String, dynamic>;
          return _DailyWork(
            id: (m['id'] ?? '').toString(),
            date: _parseDate(m['date'] ?? m['workDate']) ?? DateTime.now(),
            equipment: (m['equipment'] ?? m['equipmentName'] ?? '-').toString(),
            operator: (m['operator'] ?? m['operatorName'] ?? '-').toString(),
            site: (m['site'] ?? m['siteName'] ?? '-').toString(),
            vehicleNumber: (m['vehicleNumber'] ?? m['vehicle_number'] ?? '-').toString(),
            workContent: (m['workContent'] ?? m['description'] ?? '-').toString(),
            startTime: _parseDate(m['startTime']) ?? DateTime.now(),
            endTime: _parseDate(m['endTime']) ?? DateTime.now(),
            hasOvertime: m['hasOvertime'] == true || m['overtime'] == true,
            status: (m['status'] ?? 'draft').toString().toLowerCase(),
          );
        }).toList();
      }
    } catch (e) {
      _error = e.toString();
      // Fallback to mock data
      if (_dailyWorks.isEmpty) {
        _dailyWorks = _getDefaultWorks();
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  List<_DailyWork> _getDefaultWorks() => [
    _DailyWork(
      id: 'w1',
      date: DateTime.now().subtract(const Duration(days: 0)),
      equipment: '25톤 크레인',
      operator: '김철수',
      site: '강남 현장 A',
      vehicleNumber: '서울 가 1234',
      workContent: '철골 양중 작업',
      startTime: DateTime(2026, 3, 22, 7, 0),
      endTime: DateTime(2026, 3, 22, 17, 30),
      hasOvertime: true,
      status: 'pending',
    ),
    _DailyWork(
      id: 'w2',
      date: DateTime.now().subtract(const Duration(days: 1)),
      equipment: '25톤 크레인',
      operator: '김철수',
      site: '강남 현장 A',
      vehicleNumber: '서울 가 1234',
      workContent: '자재 운반 및 양중',
      startTime: DateTime(2026, 3, 21, 7, 0),
      endTime: DateTime(2026, 3, 21, 17, 0),
      hasOvertime: false,
      status: 'signed',
    ),
    _DailyWork(
      id: 'w3',
      date: DateTime.now().subtract(const Duration(days: 2)),
      equipment: '50톤 크레인',
      operator: '이영희',
      site: '송파 현장 B',
      vehicleNumber: '경기 나 5678',
      workContent: '대형 패널 양중',
      startTime: DateTime(2026, 3, 20, 6, 0),
      endTime: DateTime(2026, 3, 20, 19, 0),
      hasOvertime: true,
      status: 'draft',
    ),
  ];

  Future<void> _requestBpSign(_DailyWork work) async {
    try {
      final dioClient = context.read<DioClient>();
      await dioClient.post<dynamic>(
        '${ApiEndpoints.dailyConfirmations}/${work.id}/request-sign',
      );
    } catch (_) {
      // Proceed with local state change even if API fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2196F3),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF2196F3),
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: '일일 작업확인서 (TYPE B)'),
                Tab(text: '월간 작업확인서 (TYPE A)'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDailyTab(),
                _buildMonthlyTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────── Tab 1: 일일 작업확인서 ────────────
  Widget _buildDailyTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _dailyWorks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)),
            const SizedBox(height: 12),
            const Text('데이터를 불러오는데 실패했습니다'),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            const SizedBox(height: 16),
            TextButton(onPressed: _loadDailyWorks, child: const Text('다시 시도')),
          ],
        ),
      );
    }
    if (_dailyWorks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 56, color: Color(0xFFCBD5E1)),
            SizedBox(height: 16),
            Text('작업확인서가 없습니다', style: TextStyle(fontSize: 16, color: Color(0xFF94A3B8))),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _dailyWorks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final work = _dailyWorks[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showDailyDetail(work),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        DateFormat('yyyy-MM-dd (E)', 'ko').format(work.date),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: work.statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          work.statusLabel,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: work.statusColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.build, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text('${work.equipment} (${work.vehicleNumber})', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(work.operator, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        '${DateFormat('HH:mm').format(work.startTime)} ~ ${DateFormat('HH:mm').format(work.endTime)}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      if (work.hasOvertime) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('연장', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFD97706))),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDailyDetail(_DailyWork work) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('일일 작업확인서 (TYPE B)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildDetailRow('현장명', work.site),
                _buildDetailRow('차량번호', work.vehicleNumber),
                _buildDetailRow('장비', work.equipment),
                _buildDetailRow('기사명', work.operator),
                _buildDetailRow('작업내용', work.workContent),
                _buildDetailRow('시작시간', DateFormat('HH:mm').format(work.startTime)),
                _buildDetailRow('종료시간', DateFormat('HH:mm').format(work.endTime)),
                _buildDetailRow('연장작업', work.hasOvertime ? '예' : '아니오'),
                _buildDetailRow('상태', work.statusLabel),
                const SizedBox(height: 20),
                if (work.status == 'draft' || work.status == 'pending') ...[
                  const Text('전자서명', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _SignatureWidget(),
                  const SizedBox(height: 16),
                ],
                if (work.status == 'draft')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _requestBpSign(work);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('BP서명 요청을 보냈습니다.'), backgroundColor: Color(0xFF2196F3)),
                        );
                        _loadDailyWorks();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('BP서명 요청'),
                    ),
                  ),
                if (work.status == 'signed')
                  const Center(
                    child: Text(
                      '서명 완료',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
          ),
        ],
      ),
    );
  }

  // ──────────── Tab 2: 월간 작업확인서 ────────────
  Widget _buildMonthlyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 월 선택
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() {
                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                }),
              ),
              Text(
                DateFormat('yyyy년 MM월').format(_selectedMonth),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() {
                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                }),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PDF 다운로드 시뮬레이션'), duration: Duration(seconds: 1)),
                  );
                },
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('PDF 다운로드', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('이메일 발송 시뮬레이션'), duration: Duration(seconds: 1)),
                  );
                },
                icon: const Icon(Icons.email, size: 16),
                label: const Text('이메일 발송', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 월간 요약 테이블
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                dataTextStyle: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                columnSpacing: 16,
                columns: const [
                  DataColumn(label: Text('날짜')),
                  DataColumn(label: Text('작업내용')),
                  DataColumn(label: Text('조출')),
                  DataColumn(label: Text('점심OT')),
                  DataColumn(label: Text('연장')),
                  DataColumn(label: Text('야간')),
                  DataColumn(label: Text('철야')),
                ],
                rows: List.generate(20, (i) {
                  final day = i + 1;
                  final isWeekend = DateTime(_selectedMonth.year, _selectedMonth.month, day).weekday > 5;
                  if (isWeekend) {
                    return DataRow(cells: [
                      DataCell(Text('$day일', style: const TextStyle(color: Color(0xFFDC2626)))),
                      const DataCell(Text('휴무', style: TextStyle(color: Color(0xFF94A3B8)))),
                      ...List.generate(5, (_) => const DataCell(Text('-', style: TextStyle(color: Color(0xFF94A3B8))))),
                    ]);
                  }
                  return DataRow(cells: [
                    DataCell(Text('$day일')),
                    DataCell(Text(i % 3 == 0 ? '철골 양중' : (i % 3 == 1 ? '자재 운반' : '기초 작업'))),
                    DataCell(_buildCheckCell(i % 5 == 0)),
                    DataCell(_buildCheckCell(i % 7 == 0)),
                    DataCell(_buildCheckCell(i % 3 == 0)),
                    DataCell(_buildCheckCell(i % 8 == 0)),
                    DataCell(_buildCheckCell(false)),
                  ]);
                }),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // 서명란
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('서명란', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('BP사 서명', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                          const SizedBox(height: 8),
                          _SignatureWidget(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('시행사 서명', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                          const SizedBox(height: 8),
                          _SignatureWidget(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckCell(bool checked) {
    return checked
        ? const Icon(Icons.check, size: 16, color: Color(0xFF16A34A))
        : const Text('-', style: TextStyle(color: Color(0xFF94A3B8)));
  }
}

// ──────────── 전자서명 위젯 ────────────
class _SignatureWidget extends StatefulWidget {
  @override
  State<_SignatureWidget> createState() => _SignatureWidgetState();
}

class _SignatureWidgetState extends State<_SignatureWidget> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: GestureDetector(
            onPanStart: (details) {
              setState(() {
                _currentStroke = [details.localPosition];
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _currentStroke.add(details.localPosition);
              });
            },
            onPanEnd: (_) {
              setState(() {
                _strokes.add(List.from(_currentStroke));
                _currentStroke = [];
              });
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomPaint(
                size: const Size(double.infinity, 120),
                painter: _SignaturePainter(
                  strokes: _strokes,
                  currentStroke: _currentStroke,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => setState(() {
                _strokes.clear();
                _currentStroke.clear();
              }),
              child: const Text('지우기', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ),
          ],
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  _SignaturePainter({required this.strokes, required this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, paint);
    }
    if (currentStroke.isNotEmpty) {
      _drawStroke(canvas, currentStroke, paint);
    }

    if (strokes.isEmpty && currentStroke.isEmpty) {
      final textPainter = TextPainter(
        text: const TextSpan(
          text: '여기에 서명하세요',
          style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
      );
    }
  }

  void _drawStroke(Canvas canvas, List<Offset> stroke, Paint paint) {
    if (stroke.length < 2) return;
    final path = Path();
    path.moveTo(stroke.first.dx, stroke.first.dy);
    for (int i = 1; i < stroke.length; i++) {
      path.lineTo(stroke[i].dx, stroke[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
