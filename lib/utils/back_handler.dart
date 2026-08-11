import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<bool> handleWillPop(BuildContext context) async {
  // If there's somewhere to pop to, allow pop.
  if (Navigator.of(context).canPop()) return true;

  // Otherwise confirm exit.
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Exit App'),
      content: const Text('Do you want to exit BizTrack?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
            onPressed: () {
              Navigator.pop(ctx, true);
            },
            child: const Text('Exit')),
      ],
    ),
  );

  if (res == true) {
    SystemNavigator.pop();
    return false;
  }
  return false;
}
