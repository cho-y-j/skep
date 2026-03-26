import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';

class AdminNotificationPage extends StatefulWidget {
  const AdminNotificationPage({Key? key}) : super(key: key);

  @override
  State<AdminNotificationPage> createState() => _AdminNotificationPageState();
}

class _AdminNotificationPageState extends State<AdminNotificationPage> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _notifications = [];

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
      final response = await dioClient.get<dynamic>(ApiEndpoints.notifications);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List) {
          _notifications = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['content'] is List) {
          _notifications = (data['content'] as List).cast<Map<String, dynamic>>();
        } else if (data is Map && data['data'] is List) {
          _notifications = (data['data'] as List).cast<Map<String, dynamic>>();
        } else if (data is Map && data['notifications'] is List) {
          _notifications = (data['notifications'] as List).cast<Map<String, dynamic>>();
        } else {
          _notifications = [];
        }
      }
    } catch (e) {
      _error = e.toString();
      _notifications = [];
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final dioClient = context.read<DioClient>();
      await dioClient.put<dynamic>(
        '${ApiEndpoints.notifications}/$notificationId/read',
      );
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('읽음 처리 실패: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  bool _isRead(Map<String, dynamic> n) {
    return n['read'] == true || n['isRead'] == true || n['readAt'] != null;
  }

  String _getContent(Map<String, dynamic> n) {
    return n['content']?.toString() ?? n['message']?.toString() ?? n['title']?.toString() ?? '-';
  }

  String _getRecipient(Map<String, dynamic> n) {
    return n['recipient']?.toString() ?? n['targetName']?.toString() ?? '-';
  }

  String _getTime(Map<String, dynamic> n) {
    final time = n['time'] ?? n['createdAt'] ?? n['sentAt'];
    if (time == null) return '-';
    try {
      final dt = DateTime.parse(time.toString());
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return time.toString();
    }
  }

  String _getPriority(Map<String, dynamic> n) {
    final p = n['priority']?.toString() ?? 'normal';
    switch (p.toLowerCase()) {
      case 'urgent': return '긴급';
      case 'important': case 'high': return '중요';
      case '긴급': return '긴급';
      case '중요': return '중요';
      default: return '일반';
    }
  }

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

  Future<void> _sendMessage(String targetRole, String title, String content, String priority) async {
    try {
      final dioClient = context.read<DioClient>();
      await dioClient.post<dynamic>(
        ApiEndpoints.messages,
        data: {
          'targetRole': targetRole,
          'title': title,
          'content': content,
          'priority': priority,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('메시지가 발송되었습니다.'), backgroundColor: AppColors.success),
        );
      }
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('메시지 발송 실패: $e'), backgroundColor: AppColors.error),
        );
      }
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
                _sendMessage(targetRole, title, content, priority);
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
    final unreadCount = _notifications.where((n) => !_isRead(n)).length;
    final readCount = _notifications.where((n) => _isRead(n)).length;

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
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
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
            )
          else ...[
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
              child: _notifications.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: Text('알림이 없습니다.', style: TextStyle(color: Color(0xFF94A3B8)))),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('읽음')),
                          DataColumn(label: Text('알림 내용')),
                          DataColumn(label: Text('수신자')),
                          DataColumn(label: Text('시점')),
                          DataColumn(label: Text('우선순위')),
                          DataColumn(label: Text('작업')),
                        ],
                        rows: _notifications.map((n) {
                          final isRead = _isRead(n);
                          final priority = _getPriority(n);
                          final notifId = n['id']?.toString();
                          return DataRow(cells: [
                            DataCell(Icon(
                              isRead
                                  ? Icons.mark_email_read
                                  : Icons.mark_email_unread,
                              color: isRead
                                  ? AppColors.grey
                                  : AppColors.primary,
                              size: 20,
                            )),
                            DataCell(
                              SizedBox(
                                width: 300,
                                child: Text(
                                  _getContent(n),
                                  style: TextStyle(
                                    fontWeight: isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(Text(_getRecipient(n))),
                            DataCell(Text(_getTime(n))),
                            DataCell(Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _priorityColor(priority)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                priority,
                                style: TextStyle(
                                  color: _priorityColor(priority),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )),
                            DataCell(
                              !isRead && notifId != null
                                  ? TextButton(
                                      onPressed: () => _markAsRead(notifId),
                                      child: const Text('읽음처리', style: TextStyle(fontSize: 12)),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
            ),
          ],
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
