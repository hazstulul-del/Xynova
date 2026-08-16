import 'package:flutter/material.dart';
import '../models/chat_models.dart';

class MessageComposer extends StatefulWidget {
  final bool streaming;
  final List<ChatAttachment> attachments;
  final ValueChanged<String> onSend;
  final VoidCallback onStop;
  final VoidCallback onAdd;
  final VoidCallback onCamera;
  final VoidCallback onFile;
  final VoidCallback onImage;
  final VoidCallback onMic;
  final bool listening;
  final TextEditingController controller;

  const MessageComposer({
    super.key,
    required this.streaming,
    required this.attachments,
    required this.onSend,
    required this.onStop,
    required this.onAdd,
    required this.onCamera,
    required this.onFile,
    required this.onImage,
    required this.onMic,
    required this.listening,
    required this.controller,
  });

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final _focus = FocusNode();

  void _submit() {
    final value = widget.controller.text.trim();
    if (value.isEmpty && widget.attachments.isEmpty) return;
    widget.onSend(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        child: Column(
          children: [
            if (widget.attachments.isNotEmpty)
              SizedBox(
                height: 62,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.attachments.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final a = widget.attachments[i];
                    return Container(
                      width: 190,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          Icon(a.kind == 'image' ? Icons.image_outlined : Icons.insert_drive_file_outlined, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              a.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            if (widget.attachments.isNotEmpty) const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxWidth: 850),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 18,
                    spreadRadius: 0,
                    color: Colors.black.withValues(alpha: theme.brightness == Brightness.light ? .06 : .22),
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Add attachment',
                    onPressed: widget.onAdd,
                    icon: const Icon(Icons.add, size: 24),
                  ),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      minLines: 1,
                      maxLines: 7,
                      textInputAction: TextInputAction.newline,
                      onSubmitted: (_) {},
                      decoration: const InputDecoration(
                        hintText: 'Message Xynova...',
                        border: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: widget.listening ? 'Stop voice input' : 'Voice input',
                    onPressed: widget.onMic,
                    icon: Icon(widget.listening ? Icons.mic : Icons.mic_none),
                  ),
                  const SizedBox(width: 2),
                  Padding(
                    padding: const EdgeInsets.only(right: 7, bottom: 7),
                    child: IconButton.filled(
                      tooltip: widget.streaming ? 'Stop generating' : 'Send',
                      onPressed: widget.streaming ? widget.onStop : _submit,
                      icon: Icon(widget.streaming ? Icons.stop_rounded : Icons.arrow_upward_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.streaming ? 'Xynova sedang merespons' : 'Enter untuk mengirim · Shift + Enter untuk baris baru',
              style: TextStyle(fontSize: 11.5, color: theme.colorScheme.secondary),
            ),
          ],
        ),
      ),
    );
  }
}
