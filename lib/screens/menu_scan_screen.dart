import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import '../services/attendance_service.dart';
import '../theme/app_theme.dart';

class MenuScanScreen extends StatefulWidget {
  const MenuScanScreen({super.key});

  @override
  State<MenuScanScreen> createState() => _MenuScanScreenState();
}

class _MenuScanScreenState extends State<MenuScanScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  
  // States: 'scanning', 'loading', 'result'
  String _uiState = 'scanning';
  bool _isFlashOn = false;
  
  Map<String, dynamic>? _resultData;
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
      if (_uiState != 'scanning' || scanData.code == null) return;

      setState(() => _uiState = 'loading');

      try {
        await controller.pauseCamera();
      } catch (_) {}

      try {
        final result = await AttendanceService.scan(scanData.code!);
        if (!mounted) return;
        
        setState(() {
          _apiSuccess = result['success'] == true;
          _resultData = result;
          _uiState = 'result';
        });

        if (_apiSuccess) {
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.heavyImpact();
        }
        
        _showResultSheet();
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _apiSuccess = false;
          _uiState = 'result';
        });
        HapticFeedback.heavyImpact();
        _showResultSheet();
      }
    });
  }

  void _resetScan() {
    setState(() {
      _uiState = 'scanning';
      _resultData = null;
      _apiSuccess = false;
    });
    controller?.resumeCamera();
  }

  void _toggleFlash() {
    setState(() => _isFlashOn = !_isFlashOn);
    controller?.toggleFlash();
  }

  void _showResultSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _buildResultSheet(),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Widget _buildResultSheet() {
    final color = _apiSuccess ? AppTheme.success : AppTheme.danger;
    final icon = _apiSuccess ? Icons.check_circle_rounded : Icons.error_rounded;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 64),
          const SizedBox(height: 16),
          Text(_apiSuccess ? 'Success' : 'Scan Failed',
              style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          if (_resultData?['employee_name'] != null) ...[
            const SizedBox(height: 8),
            Text(_resultData!['employee_name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ],
          const SizedBox(height: 8),
          Text(
            _apiSuccess 
              ? '${_resultData!['label'] ?? 'Recorded'} at ${_resultData!['time'] ?? ''}'
              : (_resultData?['message'] ?? 'Connection error. Please try again.'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _resetScan();
              },
              child: const Text('Scan Again'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.3),
        elevation: 0,
        title: const Text('Attendance Scanner', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded, color: Colors.white),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: AppTheme.brand,
              borderRadius: 16,
              borderLength: 30,
              borderWidth: 8,
              cutOutSize: 260,
              overlayColor: Colors.black.withValues(alpha: 0.75),
            ),
          ),
          
          // Instruction Text
          Positioned(
            top: MediaQuery.of(context).size.height / 2 + 150,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                'Align the QR code inside the frame',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          // Loading Overlay
          if (_uiState == 'loading')
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 20),
                      Text('Processing attendance...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
