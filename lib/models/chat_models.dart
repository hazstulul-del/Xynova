class ChatAttachment {
  final String name;
  final String mimeType;
  final int size;
  final String? base64;
  final String? localPath;
  final String kind;

  const ChatAttachment({
    required this.name,
    required this.mimeType,
    required this.size,
    this.base64,
    this.localPath,
    required this.kind,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'mimeType': mimeType,
        'size': size,
        'base64': base64,
        'kind': kind,
      };
}

class ChatMessage {
  final String id;
  final String role;
  String text;
  final DateTime createdAt;
  final List<ChatAttachment> attachments;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.attachments = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'attachments': attachments.map((e) => e.toJson()).toList(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final raw = (json['attachments'] as List?) ?? const [];
    return ChatMessage(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      role: json['role'] as String? ?? 'assistant',
      text: json['text'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      attachments: raw
          .whereType<Map>()
          .map((e) => ChatAttachment(
                name: e['name'] as String? ?? 'file',
                mimeType: e['mimeType'] as String? ?? 'application/octet-stream',
                size: (e['size'] as num?)?.toInt() ?? 0,
                base64: e['base64'] as String?,
                kind: e['kind'] as String? ?? 'file',
              ))
          .toList(),
    );
  }
}

class Conversation {
  final String id;
  String title;
  final List<ChatMessage> messages;
  DateTime createdAt;
  DateTime updatedAt;
  bool pinned;

  Conversation({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.pinned = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messages': messages.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'pinned': pinned,
      };

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'New chat',
        messages: ((json['messages'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
        pinned: json['pinned'] as bool? ?? false,
      );
}

class ModelInfo {
  final String id;
  final String provider;
  final String category;
  final int speed;
  final int reasoning;
  final int coding;
  final bool vision;
  final int context;
  final bool enabled;

  const ModelInfo({
    required this.id,
    required this.provider,
    required this.category,
    required this.speed,
    required this.reasoning,
    required this.coding,
    required this.vision,
    required this.context,
    required this.enabled,
  });
}
