import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import '../services/attendance_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';

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
          _apiMessage = _apiSuccess
              ? '${result['label'] ?? 'Recorded'} at ${result['time'] ?? ''}'
              : result['message'] ?? 'Failed to record attendance';
        });
      } catch (_) {
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
          backgroundColor: _apiSuccess ? AppTheme.success : AppTheme.danger,
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
    super.dispose();
  }

  Widget _buildHeader() {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.brandDark, AppTheme.brand],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance scanner',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Point the camera at the QR code to record attendance.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              AppStatusPill(
                label: 'Keep QR centered',
                color: AppTheme.brandDark,
                backgroundColor: AppTheme.brandSoft,
                icon: Icons.center_focus_strong_rounded,
              ),
              AppStatusPill(
                label: 'One scan at a time',
                color: AppTheme.accent,
                backgroundColor: AppTheme.accentSoft,
                icon: Icons.timer_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScannerArea() {
    if (_scanComplete) {
      final accent = _apiSuccess ? AppTheme.success : AppTheme.danger;
      final bg = _apiSuccess ? const Color(0xFFEAFBF2) : const Color(0xFFFDECEC);
      final icon = _apiSuccess ? Icons.check_circle_rounded : Icons.error_rounded;

      return AppSurfaceCard(
        padding: EdgeInsets.zero,
        child: Container(
          height: 360,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                bg,
                Colors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: AppTheme.cardRadius,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSubmitting)
                    const CircularProgressIndicator()
                  else ...[
                    Icon(icon, color: accent, size: 68),
                    const SizedBox(height: 16),
                    if (_employeeName != null) ...[
                      Text(
                        _employeeName!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      _apiSuccess ? 'Attendance recorded' : 'Scan failed',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: accent,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_apiMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _apiMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: _resetScan,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Scan again'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return AppSurfaceCard(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        height: 360,
        child: ClipRRect(
          borderRadius: AppTheme.cardRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
                overlay: QrScannerOverlayShape(
                  borderColor: AppTheme.brand,
                  borderRadius: 18,
                  borderLength: 32,
                  borderWidth: 8,
                  cutOutSize: 250,
                  overlayColor: Colors.black.withValues(alpha: 0.78),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Hold the QR code inside the frame until the app confirms the scan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Scanner'),
        actions: [
          if (!_scanComplete)
            IconButton(
              icon: Icon(
                _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              ),
              onPressed: _toggleFlash,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            const AppSectionHeader(
              title: 'Scan area',
              subtitle: 'Use your camera to record check-in or check-out.',
            ),
            const SizedBox(height: 12),
            _buildScannerArea(),
            const SizedBox(height: 16),
            if (!_scanComplete)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _toggleFlash,
                      icon: Icon(
                        _isFlashOn ? Icons.flash_off_rounded : Icons.flash_on_rounded,
                      ),
                      label: Text(_isFlashOn ? 'Flash off' : 'Flash on'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _resetScan,
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('Reset'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            AppSurfaceCard(
              color: AppTheme.accentSoft,
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: AppTheme.accent),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tip: If the room is bright, turn the flash off for a cleaner scan. If it is dim, switch it on before aiming at the code.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
