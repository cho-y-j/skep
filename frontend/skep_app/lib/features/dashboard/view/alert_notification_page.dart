import 'package:flutter/material.dart';

class AlertNotificationPage extends StatefulWidget {
  const AlertNotificationPage({Key? key}) : super(key: key);

  @override
  State<AlertNotificationPage> createState() => _AlertNotificationPageState();
}

class _Notice {
  final String id;
  final String title;
  final String content;
  final String sender;
  final String senderRole;
  final DateTime dateTime;
  final String priority; // 'normal', 'important', 'urgent'
  final String target;
  bool isRead;
  final int readCount;
  final int totalCount;

  _Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.sender,
    required this.senderRole,
    required this.dateTime,
    required this.priority,
    required this.target,
    this.isRead = false,
    required this.readCount,
    required this.totalCount,
  });

  Color get priorityColor {
    switch (priority) {
      case 'urgent':
        return const Color(0xFFDC2626);
      case 'important':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF2196F3);
    }
  }

  String get priorityLabel {
    switch (priority) {
      case 'urgent':
        return '긴급';
      case 'important':
        return '중요';
      default:
        return '일반';
    }
  }
}

class _EmergencyReport {
  final String id;
  final String reporter;
  final String type; // 'vehicle', 'health', 'danger', 'other'
  final String content;
  final DateTime dateTime;
  final String location;
  final String status; // 'reported', 'processing', 'resolved'

  const _EmergencyReport({
    required this.id,
    required this.reporter,
    required this.type,
    required this.content,
    required this.dateTime,
    required this.location,
    required this.status,
  });

  IconData get typeIcon {
    switch (type) {
      case 'vehicle':
        return Icons.build;
      case 'health':
        return Icons.local_hospital;
      case 'danger':
        return Icons.warning_amber;
      default:
        return Icons.campaign;
    }
  }

  Color get typeColor {
    switch (type) {
      case 'vehicle':
        return const Color(0xFFD97706);
      case 'health':
        return const Color(0xFFDC2626);
      case 'danger':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF2196F3);
    }
  }

  String get typeLabel {
    switch (type) {
      case 'vehicle':
        return '차량고장';
      case 'health':
        return '건강이상';
      case 'danger':
        return '현장위험';
      default:
        return '기타';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'reported':
        return '신고접수';
      case 'processing':
        return '처리중';
      case 'resolved':
        return '처리완료';
      default:
        return '알 수 없음';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'reported':
        return const Color(0xFFDC2626);
      case 'processing':
        return const Color(0xFFD97706);
      case 'resolved':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF94A3B8);
    }
  }
}

class _Message {
  final String id;
  final String senderName;
  final String content;
  final DateTime dateTime;
  final bool isSent;
  final bool isRead;

  const _Message({
    required this.id,
    required this.senderName,
    required this.content,
    required this.dateTime,
    required this.isSent,
    required this.isRead,
  });
}

