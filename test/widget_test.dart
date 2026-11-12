import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velvetherald/velvet_assets.dart';
import 'package:velvetherald/velvet_loading_screen.dart';

void main() {
  test('Asset handler only exposes bundled allowlisted resources', () {
    expect(
      bundledAssetFor(Uri.parse('velvet-asset://bundle/images/herald.png')),
      'assets/images/herald.png',
    );
    expect(
      bundledAssetFor(Uri.parse('velvet-asset://bundle/images/salon.png')),
      'assets/images/salon.png',
    );
    expect(
      bundledAssetFor(Uri.parse('https://bundle/images/herald.png')),
      isNull,
    );
    expect(
      bundledAssetFor(Uri.parse('velvet-asset://other/images/herald.png')),
      isNull,
    );
    expect(
      bundledAssetFor(Uri.parse('velvet-asset://bundle/../../secret')),
      isNull,
    );
  });
  for (final size in [
    const Size(390, 844),
    const Size(1024, 1366),
    const Size(844, 390),
  ]) {
    testWidgets('Loader renders at $size with reduced motion', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: size, disableAnimations: true),
            child: const VelvetLoadingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('LOADING'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
