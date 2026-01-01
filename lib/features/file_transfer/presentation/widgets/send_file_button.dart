import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/file_transfer_provider.dart';
import '../../../../core/utils/logger.dart';

class SendFileButton extends ConsumerWidget {
  const SendFileButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () async {
        try {
          // Pick file
          final result = await FilePicker.platform.pickFiles(
            allowMultiple: false,
            type: FileType.any,
          );
          
          if (result == null || result.files.isEmpty) {
            return;
          }
          
          final file = result.files.first;
          if (file.path == null) {
            AppLogger.warning('File path is null');
            return;
          }
          
          // Send file through provider
          await ref.read(fileTransferProvider.notifier).sendFile(file.path!);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('📤 Sending ${file.name}...'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          AppLogger.error('Failed to pick/send file', e);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      backgroundColor: Colors.green,
      child: const Icon(Icons.send_to_mobile, color: Colors.white),
      tooltip: 'Send File',
    );
  }
}
