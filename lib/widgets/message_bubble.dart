import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/chat_models.dart';
import '../services/tts_service.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onRegenerate;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    this.onRegenerate,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final theme = Theme.of(context);
    final bg = isUser
        ? theme.colorScheme.onSurface
        : Colors.transparent;
    final fg = isUser
        ? theme.colorScheme.surface
        : theme.colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isUser ? 760 : 850,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (message.attachments.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: message.attachments.map((a) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(a.kind == 'image' ? Icons.image_outlined : Icons.insert_drive_file_outlined, size: 18),
                          const SizedBox(width: 7),
                          Text(a.name, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              if (message.attachments.isNotEmpty) const SizedBox(height: 7),
              Container(
                padding: isUser ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12) : EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: isUser
                    ? SelectableText(
                        message.text,
                        style: TextStyle(color: fg, fontSize: 16, height: 1.5),
                      )
                    : MarkdownBody(
                        data: message.text.isEmpty ? ' ' : message.text,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(color: fg, fontSize: 16, height: 1.6),
                          h1: TextStyle(color: fg, fontSize: 26, fontWeight: FontWeight.w700),
                          h2: TextStyle(color: fg, fontSize: 22, fontWeight: FontWeight.w700),
                          h3: TextStyle(color: fg, fontSize: 19, fontWeight: FontWeight.w600),
                          code: TextStyle(
                            color: fg,
                            fontFamily: 'monospace',
                            fontSize: 13.5,
                            backgroundColor: theme.brightness == Brightness.light
                                ? const Color(0xFFF0F0F0)
                                : const Color(0xFF1B1B1B),
                          ),
                          blockquote: TextStyle(color: theme.colorScheme.secondary, fontSize: 15),
                        ),
                      ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Action(icon: Icons.copy_outlined, tooltip: 'Copy', onTap: () {
                    Clipboard.setData(ClipboardData(text: message.text));
                  }),
                  if (!isUser)
                    _Action(
                      icon: Icons.volume_up_outlined,
                      tooltip: 'Read aloud',
                      onTap: () => TtsService().speak(message.text),
                    ),
                  if (!isUser && onRegenerate != null)
                    _Action(icon: Icons.refresh_rounded, tooltip: 'Regenerate', onTap: onRegenerate!),
                  if (isUser && onEdit != null)
                    _Action(icon: Icons.edit_outlined, tooltip: 'Edit', onTap: onEdit!),
                  if (isUser && onDelete != null)
                    _Action(icon: Icons.delete_outline, tooltip: 'Delete', onTap: onDelete!),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _Action({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 17),
    );
  }
}
