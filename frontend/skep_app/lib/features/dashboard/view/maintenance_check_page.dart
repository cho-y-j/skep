import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MaintenanceCheckPage extends StatefulWidget {
  const MaintenanceCheckPage({Key? key}) : super(key: key);

  @override
  State<MaintenanceCheckPage> createState() => _MaintenanceCheckPageState();
}

class _MaintenanceHistory {
  final DateTime date;
  final String equipment;
  final int mileage;
  final String status;

  const _MaintenanceHistory({
    required this.date,
    required this.equipment,
    required this.mileage,
    required this.status,
  });

  Color get statusColor {
    switch (status) {
      case '정상':
        return const Color(0xFF16A34A);
      case '보충필요':
        return const Color(0xFFD97706);
      case '점검필요':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF94A3B8);
    }
  }
}

class _MaintenanceCheckPageState extends State<MaintenanceCheckPage> {
  bool _nfcScanned = false;
  final _formKey = GlobalKey<FormState>();
  final _mileageController = TextEditingController();
  final _remarksController = TextEditingController();
  String _engineOil = '정상';
  String _hydraulicOil = '정상';
  String _coolant = '정상';
  double _fuelLevel = 50.0;
  bool _showForm = true;

  final List<_MaintenanceHistory> _history = [
    _MaintenanceHistory(
      date: DateTime.now().subtract(const Duration(days: 1)),
      equipment: '25톤 크레인 (서울 가 1234)',
      mileage: 45230,
      status: '정상',
    ),
    _MaintenanceHistory(
      date: DateTime.now().subtract(const Duration(days: 2)),
      equipment: '25톤 크레인 (서울 가 1234)',
      mileage: 45100,
      status: '보충필요',
    ),
    _MaintenanceHistory(
      date: DateTime.now().subtract(const Duration(days: 3)),
      equipment: '50톤 크레인 (경기 나 5678)',
      mileage: 32400,
      status: '정상',
    ),
    _MaintenanceHistory(
      date: DateTime.now().subtract(const Duration(days: 5)),
      equipment: '굴삭기 (서울 다 9012)',
      mileage: 18900,
      status: '점검필요',
    ),
  ];

