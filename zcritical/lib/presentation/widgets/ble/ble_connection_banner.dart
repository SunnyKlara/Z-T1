// ══════════════════════════════════════════════════════════════
// STEER: 反臃肿 | max_lines=100 | scope=app-presentation | 修改前读 anti-bloat.md
// ══════════════════════════════════════════════════════════════
// 职责：HomeShell 顶部 BLE 连接状态 Banner — 未连接/连接中提示条
// 不做什么：不处理扫描、连接逻辑（由 Provider 层处理）

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/ble/ble_connection_provider.dart';
import '../../providers/ble/ble_status_provider.dart';
import '../../../domain/models/connection_state.dart';

class BleConnectionBanner extends ConsumerWidget {
  const BleConnectionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(connectionStateProvider);
    final bleAvailable = ref.watch(isBleAvailableProvider);

    if (state.isConnected) return const SizedBox.shrink();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showPrompt(context, state, bleAvailable),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _bannerColor(state, bleAvailable),
          border: const Border(bottom: BorderSide(color: Color(0x1AFFFFFF), width: 0.5)),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(children: [
            Icon(_bannerIcon(state, bleAvailable), size: 14, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(_bannerText(state, bleAvailable), style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 14, color: Colors.white70),
          ]),
        ),
      ),
    );
  }

  Color _bannerColor(DeviceConnectionState state, bool bleAvailable) {
    if (!bleAvailable) return const Color(0xCCFF5722);
    if (state.isConnecting) return const Color(0xCC2196F3);
    if (state == DeviceConnectionState.disconnecting) return const Color(0xCC9E9E9E);
    return const Color(0xCCFF9800);
  }

  IconData _bannerIcon(DeviceConnectionState state, bool bleAvailable) {
    if (!bleAvailable) return Icons.bluetooth_disabled;
    if (state.isConnecting) return Icons.bluetooth_searching;
    return Icons.bluetooth;
  }

  String _bannerText(DeviceConnectionState state, bool bleAvailable) {
    if (!bleAvailable) return '蓝牙未开启 — 请开启蓝牙后重试';
    if (state.isConnecting) return '正在连接设备...';
    if (state == DeviceConnectionState.disconnecting) return '正在断开连接...';
    return '未连接设备 — 点击连接';
  }

  void _showPrompt(BuildContext context, DeviceConnectionState state, bool bleAvailable) {
    if (!bleAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在系统设置中开启蓝牙'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('设备扫描功能即将接入'), behavior: SnackBarBehavior.floating),
    );
  }
}
