// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

/// A small compatibility wrapper named `PopScopeCompat` that provides the
/// same API intent as the newer `PopScope` while delegating to the existing
/// `WillPopScope`. This centralizes the deprecation ignore so other files
/// don't need to suppress the analyzer.
class PopScopeCompat extends StatelessWidget {
  final Future<bool> Function()? onPop;
  final Widget child;

  const PopScopeCompat({super.key, this.onPop, required this.child});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onPop ?? () async => true,
      child: child,
    );
  }
}
