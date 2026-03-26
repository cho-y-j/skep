import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';
import 'package:dio/dio.dart';

class DocumentPreviewPage extends StatefulWidget {
  const DocumentPreviewPage({Key? key}) : super(key: key);

  @override
  State<DocumentPreviewPage> createState() => _DocumentPreviewPageState();
}

class _DocumentPreviewPageState extends State<DocumentPreviewPage> {
  List<Map<String, dynamic>> _documents = [];
  List<Map<String, dynamic>> _documentTypes = [];
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _selectedDocument;

  // 검색용
  final TextEditingController _ownerIdController = TextEditingController();
  String _ownerType = 'EQUIPMENT';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDocumentTypes();
      _loadDocuments();
    });
  }

  @override
  void dispose() {
    _ownerIdController.dispose();
    super.dispose();
  }

  Future<void> _loadDocumentTypes() async {
    try {
      final dioClient = context.read<DioClient>();
      final response = await dioClient.get<dynamic>(ApiEndpoints.documentTypes);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List) {
          _documentTypes = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['content'] is List) {
          _documentTypes = (data['content'] as List).cast<Map<String, dynamic>>();
        }
      }
    } catch (_) {
      // 유형 로드 실패는 무시
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dioClient = context.read<DioClient>();
      String endpoint;
      if (_ownerIdController.text.trim().isNotEmpty) {
        endpoint = '/api/documents/${_ownerIdController.text.trim()}/$_ownerType';
      } else {
        endpoint = ApiEndpoints.documents;
      }
      final response = await dioClient.get<dynamic>(endpoint);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List) {
          _documents = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['content'] is List) {
          _documents = (data['content'] as List).cast<Map<String, dynamic>>();
        } else if (data is Map && data['documents'] is List) {
          _documents = (data['documents'] as List).cast<Map<String, dynamic>>();
        } else {
          _documents = [];
        }
      }
    } catch (e) {
      _error = e.toString();
      _documents = [];
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getDocName(Map<String, dynamic> doc) {
    return doc['name']?.toString() ??
        doc['documentName']?.toString() ??
        doc['fileName']?.toString() ??
        '-';
  }

  String _getDocType(Map<String, dynamic> doc) {
    return doc['documentType']?.toString() ??
        doc['type']?.toString() ??
        doc['typeName']?.toString() ??
        '-';
  }

  String _getDocStatus(Map<String, dynamic> doc) {
    final status = doc['status']?.toString() ?? '';
    switch (status) {
      case 'VALID':
        return '유효';
      case 'EXPIRED':
        return '만료';
      case 'PENDING':
        return '대기';
      case 'REJECTED':
        return '반려';
      default:
        return status.isNotEmpty ? status : '-';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case '유효':
        return AppColors.success;
      case '만료':
        return AppColors.error;
      case '대기':
        return AppColors.warning;
      case '반려':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  String _getExpiryDate(Map<String, dynamic> doc) {
    return _formatDate(doc['expiryDate'] ?? doc['expiry_date'] ?? doc['expirationDate']);
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return date.toString();
    }
  }

  String _getFileUrl(Map<String, dynamic> doc) {
    final id = doc['id']?.toString() ?? '';
    return '${ApiEndpoints.baseUrl}/api/documents/$id/file';
  }

  bool _isImageFile(Map<String, dynamic> doc) {
    final fileName = (doc['fileName'] ?? doc['name'] ?? '').toString().toLowerCase();
    final contentType = (doc['contentType'] ?? doc['mimeType'] ?? '').toString().toLowerCase();
    return fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.png') ||
        fileName.endsWith('.gif') ||
        contentType.startsWith('image/');
  }

  void _showUploadDialog() {
    final ownerIdCtrl = TextEditingController();
    String ownerType = 'EQUIPMENT';
    String? selectedDocType;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('서류 업로드'),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: ownerIdCtrl,
                        decoration: const InputDecoration(
                          labelText: '소유자 ID',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: ownerType,
                        decoration: const InputDecoration(
                          labelText: '소유자 유형',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'EQUIPMENT', child: Text('장비')),
                          DropdownMenuItem(value: 'PERSON', child: Text('인력')),
                          DropdownMenuItem(value: 'COMPANY', child: Text('회사')),
                          DropdownMenuItem(value: 'DRIVER', child: Text('기사')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => ownerType = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedDocType,
                        decoration: const InputDecoration(
                          labelText: '서류 유형',
                          border: OutlineInputBorder(),
                        ),
                        items: _documentTypes.map((t) {
                          final code = t['code']?.toString() ?? t['id']?.toString() ?? '';
                          final name = t['name']?.toString() ?? t['typeName']?.toString() ?? code;
                          return DropdownMenuItem(value: code, child: Text(name));
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() => selectedDocType = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFFF8FAFC),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.cloud_upload_outlined, size: 40, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 8),
                            Text(
                              '파일 선택은 웹 환경에서 지원됩니다.\n파일을 드래그하거나 클릭하여 선택하세요.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('파일 업로드 기능은 웹 환경에서 지원됩니다.'),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('업로드'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '서류 관리 및 미리보기',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Text('서류를 조회하고 미리보기합니다.', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _loadDocuments,
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
                onPressed: _showUploadDialog,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('업로드'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 검색 필터
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _ownerIdController,
                    decoration: InputDecoration(
                      hintText: '소유자 ID로 검색...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    value: _ownerType,
                    decoration: InputDecoration(
                      labelText: '소유자 유형',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'EQUIPMENT', child: Text('장비')),
                      DropdownMenuItem(value: 'PERSON', child: Text('인력')),
                      DropdownMenuItem(value: 'COMPANY', child: Text('회사')),
                      DropdownMenuItem(value: 'DRIVER', child: Text('기사')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _ownerType = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _loadDocuments,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  child: const Text('검색'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 본문: 좌측 목록 + 우측 미리보기
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _buildDocumentList()),
                    const SizedBox(width: 16),
                    Expanded(flex: 5, child: _buildPreviewPanel()),
                  ],
                );
              }
              return Column(
                children: [
                  _buildDocumentList(),
                  const SizedBox(height: 16),
                  _buildPreviewPanel(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentList() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: _buildListContent(),
    );
  }

  Widget _buildListContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
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
              TextButton(onPressed: _loadDocuments, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }

    if (_documents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: const [
              Icon(Icons.description_outlined, size: 56, color: Color(0xFFCBD5E1)),
              SizedBox(height: 16),
              Text('등록된 서류가 없습니다', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text('총 ${_documents.length}건', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            headingTextStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            dataTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
            columns: const [
              DataColumn(label: Text('서류명')),
              DataColumn(label: Text('유형')),
              DataColumn(label: Text('상태')),
              DataColumn(label: Text('만료일')),
            ],
            rows: _documents.map((doc) {
              final isSelected = _selectedDocument != null && _selectedDocument!['id'] == doc['id'];
              final status = _getDocStatus(doc);
              return DataRow(
                selected: isSelected,
                onSelectChanged: (_) {
                  setState(() => _selectedDocument = doc);
                },
                cells: [
                  DataCell(Text(_getDocName(doc))),
                  DataCell(Text(_getDocType(doc))),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(status, style: TextStyle(color: _statusColor(status), fontSize: 12, fontWeight: FontWeight.w600)),
                  )),
                  DataCell(Text(_getExpiryDate(doc))),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewPanel() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: _selectedDocument == null
          ? Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.preview_outlined, size: 64, color: Color(0xFFCBD5E1)),
                    SizedBox(height: 16),
                    Text('서류를 선택하면 미리보기가 표시됩니다', style: TextStyle(fontSize: 15, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
            )
          : _buildPreviewContent(),
    );
  }

  Widget _buildPreviewContent() {
    final doc = _selectedDocument!;
    final fileUrl = _getFileUrl(doc);
    final isImage = _isImageFile(doc);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('미리보기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _selectedDocument = null),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 12),
          // 미리보기 영역
          if (isImage)
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 350),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFF8FAFC),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  fileUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) => Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.broken_image_outlined, size: 48, color: Color(0xFFCBD5E1)),
                        SizedBox(height: 8),
                        Text('이미지를 불러올 수 없습니다', style: TextStyle(color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFF8FAFC),
              ),
              child: Column(
                children: [
                  const Icon(Icons.picture_as_pdf_outlined, size: 48, color: Color(0xFFEF4444)),
                  const SizedBox(height: 12),
                  const Text('PDF 파일', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                  const SizedBox(height: 8),
                  SelectableText(
                    fileUrl,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF2196F3), decoration: TextDecoration.underline),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      // 웹에서는 url_launcher 사용 가능
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('파일 URL: $fileUrl'), backgroundColor: AppColors.primary),
                      );
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('새 탭에서 열기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          // 문서 메타데이터
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('문서 정보', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                const SizedBox(height: 12),
                _infoRow('서류명', _getDocName(doc)),
                _infoRow('유형', _getDocType(doc)),
                _infoRow('상태', _getDocStatus(doc)),
                _infoRow('만료일', _getExpiryDate(doc)),
                _infoRow('소유자 ID', doc['ownerId']?.toString() ?? '-'),
                _infoRow('소유자 유형', doc['ownerType']?.toString() ?? '-'),
                _infoRow('등록일', _formatDate(doc['createdAt'] ?? doc['created_at'])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
        ],
      ),
    );
  }
}
