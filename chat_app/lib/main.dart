import 'dart:async';

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'model/msgModel.dart';
import 'widget/msg.dart';

/// Server address. Override at run time, for example:
///   flutter run --dart-define=SERVER_URL=http://192.168.1.105:4000
/// The default reaches a server on your computer from the Android emulator.
const String serverUrl = String.fromEnvironment(
  'SERVER_URL',
  defaultValue: 'http://10.0.2.2:4000',
);

void main() => runApp(const ChatApp());

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const NameScreen(),
    );
  }
}

/// First screen: pick a display name, then open the chat.
class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _enterChat() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChatScreen(name: _nameController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.forum_rounded,
                      size: 72, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('Chat App',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    maxLength: 30,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _enterChat(),
                    decoration: const InputDecoration(
                      labelText: 'Your name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'Please enter a name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _enterChat,
                      child: const Text('Join chat'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The chat room: live messages, who is online and who is typing.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.name});

  final String name;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final IO.Socket _socket;
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  final List<MsgModel> _messages = [];
  final Set<String> _typingUsers = {};
  List<String> _onlineUsers = [];
  bool _connected = false;
  bool _isTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  void _initSocket() {
    _socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket.onConnect((_) {
      setState(() => _connected = true);
      _socket.emit('join', {'name': widget.name});
    });
    _socket.onDisconnect((_) {
      if (mounted) setState(() => _connected = false);
    });
    _socket.onConnectError((_) {
      if (mounted) setState(() => _connected = false);
    });

    _socket.on('history', (data) {
      final history = (data as List)
          .map((m) => MsgModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      setState(() => _messages
        ..clear()
        ..addAll(history));
      _scrollToBottom();
    });
    _socket.on('message', (data) {
      _addMessage(MsgModel.fromJson(Map<String, dynamic>.from(data)));
      setState(() => _typingUsers.remove(data['sender']));
    });
    _socket.on('system', (data) {
      _addMessage(MsgModel.system(Map<String, dynamic>.from(data)));
    });
    _socket.on('users', (data) {
      setState(() => _onlineUsers = List<String>.from(data));
    });
    _socket.on('typing', (data) {
      final name = data['name'].toString();
      setState(() {
        if (data['isTyping'] == true) {
          _typingUsers.add(name);
        } else {
          _typingUsers.remove(name);
        }
      });
    });
    _socket.on('error_msg', (data) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['text'].toString())),
      );
    });

    _socket.connect();
  }

  void _addMessage(MsgModel message) {
    if (!mounted) return;
    setState(() => _messages.add(message));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onTextChanged(String text) {
    if (!_isTyping && text.isNotEmpty) {
      _isTyping = true;
      _socket.emit('typing', true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), _stopTyping);
  }

  void _stopTyping() {
    if (_isTyping) {
      _isTyping = false;
      _socket.emit('typing', false);
    }
  }

  void _send() {
    final text = _msgController.text.trim();
    if (text.isEmpty || !_connected) return;
    _socket.emit('send', {'msg': text});
    _msgController.clear();
    _typingTimer?.cancel();
    _stopTyping();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _socket.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _statusText {
    if (!_connected) return 'Connecting…';
    if (_typingUsers.isNotEmpty) {
      return _typingUsers.length == 1
          ? '${_typingUsers.first} is typing…'
          : '${_typingUsers.length} people are typing…';
    }
    return '${_onlineUsers.length} online';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Group chat'),
            Text(_statusText, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Who is online',
            icon: const Icon(Icons.people_alt_outlined),
            onPressed: _showOnlineUsers,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? const Center(child: Text('No messages yet. Say hello!'))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final m = _messages[index];
                        if (m.isSystem) return SystemMessage(text: m.msg);
                        return MessageBubble(
                          message: m,
                          isMine: m.senderId == _socket.id,
                        );
                      },
                    ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
              onChanged: _onTextChanged,
              onSubmitted: (_) => _send(),
              textInputAction: TextInputAction.send,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: _connected ? 'Message' : 'Waiting for server…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Send',
            onPressed: _connected ? _send : null,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  void _showOnlineUsers() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Online now')),
            for (final user in _onlineUsers)
              ListTile(
                leading: CircleAvatar(
                    child: Text(user.isEmpty ? '?' : user[0].toUpperCase())),
                title: Text(user == widget.name ? '$user (you)' : user),
              ),
          ],
        ),
      ),
    );
  }
}
