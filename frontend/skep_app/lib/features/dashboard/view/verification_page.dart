import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({Key? key}) : super(key: key);

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 운전면허 검증
  final TextEditingController _licenseNumberCtrl = TextEditingController();
  final TextEditingController _licenseNameCtrl = TextEditingController();
  Map<String, dynamic>? _licenseResult;
  bool _licenseLoading = false;
  String? _licenseError;

  // 사업자등록 검증
  final TextEditingController _bizNumberCtrl = TextEditingController();
  Map<String, dynamic>? _bizResult;
  bool _bizLoading = false;
  String? _bizError;

  // 화물자격 검증
  final TextEditingController _cargoNameCtrl = TextEditingController();
  final TextEditingController _cargoBirthCtrl = TextEditingController();
  final TextEditingController _cargoLicenseCtrl = TextEditingController();
  Map<String, dynamic>? _cargoResult;
  bool _cargoLoading = false;
  String? _cargoError;

  // 일괄 검증
  List<Map<String, dynamic>> _allDrivers = [];
  bool _isLoadingDrivers = false;
  bool _isBatchVerifying = false;
  int _batchTotal = 0;
  int _batchCompleted = 0;
  Map<int, Map<String, dynamic>> _batchResults = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _licenseNumberCtrl.dispose();
    _licenseNameCtrl.dispose();
    _bizNumberCtrl.dispose();
    _cargoNameCtrl.dispose();
    _cargoBirthCtrl.dispose();
    _cargoLicenseCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyDriverLicense() async {
    if (_licenseNumberCtrl.text.trim().isEmpty || _licenseNameCtrl.text.trim().isEmpty) {
      setState(() => _licenseError = '면허번호와 이름을 모두 입력해주세요.');
      return;
    }
    setState(() {
      _licenseLoading = true;
      _licenseError = null;
      _licenseResult = null;
    });
    try {
      final dioClient = context.read<DioClient>();
      final response = await dioClient.post<dynamic>(
        '/api/documents/verify/driver-license',
        data: {
          'licenseNumber': _licenseNumberCtrl.text.trim(),
          'name': _licenseNameCtrl.text.trim(),
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        _licenseResult = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : {'result': response.data.toString()};
      }
    } catch (e) {
      _licenseError = e.toString();
    }
    if (mounted) setState(() => _licenseLoading = false);
  }

  Future<void> _verifyBusinessRegistration() async {
    if (_bizNumberCtrl.text.trim().isEmpty) {
      setState(() => _bizError = '사업자번호를 입력해주세요.');
      return;
    }
    setState(() {
      _bizLoading = true;
      _bizError = null;
      _bizResult = null;
    });
    try {
      final dioClient = context.read<DioClient>();
      final response = await dioClient.post<dynamic>(
        '/api/documents/verify/business-registration',
        data: {
          'businessNumber': _bizNumberCtrl.text.trim(),
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        _bizResult = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : {'result': response.data.toString()};
      }
    } catch (e) {
      _bizError = e.toString();
    }
    if (mounted) setState(() => _bizLoading = false);
  }

  Future<void> _verifyCargo() async {
    if (_cargoNameCtrl.text.trim().isEmpty || _cargoBirthCtrl.text.trim().isEmpty || _cargoLicenseCtrl.text.trim().isEmpty) {
      setState(() => _cargoError = '이름, 생년월일, 자격번호를 모두 입력해주세요.');
      return;
    }
    setState(() {
      _cargoLoading = true;
      _cargoError = null;
      _cargoResult = null;
    });
    try {
      final dioClient = context.read<DioClient>();
      final response = await dioClient.post<dynamic>(
        '/api/documents/verify/cargo',
        data: {
          'name': _cargoNameCtrl.text.trim(),
          'birth': _cargoBirthCtrl.text.trim(),
          'lcnsNo': _cargoLicenseCtrl.text.trim(),
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        _cargoResult = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : {'result': response.data.toString()};
      }
    } catch (e) {
      _cargoError = e.toString();
    }
    if (mounted) setState(() => _cargoLoading = false);
  }

  // === Batch verification ===

  Future<void> _loadAllDrivers() async {
    setState(() {
      _isLoadingDrivers = true;
      _allDrivers = [];
    });
    try {
      final dioClient = context.read<DioClient>();
      final response = await dioClient.get<dynamic>(ApiEndpoints.persons);
      List<Map<String, dynamic>> all = [];
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List) {
          all = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['content'] is List) {
          all = (data['content'] as List).cast<Map<String, dynamic>>();
        }
      }
      // Filter DRIVER type only
      _allDrivers = all.where((p) {
        final type = (p['type'] ?? p['personType'] ?? p['role'] ?? '').toString().toUpperCase();
        return type == 'DRIVER';
      }).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('기사 목록 로딩 실패: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _isLoadingDrivers = false);
  }

  Future<void> _batchVerifyAll() async {
    if (_allDrivers.isEmpty) return;
    setState(() {
      _isBatchVerifying = true;
      _batchTotal = _allDrivers.length;
      _batchCompleted = 0;
      _batchResults = {};
    });

    final dioClient = context.read<DioClient>();

    for (int i = 0; i < _allDrivers.length; i++) {
      final driver = _allDrivers[i];
      final driverId = driver['id'];
      final name = driver['name']?.toString() ?? driver['personName']?.toString() ?? '';
      final licenseNumber = driver['licenseNumber']?.toString() ??
          driver['driverLicenseNumber']?.toString() ?? '';

      if (name.isEmpty || licenseNumber.isEmpty) {
        _batchResults[i] = {
          'result': 'UNKNOWN',
          'message': '면허번호 또는 이름 정보 없음',
        };
        setState(() => _batchCompleted = i + 1);
        continue;
      }

      try {
        final response = await dioClient.post<dynamic>(
          '/api/documents/verify/driver-license',
          data: {
            'licenseNumber': licenseNumber,
            'name': name,
          },
        );
        if (response.statusCode == 200 && response.data != null) {
          _batchResults[i] = response.data is Map<String, dynamic>
              ? response.data as Map<String, dynamic>
              : {'result': response.data.toString()};
        } else {
          _batchResults[i] = {'result': 'UNKNOWN', 'message': 'No response data'};
        }
      } catch (e) {
        _batchResults[i] = {'result': 'UNKNOWN', 'message': e.toString()};
      }

      if (mounted) setState(() => _batchCompleted = i + 1);
    }

    if (mounted) setState(() => _isBatchVerifying = false);
  }

  Future<void> _verifySingleDriver(int index) async {
    final driver = _allDrivers[index];
    final name = driver['name']?.toString() ?? driver['personName']?.toString() ?? '';
    final licenseNumber = driver['licenseNumber']?.toString() ??
        driver['driverLicenseNumber']?.toString() ?? '';

    if (name.isEmpty || licenseNumber.isEmpty) {
      setState(() {
        _batchResults[index] = {
          'result': 'UNKNOWN',
          'message': '면허번호 또는 이름 정보 없음',
        };
      });
      return;
    }

    // Mark as loading
    setState(() {
      _batchResults[index] = {'result': 'LOADING'};
    });

    try {
      final dioClient = context.read<DioClient>();
      final response = await dioClient.post<dynamic>(
        '/api/documents/verify/driver-license',
        data: {
          'licenseNumber': licenseNumber,
          'name': name,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        _batchResults[index] = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : {'result': response.data.toString()};
      } else {
        _batchResults[index] = {'result': 'UNKNOWN', 'message': 'No response data'};
      }
    } catch (e) {
      _batchResults[index] = {'result': 'UNKNOWN', 'message': e.toString()};
    }

    if (mounted) setState(() {});
  }

  Color _resultCardColor(Map<String, dynamic>? result) {
    if (result == null) return Colors.transparent;
    final status = (result['result'] ?? result['status'] ?? result['valid'] ?? '').toString().toUpperCase();
    if (status == 'VALID' || status == 'TRUE' || status == 'SUCCESS' || status == '01') {
      return const Color(0xFF16A34A);
    } else if (status == 'UNKNOWN' || status == 'PENDING') {
      return const Color(0xFFD97706);
    } else {
      return const Color(0xFFDC2626);
    }
  }

  String _resultLabel(Map<String, dynamic>? result) {
    if (result == null) return '';
    final status = (result['result'] ?? result['status'] ?? result['valid'] ?? '').toString().toUpperCase();
    if (status == 'VALID' || status == 'TRUE' || status == 'SUCCESS' || status == '01') {
      return '검증 성공';
    } else if (status == 'UNKNOWN' || status == 'PENDING') {
      return '확인 불가';
    } else {
      return '검증 실패';
    }
  }

  String _batchStatusText(Map<String, dynamic>? result) {
    if (result == null) return '미검증';
    final status = (result['result'] ?? result['status'] ?? result['valid'] ?? '').toString().toUpperCase();
    if (status == 'LOADING') return '검증 중...';
    if (status == 'VALID' || status == 'TRUE' || status == 'SUCCESS' || status == '01') return 'VALID';
    if (status == 'INVALID' || status == 'FALSE' || status == 'FAIL') return 'INVALID';
    if (status == 'UNKNOWN' || status == 'PENDING') return 'UNKNOWN';
    return status.isEmpty ? '미검증' : status;
  }

  Color _batchStatusColor(String statusText) {
    switch (statusText) {
      case 'VALID':
        return const Color(0xFF16A34A);
      case 'INVALID':
        return const Color(0xFFDC2626);
      case 'UNKNOWN':
        return const Color(0xFFD97706);
      case '미검증':
        return const Color(0xFF94A3B8);
      case '검증 중...':
        return AppColors.primary;
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '검증 관리',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          Text('운전면허, 사업자등록, 화물자격 검증을 수행합니다.', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 24),
          // 탭
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: const Color(0xFF64748B),
                  indicatorColor: AppColors.primary,
                  labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  isScrollable: true,
                  tabs: const [
                    Tab(text: '운전면허 검증'),
                    Tab(text: '사업자등록 검증'),
                    Tab(text: '화물자격 검증'),
                    Tab(text: '일괄 검증'),
                  ],
                ),
                SizedBox(
                  height: 600,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDriverLicenseTab(),
                      _buildBusinessRegistrationTab(),
                      _buildCargoTab(),
                      _buildBatchVerificationTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverLicenseTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('운전면허 검증', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text('운전면허 정보를 입력하여 유효성을 검증합니다.', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 20),
          TextField(
            controller: _licenseNumberCtrl,
            decoration: InputDecoration(
              labelText: '면허번호',
              hintText: '예: 11-12-345678-90',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _licenseNameCtrl,
            decoration: InputDecoration(
              labelText: '이름',
              hintText: '면허 소유자 이름',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _licenseLoading ? null : _verifyDriverLicense,
              icon: _licenseLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.verified_outlined, size: 18),
              label: const Text('검증 실행'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_licenseError != null) _buildErrorCard(_licenseError!),
          if (_licenseResult != null) _buildResultCard(_licenseResult!),
        ],
      ),
    );
  }

  Widget _buildBusinessRegistrationTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('사업자등록 검증', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text('사업자등록번호를 입력하여 유효성을 검증합니다.', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 20),
          TextField(
            controller: _bizNumberCtrl,
            decoration: InputDecoration(
              labelText: '사업자번호',
              hintText: '예: 123-45-67890',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _bizLoading ? null : _verifyBusinessRegistration,
              icon: _bizLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.verified_outlined, size: 18),
              label: const Text('검증 실행'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_bizError != null) _buildErrorCard(_bizError!),
          if (_bizResult != null) _buildResultCard(_bizResult!),
        ],
      ),
    );
  }

  Widget _buildCargoTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('화물자격 검증', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            Text('화물운송자격 정보를 입력하여 유효성을 검증합니다.', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            const SizedBox(height: 20),
            TextField(
              controller: _cargoNameCtrl,
              decoration: InputDecoration(
                labelText: '이름',
                hintText: '자격 소유자 이름',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cargoBirthCtrl,
              decoration: InputDecoration(
                labelText: '생년월일',
                hintText: '예: 19900101',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cargoLicenseCtrl,
              decoration: InputDecoration(
                labelText: '자격번호',
                hintText: '화물운송자격 번호',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _cargoLoading ? null : _verifyCargo,
                icon: _cargoLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.verified_outlined, size: 18),
                label: const Text('검증 실행'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_cargoError != null) _buildErrorCard(_cargoError!),
            if (_cargoResult != null) _buildResultCard(_cargoResult!),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchVerificationTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('일괄 면허 검증', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text('등록된 전체 기사의 운전면허를 일괄 검증합니다.', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _isLoadingDrivers ? null : _loadAllDrivers,
                icon: _isLoadingDrivers
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download_outlined, size: 18),
                label: const Text('기사 목록 불러오기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.greyDark,
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: (_allDrivers.isEmpty || _isBatchVerifying) ? null : _batchVerifyAll,
                icon: _isBatchVerifying
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.verified_outlined, size: 18),
                label: const Text('전체 검증'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
              ),
              const SizedBox(width: 16),
              if (_allDrivers.isNotEmpty)
                Text(
                  '총 ${_allDrivers.length}명',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
            ],
          ),

          // Progress indicator
          if (_isBatchVerifying || (_batchCompleted > 0 && _batchTotal > 0)) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _batchTotal > 0 ? _batchCompleted / _batchTotal : 0,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _isBatchVerifying ? AppColors.primary : const Color(0xFF16A34A),
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$_batchCompleted / $_batchTotal',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Driver table
          Expanded(
            child: _allDrivers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline, size: 48, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 12),
                        Text(
                          _isLoadingDrivers ? '기사 목록을 불러오는 중...' : '"기사 목록 불러오기" 버튼을 눌러주세요',
                          style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                      headingTextStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      dataTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                      columnSpacing: 24,
                      columns: const [
                        DataColumn(label: Text('#')),
                        DataColumn(label: Text('이름')),
                        DataColumn(label: Text('전화번호')),
                        DataColumn(label: Text('면허번호')),
                        DataColumn(label: Text('검증 상태')),
                        DataColumn(label: Text('작업')),
                      ],
                      rows: List.generate(_allDrivers.length, (index) {
                        final driver = _allDrivers[index];
                        final name = driver['name']?.toString() ?? driver['personName']?.toString() ?? '-';
                        final phone = driver['phone']?.toString() ?? driver['phoneNumber']?.toString() ?? '-';
                        final licenseNo = driver['licenseNumber']?.toString() ??
                            driver['driverLicenseNumber']?.toString() ?? '-';
                        final result = _batchResults[index];
                        final statusText = _batchStatusText(result);
                        final statusColor = _batchStatusColor(statusText);

                        return DataRow(cells: [
                          DataCell(Text('${index + 1}')),
                          DataCell(Text(name)),
                          DataCell(Text(phone)),
                          DataCell(Text(licenseNo)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            statusText == '검증 중...'
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : TextButton(
                                    onPressed: _isBatchVerifying ? null : () => _verifySingleDriver(index),
                                    child: const Text('개별 검증', style: TextStyle(fontSize: 12)),
                                  ),
                          ),
                        ]);
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(error, style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626))),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    final color = _resultCardColor(result);
    final label = _resultLabel(result);
    final jsonStr = const JsonEncoder.withIndent('  ').convert(result);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                color == const Color(0xFF16A34A) ? Icons.check_circle_outline : color == const Color(0xFFD97706) ? Icons.help_outline : Icons.cancel_outlined,
                color: color,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: SelectableText(
              jsonStr,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }
}
