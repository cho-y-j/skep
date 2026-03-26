import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';

class BpInspectionStatusPage extends StatefulWidget {
  const BpInspectionStatusPage({Key? key}) : super(key: key);

  @override
  State<BpInspectionStatusPage> createState() => _BpInspectionStatusPageState();
}

class _BpInspectionStatusPageState extends State<BpInspectionStatusPage> {
  List<Map<String, dynamic>> _inspections = [];
  bool _isLoading = true;
  String? _error;
  int? _expandedIndex;

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
      final response = await dioClient.get<dynamic>(ApiEndpoints.safetyInspections);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<Map<String, dynamic>> rawList;
        if (data is List) {
          rawList = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['content'] is List) {
          rawList = (data['content'] as List).cast<Map<String, dynamic>>();
        } else {
          rawList = [];
        }
        // Map API response to expected format
        _inspections = rawList.map((insp) {
          final status = (insp['status'] ?? '').toString().toUpperCase();
          final completed = status == 'COMPLETED' || status == 'DONE' || insp['completed'] == true;
          final hasIssue = insp['hasIssue'] == true || (insp['issueCount'] ?? 0) > 0;
          // Parse inspection items
          List<Map<String, dynamic>> items = [];
          if (insp['items'] is List) {
            items = (insp['items'] as List).map((item) {
              if (item is Map<String, dynamic>) {
                return {
                  'name': item['itemName'] ?? item['name'] ?? '',
                  'ok': item['result'] == 'OK' || item['ok'] == true || item['passed'] == true,
                };
              }
              return <String, dynamic>{'name': '', 'ok': true};
            }).toList();
          }
          return {
            'id': insp['id'],
            'plateNo': insp['vehicleNumber'] ?? insp['plateNo'] ?? '',
            'equipType': insp['equipmentType'] ?? insp['equipType'] ?? '',
            'completed': completed,
            'time': insp['inspectionTime'] ?? insp['time'] ?? (completed ? '' : '-'),
            'inspector': insp['inspectorName'] ?? insp['inspector'] ?? (completed ? '' : '-'),
            'hasIssue': hasIssue,
            'items': items,
          };
        }).toList();
      }
    } catch (e) {
      _error = e.toString();
      _inspections = [];
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(48),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('데이터를 불러오는데 실패했습니다', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
              const SizedBox(height: 8),
              Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton(onPressed: _loadData, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }

    final completed =
        _inspections.where((i) => i['completed'] == true).length;
    final notCompleted =
        _inspections.where((i) => i['completed'] == false).length;
    final withIssue =
        _inspections.where((i) => i['hasIssue'] == true).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('안전점검 현황', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 4),
          Text(
            '오늘의 안전점검 현황을 확인합니다.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: 24),
          // 요약 카드
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
                  _buildSummaryCard(
                      '점검 완료', '$completed건', AppColors.success),
                  _buildSummaryCard(
                      '미완료', '$notCompleted건', AppColors.error),
                  _buildSummaryCard(
                      '이상 발견', '$withIssue건', AppColors.warning),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          // 장비 목록
          ...List.generate(_inspections.length, (index) {
            final insp = _inspections[index];
            final isExpanded = _expandedIndex == index;
            final hasIssue = insp['hasIssue'] as bool;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(
                  color: hasIssue ? AppColors.error : AppColors.border,
                  width: hasIssue ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      insp['completed']
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: insp['completed']
                          ? AppColors.success
                          : AppColors.error,
                      size: 28,
                    ),
                    title: Text(
                      '${insp['plateNo']} (${insp['equipType']})',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: hasIssue ? AppColors.error : null,
                      ),
                    ),
                    subtitle: Text(
                      insp['completed']
                          ? '점검시간: ${insp['time']}  |  점검자: ${insp['inspector']}'
                          : '미완료',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.grey),
                    ),
                    trailing: insp['completed']
                        ? IconButton(
                            icon: Icon(isExpanded
                                ? Icons.expand_less
                                : Icons.expand_more),
                            onPressed: () {
                              setState(() {
                                _expandedIndex = isExpanded ? null : index;
                              });
                            },
                          )
                        : null,
                  ),
                  if (isExpanded && insp['completed']) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('점검 항목별 결과',
                              style: AppTextStyles.titleMedium),
                          const SizedBox(height: 8),
                          ...(insp['items'] as List<Map<String, dynamic>>)
                              .map((item) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          item['ok']
                                              ? Icons.check_circle_outline
                                              : Icons.error_outline,
                                          color: item['ok']
                                              ? AppColors.success
                                              : AppColors.error,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          item['name'],
                                          style: TextStyle(
                                            color: item['ok']
                                                ? null
                                                : AppColors.error,
                                            fontWeight: item['ok']
                                                ? FontWeight.normal
                                                : FontWeight.bold,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          item['ok'] ? '정상' : '이상',
                                          style: TextStyle(
                                            color: item['ok']
                                                ? AppColors.success
                                                : AppColors.error,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.greyLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.photo_camera_outlined,
                                      color: AppColors.grey),
                                  SizedBox(height: 4),
                                  Text('점검 사진',
                                      style: TextStyle(
                                          color: AppColors.grey,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
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
            child: Icon(Icons.verified_user, color: color, size: 24),
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