class _AlertNotificationPageState extends State<AlertNotificationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<_Notice> _notices = [
    _Notice(
      id: 'n1',
      title: '3월 안전교육 일정 안내',
      content: '3월 25일(화) 오후 2시부터 안전교육이 진행됩니다. 모든 작업자는 필수 참석 바랍니다.',
      sender: '관리자',
      senderRole: '시행사',
      dateTime: DateTime.now().subtract(const Duration(hours: 2)),
      priority: 'important',
      target: '전체',
      isRead: true,
      readCount: 42,
      totalCount: 50,
    ),
    _Notice(
      id: 'n2',
      title: '긴급: 강풍 주의보 - 크레인 작업 중지',
      content: '기상청 강풍 주의보 발령으로 크레인 작업을 즉시 중지해 주세요.',
      sender: '안전관리팀',
      senderRole: 'BP사',
      dateTime: DateTime.now().subtract(const Duration(hours: 5)),
      priority: 'urgent',
      target: '크레인 운전원',
      readCount: 8,
      totalCount: 12,
    ),
    _Notice(
      id: 'n3',
      title: '4월 투입 일정 확인 요청',
      content: '4월 투입 계획서를 첨부 파일로 확인해 주세요.',
      sender: '김매니저',
      senderRole: '공급사',
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
      priority: 'normal',
      target: '공급사 전체',
      isRead: true,
      readCount: 15,
      totalCount: 15,
    ),
    _Notice(
      id: 'n4',
      title: '장비 정기점검 일정 공지',
      content: '3월 28일 ~ 29일 장비 정기점검이 예정되어 있습니다.',
      sender: '정비팀',
      senderRole: '시행사',
      dateTime: DateTime.now().subtract(const Duration(days: 2)),
      priority: 'normal',
      target: '전체',
      readCount: 30,
      totalCount: 50,
    ),
  ];

  final List<_EmergencyReport> _emergencyReports = [
    _EmergencyReport(
      id: 'e1',
      reporter: '김철수 (운전원)',
      type: 'vehicle',
      content: '유압호스 파열로 작업 불가',
      dateTime: DateTime.now().subtract(const Duration(minutes: 30)),
      location: '강남 현장 A',
      status: 'processing',
    ),
    _EmergencyReport(
      id: 'e2',
      reporter: '이유도 (유도원)',
      type: 'danger',
      content: '지반 침하 발견 - 크레인 작업 구역',
      dateTime: DateTime.now().subtract(const Duration(hours: 2)),
      location: '송파 현장 B',
      status: 'reported',
    ),
    _EmergencyReport(
      id: 'e3',
      reporter: '박민수 (운전원)',
      type: 'health',
      content: '어지러움 증세로 작업 중단',
      dateTime: DateTime.now().subtract(const Duration(hours: 6)),
      location: '성남 현장 C',
      status: 'resolved',
    ),
    _EmergencyReport(
      id: 'e4',
      reporter: '최기사 (운전원)',
      type: 'other',
      content: '현장 진입로 차단 - 자재 적치 방해',
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
      location: '수원 현장 D',
      status: 'resolved',
    ),
  ];

  final List<_Message> _messages = [
    _Message(
      id: 'm1',
      senderName: '김매니저 (BP사)',
      content: '내일 작업 일정 변경 건 확인 부탁드립니다.',
      dateTime: DateTime.now().subtract(const Duration(minutes: 15)),
      isSent: false,
      isRead: false,
    ),
    _Message(
      id: 'm2',
      senderName: '이팀장 (공급사)',
      content: '장비 교체 건 서류 보냈습니다.',
      dateTime: DateTime.now().subtract(const Duration(hours: 1)),
      isSent: false,
      isRead: true,
    ),
    _Message(
      id: 'm3',
      senderName: '나',
      content: '확인했습니다. 감사합니다.',
      dateTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 5)),
      isSent: true,
      isRead: true,
    ),
    _Message(
      id: 'm4',
      senderName: '박안전 (안전점검원)',
      content: '점검 결과 전달드립니다. 특이사항 없습니다.',
      dateTime: DateTime.now().subtract(const Duration(hours: 3)),
      isSent: false,
      isRead: true,
    ),
  ];

  bool _showSentMessages = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.campaign, size: 18),
                      const SizedBox(width: 6),
                      const Text('공지사항'),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_notices.where((n) => !n.isRead).length}',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber, size: 18),
                      const SizedBox(width: 6),
                      const Text('긴급 신고'),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_emergencyReports.where((e) => e.status != 'resolved').length}',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.message, size: 18),
                      const SizedBox(width: 6),
                      const Text('메시지'),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_messages.where((m) => !m.isSent && !m.isRead).length}',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNoticeTab(),
                _buildEmergencyTab(),
                _buildMessageTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────── Tab 1: 공지사항 ────────────
  Widget _buildNoticeTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showCreateNoticeDialog(),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('공지 작성', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _notices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final notice = _notices[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: notice.isRead
                      ? null
                      : Border.all(color: notice.priorityColor.withOpacity(0.3)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    setState(() => notice.isRead = true);
                    _showNoticeDetail(notice);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: notice.priorityColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                notice.priorityLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: notice.priorityColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!notice.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDC2626),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            const Spacer(),
                            Text(
                              _formatDateTime(notice.dateTime),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notice.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: notice.isRead ? FontWeight.w500 : FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${notice.sender} (${notice.senderRole}) | 대상: ${notice.target}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.visibility, size: 14, color: const Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text(
                              '${notice.readCount}명 읽음 / ${notice.totalCount - notice.readCount}명 미읽음',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showNoticeDetail(_Notice notice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: notice.priorityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                notice.priorityLabel,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: notice.priorityColor),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(notice.title, style: const TextStyle(fontSize: 16))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '발신: ${notice.sender} (${notice.senderRole})',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            Text(
              '대상: ${notice.target}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const Divider(height: 24),
            Text(notice.content, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            Text(
              '${notice.readCount}명 읽음 / ${notice.totalCount - notice.readCount}명 미읽음',
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showCreateNoticeDialog() {
    String title = '';
    String content = '';
    String target = '전체';
    String priority = 'normal';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('공지 작성', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: '제목',
                      labelStyle: const TextStyle(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (v) => title = v,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '내용',
                      labelStyle: const TextStyle(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    maxLines: 4,
                    onChanged: (v) => content = v,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: target,
                    decoration: InputDecoration(
                      labelText: '대상',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: ['전체', '관리자', '공급사', 'BP사', '운전원', '유도원', '안전점검원']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) => setDialogState(() => target = v ?? '전체'),
                  ),
                  const SizedBox(height: 12),
                  const Text('우선순위', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPriorityChip('normal', '일반', const Color(0xFF2196F3), priority, (v) => setDialogState(() => priority = v)),
                      const SizedBox(width: 8),
                      _buildPriorityChip('important', '중요', const Color(0xFFD97706), priority, (v) => setDialogState(() => priority = v)),
                      const SizedBox(width: 8),
                      _buildPriorityChip('urgent', '긴급', const Color(0xFFDC2626), priority, (v) => setDialogState(() => priority = v)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () {
                if (title.isNotEmpty && content.isNotEmpty) {
                  setState(() {
                    _notices.insert(
                      0,
                      _Notice(
                        id: 'n${_notices.length + 1}',
                        title: title,
                        content: content,
                        sender: '나',
                        senderRole: '관리자',
                        dateTime: DateTime.now(),
                        priority: priority,
                        target: target,
                        isRead: true,
                        readCount: 0,
                        totalCount: 50,
                      ),
                    );
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('공지가 등록되었습니다.'), backgroundColor: Color(0xFF16A34A)),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('등록'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String value, String label, Color color, String selected, ValueChanged<String> onSelect) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? color : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // ──────────── Tab 2: 긴급 신고 ────────────
  Widget _buildEmergencyTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showEmergencyReportDialog(),
                icon: const Icon(Icons.warning_amber, size: 16),
                label: const Text('긴급 신고', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _emergencyReports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final report = _emergencyReports[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: report.typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(report.typeIcon, color: report.typeColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: report.typeColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    report.typeLabel,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: report.typeColor),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: report.statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    report.statusLabel,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: report.statusColor),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatDateTime(report.dateTime),
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              report.content,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '신고자: ${report.reporter}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 12, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 2),
                                Text(
                                  report.location,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showEmergencyReportDialog() {
    String type = 'vehicle';
    String content = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber, color: Color(0xFFDC2626)),
              const SizedBox(width: 8),
              const Text('긴급 신고', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('신고 유형', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTypeChip('vehicle', '차량고장', Icons.build, const Color(0xFFD97706), type, (v) => setDialogState(() => type = v)),
                    _buildTypeChip('health', '건강이상', Icons.local_hospital, const Color(0xFFDC2626), type, (v) => setDialogState(() => type = v)),
                    _buildTypeChip('danger', '현장위험', Icons.warning_amber, const Color(0xFFEF4444), type, (v) => setDialogState(() => type = v)),
                    _buildTypeChip('other', '기타', Icons.campaign, const Color(0xFF2196F3), type, (v) => setDialogState(() => type = v)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: '신고 내용',
                    labelStyle: const TextStyle(fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  maxLines: 3,
                  onChanged: (v) => content = v,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('사진 첨부 시뮬레이션'), duration: Duration(seconds: 1)),
                    );
                  },
                  icon: const Icon(Icons.camera_alt, size: 16),
                  label: const Text('사진 첨부 (선택)', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () {
                if (content.isNotEmpty) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('긴급 신고가 접수되었습니다.'), backgroundColor: Color(0xFFDC2626)),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('신고 접수'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String value, String label, IconData icon, Color color, String selected, ValueChanged<String> onSelect) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : const Color(0xFF94A3B8)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────── Tab 3: 메시지 ────────────
  Widget _buildMessageTab() {
    final filtered = _messages.where((m) => _showSentMessages ? m.isSent : !m.isSent).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildToggleButton('수신함', !_showSentMessages, () => setState(() => _showSentMessages = false)),
                    _buildToggleButton('발신함', _showSentMessages, () => setState(() => _showSentMessages = true)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text('메시지가 없습니다.', style: TextStyle(color: Color(0xFF94A3B8))),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final msg = filtered[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: !msg.isRead && !msg.isSent
                            ? Border.all(color: const Color(0xFF2196F3).withOpacity(0.3))
                            : null,
                        boxShadow: const [
                          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: msg.isSent
                              ? const Color(0xFF16A34A).withOpacity(0.1)
                              : const Color(0xFF2196F3).withOpacity(0.1),
                          child: Icon(
                            msg.isSent ? Icons.arrow_upward : Icons.arrow_downward,
                            color: msg.isSent ? const Color(0xFF16A34A) : const Color(0xFF2196F3),
                            size: 18,
                          ),
                        ),
                        title: Text(
                          msg.senderName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: msg.isRead ? FontWeight.w500 : FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            msg.content,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatDateTime(msg.dateTime),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                            if (!msg.isRead && !msg.isSent) ...[
                              const SizedBox(height: 4),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2196F3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2196F3) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
