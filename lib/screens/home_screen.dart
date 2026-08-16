import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat_models.dart';
import '../services/backend_client.dart';
import '../services/local_store.dart';
import '../services/voice_service.dart';
import '../widgets/composer.dart';
import '../widgets/message_bubble.dart';
import '../widgets/xynova_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocalStore _store = LocalStore();
  final BackendClient _backend = BackendClient();
  final VoiceService _voice = VoiceService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scroll = ScrollController();

  List<Conversation> _conversations = [];
  Conversation? _current;
  List<ChatAttachment> _pending = [];
  bool _streaming = false;
  bool _listening = false;
  String _selectedModel = 'auto';
  String _language = 'auto';
  String _search = '';
  StreamSubscription<BackendEvent>? _streamSub;
  String? _activeRequestId;

  final List<ModelInfo> _models = const [
    ModelInfo(id: 'auto', provider: 'router', category: 'AUTO', speed: 5, reasoning: 5, coding: 5, vision: true, context: 128000, enabled: true),
    ModelInfo(id: 'deepseek/deepseek-v3.2', provider: 'xkiro', category: 'GENERAL', speed: 4, reasoning: 5, coding: 5, vision: false, context: 131000, enabled: true),
    ModelInfo(id: 'deepseek/deepseek-v4-flash', provider: 'xkiro', category: 'FAST', speed: 5, reasoning: 4, coding: 4, vision: false, context: 131000, enabled: true),
    ModelInfo(id: 'qwen/qwen3.5-flash', provider: 'xkiro', category: 'GENERAL', speed: 5, reasoning: 4, coding: 4, vision: false, context: 131000, enabled: true),
    ModelInfo(id: 'minimax/minimax-m2.7-highspeed', provider: 'xkiro', category: 'FAST', speed: 5, reasoning: 4, coding: 4, vision: false, context: 128000, enabled: true),
    ModelInfo(id: 'mistralai/mistral-small-2603', provider: 'xkiro', category: 'GENERAL', speed: 4, reasoning: 3, coding: 4, vision: false, context: 128000, enabled: true),
    ModelInfo(id: 'mistralai/devstral-medium', provider: 'xkiro', category: 'CODING', speed: 4, reasoning: 5, coding: 5, vision: false, context: 128000, enabled: true),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = await _store.loadConversations();
    final model = await _store.getModel();
    final language = await _store.getLanguage();
    if (!mounted) return;
    setState(() {
      _conversations = history;
      _selectedModel = model ?? 'auto';
      _language = language ?? 'auto';
      if (history.isNotEmpty) _current = history.first;
    });
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _newChat() {
    setState(() {
      _current = null;
      _pending = [];
      _composer.clear();
    });
    Navigator.maybePop(context);
  }

  Conversation _ensureConversation() {
    if (_current != null) return _current!;
    final now = DateTime.now();
    final c = Conversation(
      id: now.microsecondsSinceEpoch.toString(),
      title: 'New chat',
      messages: [],
      createdAt: now,
      updatedAt: now,
    );
    _conversations.insert(0, c);
    _current = c;
    return c;
  }

  Future<void> _persist() => _store.saveConversations(_conversations);

  Future<void> _send(String text) async {
    if (_streaming) return;
    if (text.trim().isEmpty && _pending.isEmpty) return;

    final conversation = _ensureConversation();
    final user = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: 'user',
      text: text.trim(),
      createdAt: DateTime.now(),
      attachments: List.unmodifiable(_pending),
    );
    conversation.messages.add(user);
    if (conversation.title == 'New chat') {
      conversation.title = _makeTitle(text);
    }
    conversation.updatedAt = DateTime.now();

    final assistant = ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}-assistant',
      role: 'assistant',
      text: '',
      createdAt: DateTime.now(),
    );
    conversation.messages.add(assistant);

    final requestId = DateTime.now().microsecondsSinceEpoch.toString();
    _activeRequestId = requestId;
    final attachments = List<ChatAttachment>.from(_pending);
    _pending = [];
    _composer.clear();

    setState(() => _streaming = true);
    await _persist();
    _scrollToBottom();

    await _streamSub?.cancel();
    _streamSub = _backend.streamChat(
      message: text.trim(),
      conversation: conversation.messages.where((m) => m.id != assistant.id).toList(),
      selectedModel: _selectedModel,
      attachments: attachments,
      language: _language,
      requestId: requestId,
    ).listen((event) {
      if (!mounted || _activeRequestId != requestId) return;
      if (event.type == 'token') {
        assistant.text += event.text ?? '';
        setState(() {});
        _scrollToBottom();
      } else if (event.type == 'done') {
        setState(() => _streaming = false);
        _persist();
      } else if (event.type == 'error') {
        assistant.text = event.message ?? 'Request gagal. Silakan coba lagi.';
        setState(() => _streaming = false);
        _persist();
      }
    }, onDone: () {
      if (mounted && _activeRequestId == requestId && _streaming) {
        setState(() => _streaming = false);
        _persist();
      }
    });
  }

  void _stop() {
    _streamSub?.cancel();
    _streamSub = null;
    _activeRequestId = null;
    if (mounted) setState(() => _streaming = false);
  }

  String _makeTitle(String input) {
    final clean = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.isEmpty) return 'New chat';
    final words = clean.split(' ').take(6).join(' ');
    return words.length > 34 ? '${words.substring(0, 34)}…' : words;
  }

  Future<void> _addFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true, allowMultiple: true);
    if (result == null) return;
    final next = <ChatAttachment>[];
    for (final file in result.files) {
      if (file.size > 20 * 1024 * 1024) continue;
      final ext = (file.extension ?? '').toLowerCase();
      final image = ['png', 'jpg', 'jpeg', 'webp'].contains(ext);
      String? encoded;
      if (file.bytes != null && (image || ['txt', 'md', 'json', 'csv', 'html', 'css', 'js', 'ts', 'py', 'java', 'c', 'cpp'].contains(ext))) {
        encoded = base64Encode(file.bytes!);
      }
      next.add(ChatAttachment(
        name: file.name,
        mimeType: _mime(ext),
        size: file.size,
        base64: encoded,
        localPath: file.path,
        kind: image ? 'image' : 'file',
      ));
    }
    if (mounted) setState(() => _pending.addAll(next));
  }

  Future<void> _camera() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 88, maxWidth: 1800);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (mounted) {
        setState(() {
          _pending.add(ChatAttachment(
            name: 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg',
            mimeType: 'image/jpeg',
            size: bytes.length,
            base64: base64Encode(bytes),
            localPath: image.path,
            kind: 'image',
          ));
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission was denied or camera tidak tersedia.')),
      );
    }
  }

  Future<void> _image() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 88, maxWidth: 1800);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (mounted) {
      setState(() {
        _pending.add(ChatAttachment(
          name: image.name,
          mimeType: 'image/jpeg',
          size: bytes.length,
          base64: base64Encode(bytes),
          localPath: image.path,
          kind: 'image',
        ));
      });
    }
  }

  Future<void> _voiceInput() async {
    if (_listening) {
      await _voice.stop((value) {
        if (mounted) setState(() => _listening = value);
      });
      return;
    }
    await _voice.listen(
      onResult: (text) {
        _composer.text = text;
        _composer.selection = TextSelection.collapsed(offset: text.length);
      },
      onState: (value) {
        if (mounted) setState(() => _listening = value);
      },
    );
    if (!_voice.isListening && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice input tidak tersedia di browser/perangkat ini.')),
      );
    }
  }

  String _mime(String ext) {
    const map = {
      'png': 'image/png',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'webp': 'image/webp',
      'pdf': 'application/pdf',
      'json': 'application/json',
      'txt': 'text/plain',
      'md': 'text/markdown',
      'csv': 'text/csv',
      'html': 'text/html',
      'css': 'text/css',
      'js': 'text/javascript',
      'ts': 'text/typescript',
      'py': 'text/x-python',
      'java': 'text/x-java',
      'c': 'text/x-c',
      'cpp': 'text/x-c++',
      'zip': 'application/zip',
    };
    return map[ext] ?? 'application/octet-stream';
  }

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(leading: const Icon(Icons.camera_alt_outlined), title: const Text('Camera'), onTap: () { Navigator.pop(context); _camera(); }),
              ListTile(leading: const Icon(Icons.image_outlined), title: const Text('Upload Image'), onTap: () { Navigator.pop(context); _image(); }),
              ListTile(leading: const Icon(Icons.attach_file), title: const Text('Upload File'), onTap: () { Navigator.pop(context); _addFile(); }),
            ],
          ),
        ),
      ),
    );
  }

  void _showModelSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 6, 20, 10),
              child: Text('Model', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ),
            ..._models.where((m) => m.enabled).map((m) => ListTile(
              title: Text(m.id == 'auto' ? 'Xynova Auto' : m.id.split('/').last),
              subtitle: Text('${m.provider} · ${m.category}'),
              trailing: m.id == _selectedModel ? const Icon(Icons.check) : null,
              onTap: () async {
                setState(() => _selectedModel = m.id);
                await _store.setModel(m.id);
                if (mounted) Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setModal) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
            children: [
              const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 18),
              const Text('Language', style: TextStyle(fontWeight: FontWeight.w650)),
              DropdownButton<String>(
                isExpanded: true,
                value: _language,
                items: const [
                  DropdownMenuItem(value: 'auto', child: Text('Auto')),
                  DropdownMenuItem(value: 'id', child: Text('Indonesian')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'ja', child: Text('Japanese')),
                  DropdownMenuItem(value: 'ko', child: Text('Korean')),
                  DropdownMenuItem(value: 'zh', child: Text('Chinese')),
                  DropdownMenuItem(value: 'es', child: Text('Spanish')),
                  DropdownMenuItem(value: 'fr', child: Text('French')),
                  DropdownMenuItem(value: 'de', child: Text('German')),
                  DropdownMenuItem(value: 'pt', child: Text('Portuguese')),
                  DropdownMenuItem(value: 'ar', child: Text('Arabic')),
                ],
                onChanged: (value) async {
                  if (value == null) return;
                  setModal(() => _language = value);
                  setState(() {});
                  await _store.setLanguage(value);
                },
              ),
              const SizedBox(height: 16),
              const Text('Providers', style: TextStyle(fontWeight: FontWeight.w650)),
              const SizedBox(height: 8),
              _providerTile('xKiro'),
              _providerTile('Groq'),
              _providerTile('OpenRouter'),
              _providerTile('Image'),
              _providerTile('TTS'),
              const Divider(height: 30),
              const Text('About', style: TextStyle(fontWeight: FontWeight.w650)),
              const SizedBox(height: 8),
              const Text('Xynova\nYour intelligent AI.\nCreated by X Shine\n© 2026 X Shine\nVersion 2.0'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _providerTile(String name) {
    final configured = name == 'TTS' || name == 'Image' ? 'Not configured' : (_backend.configured ? 'Backend connected' : 'Not configured');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(name),
      trailing: Text(configured, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.secondary)),
    );
  }

  void _showSidebar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * .85,
        child: _sidebarContent(closeAfterTap: true),
      ),
    );
  }

  Widget _sidebarContent({bool closeAfterTap = false}) {
    final filtered = _conversations.where((c) => c.title.toLowerCase().contains(_search.toLowerCase())).toList();
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: XynovaLogo(size: 26)),
              IconButton(tooltip: 'New chat', onPressed: _newChat, icon: const Icon(Icons.edit_square)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: const InputDecoration(
              hintText: 'Search',
              prefixIcon: Icon(Icons.search),
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.add),
                  title: const Text('New Chat'),
                  onTap: _newChat,
                ),
                const SizedBox(height: 6),
                ...filtered.map((c) => ListTile(
                  selected: _current?.id == c.id,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: c.pinned ? const Icon(Icons.push_pin_outlined, size: 16) : null,
                  onTap: () {
                    setState(() => _current = c);
                    if (closeAfterTap) Navigator.pop(context);
                  },
                  onLongPress: () => _conversationMenu(c),
                )),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              _showSettings();
            },
          ),
        ],
      ),
    );
  }

  void _conversationMenu(Conversation c) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.push_pin_outlined), title: Text(c.pinned ? 'Unpin' : 'Pin'), onTap: () async {
              c.pinned = !c.pinned;
              await _persist();
              if (mounted) { Navigator.pop(context); setState(() {}); }
            }),
            ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Rename'), onTap: () async {
              Navigator.pop(context);
              final controller = TextEditingController(text: c.title);
              final title = await showDialog<String>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Rename'),
                  content: TextField(controller: controller, autofocus: true),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
                  ],
                ),
              );
              if (title != null && title.isNotEmpty) {
                c.title = title;
                await _persist();
                setState(() {});
              }
            }),
            ListTile(leading: const Icon(Icons.delete_outline), title: const Text('Delete'), onTap: () async {
              _conversations.removeWhere((x) => x.id == c.id);
              if (_current?.id == c.id) _current = null;
              await _persist();
              if (mounted) { Navigator.pop(context); setState(() {}); }
            }),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              SizedBox(width: 280, child: _sidebarContent()),
            Expanded(
              child: Column(
                children: [
                  _header(wide),
                  Expanded(child: _chatBody()),
                  MessageComposer(
                    controller: _composer,
                    streaming: _streaming,
                    attachments: _pending,
                    onSend: _send,
                    onStop: _stop,
                    onAdd: _showAddMenu,
                    onCamera: _camera,
                    onFile: _addFile,
                    onImage: _image,
                    onMic: _voiceInput,
                    listening: _listening,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(bool wide) {
    return SizedBox(
      height: 58,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            if (!wide)
              IconButton(tooltip: 'Menu', onPressed: _showSidebar, icon: const Icon(Icons.menu_rounded)),
            if (wide) const SizedBox(width: 4),
            if (!wide) const Expanded(child: Center(child: XynovaLogo(size: 24))),
            if (wide)
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _showModelSheet,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_selectedModel == 'auto' ? 'Xynova Auto' : _selectedModel.split('/').last, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (!wide) IconButton(tooltip: 'New chat', onPressed: _newChat, icon: const Icon(Icons.add)),
            if (wide) ...[
              IconButton(tooltip: 'New chat', onPressed: _newChat, icon: const Icon(Icons.add)),
              IconButton(tooltip: 'Theme', onPressed: () {
                final brightness = Theme.of(context).brightness;
                final mode = brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
                // MaterialApp themeMode is not held in this screen; system remains authoritative.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(mode == ThemeMode.dark ? 'Dark mode tersedia melalui tema aplikasi.' : 'Light mode tersedia melalui tema aplikasi.')),
                );
              }, icon: const Icon(Icons.brightness_6_outlined)),
              IconButton(tooltip: 'Settings', onPressed: _showSettings, icon: const Icon(Icons.settings_outlined)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chatBody() {
    final messages = _current?.messages ?? const <ChatMessage>[];
    if (messages.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 30, 18, 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const XynovaLogo(size: 64, showWordmark: false),
                const SizedBox(height: 24),
                const Text('Where should we begin?', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -.6)),
                const SizedBox(height: 9),
                Text('Ask anything. Build anything. Create anything.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15.5, color: Theme.of(context).colorScheme.secondary)),
                const SizedBox(height: 28),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    'Explain something',
                    'Help me code',
                    'Analyze an image',
                    'Analyze a file',
                    'Write something',
                    'Translate something',
                    'Create an image',
                  ].map((prompt) => ActionChip(
                    label: Text(prompt),
                    onPressed: () => _send(prompt),
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.only(top: 14, bottom: 20),
      itemCount: messages.length + (_streaming ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == messages.length && _streaming) {
          final assistant = messages.last.role == 'assistant' ? messages.last : null;
          if (assistant != null && assistant.text.isEmpty) {
            return const _Thinking();
          }
        }
        final m = messages[i];
        return MessageBubble(
          message: m,
          onRegenerate: m.role == 'assistant' ? () {
            final previous = messages.length >= 2 ? messages[messages.indexOf(m) - 1] : null;
            if (previous?.role == 'user') {
              setState(() => messages.remove(m));
              _send(previous!.text);
            }
          } : null,
          onDelete: m.role == 'user' ? () async {
            setState(() => messages.remove(m));
            await _persist();
          } : null,
          onEdit: m.role == 'user' ? () {
            _composer.text = m.text;
            _composer.selection = TextSelection.collapsed(offset: _composer.text.length);
          } : null,
        );
      },
    );
  }
}

class _Thinking extends StatelessWidget {
  const _Thinking();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
      child: Row(
        children: [
          const SizedBox(width: 4),
          Text('Thinking...', style: TextStyle(fontSize: 14.5, color: Theme.of(context).colorScheme.secondary)),
          const SizedBox(width: 8),
          const _Dots(),
        ],
      ),
    );
  }
}

class _Dots extends StatefulWidget {
  const _Dots();

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final step = (_controller.value * 3).floor();
        return Text(
          '.' * (step + 1),
          style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 18),
        );
      },
    );
  }
}
