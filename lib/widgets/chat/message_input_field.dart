import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../services/cloudinary_service.dart';
import '../../theme/app_colors.dart';

/// Text + voice message composer for [ChatScreen].
///
/// [onSend] is called with the typed text when the user sends a text
/// message. [onSendVoice] is called with the uploaded voice note's
/// Cloudinary URL and its recorded duration once recording finishes.
class MessageInputField extends StatefulWidget {
  final Future<void> Function(String text) onSend;
  final Future<void> Function(String voiceUrl, int durationSeconds)
  onSendVoice;

  const MessageInputField({
    super.key,
    required this.onSend,
    required this.onSendVoice,
  });

  @override
  State<MessageInputField> createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<MessageInputField> {
  final TextEditingController _textController = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  bool _isUploadingVoice = false;
  bool _isSendingText = false;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;

  bool get _hasText => _textController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _textController.dispose();
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  // ============ TEXT SEND ============
  Future<void> _handleSendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSendingText) return;

    setState(() => _isSendingText = true);
    _textController.clear();

    try {
      await widget.onSend(text);
    } finally {
      if (mounted) setState(() => _isSendingText = false);
    }
  }

  // ============ VOICE RECORDING ============
  Future<void> _startRecording() async {
    if (_isRecording) return;

    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Microphone permission is required to record voice messages.',
            ),
          ),
        );
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    setState(() {
      _isRecording = true;
      _recordDuration = Duration.zero;
    });

    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordDuration += const Duration(seconds: 1));
    });
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();

    if (_isRecording) {
      final path = await _audioRecorder.stop();
      if (path != null) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    }

    if (mounted) {
      setState(() {
        _isRecording = false;
        _recordDuration = Duration.zero;
      });
    }
  }

  Future<void> _stopAndSendRecording() async {
    _recordTimer?.cancel();
    final duration = _recordDuration;
    final path = await _audioRecorder.stop();

    setState(() {
      _isRecording = false;
      _isUploadingVoice = path != null;
    });

    if (path == null) return;

    try {
      final voiceUrl = await CloudinaryService.uploadVoiceMessage(File(path));

      if (voiceUrl == null) {
        throw Exception('Upload failed, please try again.');
      }

      await widget.onSendVoice(voiceUrl, duration.inSeconds);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send voice message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingVoice = false;
          _recordDuration = Duration.zero;
        });
      }
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: _isRecording || _isUploadingVoice
            ? _buildRecordingBar()
            : _buildTextBar(),
      ),
    );
  }

  // ============ TEXT INPUT BAR ============
  Widget _buildTextBar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 120),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _textController,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                color: AppColors.text,
                fontFamily: 'Inter',
                fontSize: 15,
              ),
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(
                  color: AppColors.muted,
                  fontFamily: 'Inter',
                ),
                border: InputBorder.none,
                contentPadding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _hasText
            ? _RoundIconButton(
          icon: Icons.send_rounded,
          loading: _isSendingText,
          onTap: _isSendingText ? null : _handleSendText,
        )
            : _RoundIconButton(
          icon: Icons.mic,
          onTap: _startRecording,
        ),
      ],
    );
  }

  // ============ RECORDING / UPLOADING BAR ============
  Widget _buildRecordingBar() {
    if (_isUploadingVoice) {
      return Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Sending voice message...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: AppColors.error,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          _formatDuration(_recordDuration),
          style: const TextStyle(
            color: AppColors.text,
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Recording voice message...',
            style: TextStyle(
              color: AppColors.muted,
              fontFamily: 'Inter',
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          onPressed: _cancelRecording,
        ),
        _RoundIconButton(
          icon: Icons.send_rounded,
          onTap: _stopAndSendRecording,
        ),
      ],
    );
  }
}

// ── Round gradient icon button ───────────────────────────────────────────────

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: loading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}