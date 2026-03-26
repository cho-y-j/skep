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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
                  tabs: const [
                    Tab(text: '운전면허 검증'),
                    Tab(text: '사업자등록 검증'),
                    Tab(text: '화물자격 검증'),
                  ],
                ),
                SizedBox(
                  height: 500,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDriverLicenseTab(),
                      _buildBusinessRegistrationTab(),
                      _buildCargoTab(),
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
