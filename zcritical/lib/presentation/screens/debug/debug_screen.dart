// ══════════════════════════════════════════════════════════════
// STEER: 反臃肿 | scope=app | 修改前读 anti-bloat.md
//
// 职责：调试/诊断页 — 开发者模式，展示诊断数据(Mock) + 日志导出入口
// 不做什么：不实现真实日志导出（data层数据源未接入）
// ══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  // ── Mock 诊断数据 ──
  String _deviceUptime = '0h 0m';
  String _bleState = 'disconnected';
  String _rssi = '—';
  String _freeHeap = '0 KB';
  String _freePsram = '0 KB';
  String _fwVersion = '—';
  String _reconnectCount = '0';
  String _totalSent = '0';
  String _totalRecv = '0';
  String _lastCrash = '无';
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadMockData();
  }

  void _loadMockData() {
    // 模拟数据加载
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _deviceUptime = '3h 42m';
          _bleState = 'connected';
          _rssi = '-48 dBm';
          _freeHeap = '128 KB';
          _freePsram = '3.2 MB';
          _fwVersion = 'v0.1.0-dev';
          _reconnectCount = '2';
          _totalSent = '1,247';
          _totalRecv = '892';
        });
      }
    });
  }

  void _exportLogs() {
    HapticFeedback.mediumImpact();
    setState(() => _isExporting = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('日志已导出到 Downloads/ZCritical/'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void _refreshDiagnostics() {
    HapticFeedback.selectionClick();
    // 重置为加载状态
    setState(() {
      _deviceUptime = '...';
      _bleState = '...';
      _rssi = '...';
      _freeHeap = '...';
      _freePsram = '...';
      _fwVersion = '...';
      _reconnectCount = '...';
      _totalSent = '...';
      _totalRecv = '...';
      _lastCrash = '...';
    });
    _loadMockData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bug_report, color: Color(0xFFFF5722), size: 18),
            SizedBox(width: 8),
            Text('开发者调试', style: TextStyle(color: Colors.white)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
            onPressed: _refreshDiagnostics,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 40),
        children: [
          // ── 调试模式标记 ──
          _buildDevBanner(),
          const SizedBox(height: 20),

          // ── 设备状态 ──
          _sectionTitle('设备状态'),
          _diagnosticTile('运行时间', _deviceUptime, Icons.timer_outlined),
          _diagnosticTile('BLE 状态', _bleState, Icons.bluetooth,
              valueColor: _bleState == 'connected'
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFFF5722)),
          _diagnosticTile('信号强度', _rssi, Icons.signal_cellular_alt),
          const SizedBox(height: 20),

          // ── 系统资源 ──
          _sectionTitle('系统资源'),
          _diagnosticTile('剩余 Heap', _freeHeap, Icons.memory),
          _diagnosticTile('剩余 PSRAM', _freePsram, Icons.storage),
          _diagnosticTile('固件版本', _fwVersion, Icons.system_update),
          const SizedBox(height: 20),

          // ── 通信统计 ──
          _sectionTitle('通信统计'),
          _diagnosticTile('重连次数', _reconnectCount, Icons.replay),
          _diagnosticTile('已发送命令', _totalSent, Icons.upload_outlined),
          _diagnosticTile('已接收响应', _totalRecv, Icons.download_outlined),
          const SizedBox(height: 20),

          // ── 异常记录 ──
          _sectionTitle('异常记录'),
          _diagnosticTile('最近崩溃', _lastCrash, Icons.warning_amber_outlined,
              valueColor: _lastCrash == '无'
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFFF5722)),
          const SizedBox(height: 32),

          // ── 操作按钮 ──
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildDevBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5722).withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFF5722).withAlpha(80),
          width: 1,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.construction, color: Color(0xFFFF5722), size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '开发者模式 — 仅供开发调试使用',
              style: TextStyle(color: Color(0xFFFF5722), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withAlpha(100),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _diagnosticTile(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    final color = valueColor ?? const Color(0xFF00BCD4);
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0x14FFFFFF), width: 0.5),
        ),
      ),
      child: Row(children: [
        Icon(icon, color: Colors.white.withAlpha(120), size: 18),
        const SizedBox(width: 14),
        Text(
          label,
          style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Consolas',
          ),
        ),
      ]),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // 导出日志
          GestureDetector(
            onTap: _isExporting ? null : _exportLogs,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withAlpha(15),
                  width: 1,
                ),
              ),
              child: Center(
                child: _isExporting
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF00BCD4),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            '正在导出...',
                            style: TextStyle(
                              color: Color(0xFF00BCD4),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.file_download_outlined, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '导出诊断日志',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // 提示
          Text(
            '说明：本页面仅用于开发和调试。\n数据来源于设备请求，非持久化存储。',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(40),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
