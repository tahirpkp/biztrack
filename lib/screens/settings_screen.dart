import 'package:file_selector/file_selector.dart';
import 'package:hive/hive.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/export_import.dart';
import '../widgets/app_drawer.dart';
import '../widgets/pop_scope_compat.dart';
import '../utils/back_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  final _businessController = TextEditingController();

  Future<void> _doBackup() async {
    setState(() => _isExporting = true);
    try {
      final fileName = 'biztrack_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.biztrack';
      String? filePath;
      try {
        final folder = await getDirectoryPath();
        if (folder != null && folder.isNotEmpty) {
          filePath = path.join(folder, fileName);
        } else {
          final location = await getSaveLocation(
            acceptedTypeGroups: [XTypeGroup(label: 'BizTrack Backup', extensions: ['biztrack'], mimeTypes: ['application/x-biztrack'])],
            suggestedName: fileName,
          );
          filePath = location?.path;
        }
      } catch (e) {
        filePath = await _promptBackupPath(fileName);
      }
      if (filePath == null) return;
      await exportBackup(filePath);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup saved: $filePath')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<String?> _promptBackupPath(String defaultFileName) async {
    final controller = TextEditingController(text: '');
    Directory directory;
    try {
      final downloadsDirectory = await getDownloadsDirectory();
      directory = downloadsDirectory ?? await getApplicationDocumentsDirectory();
    } catch (_) {
      directory = await getApplicationDocumentsDirectory();
    }
    if (!mounted) return null;
    final defaultFolder = directory.path;
    final result = await showDialog<String?> (
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose backup folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your platform does not support a native folder chooser. Please enter the folder path where the backup should be saved. The default location is outside the app folder:'),
            const SizedBox(height: 8),
            TextField(controller: controller, decoration: const InputDecoration(labelText: 'Backup folder path')),
            const SizedBox(height: 8),
            Text('Default folder:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Text(defaultFolder, style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
          TextButton(onPressed: () {
            final input = controller.text.trim();
            final folder = input.isEmpty
                ? defaultFolder
                : path.isAbsolute(input)
                    ? input
                    : path.join(defaultFolder, input);
            Navigator.pop(ctx, path.join(folder, defaultFileName));
          }, child: const Text('Save')),
        ],
      ),
    );
    if (result == null || result.isEmpty) return null;
    return result;
  }

  Future<void> _doRestore() async {
    try {
      final typeGroup = XTypeGroup(label: 'BizTrack Backup', extensions: ['biztrack']);
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return;
      final preview = await previewBackup(file.path);
      if (!preview.isValid) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: ${preview.errorMessage}')));
        return;
      }
      if (!mounted) return;
      final confirm = await showDialog<String?>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restore Backup'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text('Backup schema: ${preview.schemaVersion}'),
                Text('App version: ${preview.appVersion ?? 'unknown'}'),
                const SizedBox(height: 8),
                Text('Settings: ${preview.recordCounts['settings'] ?? 0}'),
                Text('Customers: ${preview.recordCounts['customers'] ?? 0}'),
                Text('Sales: ${preview.recordCounts['sales'] ?? 0}'),
                Text('Expenses: ${preview.recordCounts['expenses'] ?? 0}'),
                Text('Receivables: ${preview.recordCounts['receivables'] ?? 0}'),
                const SizedBox(height: 12),
                Text('Existing records that may be overwritten:'),
                Text('Customers: ${preview.duplicateCounts['customers'] ?? 0}'),
                Text('Sales: ${preview.duplicateCounts['sales'] ?? 0}'),
                Text('Expenses: ${preview.duplicateCounts['expenses'] ?? 0}'),
                Text('Receivables: ${preview.duplicateCounts['receivables'] ?? 0}'),
                Text('Settings keys: ${preview.duplicateCounts['settings'] ?? 0}'),
                if (preview.missingBoxes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Warning: Backup is missing: ${preview.missingBoxes.join(', ')}'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, 'merge'), child: const Text('Merge (keep existing)')),
            TextButton(onPressed: () => Navigator.pop(ctx, 'overwrite'), child: const Text('Clear & Restore')),
          ],
        ),
      );

      if (confirm == null || confirm == 'cancel') return;
      await restoreBackup(file.path, overwrite: confirm == 'overwrite');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore completed successfully')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final settings = Hive.box('settings');
    _businessController.text = (settings.get('businessName') as String?) ?? 'BizTrack';
    return PopScopeCompat(
      onPop: () => handleWillPop(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        drawer: const AppDrawer(),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                title: const Text('Dark Mode'),
                value: theme.isDark,
                onChanged: (v) => theme.setDark(v),
              ),
              const SizedBox(height: 12),
              TextField(controller: _businessController, decoration: const InputDecoration(labelText: 'Business Name')),
              const SizedBox(height: 8),
              ElevatedButton.icon(onPressed: () { settings.put('businessName', _businessController.text.trim()); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Business name saved'))); }, icon: const Icon(Icons.save), label: const Text('Save Business Name')),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isExporting ? null : _doBackup,
                icon: const Icon(Icons.upload_file),
                label: Text(_isExporting ? 'Backing up...' : 'Backup Data'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _doRestore,
                icon: const Icon(Icons.download),
                label: const Text('Restore Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
