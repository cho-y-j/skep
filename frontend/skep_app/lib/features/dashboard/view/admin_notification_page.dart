import 'package:flutter/material.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';

class AdminNotificationPage extends StatefulWidget {
  const AdminNotificationPage({Key? key}) : super(key: key);

  @override
  State<AdminNotificationPage> createState() => _AdminNotificationPageState();
}

class _AdminNotificationPageState extends State<AdminNotificationPage> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'content': '(주)한국크레인의 건설기계등록증이 7일 후 만료됩니다.',
      'recipient': '(주)한국크레인 관리자',
      'time': '2026-03-22 09:00',
      'priority': '긴급',
      'read': false,
    },
    {
      'content': '삼성중장비에서 새 투입 요청이 접수되었습니다.',
      'recipient': '현대건설 담당자',
      'time': '2026-03-22 08:30',
      'priority': '중요',
      'read': false,
    },
    {
      'content': '강남 현장 A의 안전점검에서 이상이 발견되었습니다.',
      'recipient': '현대건설 안전담당',
      'time': '2026-03-21 16:00',
      'priority': '긴급',
      'read': true,
    },
    {
      'content': '3월 정산 마감이 3일 남았습니다.',
      'recipient': '전체 공급사',
      'time': '2026-03-21 10:00',
      'priority': '일반',
      'read': true,
    },
    {
      'content': '신규 회원 대한건기가 가입을 완료했습니다.',
      'recipient': '관리자',
      'time': '2026-03-20 14:00',
      'priority': '일반',
      'read': true,
    },
    {
      'content': '김운전의 건강검진 결과가 만료되었습니다.',
      'recipient': '(주)한국크레인 관리자',
      'time': '2026-03-20 09:00',
      'priority': '중요',
      'read': false,
    },
  ];

  Color _priorityColor(String priority) {
    switch (priority) {
      case '긴급':
        return AppColors.error;
      case '중요':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  void _showSendMessageDialog() {
    String targetType = '역할별';
    String targetRole = '';
    String title = '';
    String content = '';
    String priority = '일반';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('메시지 발송'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: targetType,
                    decoration: const InputDecoration(
                      labelText: '수신 대상 유형',
                      border: OutlineInputBorder(),
                    ),
                    items: ['역할별', '개인']
                        .map((t) =>
                            DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => targetType = v ?? '역할별'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText:
                          targetType == '역할별' ? '역할 (예: 전체 공급사)' : '수신자명',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) => targetRole = v,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: '제목',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => title = v,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: '내용',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => content = v,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(
                      labelText: '우선순위',
                      border: OutlineInputBorder(),
                    ),
                    items: ['일반', '중요', '긴급']
                        .map((p) =>
                            DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => priority = v ?? '일반'),
                  ),
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
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('메시지가 발송되었습니다.')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('발송'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        _notifications.where((n) => n['read'] == false).length;
    final readCount =
        _notifications.where((n) => n['read'] == true).length;

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
                    Text('알림/메시지', style: AppTextStyles.headlineLarge),
                    const SizedBox(height: 4),
                    Text(
                      '알림 및 메시지를 관리합니다.',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showSendMessageDialog,
                icon: const Icon(Icons.send),
                label: const Text('메시지 발송'),
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
          // 수신 확인 현황
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 3 : 1;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 2.5,
                children: [
                  _buildSummaryCard('전체 알림',
                      '${_notifications.length}건', AppColors.primary),
                  _buildSummaryCard('미읽음', '$unreadCount건', AppColors.error),
                  _buildSummaryCard('읽음', '$readCount건', AppColors.success),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          // 알림 목록
          Text('알림 목록', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
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
                  DataColumn(label: Text('읽음')),
                  DataColumn(label: Text('알림 내용')),
                  DataColumn(label: Text('수신자')),
                  DataColumn(label: Text('시점')),
                  DataColumn(label: Text('우선순위')),
                ],
                rows: _notifications
                    .map((n) => DataRow(cells: [
                          DataCell(Icon(
                            n['read']
                                ? Icons.mark_email_read
                                : Icons.mark_email_unread,
                            color: n['read']
                                ? AppColors.grey
                                : AppColors.primary,
                            size: 20,
                          )),
                          DataCell(
                            SizedBox(
                              width: 300,
                              child: Text(
                                n['content'],
                                style: TextStyle(
                                  fontWeight: n['read']
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(Text(n['recipient'])),
                          DataCell(Text(n['time'])),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _priorityColor(n['priority'])
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              n['priority'],
                              style: TextStyle(
                                color: _priorityColor(n['priority']),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )),
                        ]))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.notifications, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value,
                  style: AppTextStyles.displaySmall.copyWith(color: color)),
              Text(label,
                  style:
                      AppTextStyles.bodySmall.copyWith(color: AppColors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
