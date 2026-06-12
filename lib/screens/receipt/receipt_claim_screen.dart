import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../config/app_config.dart';
import '../../config/malaysian_states.dart';
import '../../config/routes.dart';
import '../../config/web_hash_route.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Public e-invoice claim (portal-style): receipt → buyer form → LHDN submit → status.
class ReceiptClaimScreen extends StatefulWidget {
  final String receiptNo;
  final String? tenantId;

  const ReceiptClaimScreen({
    super.key,
    required this.receiptNo,
    this.tenantId,
  });

  @override
  State<ReceiptClaimScreen> createState() => _ReceiptClaimScreenState();
}

class _ReceiptClaimScreenState extends State<ReceiptClaimScreen> {
  final _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    headers: {'Content-Type': 'application/json'},
  ));

  int _step = 0;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  Map<String, dynamic>? _receipt;

  String _claimantType = 'individual';
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _ic = TextEditingController();
  final _tin = TextEditingController();
  final _brn = TextEditingController();
  final _sst = TextEditingController();
  final _address1 = TextEditingController();
  final _address2 = TextEditingController();
  final _postcode = TextEditingController();
  final _city = TextEditingController();
  String _stateCode = '10';

  Map<String, dynamic>? _submissionStatus;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadReceipt();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _ic.dispose();
    _tin.dispose();
    _brn.dispose();
    _sst.dispose();
    _address1.dispose();
    _address2.dispose();
    _postcode.dispose();
    _city.dispose();
    super.dispose();
  }

  String get _tenantQuery =>
      widget.tenantId != null ? '?tenant=${widget.tenantId}' : '';

  Future<void> _loadReceipt() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _dio.get(
        '/public/receipts/${Uri.encodeComponent(widget.receiptNo)}$_tenantQuery',
      );
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _receipt = data;
        _loading = false;
        if (data['claim_submitted'] == true ||
            data['invoice_status'] == 'accepted') {
          _step = 4;
          _fetchStatus();
        }
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Receipt not found. Complete checkout and ensure backend is running.';
      });
    }
  }

  Future<void> _fetchStatus() async {
    try {
      final res = await _dio.get(
        '/public/receipts/${Uri.encodeComponent(widget.receiptNo)}/status$_tenantQuery',
      );
      if (mounted) {
        setState(() => _submissionStatus = res.data as Map<String, dynamic>);
      }
    } catch (_) {}
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _fetchStatus();
      final status = _submissionStatus?['status']?.toString() ?? '';
      if (status == 'Valid' || status == 'Invalid') {
        _pollTimer?.cancel();
        if (mounted) {
          setState(() => _step = 4);
          if (status == 'Valid') {
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) _returnToPos();
            });
          }
        }
      }
    });
  }

  bool get _formValid {
    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty) return false;
    if (_address1.text.trim().isEmpty || _postcode.text.trim().isEmpty) return false;
    if (_city.text.trim().isEmpty) return false;
    if (_claimantType == 'individual') {
      return _ic.text.trim().length >= 12;
    }
    return _tin.text.trim().isNotEmpty && _brn.text.trim().isNotEmpty;
  }

  /// Backend Zod schema expects strings, not null, for optional fields.
  String _optionalField(String value) => value.trim();

  Map<String, dynamic> _claimPayload() {
    final isIndividual = _claimantType == 'individual';
    return {
      'claimant_type': _claimantType,
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
      'ic': isIndividual ? _ic.text.trim() : '',
      'tin': isIndividual ? '' : _tin.text.trim(),
      'brn': isIndividual ? '' : _brn.text.trim(),
      'sst': isIndividual ? '' : _sst.text.trim(),
      'address_line1': _address1.text.trim(),
      'address_line2': _optionalField(_address2.text),
      'postcode': _postcode.text.trim(),
      'city': _city.text.trim(),
      'state_code': _stateCode,
      'country_code': 'MY',
    };
  }

  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
      final error = data['error'];
      if (error is String && error.isNotEmpty) return error;
    }
    return 'Claim failed. Please check your details and try again.';
  }

  Future<void> _submitClaim() async {
    setState(() {
      _submitting = true;
      _step = 3;
    });
    try {
      await _dio.post(
        '/public/receipts/${Uri.encodeComponent(widget.receiptNo)}/claim$_tenantQuery',
        data: _claimPayload(),
      );
      await _fetchStatus();
      _startPolling();
      if (mounted) {
        final st = _submissionStatus?['status']?.toString() ?? '';
        setState(() => _step = (st == 'Valid' || st == 'Invalid') ? 4 : 3);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is DioException ? _extractErrorMessage(e) : 'Claim failed',
            ),
          ),
        );
        setState(() => _step = 1);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _returnToPos() {
    if (kIsWeb) {
      setWebHashRoute(AppRoutes.cashier);
    }
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed(AppRoutes.cashier);
    }
  }

  static const _primary = Color(0xFF4F46E5);
  static const _primarySoft = Color(0xFFEEF2FF);
  static const _text = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _surface = Color(0xFFF9FAFB);

  ThemeData get _portalTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: _text),
          bodyLarge: TextStyle(color: _text),
          titleMedium: TextStyle(color: _text, fontWeight: FontWeight.w600),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surface,
          labelStyle: const TextStyle(color: _muted, fontSize: 13),
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _primary, width: 2),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _portalTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.white,
          foregroundColor: _text,
          title: const Text(
            'E-Invoice claim',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _border),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _returnToPos,
          ),
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _primary))
              : _error != null
                  ? _errorView()
                  : Column(
                      children: [
                        if (_step < 3) _stepIndicator(),
                        Expanded(child: _buildStep()),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _stepIndicator() {
    const labels = ['Receipt', 'Your details', 'Confirm'];
    final active = _step.clamp(0, 2);

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Row(
            children: List.generate(labels.length * 2 - 1, (i) {
              if (i.isOdd) {
                final stepIndex = i ~/ 2;
                return Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 18),
                    color: stepIndex < active ? _primary : _border,
                  ),
                );
              }
              final stepIndex = i ~/ 2;
              final done = stepIndex < active;
              final current = stepIndex == active;
              return Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done || current ? _primary : Colors.white,
                      border: Border.all(
                        color: done || current ? _primary : _border,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: done
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : Text(
                              '${stepIndex + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: current ? Colors.white : _muted,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[stepIndex],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: current ? FontWeight.w600 : FontWeight.w500,
                      color: current ? _primary : _muted,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _receiptStep();
      case 1:
        return _claimFormStep();
      case 2:
        return _confirmationStep();
      case 3:
        return _processingStep();
      case 4:
        return _einvoiceStep();
      default:
        return _receiptStep();
    }
  }

  Widget _receiptStep() {
    final supplier = _receipt!['supplier'] as Map<String, dynamic>;
    final items = _receipt!['items'] as List<dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _primarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.storefront_outlined, color: _primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Merchant (Supplier)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _muted,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                supplier['company_name'] as String? ?? '',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    if (supplier['sst_registration_no'] != null)
                      _supplierRow('SST', supplier['sst_registration_no']),
                    _supplierRow('Phone', supplier['phone']),
                    _supplierRow('Email', supplier['email']),
                    _supplierRow('Address', _formatAddress(supplier)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Receipt',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _primarySoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.receiptNo,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 14, color: _muted),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(_receipt!['issue_date']),
                          style: const TextStyle(color: _muted, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _itemsTable(items),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        children: [
                          _totalRow('Subtotal', _receipt!['subtotal']),
                          _totalRow('Tax (SST)', _receipt!['tax_amount']),
                          const Divider(height: 20),
                          _totalRow('Total', _receipt!['total_amount'], bold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _step = 1),
                        icon: const Icon(Icons.receipt_long_outlined, size: 20),
                        label: const Text('Request E-Invoice'),
                        style: _primaryButtonStyle(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _claimFormStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Claimant type', 'Who is requesting this e-invoice?'),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _typeChip('individual', 'Individual', Icons.person_outline)),
                        const SizedBox(width: 12),
                        Expanded(child: _typeChip('business', 'Business', Icons.business_outlined)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                      _claimantType == 'business'
                          ? 'Buyer company details'
                          : 'Your personal details',
                      'Required for LHDN MyInvois submission',
                    ),
                    const SizedBox(height: 16),
                    _field(
                      _name,
                      _claimantType == 'business' ? 'Company name' : 'Full name',
                      icon: _claimantType == 'business' ? Icons.business : Icons.badge_outlined,
                    ),
                    if (_claimantType == 'individual')
                      _field(_ic, 'IC / NRIC (12 digits)', icon: Icons.credit_card_outlined,
                          keyboard: TextInputType.number),
                    if (_claimantType == 'business') ...[
                      _field(_tin, 'TIN', icon: Icons.numbers),
                      _field(_brn, 'Company registration no (BRN)', icon: Icons.apartment),
                      _field(_sst, 'SST (optional)', icon: Icons.receipt_outlined),
                    ],
                    _field(_email, 'Email', icon: Icons.email_outlined,
                        keyboard: TextInputType.emailAddress),
                    _field(_phone, 'Mobile number', icon: Icons.phone_outlined,
                        keyboard: TextInputType.phone),
                    _sectionSubtitle('Billing address'),
                    _field(_address1, 'Address line 1', icon: Icons.home_outlined),
                    _field(_address2, 'Address line 2 (optional)', icon: Icons.home_work_outlined),
                    Row(
                      children: [
                        Expanded(child: _field(_postcode, 'Postcode', keyboard: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: _field(_city, 'City')),
                      ],
                    ),
                    DropdownButtonFormField<String>(
                      value: _stateCode,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        prefixIcon: Icon(Icons.map_outlined, size: 20),
                      ),
                      items: kMalaysianStates
                          .map((s) => DropdownMenuItem(
                                value: s.code,
                                child: Text(s.name),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _stateCode = v ?? _stateCode),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _step = 0),
                            style: _outlineButtonStyle(),
                            child: const Text('Back'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _formValid ? () => setState(() => _step = 2) : null,
                            style: _primaryButtonStyle(),
                            child: const Text('Continue'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _confirmationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(
                  'Confirm details',
                  'Review your information before submitting to LHDN MyInvois.',
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    children: [
                      _confirmRow('Type', _claimantType == 'business' ? 'Business' : 'Individual'),
                      _confirmRow('Name', _name.text.trim()),
                      if (_claimantType == 'individual') _confirmRow('IC', _ic.text.trim()),
                      if (_claimantType == 'business') ...[
                        _confirmRow('TIN', _tin.text.trim()),
                        _confirmRow('BRN', _brn.text.trim()),
                        if (_sst.text.trim().isNotEmpty) _confirmRow('SST', _sst.text.trim()),
                      ],
                      _confirmRow('Email', _email.text.trim()),
                      _confirmRow('Phone', _phone.text.trim()),
                      _confirmRow(
                        'Address',
                        '${_address1.text.trim()}${_address2.text.trim().isEmpty ? '' : ', ${_address2.text.trim()}'}, ${_postcode.text.trim()} ${_city.text.trim()}, ${malaysianStateName(_stateCode)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting ? null : () => setState(() => _step = 1),
                        style: _outlineButtonStyle(),
                        child: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submitClaim,
                        style: _primaryButtonStyle(),
                        child: _submitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Submit to MyInvois'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: const TextStyle(color: _muted, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, color: _text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _processingStep() {
    return Center(
      child: _card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Submitting to LHDN MyInvois…',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Receipt ${widget.receiptNo}',
                style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _einvoiceStep() {
    final status = _submissionStatus?['status']?.toString() ?? '';
    final isValid = status == 'Valid';
    final isInvalid = status == 'Invalid';
    final qrUrl = _submissionStatus?['qr_code_url'] as String?;
    final uuid = _submissionStatus?['uuid'] as String?;
    final longId = _submissionStatus?['long_id'] as String?;
    final items = (_submissionStatus?['receipt']?['items'] ?? _receipt!['items']) as List;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              _card(
                child: Column(
                  children: [
                    Icon(
                      isValid
                          ? Icons.check_circle
                          : isInvalid
                              ? Icons.error
                              : Icons.hourglass_top,
                      size: 56,
                      color: isValid
                          ? Colors.green
                          : isInvalid
                              ? Colors.red
                              : Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isValid
                          ? 'E-Invoice validated'
                          : isInvalid
                              ? 'Validation failed'
                              : 'Processing…',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (isInvalid)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _formatLhdnError(_submissionStatus),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    if (isValid)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Redirecting to POS…',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.green.shade700, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Receipt details',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('No: ${widget.receiptNo}'),
                    _itemsTable(items),
                    _totalRow('Total',
                        _receipt!['total_amount'] ?? _submissionStatus?['receipt']?['total_amount'],
                        bold: true),
                  ],
                ),
              ),
              if (qrUrl != null && qrUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                _card(
                  child: Column(
                    children: [
                      const Text('LHDN validation QR',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Image.network(qrUrl, height: 180, errorBuilder: (_, __, ___) =>
                          QrImageView(data: qrUrl, size: 160)),
                      if (uuid != null && longId != null)
                        TextButton(
                          onPressed: () => launchUrl(
                            Uri.parse(
                                'https://myinvois.hasil.gov.my/$uuid/share/$longId'),
                            mode: LaunchMode.externalApplication,
                          ),
                          child: const Text('View on MyInvois'),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (isValid)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _returnToPos,
                    icon: const Icon(Icons.point_of_sale),
                    label: const Text('Back to POS'),
                    style: _primaryButtonStyle(),
                  ),
                ),
              if (!isValid) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showPrintableReceipt(items),
                        icon: const Icon(Icons.print),
                        label: const Text('Print receipt'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _fetchStatus,
                        style: _primaryButtonStyle(),
                        child: const Text('Refresh status'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _step = 1),
                    style: _outlineButtonStyle(),
                    child: const Text('Edit details & retry'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showPrintableReceipt(List items) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Print receipt'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_receipt!['supplier']?['company_name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Receipt: ${widget.receiptNo}'),
                const Divider(),
                ...items.map((raw) {
                  final it = raw as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${it['description']}  ${it['quantity']} x ${(it['unit_price'] as num).toStringAsFixed(2)} = ${(it['line_total'] as num).toStringAsFixed(2)}',
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() => ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFC7D2FE),
        disabledForegroundColor: Colors.white70,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      );

  ButtonStyle _outlineButtonStyle() => OutlinedButton.styleFrom(
        foregroundColor: _text,
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: _border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _text),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: _muted, fontSize: 13)),
      ],
    );
  }

  Widget _sectionSubtitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _muted,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _typeChip(String value, String label, IconData icon) {
    final selected = _claimantType == value;
    return InkWell(
      onTap: () => setState(() => _claimantType = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? _primary : _border,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: selected ? _primarySoft : Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? _primary : _muted),
            const SizedBox(width: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? _primary : _text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    IconData? icon,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: _text),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, size: 20, color: _muted) : null,
        ),
      ),
    );
  }

  Widget _supplierRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(color: _muted, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: const TextStyle(fontSize: 13, color: _text, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemsTable(List items) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1.2),
        3: FlexColumnWidth(1.2),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          children: const [
            Padding(padding: EdgeInsets.all(10), child: Text('Item', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: _muted))),
            Padding(padding: EdgeInsets.all(10), child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: _muted))),
            Padding(padding: EdgeInsets.all(10), child: Text('Unit', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: _muted))),
            Padding(padding: EdgeInsets.all(10), child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: _muted))),
          ],
        ),
        ...items.map((raw) {
          final it = raw as Map<String, dynamic>;
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(it['description'] as String? ?? ''),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('${it['quantity']}', textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  (it['unit_price'] as num).toStringAsFixed(2),
                  textAlign: TextAlign.right,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  (it['line_total'] as num).toStringAsFixed(2),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _totalRow(String label, dynamic amount, {bool bold = false}) {
    final v = (amount as num?)?.toStringAsFixed(2) ?? '0.00';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: bold ? _text : _muted,
              fontSize: bold ? 16 : 14,
            ),
          ),
          Text(
            'RM $v',
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: bold ? _primary : _text,
              fontSize: bold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAddress(Map<String, dynamic> s) {
    final stateCode = s['state_code']?.toString() ?? '';
    return [
      s['address_line1'],
      s['address_line2'],
      '${s['postcode'] ?? ''} ${s['city'] ?? ''}'.trim(),
      stateCode.isEmpty ? null : malaysianStateName(stateCode),
    ].where((e) => e != null && e.toString().isNotEmpty).join(', ');
  }

  String _formatLhdnError(dynamic status) {
    if (status is! Map) {
      return 'LHDN rejected this e-invoice. Please verify your IC/TIN is registered with LHDN and try again.';
    }

    final fromSteps = _extractLhdnStepError(status['validation_results']);
    if (fromSteps != null) return fromSteps;

    final raw = status['error_message'];
    if (raw == null) {
      return 'LHDN rejected this e-invoice. Please verify your IC/TIN is registered with LHDN and try again.';
    }

    if (raw is Map) {
      final nested = _extractLhdnStepError(raw);
      if (nested != null) return nested;
    }

    final text = raw.toString();
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        final nested = _extractLhdnStepError(decoded);
        if (nested != null) return nested;
      }
    } catch (_) {}

    if (text.length > 220) return '${text.substring(0, 220)}…';
    return text;
  }

  String? _extractLhdnStepError(dynamic decoded) {
    if (decoded is! Map) return null;
    final steps = decoded['validationSteps'];
    if (steps is! List) return null;

    for (final step in steps) {
      if (step is! Map || step['status'] != 'Invalid') continue;
      final inner = step['validationResults'];
      if (inner is! List) continue;
      for (final result in inner) {
        if (result is Map && result['error'] is Map) {
          final err = result['error'] as Map;
          final msg = err['message']?.toString();
          final code = err['code']?.toString();
          if (msg != null && msg.isNotEmpty) {
            return code != null ? '[$code] $msg' : msg;
          }
        }
      }
    }
    return null;
  }

  String _formatDate(dynamic d) {
    if (d == null) return '';
    try {
      final dt = DateTime.parse(d.toString()).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day/$month/${dt.year} $hour:$minute';
    } catch (_) {
      return d.toString();
    }
  }
}