  @override
  void dispose() {
    _mileageController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _buildToggleButton('정비점검 입력', _showForm, () => setState(() => _showForm = true)),
                      _buildToggleButton('제출 이력', !_showForm, () => setState(() => _showForm = false)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_showForm) _buildFormSection() else _buildHistorySection(),
          ],
        ),
      ),
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

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // NFC 스캔 영역
        GestureDetector(
          onTap: () {
            setState(() => _nfcScanned = true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('NFC 스캔 완료: 25톤 크레인 (서울 가 1234)'),
                backgroundColor: Color(0xFF16A34A),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _nfcScanned
                  ? const Color(0xFF16A34A).withOpacity(0.05)
                  : const Color(0xFF2196F3).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _nfcScanned
                    ? const Color(0xFF16A34A).withOpacity(0.3)
                    : const Color(0xFF2196F3).withOpacity(0.3),
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _nfcScanned ? Icons.check_circle : Icons.nfc,
                  size: 48,
                  color: _nfcScanned ? const Color(0xFF16A34A) : const Color(0xFF2196F3),
                ),
                const SizedBox(height: 12),
                Text(
                  _nfcScanned ? 'NFC 스캔 완료' : '여기를 탭하여 NFC 스캔 시작',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _nfcScanned ? const Color(0xFF16A34A) : const Color(0xFF2196F3),
                  ),
                ),
                if (_nfcScanned)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      '25톤 크레인 (서울 가 1234)',
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                  ),
                if (!_nfcScanned)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      '장비 NFC 태그에 휴대폰을 가까이 대세요',
                      style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // 점검 폼
        AnimatedOpacity(
          opacity: _nfcScanned ? 1.0 : 0.4,
          duration: const Duration(milliseconds: 300),
          child: IgnorePointer(
            ignoring: !_nfcScanned,
            child: Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '정비점검표',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 20),
                    // 주행거리
                    _buildFieldLabel('주행거리 (키로수)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _mileageController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('예: 45230'),
                      validator: (v) => (v == null || v.isEmpty) ? '주행거리를 입력하세요' : null,
                    ),
                    const SizedBox(height: 16),
                    // 엔진오일
                    _buildFieldLabel('엔진오일'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _engineOil,
                      decoration: _inputDecoration(''),
                      items: ['정상', '보충필요', '교체필요']
                          .map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 14))))
                          .toList(),
                      onChanged: (v) => setState(() => _engineOil = v ?? '정상'),
                    ),
                    const SizedBox(height: 16),
                    // 유압오일
                    _buildFieldLabel('유압오일'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _hydraulicOil,
                      decoration: _inputDecoration(''),
                      items: ['정상', '보충필요', '교체필요']
                          .map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 14))))
                          .toList(),
                      onChanged: (v) => setState(() => _hydraulicOil = v ?? '정상'),
                    ),
                    const SizedBox(height: 16),
                    // 냉각수
                    _buildFieldLabel('냉각수'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _coolant,
                      decoration: _inputDecoration(''),
                      items: ['정상', '보충필요']
                          .map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 14))))
                          .toList(),
                      onChanged: (v) => setState(() => _coolant = v ?? '정상'),
                    ),
                    const SizedBox(height: 16),
                    // 연료잔량
                    _buildFieldLabel('연료잔량: ${_fuelLevel.round()}%'),
                    const SizedBox(height: 6),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: _fuelLevel < 20
                            ? const Color(0xFFDC2626)
                            : _fuelLevel < 50
                                ? const Color(0xFFD97706)
                                : const Color(0xFF16A34A),
                        thumbColor: const Color(0xFF2196F3),
                        overlayColor: const Color(0xFF2196F3).withOpacity(0.1),
                      ),
                      child: Slider(
                        value: _fuelLevel,
                        min: 0,
                        max: 100,
                        divisions: 20,
                        label: '${_fuelLevel.round()}%',
                        onChanged: (v) => setState(() => _fuelLevel = v),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 특이사항
                    _buildFieldLabel('특이사항'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _remarksController,
                      maxLines: 3,
                      decoration: _inputDecoration('특이사항이 있으면 입력하세요'),
                    ),
                    const SizedBox(height: 16),
                    // 사진 첨부
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 제출 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _showConfirmDialog(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('제출', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  void _showConfirmDialog() {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('정비점검 제출 확인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('장비: 25톤 크레인 (서울 가 1234)', style: TextStyle(fontSize: 14)),
            Text('주행거리: ${_mileageController.text} km', style: const TextStyle(fontSize: 14)),
            Text('엔진오일: $_engineOil', style: const TextStyle(fontSize: 14)),
            Text('유압오일: $_hydraulicOil', style: const TextStyle(fontSize: 14)),
            Text('냉각수: $_coolant', style: const TextStyle(fontSize: 14)),
            Text('연료잔량: ${_fuelLevel.round()}%', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            const Text('제출하시겠습니까?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _nfcScanned = false;
                _mileageController.clear();
                _remarksController.clear();
                _engineOil = '정상';
                _hydraulicOil = '정상';
                _coolant = '정상';
                _fuelLevel = 50.0;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('정비점검이 제출되었습니다.'), backgroundColor: Color(0xFF16A34A)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('제출'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          headingTextStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          dataTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
          columns: const [
            DataColumn(label: Text('날짜')),
            DataColumn(label: Text('장비')),
            DataColumn(label: Text('키로수')),
            DataColumn(label: Text('상태')),
          ],
          rows: _history.map((h) {
            return DataRow(cells: [
              DataCell(Text(DateFormat('yyyy-MM-dd').format(h.date))),
              DataCell(Text(h.equipment)),
              DataCell(Text('${h.mileage} km')),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: h.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    h.status,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: h.statusColor),
                  ),
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
