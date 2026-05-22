import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:liqd_client/liqd_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import '../catalog/reactive_stac_host.dart';
import '../stac_app/stac_app_controller.dart';
import '../stac_app/stac_generate_outcome.dart';

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
  late final StacAppController _controller;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatMessages = <_ChatBubble>[];
  String? _previewWarning;
  bool _initializing = true;
  bool _isWaiting = false;
  String? _initError;
  int? _appId;

  @override
  void initState() {
    super.initState();
    _appId = widget.existingApp?.id;
    _controller = StacAppController(
      client: widget.client,
      model: widget.model,
      savedState: widget.existingApp?.surfaceState,
    );
    widget.client.auth.authInfoListenable.addListener(_onAuthChanged);
    _initialize();
  }

  @override
  void dispose() {
    widget.client.auth.authInfoListenable.removeListener(_onAuthChanged);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (!widget.client.auth.isAuthenticated || _initError == null) {
      return;
    }
    setState(() {
      _initError = null;
      _initializing = true;
    });
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      if (widget.existingApp != null) {
        for (final message in _controller.messageHistory) {
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
        _initializing = false;
      });
    } on ServerpodClientUnauthorized {
      await widget.client.auth.signOutDevice();
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

  void _handleOutcome(StacGenerateOutcome outcome) {
    if (!mounted) {
      return;
    }

    if (outcome.isWarning) {
      setState(() {
        _previewWarning = outcome.message;
        _upsertAssistantMessage(outcome.message, isWarning: true);
      });
      return;
    }

    setState(() {
      _previewWarning = null;
      _upsertAssistantMessage(
        _controller.stacJson == null ? 'App updated.' : 'App created.',
      );
    });
  }

  void _upsertAssistantMessage(String text, {bool isWarning = false}) {
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
        isWarning: isWarning,
      );
    } else {
      _chatMessages.add(
        _ChatBubble(text: text, isUser: false, isWarning: isWarning),
      );
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
      _isWaiting = true;
    });
    try {
      final outcome = await _controller.sendMessage(text);
      _handleOutcome(outcome);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      final message = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 8)),
      );
    } finally {
      if (mounted) {
        setState(() => _isWaiting = _controller.isGenerating);
      }
      _scrollToBottom();
    }
  }

  Future<void> _retryLastMessage() async {
    if (_isWaiting) {
      return;
    }
    setState(() => _isWaiting = true);
    try {
      final outcome = await _controller.retryLastMessage();
      _handleOutcome(outcome);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), duration: const Duration(seconds: 8)),
      );
    } finally {
      if (mounted) {
        setState(() => _isWaiting = _controller.isGenerating);
      }
      _scrollToBottom();
    }
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

    try {
      final snapshot = _controller.exportSnapshot();
      final saved = await widget.client.userApp.saveApp(
        id: _appId,
        title: title,
        surfaceStateJson: jsonEncode(snapshot.toJson()),
      );
      _appId = saved.id;
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App saved')),
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save app: $error'),
          duration: const Duration(seconds: 8),
        ),
      );
    }
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
    final stacJson = _controller.stacJson;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: stacJson == null
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
                  if (_previewWarning != null) ...[
                    MaterialBanner(
                      key: const ValueKey('preview_update_warning'),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer,
                      leading: Icon(
                        Icons.warning_amber_rounded,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      content: Text(
                        _previewWarning!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: _retryLastMessage,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ReactiveStacHost(stacJson: stacJson),
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
                        : message.isWarning
                        ? Theme.of(context).colorScheme.errorContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.isWarning) ...[
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(child: Text(message.text)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_isWaiting)
          const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(),
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
  const _ChatBubble({
    required this.text,
    required this.isUser,
    this.isWarning = false,
  });

  final String text;
  final bool isUser;
  final bool isWarning;
}
