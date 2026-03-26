import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';
import 'package:dio/dio.dart';

// Conditional imports for web platform
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

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

  // PDF viewer registration tracking
  final Set<String> _registeredPdfViewers = {};

  // Web platform detection
  bool _isWebPlatform = true;

  @override
  void initState() {
    super.initState();
    // Detect web platform
    try {
      html.window; // Will work on web
      _isWebPlatform = true;
    } catch (_) {
      _isWebPlatform = false;
    }
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

  String _getOriginalFilename(Map<String, dynamic> doc) {
    return doc['originalFilename']?.toString() ??
        doc['fileName']?.toString() ??
        doc['name']?.toString() ??
        '';
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

  String _getFileSize(Map<String, dynamic> doc) {
    final size = doc['fileSize'] ?? doc['file_size'] ?? doc['size'];
    if (size == null) return '-';
    final bytes = size is num ? size : num.tryParse(size.toString()) ?? 0;
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String _getUploadDate(Map<String, dynamic> doc) {
    return _formatDate(doc['createdAt'] ?? doc['created_at'] ?? doc['uploadedAt'] ?? doc['uploaded_at']);
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

  /// Detect file type from originalFilename extension
  String _detectFileType(Map<String, dynamic> doc) {
    final fileName = _getOriginalFilename(doc).toLowerCase();
    final contentType = (doc['contentType'] ?? doc['mimeType'] ?? '').toString().toLowerCase();

    if (fileName.endsWith('.pdf') || contentType.contains('pdf')) {
      return 'pdf';
    }
    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') ||
        fileName.endsWith('.png') || fileName.endsWith('.gif') ||
        fileName.endsWith('.bmp') || fileName.endsWith('.webp') ||
        contentType.startsWith('image/')) {
      return 'image';
    }
    if (fileName.endsWith('.doc') || fileName.endsWith('.docx') ||
        contentType.contains('word')) {
      return 'word';
    }
    if (fileName.endsWith('.xls') || fileName.endsWith('.xlsx') ||
        contentType.contains('spreadsheet') || contentType.contains('excel')) {
      return 'excel';
    }
    return 'other';
  }

  bool _isImageFile(Map<String, dynamic> doc) {
    return _detectFileType(doc) == 'image';
  }

  bool _isPdfFile(Map<String, dynamic> doc) {
    return _detectFileType(doc) == 'pdf';
  }

  void _openInNewTab(String url) {
    try {
      html.window.open(url, '_blank');
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('파일 URL: $url'), backgroundColor: AppColors.primary),
      );
    }
  }

  void _registerPdfViewer(String docId, String fileUrl) {
    final viewType = 'pdf-viewer-$docId';
    if (!_registeredPdfViewers.contains(viewType)) {
      try {
        ui_web.platformViewRegistry.registerViewFactory(
          viewType,
          (int viewId) => html.IFrameElement()
            ..src = fileUrl
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%',
        );
        _registeredPdfViewers.add(viewType);
      } catch (_) {
        // Registration may fail if already registered
      }
    }
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
              DataColumn(label: Text('파일형식')),
              DataColumn(label: Text('상태')),
              DataColumn(label: Text('만료일')),
            ],
            rows: _documents.map((doc) {
              final isSelected = _selectedDocument != null && _selectedDocument!['id'] == doc['id'];
              final status = _getDocStatus(doc);
              final fileType = _detectFileType(doc);
              return DataRow(
                selected: isSelected,
                onSelectChanged: (_) {
                  setState(() => _selectedDocument = doc);
                },
                cells: [
                  DataCell(Text(_getDocName(doc))),
                  DataCell(Text(_getDocType(doc))),
                  DataCell(_buildFileTypeBadge(fileType)),
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

  Widget _buildFileTypeBadge(String fileType) {
    final IconData icon;
    final Color color;
    final String label;
    switch (fileType) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        color = const Color(0xFFEF4444);
        label = 'PDF';
        break;
      case 'image':
        icon = Icons.image;
        color = AppColors.success;
        label = '이미지';
        break;
      case 'word':
        icon = Icons.description;
        color = AppColors.info;
        label = 'Word';
        break;
      case 'excel':
        icon = Icons.table_chart;
        color = const Color(0xFF22C55E);
        label = 'Excel';
        break;
      default:
        icon = Icons.insert_drive_file;
        color = AppColors.grey;
        label = '파일';
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
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
    final fileType = _detectFileType(doc);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and actions
          Row(
            children: [
              const Text('미리보기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
              const Spacer(),
              // Download button
              IconButton(
                icon: const Icon(Icons.download, size: 20, color: AppColors.primary),
                tooltip: '다운로드 (새 탭)',
                onPressed: () => _openInNewTab(fileUrl),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _selectedDocument = null),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 12),
          // Preview area based on file type
          if (fileType == 'image')
            _buildImagePreview(doc, fileUrl)
          else if (fileType == 'pdf')
            _buildPdfPreview(doc, fileUrl)
          else
            _buildGenericFilePreview(doc, fileUrl),
          const SizedBox(height: 16),
          // File metadata panel
          _buildMetadataPanel(doc),
        ],
      ),
    );
  }

  Widget _buildImagePreview(Map<String, dynamic> doc, String fileUrl) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFFF8FAFC),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
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
      ),
    );
  }

  Widget _buildPdfPreview(Map<String, dynamic> doc, String fileUrl) {
    final docId = doc['id']?.toString() ?? '';

    if (_isWebPlatform && docId.isNotEmpty) {
      // Register the PDF viewer for this document
      _registerPdfViewer(docId, fileUrl);
      final viewType = 'pdf-viewer-$docId';

      return Column(
        children: [
          Container(
            width: double.infinity,
            height: 500,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: HtmlElementView(viewType: viewType),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => _openInNewTab(fileUrl),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('새 탭에서 열기'),
              ),
            ],
          ),
        ],
      );
    }

    // Fallback for non-web or missing ID
    return Container(
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
            onPressed: () => _openInNewTab(fileUrl),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('PDF 보기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericFilePreview(Map<String, dynamic> doc, String fileUrl) {
    final fileType = _detectFileType(doc);
    final IconData icon;
    final Color color;
    switch (fileType) {
      case 'word':
        icon = Icons.description;
        color = AppColors.info;
        break;
      case 'excel':
        icon = Icons.table_chart;
        color = const Color(0xFF22C55E);
        break;
      default:
        icon = Icons.insert_drive_file;
        color = AppColors.grey;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFFF8FAFC),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 12),
          Text(
            _getOriginalFilename(doc).isNotEmpty ? _getOriginalFilename(doc) : '파일',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            '이 파일 형식은 인라인 미리보기를 지원하지 않습니다.',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _openInNewTab(fileUrl),
            icon: const Icon(Icons.download, size: 16),
            label: const Text('다운로드'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataPanel(Map<String, dynamic> doc) {
    final status = _getDocStatus(doc);
    return Container(
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
          const Text('파일 정보', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          _infoRow('파일명', _getOriginalFilename(doc).isNotEmpty ? _getOriginalFilename(doc) : _getDocName(doc)),
          _infoRow('파일 크기', _getFileSize(doc)),
          _infoRow('업로드일', _getUploadDate(doc)),
          _infoRow('유형', _getDocType(doc)),
          _infoRowWidget('상태', Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _statusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _statusColor(status))),
          )),
          _infoRow('만료일', _getExpiryDate(doc)),
          _infoRow('소유자 ID', doc['ownerId']?.toString() ?? '-'),
          _infoRow('소유자 유형', doc['ownerType']?.toString() ?? '-'),
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

  Widget _infoRowWidget(String label, Widget valueWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ),
          valueWidget,
        ],
      ),
    );
  }
}
