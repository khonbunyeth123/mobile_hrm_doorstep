import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'dart:io';
import '../services/attendance_service.dart';

class MenuScanScreen extends StatefulWidget {
  const MenuScanScreen({super.key});

  @override
  State<MenuScanScreen> createState() => _MenuScanScreenState();
}

class _MenuScanScreenState extends State<MenuScanScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _scanComplete = false;
  bool _isFlashOn = false;
  bool _isSubmitting = false;
  String? _apiMessage;
  String? _employeeName;
  bool _apiSuccess = false;

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      if (Platform.isAndroid) {
        controller!.pauseCamera();
      } else if (Platform.isIOS) {
        controller!.resumeCamera();
      }
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (_scanComplete || scanData.code == null) return;

      setState(() {
        _scanComplete = true;
        _isSubmitting = true;
      });

      try {
        await controller.pauseCamera();
      } catch (_) {}

      try {
        final result = await AttendanceService.scan(scanData.code!);
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
          _apiSuccess = result['success'] == true;
          _employeeName = result['employee_name'];
          if (_apiSuccess) {
            final label = result['label'] ?? 'Recorded';
            final time = result['time'] ?? '';
            _apiMessage = '$label at $time';
          } else {
            _apiMessage = result['message'] ?? 'Failed to record attendance';
          }
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
          _apiSuccess = false;
          _apiMessage = 'Connection error. Please try again.';
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_apiMessage ?? 'Done'),
          backgroundColor: _apiSuccess ? Colors.green : Colors.red,
        ),
      );
    });
  }

  void _resetScan() {
    setState(() {
      _scanComplete = false;
      _apiMessage = null;
      _employeeName = null;
      _apiSuccess = false;
      _isSubmitting = false;
    });
    controller?.resumeCamera();
  }

  void _toggleFlash() {
    setState(() => _isFlashOn = !_isFlashOn);
    controller?.toggleFlash();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Attendance Scanner'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_scanComplete)
            IconButton(
              icon: Icon(
                _isFlashOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
              onPressed: _toggleFlash,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ── Scanner / Result area ──────────────────────────────────────
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Stack(
                    children: [
                      // ── Success / Fail screen ────────────────────────────
                      if (_scanComplete)
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _apiSuccess
                                  ? [
                                      Colors.green.withValues(alpha: 0.8),
                                      Colors.green.withValues(alpha: 0.4),
                                    ]
                                  : [
                                      Colors.red.withValues(alpha: 0.8),
                                      Colors.red.withValues(alpha: 0.4),
                                    ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Center(
                            child: _isSubmitting
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _apiSuccess
                                            ? Icons.check_circle
                                            : Icons.error,
                                        color: Colors.white,
                                        size: 64,
                                      ),
                                      const SizedBox(height: 16),
                                      // Employee name from token
                                      if (_employeeName != null) ...[
                                        Text(
                                          _employeeName!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      Text(
                                        _apiSuccess
                                            ? 'Attendance Recorded!'
                                            : 'Failed!',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (_apiMessage != null) ...[
                                        const SizedBox(height: 8),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                          ),
                                          child: Text(
                                            _apiMessage!,
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.9,
                                              ),
                                              fontSize: 14,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                        )
                      // ── Camera view ──────────────────────────────────────
                      else
                        QRView(
                          key: qrKey,
                          onQRViewCreated: _onQRViewCreated,
                          overlay: QrScannerOverlayShape(
                            borderColor: Colors.orange,
                            borderRadius: 12,
                            borderLength: 30,
                            borderWidth: 8,
                            cutOutSize: 250,
                            overlayColor: Colors.black.withValues(alpha: 0.8),
                          ),
                        ),

                      // ── Instruction overlay ──────────────────────────────
                      if (!_scanComplete)
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Point camera at the attendance QR code',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Instruction banner (before scan) ───────────────────────────
            if (!_scanComplete)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Scan the QR code to check in or check out',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Result info card (after scan) ──────────────────────────────
            if (_scanComplete && !_isSubmitting)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _apiSuccess ? Icons.check_circle : Icons.error,
                          color: _apiSuccess ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _apiSuccess ? 'Success' : 'Failed',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _apiSuccess ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    if (_employeeName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _employeeName!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (_apiMessage != null)
                      Text(
                        _apiMessage!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Scanned at: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // ── Scan Again button ──────────────────────────────────────────
            if (_scanComplete)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _resetScan,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text(
                    'Scan Again',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
