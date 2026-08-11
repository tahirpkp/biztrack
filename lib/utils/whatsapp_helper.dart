import 'package:url_launcher/url_launcher.dart';

Future<void> openWhatsApp({required String rawPhone, String? message}) async {
  final digits = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '').replaceFirst('+', '');
  if (digits.isEmpty) {
    return;
  }

  final query = message != null && message.isNotEmpty
      ? '?text=${Uri.encodeComponent(message)}'
      : '';
  final uri = Uri.parse('https://wa.me/$digits$query');
  final fallbackUri = Uri.parse('https://api.whatsapp.com/send?phone=$digits$query');

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return;
  }
  if (await canLaunchUrl(fallbackUri)) {
    await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
    return;
  }
}
