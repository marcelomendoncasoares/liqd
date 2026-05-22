import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:liqd_client/liqd_client.dart';

import '../chat/gen_ui_controller.dart';
import '../chat/serverpod_transport.dart';
import '../catalog/stac_template_merger.dart';

class AppBuilderScreen extends StatefulWidget {
  const AppBuilderScreen({
    super.key,
    required this.client,
    required this.model,
    this.existingApp,
  });

  final Client client;
  final String model;
  final UserApp? existingApp;

  @override
  State<AppBuilderScreen> createState() => _AppBuilderScreenState();
}

class _AppBuilderScreenState extends State<AppBuilderScreen> {
  late final GenUiController _genUiController;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatMessages = <_ChatBubble>[];
  final _surfaceIds = <String>[];
  String _latestAssistantText = '';
  bool _initializing = true;
  bool _isWaiting = false;
  String? _initError;
  int? _appId;

  @override
  void initState() {
    super.initState();
    _appId = widget.existingApp?.id;
    _genUiController = GenUiController(
      client: widget.client,
      savedSurfaceState: widget.existingApp?.surfaceState,
      onSendToServer: (message, transport, history) {
        return streamGenUiFromServer(
          client: widget.client,
          transport: transport,
          history: history,
          model: widget.model,
        );
      },
    );
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _genUiController.initialize();
      final conversation = _genUiController.conversation;
      if (conversation != null) {
        conversation.events.listen(_onConversationEvent);
        conversation.state.addListener(_onStateChanged);
      }
      if (widget.existingApp != null) {
        for (final message in _genUiController.messageHistory) {
          _chatMessages.add(
            _ChatBubble(
              text: message.content,
              isUser: message.role == 'user',
            ),
          );
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _surfaceIds.addAll(
          _genUiController.surfaceController?.activeSurfaceIds ?? [],
        );
        _initializing = false;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _initError = error.toString();
        _initializing = false;
      });
    }
  }

  void _onStateChanged() {
    final state = _genUiController.conversation?.state.value;
    if (state == null) {
      return;
    }
    setState(() {
      _isWaiting = state.isWaiting;
      if (state.latestText.isNotEmpty) {
        _latestAssistantText = state.latestText;
      }
    });
  }

  void _onConversationEvent(ConversationEvent event) {
    switch (event) {
      case ConversationSurfaceAdded(:final surfaceId):
        setState(() {
          if (!_surfaceIds.contains(surfaceId)) {
            _surfaceIds.add(surfaceId);
          }
        });
      case ConversationComponentsUpdated(:final surfaceId):
        setState(() {
          if (!_surfaceIds.contains(surfaceId)) {
            _surfaceIds.add(surfaceId);
          }
        });
      case ConversationSurfaceRemoved(:final surfaceId):
        setState(() {
          _surfaceIds.remove(surfaceId);
        });
      case ConversationContentReceived(:final text):
        setState(() {
          _latestAssistantText = text;
          _upsertAssistantMessage(text);
        });
      case ConversationError(:final error):
        if (!mounted) {
          return;
        }
        final message = error.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 8),
          ),
        );
      default:
        break;
    }
  }

  void _upsertAssistantMessage(String text) {
    if (text.trim().isEmpty) {
      return;
    }
    if (_chatMessages.isNotEmpty &&
        !_chatMessages.last.isUser &&
        _chatMessages.last.text == text) {
      return;
    }
    if (_chatMessages.isNotEmpty && !_chatMessages.last.isUser) {
      _chatMessages[_chatMessages.length - 1] = _ChatBubble(
        text: text,
        isUser: false,
      );
    } else {
      _chatMessages.add(_ChatBubble(text: text, isUser: false));
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text;
    if (text.trim().isEmpty || _isWaiting) {
      return;
    }
    _textController.clear();
    setState(() {
      _chatMessages.add(_ChatBubble(text: text, isUser: true));
      _latestAssistantText = '';
    });
    await _genUiController.sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _retryLastMessage() async {
    if (_isWaiting) {
      return;
    }
    final lastUser = _chatMessages.lastWhere(
      (message) => message.isUser,
      orElse: () => const _ChatBubble(text: '', isUser: true),
    );
    if (lastUser.text.trim().isEmpty) {
      return;
    }
    setState(() {
      _latestAssistantText = '';
    });
    await _genUiController.retryLastMessage();
    _scrollToBottom();
  }

  Future<void> _saveApp() async {
    final title = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(
          text: widget.existingApp?.title ?? 'My app',
        );
        return AlertDialog(
          title: const Text('Save app'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Title'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (title == null || title.isEmpty) {
      return;
    }

    final snapshot = _genUiController.exportSnapshot();
    final saved = await widget.client.userApp.saveApp(
      id: _appId,
      title: title,
      surfaceState: exportSurfaceState(snapshot),
    );
    _appId = saved.id;
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('App saved')),
    );
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

  @override
  void dispose() {
    _genUiController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingApp?.title ?? 'New app'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveApp,
          ),
        ],
      ),
      body: _initializing
          ? const Center(child: CircularProgressIndicator())
          : _initError != null
          ? Center(child: Text(_initError!))
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                if (isWide) {
                  return Row(
                    children: [
                      Expanded(flex: 2, child: _buildPreviewPane()),
                      const VerticalDivider(width: 1),
                      Expanded(flex: 3, child: _buildChatPane()),
                    ],
                  );
                }
                return Column(
                  children: [
                    Expanded(flex: 3, child: _buildPreviewPane()),
                    const Divider(height: 1),
                    Expanded(flex: 2, child: _buildChatPane()),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildPreviewPane() {
    final controller = _genUiController.surfaceController;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: _surfaceIds.isEmpty
          ? Center(
              key: const ValueKey('preview_empty'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isWaiting
                        ? 'Generating UI...'
                        : 'Your generated app preview will appear here.',
                    textAlign: TextAlign.center,
                  ),
                  if (!_isWaiting &&
                      _chatMessages.any((message) => message.isUser)) ...[
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      key: const ValueKey('retry_generation_button'),
                      onPressed: _retryLastMessage,
                      child: const Text('Retry generation'),
                    ),
                  ],
                ],
              ),
            )
          : SingleChildScrollView(
              key: const ValueKey('preview_pane'),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final surfaceId in _surfaceIds)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: SizedBox(
                          key: ValueKey('preview_surface_$surfaceId'),
                          height: 480,
                          width: double.infinity,
                          child: ClipRect(
                            child: controller == null
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : Surface(
                                    surfaceContext: controller.contextFor(
                                      surfaceId,
                                    ),
                                    defaultBuilder: (context) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildChatPane() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _chatMessages.length,
            itemBuilder: (context, index) {
              final message = _chatMessages[index];
              return Align(
                alignment: message.isUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(message.text),
                ),
              );
            },
          ),
        ),
        if (_isWaiting)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                const Expanded(child: LinearProgressIndicator()),
                if (_latestAssistantText.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _latestAssistantText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('builder_prompt_field'),
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Describe the app you want to build...',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const ValueKey('send_message_button'),
                  onPressed: _isWaiting ? null : _sendMessage,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatBubble {
  const _ChatBubble({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}
