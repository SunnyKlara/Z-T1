// ZCritical 基础测试
// 阶段 0: 最小测试——验证应用能启动

import 'package:flutter_test/flutter_test.dart';
import 'package:zcritical/app.dart';

void main() {
  testWidgets('App 启动测试', (WidgetTester tester) async {
    await tester.pumpWidget(const ZCriticalApp());
    expect(find.text('ZCritical - 风洞控制终端'), findsOneWidget);
  });
}
