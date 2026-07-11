import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/wallet/presentation/widget/qr_scanner/scan_tab.dart';
import 'package:expense_management/features/wallet/presentation/widget/qr_scanner/my_qr_tab.dart';
import 'package:expense_management/features/wallet/presentation/widget/qr_scanner/payees_tab.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isCameraActive = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    setState(() {
      _isCameraActive = _tabController.index == 0;
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colors;

    return Scaffold(
      backgroundColor: color.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: color.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'qr_transfer'.tr(ref),
          style: TextStyle(color: color.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: color.primary,
          unselectedLabelColor: color.textSecondary,
          indicatorColor: color.primary,
          tabs: [
            Tab(text: 'scan_qr'.tr(ref)),
            Tab(text: 'my_qr'.tr(ref)),
            Tab(text: 'payee_list'.tr(ref)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Prevent sliding conflict with camera
        children: [
          ScanTab(isCameraActive: _isCameraActive),
          const MyQrTab(),
          const PayeesTab(),
        ],
      ),
    );
  }
}
