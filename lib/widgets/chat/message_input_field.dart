import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

class MessageInputField extends StatefulWidget {
  final Function(String) onSend;
  final Function(String, int) onSendVoice;

  const MessageInputField({
    super.key,
    required this.onSend,
    required this.onSendVoice,
  });

  @override
  State<MessageInputField> createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<MessageInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isTyping = false;
  bool _isRecording = false;
  DateTime? _recordingStartTime;
  String? _recordingPath;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    // Request permissions
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission required')),
      );
      return;
    }

    // Get temporary directory to save the recording
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: filePath,
    );

    setState(() {
      _isRecording = true;
      _recordingStartTime = DateTime.now();
      _recordingPath = filePath;
    });
  }

  Future<void> _stopRecordingAndSend() async {
    if (!_isRecording || _recordingPath == null) return;

    // Stop recording
    final path = await _audioRecorder.stop();
    final duration = DateTime.now().difference(_recordingStartTime!).inSeconds;

    if (path == null) {
      setState(() => _isRecording = false);
      return;
    }

    // Upload to Firebase Storage
    try {
      final fileName = 'voice_notes/${DateTime.now().millisecondsSinceEpoch}.m4a';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);
      await storageRef.putFile(File(path));
      final downloadUrl = await storageRef.getDownloadURL();

      // Send the voice message
      widget.onSendVoice(downloadUrl, duration);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending voice message: $e')),
      );
    } finally {
      setState(() => _isRecording = false);
      _recordingPath = null;
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
      setState(() => _isTyping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
            onPressed: () {
              // Implement emoji picker if needed
            },
          ),
          if (!_isRecording) ...[
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                maxLines: null,
                onChanged: (text) {
                  setState(() => _isTyping = text.isNotEmpty);
                },
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 4),
            if (_isTyping)
              CircleAvatar(
                backgroundColor: Colors.blue,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _sendMessage,
                ),
              )
            else
              CircleAvatar(
                backgroundColor: Colors.grey[300],
                child: IconButton(
                  icon: const Icon(Icons.mic, color: Colors.grey, size: 20),
                  onPressed: _startRecording,
                ),
              ),
          ] else ...[
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.circle, color: Colors.red, size: 12),
                    const SizedBox(width: 8),
                    Text(
                      '${DateTime.now().difference(_recordingStartTime!).inSeconds}s',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            CircleAvatar(
              backgroundColor: Colors.red,
              child: IconButton(
                icon: const Icon(Icons.stop, color: Colors.white, size: 20),
                onPressed: _stopRecordingAndSend,
              ),
            ),
          ],
        ],
      ),
    );
  }
}