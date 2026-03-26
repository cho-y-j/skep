import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';
import 'package:skep_app/core/widgets/app_button.dart';
import 'package:skep_app/core/widgets/app_text_field.dart';
import 'package:skep_app/features/auth/bloc/auth_bloc.dart';
import 'package:skep_app/features/auth/bloc/auth_event.dart';
import 'package:skep_app/features/auth/bloc/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

/// Google Vision API Key - 상수 선언
const String _kGoogleVisionApiKey = 'AIzaSyB2TuB8vQNHOEiQtJmgz7y5pfJGwzFiJ1U';

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 0;

  // Step 1: Company type
  String? _selectedCompanyType; // 'EQUIPMENT_SUPPLIER' or 'BP_COMPANY'

  // Step 2: Business license / company info
  bool _isVerifying = false;
  bool _isVerified = false;
  bool _verificationFailed = false;
  String? _uploadedFileName;

  late TextEditingController _companyNameController;
  late TextEditingController _businessNumberController;
  late TextEditingController _representativeController;
  late TextEditingController _businessTypeController;
  late TextEditingController _businessItemController;
  late TextEditingController _addressController;
  late TextEditingController _companyPhoneController;

  // Step 3: Admin account
  late TextEditingController _adminNameController;
  late TextEditingController _adminEmailController;
  late TextEditingController _adminPasswordController;
  late TextEditingController _adminPhoneController;

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController();
    _businessNumberController = TextEditingController();
    _representativeController = TextEditingController();
    _businessTypeController = TextEditingController();
    _businessItemController = TextEditingController();
    _addressController = TextEditingController();
    _companyPhoneController = TextEditingController();
    _adminNameController = TextEditingController();
    _adminEmailController = TextEditingController();
    _adminPasswordController = TextEditingController();
    _adminPhoneController = TextEditingController();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _businessNumberController.dispose();
    _representativeController.dispose();
    _businessTypeController.dispose();
    _businessItemController.dispose();
    _addressController.dispose();
    _companyPhoneController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    _adminPhoneController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  bool _validateStep1() {
    if (_selectedCompanyType == null) {
      _showError('회사 유형을 선택해주세요');
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (!_isVerified) {
      _showError('사업자 진위확인을 완료해주세요 (사업자등록증 사진 없이 번호만으로도 검증 가능합니다)');
      return false;
    }
    if (_companyNameController.text.isEmpty) {
      _showError('회사명을 입력해주세요');
      return false;
    }
    if (_businessNumberController.text.isEmpty) {
      _showError('사업자등록번호를 입력해주세요');
      return false;
    }
    if (_businessNumberController.text.replaceAll('-', '').length != 10) {
      _showError('사업자등록번호는 10자리여야 합니다');
      return false;
    }
    if (_representativeController.text.isEmpty) {
      _showError('대표자명을 입력해주세요');
      return false;
    }
    if (_addressController.text.isEmpty) {
      _showError('주소를 입력해주세요');
      return false;
    }
    if (_companyPhoneController.text.isEmpty) {
      _showError('전화번호를 입력해주세요');
      return false;
    }
    return true;
  }

  static final _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
  static final _passwordComplexityRegex = RegExp(r'^(?=.*[a-zA-Z])(?=.*\d).{8,}$');

  bool _validateStep3() {
    if (_adminNameController.text.isEmpty) {
      _showError('담당자 이름을 입력해주세요');
      return false;
    }
    if (_adminEmailController.text.isEmpty) {
      _showError('이메일을 입력해주세요');
      return false;
    }
    if (!_emailRegex.hasMatch(_adminEmailController.text)) {
      _showError('잘못된 이메일 형식입니다 (예: user@example.com)');
      return false;
    }
    if (_adminPasswordController.text.isEmpty) {
      _showError('비밀번호를 입력해주세요');
      return false;
    }
    if (_adminPasswordController.text.length < 8) {
      _showError('비밀번호는 8자 이상이어야 합니다');
      return false;
    }
    if (!_passwordComplexityRegex.hasMatch(_adminPasswordController.text)) {
      _showError('비밀번호는 영문자와 숫자를 포함해야 합니다');
      return false;
    }
    if (_adminPhoneController.text.isEmpty) {
      _showError('연락처를 입력해주세요');
      return false;
    }
    return true;
  }

  void _nextStep() {
    bool valid = false;
    switch (_currentStep) {
      case 0:
        valid = _validateStep1();
        break;
      case 1:
        valid = _validateStep2();
        break;
      case 2:
        valid = _validateStep3();
        break;
    }
    if (valid) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Uint8List? _uploadedFileBytes;
  String _verifyMessage = '';
  bool _isOcrProcessing = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    setState(() {
      _uploadedFileName = file.name;
      _uploadedFileBytes = file.bytes;
      _isVerified = false;
      _verificationFailed = false;
      _verifyMessage = '';
    });

    // 이미지 파일이면 OCR 자동 시도
    final ext = file.extension?.toLowerCase() ?? '';
    if (['jpg', 'jpeg', 'png'].contains(ext) && file.bytes != null) {
      _runOcr(file.bytes!);
    }
  }

  Future<void> _runOcr(Uint8List imageBytes) async {
    setState(() {
      _isOcrProcessing = true;
      _verifyMessage = 'Google Vision OCR로 정보를 읽는 중...';
    });

    try {
      const apiKey = _kGoogleVisionApiKey;
      final base64Image = base64Encode(imageBytes);

      final dio = Dio();
      final response = await dio.post(
        'https://vision.googleapis.com/v1/images:annotate?key=$apiKey',
        data: {
          'requests': [
            {
              'image': {'content': base64Image},
              'features': [
                {'type': 'TEXT_DETECTION', 'maxResults': 1}
              ]
            }
          ]
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (!mounted) return;

      final data = response.data as Map<String, dynamic>;
      final responses = data['responses'] as List? ?? [];
      if (responses.isNotEmpty) {
        final annotations = responses[0]['textAnnotations'] as List? ?? [];
        if (annotations.isNotEmpty) {
          final fullText = annotations[0]['description'] as String? ?? '';
          _parseOcrText(fullText);
          setState(() {
            _isOcrProcessing = false;
            _verifyMessage = 'OCR 완료 - 인식된 정보를 확인/수정해주세요';
          });
          return;
        }
      }

      setState(() {
        _isOcrProcessing = false;
        _verifyMessage = 'OCR: 텍스트를 인식하지 못했습니다. 직접 입력해주세요';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isOcrProcessing = false;
        _verifyMessage = 'OCR 실패: $e - 직접 입력해주세요';
      });
    }
  }

  void _parseOcrText(String text) {
    final lines = text.split('\n');

    // 사업자등록번호 패턴: 000-00-00000 또는 000 00 00000
    final bizNoRegex = RegExp(r'(\d{3})[-\s]?(\d{2})[-\s]?(\d{5})');
    final bizNoMatch = bizNoRegex.firstMatch(text);
    if (bizNoMatch != null && _businessNumberController.text.isEmpty) {
      _businessNumberController.text = '${bizNoMatch.group(1)}-${bizNoMatch.group(2)}-${bizNoMatch.group(3)}';
    }

    // 전화번호 패턴
    final phoneRegex = RegExp(r'(\d{2,3})-(\d{3,4})-(\d{4})');
    final phoneMatch = phoneRegex.firstMatch(text);
    if (phoneMatch != null && _companyPhoneController.text.isEmpty) {
      _companyPhoneController.text = phoneMatch.group(0) ?? '';
    }

    // 대표자(성명) 추출: "성명" 또는 "대표자" 다음 텍스트
    for (final line in lines) {
      if ((line.contains('성명') || line.contains('대표자')) && _representativeController.text.isEmpty) {
        final nameMatch = RegExp(r'[가-힣]{2,5}').firstMatch(line.replaceAll(RegExp(r'성명|대표자|:|\s'), ' ').trim());
        if (nameMatch != null) {
          _representativeController.text = nameMatch.group(0) ?? '';
        }
      }
      // 상호(법인명) 추출
      if ((line.contains('상호') || line.contains('법인명') || line.contains('명칭')) && _companyNameController.text.isEmpty) {
        final cleaned = line.replaceAll(RegExp(r'상호|법인명|명칭|\(.*?\)|:'), '').trim();
        final nameMatch = RegExp(r'[가-힣a-zA-Z\s]{2,}').firstMatch(cleaned);
        if (nameMatch != null && nameMatch.group(0)!.trim().isNotEmpty) {
          _companyNameController.text = nameMatch.group(0)!.trim();
        }
      }
      // 업태 추출
      if (line.contains('업태') && _businessTypeController.text.isEmpty) {
        final cleaned = line.replaceAll(RegExp(r'업태|:'), '').trim();
        if (cleaned.isNotEmpty) _businessTypeController.text = cleaned;
      }
      // 종목 추출
      if (line.contains('종목') && _businessItemController.text.isEmpty) {
        final cleaned = line.replaceAll(RegExp(r'종목|:'), '').trim();
        if (cleaned.isNotEmpty) _businessItemController.text = cleaned;
      }
      // 주소 추출
      if ((line.contains('소재지') || line.contains('사업장')) && _addressController.text.isEmpty) {
        final cleaned = line.replaceAll(RegExp(r'사업장\s*소재지|소재지|:'), '').trim();
        if (cleaned.length > 5) _addressController.text = cleaned;
      }
    }
  }

  Future<void> _verifyBusinessLicense() async {
    final bizNo = _businessNumberController.text.replaceAll('-', '').trim();
    final ownerName = _representativeController.text.trim();

    if (bizNo.isEmpty || bizNo.length != 10) {
      _showError('사업자등록번호 10자리를 입력해주세요');
      return;
    }
    if (ownerName.isEmpty) {
      _showError('대표자명을 입력해주세요');
      return;
    }

    setState(() {
      _isVerifying = true;
      _verificationFailed = false;
      _verifyMessage = '국세청 API로 사업자 진위확인 중...';
    });

    try {
      final dio = Dio();
      final verifyBaseUrl = Uri.base.origin;
      final response = await dio.post(
        '$verifyBaseUrl/api/verify/biz',
        data: {
          'bizNo': bizNo,
          'startDate': '20200101',
          'ownerName': ownerName,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (!mounted) return;

      final data = response.data as Map<String, dynamic>;
      final result = data['result'] as String? ?? 'UNKNOWN';
      final message = data['message'] as String? ?? '';

      setState(() {
        _isVerifying = false;
        if (result == 'VALID') {
          _isVerified = true;
          _verificationFailed = false;
          _verifyMessage = '✅ 검증 완료: 유효한 사업자입니다';
        } else if (result == 'INVALID') {
          _isVerified = false;
          _verificationFailed = true;
          _verifyMessage = '❌ 검증 실패: $message';
        } else {
          _isVerified = true;
          _verificationFailed = false;
          _verifyMessage = '⚠️ $result: $message (테스트 모드 진행 가능)';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _isVerified = true;
        _verificationFailed = false;
        _verifyMessage = '⚠️ 검증 서버 연결 오류 (테스트 모드 진행 가능)';
      });
    }
  }

  void _handleRegister() {
    context.read<AuthBloc>().add(
          AuthRegisterRequested(
            email: _adminEmailController.text,
            password: _adminPasswordController.text,
            name: _adminNameController.text,
            role: _selectedCompanyType!,
            companyName: _companyNameController.text,
            companyType: _selectedCompanyType,
            phone: _adminPhoneController.text,
            businessNumber: _businessNumberController.text,
            representative: _representativeController.text,
            address: _addressController.text,
            companyPhone: _companyPhoneController.text,
          ),
        );
  }

  Widget _buildLabelWithRequired(String label) {
    return Row(
      children: [
        Text(label, style: AppTextStyles.labelLarge),
        const SizedBox(width: 4),
        const Text('*', style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLabelWithOptional(String label) {
    return Row(
      children: [
        Text(label, style: AppTextStyles.labelLarge),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
          child: Text('선택', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ),
      ],
    );
  }

  String get _companyTypeLabel {
    if (_selectedCompanyType == 'EQUIPMENT_SUPPLIER') return '장비공급사';
    if (_selectedCompanyType == 'BP_COMPANY') return 'BP사';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 768;

    return Scaffold(
      backgroundColor:
          isDesktop ? const Color(0xFFF1F5F9) : AppColors.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthRegisterSuccess) {
            _showSuccess('가입이 완료되었습니다. 로그인해주세요.');
            context.go('/login');
          } else if (state is AuthFailure) {
            _showError(state.message);
          }
        },
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: isDesktop ? 560 : double.infinity,
              margin: isDesktop
                  ? const EdgeInsets.symmetric(vertical: 40)
                  : EdgeInsets.zero,
              padding: const EdgeInsets.all(32),
              decoration: isDesktop
                  ? BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    )
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'S',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '회사 등록',
                          style: AppTextStyles.displaySmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SKEP 플랫폼 회사 가입',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Step indicator
                  _buildStepIndicator(),
                  const SizedBox(height: 32),

                  // Step content
                  _buildStepContent(),
                  const SizedBox(height: 32),

                  // Navigation buttons
                  _buildNavigationButtons(),
                  const SizedBox(height: 20),

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '이미 계정이 있으신가요? ',
                        style: AppTextStyles.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          '로그인',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    const steps = ['유형 선택', '회사 정보', '관리자 계정', '가입 완료'];
    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final stepIndex = index ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              color: stepIndex < _currentStep
                  ? AppColors.primary
                  : AppColors.border,
            ),
          );
        }
        final stepIndex = index ~/ 2;
        final isActive = stepIndex == _currentStep;
        final isCompleted = stepIndex < _currentStep;
        return Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.primary
                    : isActive
                        ? AppColors.primary
                        : AppColors.border,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          color: isActive ? Colors.white : AppColors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              steps[stepIndex],
              style: TextStyle(
                fontSize: 11,
                color: isActive || isCompleted
                    ? AppColors.primary
                    : AppColors.grey,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1CompanyType();
      case 1:
        return _buildStep2CompanyInfo();
      case 2:
        return _buildStep3AdminAccount();
      case 3:
        return _buildStep4Summary();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Step 1: 회사 유형 선택 ───

  Widget _buildStep1CompanyType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            '회사 유형을 선택해주세요',
            style: AppTextStyles.headlineMedium,
          ),
        ),
        const SizedBox(height: 24),
        _buildCompanyTypeCard(
          type: 'EQUIPMENT_SUPPLIER',
          icon: Icons.build_outlined,
          title: '장비공급사',
          description: '건설 장비를 보유하고 현장에 장비를 투입하는 회사',
        ),
        const SizedBox(height: 16),
        _buildCompanyTypeCard(
          type: 'BP_COMPANY',
          icon: Icons.business_outlined,
          title: 'BP사',
          description: '건설 현장을 관리하고 장비 투입을 요청하는 회사',
        ),
      ],
    );
  }

  Widget _buildCompanyTypeCard({
    required String type,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isSelected = _selectedCompanyType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCompanyType = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.greyLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.grey,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }

  // ─── Step 2: 사업자등록증 업로드 + 회사 정보 ───

  Widget _buildStep2CompanyInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            '회사 정보 입력',
            style: AppTextStyles.headlineMedium,
          ),
        ),
        const SizedBox(height: 24),

        // 사업자등록증 업로드 + 미리보기
        Row(
          children: [
            Text('사업자등록증 업로드 ', style: AppTextStyles.labelLarge),
            Text('*', style: TextStyle(color: AppColors.error, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: (_isVerifying || _isOcrProcessing) ? null : _pickFile,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _uploadedFileBytes != null ? AppColors.primary : AppColors.border,
              ),
            ),
            child: _uploadedFileBytes != null
                ? Column(
                    children: [
                      // 이미지 미리보기
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: _uploadedFileName?.toLowerCase().endsWith('.pdf') == true
                              ? Container(
                                  height: 120,
                                  width: double.infinity,
                                  color: Colors.grey[200],
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.picture_as_pdf, size: 48, color: Colors.red),
                                      const SizedBox(height: 8),
                                      Text(_uploadedFileName ?? '', style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                )
                              : Image.memory(
                                  _uploadedFileBytes!,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_file, size: 16, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Expanded(child: Text(_uploadedFileName ?? '', style: const TextStyle(fontSize: 12, color: AppColors.primary), overflow: TextOverflow.ellipsis)),
                            if (_isOcrProcessing) ...[
                              const SizedBox(width: 8, height: 8, child: CircularProgressIndicator(strokeWidth: 1.5)),
                              const SizedBox(width: 6),
                              Text('OCR 처리 중...', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                            ] else
                              Text('다시 선택', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_upload_outlined, color: AppColors.grey, size: 40),
                        const SizedBox(height: 12),
                        Text('사업자등록증 파일을 업로드하세요', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey)),
                        const SizedBox(height: 4),
                        Text('JPG, PNG, PDF 형식 지원 (OCR 자동 인식)', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
          ),
        ),
        if (_verifyMessage.isNotEmpty && _uploadedFileBytes != null && !_isVerified) ...[
          const SizedBox(height: 8),
          Text(_verifyMessage, style: TextStyle(fontSize: 12, color: AppColors.primary)),
        ],

        const SizedBox(height: 24),
        // 필수 필드들
        _buildLabelWithRequired('회사명'),
        const SizedBox(height: 6),
        AppTextField(label: '', hint: '회사명을 입력하세요', controller: _companyNameController),
        const SizedBox(height: 16),
        _buildLabelWithRequired('사업자등록번호'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _businessNumberController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '000-00-00000',
            hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          inputFormatters: [_BusinessNumberFormatter()],
          maxLength: 12,
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
        ),
        const SizedBox(height: 16),
        _buildLabelWithRequired('대표자명'),
        const SizedBox(height: 6),
        AppTextField(label: '', hint: '대표자명을 입력하세요', controller: _representativeController),
        const SizedBox(height: 16),

        // 검증 요청 버튼
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isVerifying ? null : _verifyBusinessLicense,
            icon: _isVerifying
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(_isVerified ? Icons.check_circle : Icons.verified_outlined, size: 18),
            label: Text(_isVerifying ? '국세청 API 검증 중...' : _isVerified ? '✅ 검증 완료 (재검증)' : '사업자 진위확인 요청'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isVerified ? AppColors.success : AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        if (_verifyMessage.isNotEmpty && (_isVerified || _verificationFailed)) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isVerified ? AppColors.success.withOpacity(0.05) : AppColors.error.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _isVerified ? AppColors.success.withOpacity(0.3) : AppColors.error.withOpacity(0.3)),
            ),
            child: Text(_verifyMessage, style: TextStyle(fontSize: 13, color: _isVerified ? AppColors.success : AppColors.error)),
          ),
        ],

        const SizedBox(height: 24),
        // 선택 필드들
        _buildLabelWithOptional('업태'),
        const SizedBox(height: 6),
        AppTextField(label: '', hint: '업태를 입력하세요', controller: _businessTypeController),
        const SizedBox(height: 16),
        _buildLabelWithOptional('종목'),
        const SizedBox(height: 6),
        AppTextField(label: '', hint: '종목을 입력하세요', controller: _businessItemController),
        const SizedBox(height: 16),
        _buildLabelWithOptional('주소'),
        const SizedBox(height: 6),
        AppTextField(label: '', hint: '회사 주소를 입력하세요', controller: _addressController),
        const SizedBox(height: 16),
        _buildLabelWithRequired('전화번호'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _companyPhoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: '02-0000-0000',
            hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          inputFormatters: [_PhoneNumberFormatter()],
          maxLength: 13,
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
        ),
      ],
    );
  }

  // ─── Step 3: 관리자 계정 생성 ───

  Widget _buildStep3AdminAccount() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            '관리자 계정 생성',
            style: AppTextStyles.headlineMedium,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '회사를 관리할 관리자 계정 정보를 입력하세요',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
          ),
        ),
        const SizedBox(height: 24),
        AppTextField(
          label: '담당자 이름',
          hint: '이름을 입력하세요',
          controller: _adminNameController,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: '이메일 (로그인 ID)',
          hint: '이메일 주소를 입력하세요',
          controller: _adminEmailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: '비밀번호',
          hint: '영문 대/소문자, 숫자, 특수문자 포함 8자 이상',
          controller: _adminPasswordController,
          obscureText: true,
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('연락처', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _adminPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '010-0000-0000',
                hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              inputFormatters: [_PhoneNumberFormatter()],
              maxLength: 13,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
            ),
          ],
        ),
      ],
    );
  }

  // ─── Step 4: 가입 완료 (Summary) ───

  Widget _buildStep4Summary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            '가입 정보 확인',
            style: AppTextStyles.headlineMedium,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '입력하신 정보를 확인해주세요',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
          ),
        ),
        const SizedBox(height: 24),

        // Company info card
        _buildSummaryCard(
          title: '회사 정보',
          icon: Icons.business_outlined,
          items: [
            _SummaryItem('회사 유형', _companyTypeLabel),
            _SummaryItem('회사명', _companyNameController.text),
            _SummaryItem('사업자등록번호', _businessNumberController.text),
            _SummaryItem('대표자명', _representativeController.text),
            if (_businessTypeController.text.isNotEmpty)
              _SummaryItem('업태', _businessTypeController.text),
            if (_businessItemController.text.isNotEmpty)
              _SummaryItem('종목', _businessItemController.text),
            _SummaryItem('주소', _addressController.text),
            _SummaryItem('전화번호', _companyPhoneController.text),
          ],
        ),
        const SizedBox(height: 16),

        // Admin info card
        _buildSummaryCard(
          title: '관리자 계정',
          icon: Icons.person_outlined,
          items: [
            _SummaryItem('담당자 이름', _adminNameController.text),
            _SummaryItem('이메일', _adminEmailController.text),
            _SummaryItem('연락처', _adminPhoneController.text),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required IconData icon,
    required List<_SummaryItem> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      item.label,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.value.isEmpty ? '-' : item.value,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Navigation Buttons ───

  Widget _buildNavigationButtons() {
    final isLastStep = _currentStep == 3;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: AppOutlinedButton(
                  label: '이전',
                  onPressed: _previousStep,
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: isLastStep ? '가입 신청' : '다음',
                onPressed: isLastStep ? _handleRegister : _nextStep,
                isLoading: isLoading,
                width: double.infinity,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryItem {
  final String label;
  final String value;
  const _SummaryItem(this.label, this.value);
}

/// 사업자등록번호 자동 포맷터 (000-00-00000)
class _BusinessNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 10) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 3 || i == 5) buffer.write('-');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// 전화번호 자동 포맷터 (010-0000-0000 또는 02-000-0000)
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 11) return oldValue;

    final buffer = StringBuffer();
    if (digits.startsWith('02')) {
      for (int i = 0; i < digits.length; i++) {
        if (i == 2) buffer.write('-');
        if (digits.length <= 9 && i == 5) buffer.write('-');
        if (digits.length > 9 && i == 6) buffer.write('-');
        buffer.write(digits[i]);
      }
    } else {
      for (int i = 0; i < digits.length; i++) {
        if (i == 3) buffer.write('-');
        if (i == 7) buffer.write('-');
        buffer.write(digits[i]);
      }
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
