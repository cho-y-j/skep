import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';
import 'package:skep_app/core/network/dio_client.dart';
import 'package:skep_app/features/dashboard/view/document_type_master_page.dart';
import 'package:skep_app/features/dashboard/view/supplier_equipment_page.dart';

/// Google Vision API Key
const String _kGoogleVisionApiKey = 'AIzaSyB2TuB8vQNHOEiQtJmgz7y5pfJGwzFiJ1U';

/// 공급사 장비 등록 페이지 (단일 스크롤 페이지)
class SupplierEquipmentRegisterPage extends StatefulWidget {
  const SupplierEquipmentRegisterPage({Key? key}) : super(key: key);

  @override
  State<SupplierEquipmentRegisterPage> createState() =>
      _SupplierEquipmentRegisterPageState();
}

class _SupplierEquipmentRegisterPageState
    extends State<SupplierEquipmentRegisterPage> {
  final DocumentTypeRepository _docRepo = DocumentTypeRepository.instance;
  final EquipmentTypeRepository _eqRepo = EquipmentTypeRepository.instance;

  // 장비 유형 선택
  String? _selectedEquipmentType;

  // 기본정보 컨트롤러
  final _vehicleNumberController = TextEditingController();
  final _modelNameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _manufacturingYearController = TextEditingController();

  // 서류 업로드 상태
  final Map<String, UploadedEquipmentDocument> _uploadedDocs = {};
  final Map<String, DateTime?> _expiryDates = {};
  final Map<String, TextEditingController> _expiryControllers = {};

  // OCR 진행중 표시
  bool _ocrLoading = false;

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _modelNameController.dispose();
    _manufacturerController.dispose();
    _manufacturingYearController.dispose();
    for (final c in _expiryControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onEquipmentTypeChanged(String? type) {
    setState(() {
      _selectedEquipmentType = type;
      _uploadedDocs.clear();
      _expiryDates.clear();
      for (final c in _expiryControllers.values) {
        c.dispose();
      }
      _expiryControllers.clear();
      _vehicleNumberController.clear();
      _modelNameController.clear();
      _manufacturerController.clear();
      _manufacturingYearController.clear();
      if (type != null) {
        final requiredDocs = _eqRepo.getRequiredDocuments(type);
        for (final docName in requiredDocs) {
          _uploadedDocs[docName] = UploadedEquipmentDocument();
          _expiryControllers[docName] = TextEditingController();
        }
      }
    });
  }

  DocumentType? _findDocType(String name) {
    final docs = _docRepo.getByCategory('장비서류');
    for (final d in docs) {
      if (d.name == name) return d;
    }
    return null;
  }

  bool _isImageFile(String fileName) {
    final lower = fileName.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png');
  }

  // ==================== 파일 업로드 ====================

  Future<void> _pickAndUploadFile(String docName) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() {
      _uploadedDocs[docName] = UploadedEquipmentDocument(
        fileName: file.name,
        fileBytes: file.bytes,
        uploadedAt: DateTime.now(),
        verificationStatus: EquipmentVerificationStatus.pending,
      );
    });

    // 첫번째 서류면 OCR 실행
    final requiredDocs = _selectedEquipmentType != null
        ? _eqRepo.getRequiredDocuments(_selectedEquipmentType!)
        : <String>[];
    if (requiredDocs.isNotEmpty &&
        docName == requiredDocs.first &&
        _isImageFile(file.name)) {
      _runOcr(file.bytes!);
    }

    // 검증 가능한 서류인지 확인
    final docType = _findDocType(docName);
    if (docType != null && docType.hasVerification) {
      _runVerification(docName, docType, file.bytes!);
    }
  }

  // ==================== OCR (Google Vision API) ====================

  Future<void> _runOcr(Uint8List imageBytes) async {
    setState(() => _ocrLoading = true);

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
                {'type': 'TEXT_DETECTION'}
              ],
            }
          ],
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (!mounted) return;

      final responses = response.data['responses'] as List?;
      if (responses != null && responses.isNotEmpty) {
        final annotations = responses[0]['textAnnotations'] as List?;
        if (annotations != null && annotations.isNotEmpty) {
          final fullText = annotations[0]['description'] as String? ?? '';
          _parseOcrText(fullText);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OCR 처리 중 오류가 발생했습니다: $e'),
          backgroundColor: AppColors.warning,
        ),
      );
    } finally {
      if (mounted) setState(() => _ocrLoading = false);
    }
  }

  void _parseOcrText(String text) {
    final lines = text.split('\n');
    String vehicleNumber = '';
    String modelName = '';
    String manufacturer = '';
    String year = '';

    for (final line in lines) {
      final trimmed = line.trim();

      // 차량번호 패턴: "서울 01가 1234" 또는 "경기12가3456" 등
      final vehicleRegex = RegExp(
          r'[가-힣]{2,3}\s*\d{1,2}\s*[가-힣]\s*\d{4}');
      final vehicleMatch = vehicleRegex.firstMatch(trimmed);
      if (vehicleMatch != null && vehicleNumber.isEmpty) {
        vehicleNumber = vehicleMatch.group(0) ?? '';
      }

      // 건설기계 번호 패턴: "서울 000-0000" 등
      final constructionRegex = RegExp(
          r'[가-힣]{2,3}\s*\d{3}\s*[-]?\s*\d{4}');
      final constructionMatch = constructionRegex.firstMatch(trimmed);
      if (constructionMatch != null && vehicleNumber.isEmpty) {
        vehicleNumber = constructionMatch.group(0) ?? '';
      }

      // 제조사/모델명 추출
      if (trimmed.contains('형식') || trimmed.contains('모델')) {
        final parts = trimmed.split(RegExp(r'[:\s]+'));
        if (parts.length >= 2) {
          modelName = parts.sublist(1).join(' ').trim();
        }
      }

      // 제조사
      if (trimmed.contains('제조사') || trimmed.contains('제작사')) {
        final parts = trimmed.split(RegExp(r'[:\s]+'));
        if (parts.length >= 2) {
          manufacturer = parts.sublist(1).join(' ').trim();
        }
      }

      // 제조년도
      final yearRegex = RegExp(r'(19|20)\d{2}\s*[년.]');
      final yearMatch = yearRegex.firstMatch(trimmed);
      if (yearMatch != null && year.isEmpty) {
        year = yearMatch.group(0)?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
      }
    }

    setState(() {
      if (vehicleNumber.isNotEmpty && _vehicleNumberController.text.isEmpty) {
        _vehicleNumberController.text = vehicleNumber;
      }
      if (modelName.isNotEmpty && _modelNameController.text.isEmpty) {
        _modelNameController.text = modelName;
      }
      if (manufacturer.isNotEmpty && _manufacturerController.text.isEmpty) {
        _manufacturerController.text = manufacturer;
      }
      if (year.isNotEmpty && _manufacturingYearController.text.isEmpty) {
        _manufacturingYearController.text = year;
      }
    });

    if (vehicleNumber.isNotEmpty || modelName.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OCR로 기본정보가 자동 입력되었습니다. 확인 후 수정하세요.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  // ==================== 검증 ====================

  Future<void> _runVerification(
      String docName, DocumentType docType, Uint8List fileBytes) async {
    setState(() {
      _uploadedDocs[docName]!.verificationStatus =
          EquipmentVerificationStatus.verifying;
    });

    final provider = docType.verificationProvider.toLowerCase();
    final verifyBaseUrl = ApiEndpoints.baseUrl;
    final dio = Dio();

    try {
      if (provider.contains('국세청')) {
        final info = await _showVerifyInputDialog('사업자 진위확인', [
          {'key': 'bizNo', 'label': '사업자등록번호', 'hint': '000-00-00000'},
          {'key': 'ownerName', 'label': '대표자명', 'hint': '홍길동'},
        ]);
        if (info == null) {
          _resetVerifyStatus(docName);
          return;
        }
        final resp = await dio.post('$verifyBaseUrl/api/verify/biz',
            data: {
              'bizNo': (info['bizNo'] ?? '').replaceAll('-', ''),
              'startDate': '20200101',
              'ownerName': info['ownerName']
            },
            options: Options(
                headers: {'Content-Type': 'application/json'},
                receiveTimeout: const Duration(seconds: 10)));
        _setVerifyResult(docName, resp.data);
      } else if (provider.contains('경찰청')) {
        final info = await _showVerifyInputDialog('운전면허 진위확인', [
          {
            'key': 'f_license_no',
            'label': '면허번호',
            'hint': '11-12-345678-90'
          },
          {'key': 'f_resident_name', 'label': '성명', 'hint': '홍길동'},
        ]);
        if (info == null) {
          _resetVerifyStatus(docName);
          return;
        }
        final resp = await dio.post('$verifyBaseUrl/api/verify/rims/license',
            data: {
              'f_license_no': info['f_license_no'],
              'f_resident_name': info['f_resident_name'],
              'f_licn_con_code': '01'
            },
            options: Options(
                headers: {'Content-Type': 'application/json'},
                receiveTimeout: const Duration(seconds: 10)));
        _setVerifyResult(docName, resp.data);
      } else if (provider.contains('교통안전')) {
        final info = await _showVerifyInputDialog('화물운송 자격 확인', [
          {'key': 'name', 'label': '성명', 'hint': '홍길동'},
          {'key': 'birth', 'label': '생년월일', 'hint': '1990-01-01'},
          {'key': 'lcnsNo', 'label': '자격번호', 'hint': '12345678'},
        ]);
        if (info == null) {
          _resetVerifyStatus(docName);
          return;
        }
        final resp = await dio.post('$verifyBaseUrl/api/verify/cargo',
            data: info,
            options: Options(
                headers: {'Content-Type': 'application/json'},
                receiveTimeout: const Duration(seconds: 10)));
        _setVerifyResult(docName, resp.data);
      } else if (provider.contains('안전보건') || provider.contains('산업안전')) {
        final formData = FormData.fromMap({
          'image': MultipartFile.fromBytes(fileBytes,
              filename: _uploadedDocs[docName]!.fileName ?? 'doc.jpg'),
        });
        final resp = await dio.post('$verifyBaseUrl/api/verify/kosha',
            data: formData,
            options: Options(receiveTimeout: const Duration(seconds: 15)));
        _setVerifyResult(docName, resp.data);
      } else if (provider.contains('정부24')) {
        // 정부24는 자동 통과
        if (!mounted) return;
        setState(() {
          _uploadedDocs[docName]!.verificationStatus =
              EquipmentVerificationStatus.verified;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _uploadedDocs[docName]!.verificationStatus =
              EquipmentVerificationStatus.verified;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadedDocs[docName]!.verificationStatus =
            EquipmentVerificationStatus.failed;
      });
    }
  }

  void _resetVerifyStatus(String docName) {
    if (!mounted) return;
    setState(() {
      _uploadedDocs[docName]!.verificationStatus =
          EquipmentVerificationStatus.pending;
    });
  }

  void _setVerifyResult(String docName, dynamic responseData) {
    if (!mounted) return;
    final data = responseData as Map<String, dynamic>;
    final result = data['result'] as String? ?? 'UNKNOWN';
    setState(() {
      _uploadedDocs[docName]!.verificationStatus = result == 'VALID'
          ? EquipmentVerificationStatus.verified
          : EquipmentVerificationStatus.failed;
    });
  }

  Future<Map<String, String>?> _showVerifyInputDialog(
      String title, List<Map<String, String>> fields) async {
    final controllers = <String, TextEditingController>{};
    for (final f in fields) {
      controllers[f['key']!] = TextEditingController();
    }

    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('검증에 필요한 정보를 입력해주세요',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 16),
              ...fields.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: controllers[f['key']!],
                      decoration: InputDecoration(
                        labelText: f['label'],
                        hintText: f['hint'],
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('건너뛰기')),
          ElevatedButton(
            onPressed: () {
              final result = <String, String>{};
              for (final e in controllers.entries) {
                if (e.value.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          '${fields.firstWhere((f) => f['key'] == e.key)['label']}을(를) 입력해주세요'),
                      backgroundColor: AppColors.error));
                  return;
                }
                result[e.key] = e.value.text.trim();
              }
              Navigator.of(ctx).pop(result);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            child: const Text('검증 요청'),
          ),
        ],
      ),
    );
  }

  // ==================== 파일 삭제 / 만료일 ====================

  void _removeFile(String docName) {
    setState(() {
      _uploadedDocs[docName] = UploadedEquipmentDocument();
      _expiryDates.remove(docName);
      _expiryControllers[docName]?.clear();
    });
  }

  Future<void> _pickExpiryDate(String docName) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _expiryDates[docName] ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null) {
      setState(() {
        _expiryDates[docName] = picked;
        _uploadedDocs[docName]?.expiryDate = picked;
        _expiryControllers[docName]?.text =
            '${picked.year}년 ${picked.month}월 ${picked.day}일';
      });
    }
  }

  // ==================== 등록 ====================

  bool _canRegister() {
    return _selectedEquipmentType != null &&
        _vehicleNumberController.text.trim().isNotEmpty &&
        _modelNameController.text.trim().isNotEmpty;
  }

  bool get _hasUnsavedData {
    return _selectedEquipmentType != null ||
        _vehicleNumberController.text.isNotEmpty ||
        _modelNameController.text.isNotEmpty ||
        _uploadedDocs.values.any((d) => d.fileName != null);
  }

  List<String> get _missingDocuments {
    if (_selectedEquipmentType == null) return [];
    final requiredDocs = _eqRepo.getRequiredDocuments(_selectedEquipmentType!);
    return requiredDocs.where((docName) {
      final doc = _uploadedDocs[docName];
      return doc == null || doc.fileName == null;
    }).toList();
  }

  bool _isSubmitting = false;

  Future<void> _completeRegistration() async {
    if (!_canRegister()) {
      // 필수 필드 확인
      final errors = <String>[];
      if (_selectedEquipmentType == null) errors.add('장비 유형을 선택해주세요');
      if (_vehicleNumberController.text.trim().isEmpty) errors.add('차량번호를 입력해주세요');
      if (_modelNameController.text.trim().isEmpty) errors.add('모델명을 입력해주세요');

      final missing = _missingDocuments;
      if (missing.isNotEmpty) {
        errors.add('미제출 서류: ${missing.join(", ")}');
      }

      if (errors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errors.first),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dioClient = context.read<DioClient>();
      final body = {
        'vehicleNumber': _vehicleNumberController.text.trim(),
        'type': _selectedEquipmentType,
        'equipmentType': _selectedEquipmentType,
        'model': _modelNameController.text.trim(),
        'modelName': _modelNameController.text.trim(),
        'manufacturer': _manufacturerController.text.trim(),
        'manufacturingYear': _manufacturingYearController.text.trim(),
      };

      await dioClient.post<dynamic>(ApiEndpoints.equipments, data: body);

      // Also add to local store for backward compatibility
      final equipment = RegisteredEquipment(
        vehicleNumber: _vehicleNumberController.text.trim(),
        equipmentType: _selectedEquipmentType!,
        modelName: _modelNameController.text.trim(),
        manufacturer: _manufacturerController.text.trim(),
        manufacturingYear: _manufacturingYearController.text.trim(),
        registeredAt: DateTime.now(),
        documents: Map.from(_uploadedDocs),
      );
      EquipmentListStore.instance.equipmentList.add(equipment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('장비가 등록되었습니다.'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      // 폼 초기화
      setState(() {
        _selectedEquipmentType = null;
        _vehicleNumberController.clear();
        _modelNameController.clear();
        _manufacturerController.clear();
        _manufacturingYearController.clear();
        _uploadedDocs.clear();
        _expiryDates.clear();
        for (final c in _expiryControllers.values) {
          c.dispose();
        }
        _expiryControllers.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('등록 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ==================== 이미지 미리보기 ====================

  void _showImagePreview(UploadedEquipmentDocument doc) {
    if (doc.fileBytes == null) return;
    final isImage = _isImageFile(doc.fileName ?? '');
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(doc.fileName ?? '미리보기'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            ConstrainedBox(
              constraints:
                  const BoxConstraints(maxHeight: 500, maxWidth: 600),
              child: isImage
                  ? InteractiveViewer(
                      child: Image.memory(doc.fileBytes!, fit: BoxFit.contain),
                    )
                  : const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.picture_as_pdf,
                                size: 64, color: Colors.red),
                            SizedBox(height: 12),
                            Text('PDF 파일은 미리보기가 지원되지 않습니다.'),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Text('장비 등록', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 4),
          Text(
            '장비 유형을 선택하고, 서류를 업로드한 후 등록하세요.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: 24),

          // 1. 장비 유형 선택
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('장비 유형 선택', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedEquipmentType,
                  decoration: const InputDecoration(
                    labelText: '장비 유형 *',
                    hintText: '장비 유형을 선택하세요',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _eqRepo.typeNames
                      .map((type) =>
                          DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: _onEquipmentTypeChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. 서류 업로드 카드 목록
          if (_selectedEquipmentType != null) ...[
            _buildDocumentUploadSection(),
            const SizedBox(height: 20),
          ],

          // 3. 기본 정보 입력
          if (_selectedEquipmentType != null) ...[
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
          ],

          // 4. 등록 버튼
          if (_selectedEquipmentType != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canRegister() ? _completeRegistration : null,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('등록'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadSection() {
    final requiredDocs =
        _eqRepo.getRequiredDocuments(_selectedEquipmentType!);
    final uploadedCount =
        _uploadedDocs.values.where((d) => d.fileName != null).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('서류 업로드', style: AppTextStyles.headlineSmall),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: uploadedCount == requiredDocs.length
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$uploadedCount / ${requiredDocs.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: uploadedCount == requiredDocs.length
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$_selectedEquipmentType 유형의 필수 서류 ${requiredDocs.length}개를 업로드해 주세요. 첫번째 서류 업로드 시 OCR로 기본정보가 자동 입력됩니다.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(requiredDocs.length, (i) {
            final docName = requiredDocs[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildDocumentCard(i + 1, docName),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(int index, String docName) {
    final docType = _findDocType(docName);
    final uploaded = _uploadedDocs[docName];
    final hasFile = uploaded?.fileName != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasFile
            ? AppColors.success.withOpacity(0.03)
            : AppColors.greyLight,
        border: Border.all(
          color: hasFile
              ? AppColors.success.withOpacity(0.5)
              : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀 행: 번호 + 서류명 + 배지들
          _buildCardHeader(index, docName, docType),
          const SizedBox(height: 12),

          // 업로드 영역 또는 파일 정보
          if (!hasFile)
            _buildUploadArea(docName)
          else
            _buildUploadedFileInfo(docName, uploaded!),

          // 만료일 입력
          if (docType != null && docType.hasExpiryManagement && hasFile) ...[
            const SizedBox(height: 12),
            _buildExpiryDateField(docName, docType),
          ],

          // 검증 상태
          if (docType != null && docType.hasVerification && hasFile) ...[
            const SizedBox(height: 10),
            _buildVerificationStatus(uploaded!),
          ],
        ],
      ),
    );
  }

  Widget _buildCardHeader(int index, String docName, DocumentType? docType) {
    final uploaded = _uploadedDocs[docName];
    final hasFile = uploaded?.fileName != null;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        // 번호 원
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasFile
                ? AppColors.success.withOpacity(0.1)
                : AppColors.greyLight,
          ),
          child: Center(
            child: hasFile
                ? const Icon(Icons.check, size: 16, color: AppColors.success)
                : Text('$index',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey)),
          ),
        ),
        // 서류명
        Text(docName, style: AppTextStyles.titleMedium),
        // [필수] 배지
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            '필수',
            style: TextStyle(
                fontSize: 10,
                color: AppColors.error,
                fontWeight: FontWeight.w600),
          ),
        ),
        // 만료일 배지
        if (docType != null && docType.hasExpiryManagement)
          _buildBadge(
            '\u{1F4C5} ${docType.expiryFieldName.isNotEmpty ? docType.expiryFieldName : "만료일 관리"}',
            const Color(0xFFFF9800),
          ),
        // 검증기관 배지
        if (docType != null && docType.hasVerification)
          _buildBadge(
            '\u2705 ${docType.verificationProvider}',
            AppColors.success,
          ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildUploadArea(String docName) {
    return InkWell(
      onTap: () => _pickAndUploadFile(docName),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(8),
          color: AppColors.white,
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_upload_outlined,
                size: 32, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text('파일을 선택하세요',
                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text('JPG, PNG, PDF 지원',
                style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '파일 선택',
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadedFileInfo(
      String docName, UploadedEquipmentDocument doc) {
    final isImage = _isImageFile(doc.fileName ?? '');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.05),
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지 미리보기 / PDF 아이콘
          GestureDetector(
            onTap: () => _showImagePreview(doc),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(7)),
              child: SizedBox(
                width: 120,
                height: 100,
                child: isImage && doc.fileBytes != null
                    ? Image.memory(
                        doc.fileBytes!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.grey[100],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.picture_as_pdf,
                                size: 36, color: Colors.red),
                            const SizedBox(height: 4),
                            Text('PDF',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey[500])),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          // 파일 정보
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '파일명: ${doc.fileName ?? ""}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (doc.uploadedAt != null)
                    Text(
                      '업로드: ${doc.uploadedAt!.hour.toString().padLeft(2, '0')}:${doc.uploadedAt!.minute.toString().padLeft(2, '0')}',
                      style:
                          const TextStyle(fontSize: 11, color: AppColors.grey),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      InkWell(
                        onTap: () => _pickAndUploadFile(docName),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('변경',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _removeFile(docName),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('삭제',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryDateField(String docName, DocumentType docType) {
    final label = docType.expiryFieldName.isNotEmpty
        ? '만료일 (${docType.expiryFieldName})'
        : '만료일';
    return TextField(
      controller: _expiryControllers[docName],
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: '날짜를 선택하세요',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        suffixIcon: IconButton(
          icon: const Icon(Icons.date_range, size: 18),
          onPressed: () => _pickExpiryDate(docName),
        ),
      ),
      onTap: () => _pickExpiryDate(docName),
    );
  }

  Widget _buildVerificationStatus(UploadedEquipmentDocument doc) {
    final status = doc.verificationStatus;
    return Row(
      children: [
        const Text('검증: ',
            style: TextStyle(fontSize: 13, color: AppColors.greyDark)),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _verificationColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status == EquipmentVerificationStatus.verifying)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _verificationColor(status),
                    ),
                  ),
                ),
              Text(
                _verificationLabel(status),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _verificationColor(status),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _verificationLabel(EquipmentVerificationStatus status) {
    switch (status) {
      case EquipmentVerificationStatus.pending:
        return '\u23F3 대기중';
      case EquipmentVerificationStatus.verifying:
        return '\uD83D\uDD04 검증중';
      case EquipmentVerificationStatus.verified:
        return '\u2705 검증완료';
      case EquipmentVerificationStatus.failed:
        return '\u274C 검증실패';
    }
  }

  Color _verificationColor(EquipmentVerificationStatus status) {
    switch (status) {
      case EquipmentVerificationStatus.pending:
        return AppColors.warning;
      case EquipmentVerificationStatus.verifying:
        return AppColors.primary;
      case EquipmentVerificationStatus.verified:
        return AppColors.success;
      case EquipmentVerificationStatus.failed:
        return AppColors.error;
    }
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('기본 정보', style: AppTextStyles.headlineSmall),
              if (_ocrLoading) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text('OCR 분석 중...',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.primary)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'OCR로 자동 입력되거나 수동으로 입력하세요.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _vehicleNumberController,
            decoration: const InputDecoration(
              labelText: '차량번호 *',
              hintText: '예: 서울 01가 1234',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.directions_car_outlined),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _modelNameController,
            decoration: const InputDecoration(
              labelText: '모델명 *',
              hintText: '예: SCC8200',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.precision_manufacturing_outlined),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _manufacturerController,
            decoration: const InputDecoration(
              labelText: '제조사',
              hintText: '예: 삼성중공업',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.factory_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _manufacturingYearController,
            decoration: const InputDecoration(
              labelText: '제조년도',
              hintText: '예: 2022',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }
}
