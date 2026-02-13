import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

/// Explicit pump loop — do NOT use pumpAndSettle because
/// CircularProgressIndicator in DefaultLoadingWidget spins infinitely.
Future<void> pumpSettle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

/// Mutable state for widget fuzzer trials.
class WidgetFuzzerState {
  List<String> items = List.generate(10, (i) => 'Item$i');
  bool searchEnabled = true;
  bool a11yEnabled = false;
  bool selectionEnabled = false;
  SmartSearchController<String>? externalController;
  late void Function(VoidCallback) rebuild;
}
