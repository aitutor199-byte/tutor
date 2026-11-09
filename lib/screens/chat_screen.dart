import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/app_provider.dart';
import '../models/message.dart';
import '../models/subject.dart';
import '../services/stt_service.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final SttService _sttService = SttService();
  bool _isListening = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(AppProvider provider) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    provider.sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _toggleListening(AppProvider provider) async {
    if (_isListening) {
      await _sttService.stopListening();
      setState(() => _isListening = false);
      return;
    }

    setState(() => _isListening = true);

    await _sttService.startListening(
      languageCode: provider.languageCode,
      onResult: (text) {
        setState(() {
          _textController.text = text;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
        });
      },
      onDone: () {
        setState(() => _isListening = false);
      },
      onError: (error) {
        setState(() => _isListening = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        // Scroll to bottom when messages change
        if (provider.messages.isNotEmpty) {
          _scrollToBottom();
        }

        final currentSubject = SubjectData.subjects.firstWhere(
          (s) => s.id == provider.currentSubject,
          orElse: () => SubjectData.subjects.last,
        );

        return Scaffold(
          backgroundColor: AppTheme.backgroundLightBlue,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: currentSubject.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    currentSubject.icon,
                    color: currentSubject.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.tr('appTitle'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      currentSubject.getName(provider.languageCode),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              if (provider.messages.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: provider.tr('clearChat'),
                  onPressed: () => _showClearDialog(context, provider),
                ),
              // Subject selector
              PopupMenuButton<String>(
                icon: const Icon(Icons.category_rounded),
                tooltip: provider.tr('subjects'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (subjectId) {
                  provider.setSubject(subjectId);
                },
                itemBuilder: (context) => SubjectData.subjects.map((subject) {
                  return PopupMenuItem(
                    value: subject.id,
                    child: Row(
                      children: [
                        Icon(subject.icon, color: subject.color, size: 20),
                        const SizedBox(width: 10),
                        Text(subject.getName(provider.languageCode)),
                        if (subject.id == provider.currentSubject) ...[
                          const Spacer(),
                          const Icon(Icons.check, color: AppTheme.primaryBlue, size: 18),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          body: Column(
            children: [
              // Messages
              Expanded(
                child: provider.messages.isEmpty
                    ? _buildEmptyState(provider)
                    : _buildMessageList(provider),
              ),

              // Input area
              _buildInputArea(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(AppProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 48,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              provider.tr('welcome'),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              provider.tr('askQuestion'),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Suggestion chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _getSuggestions(provider.languageCode)
                  .map((suggestion) => ActionChip(
                        label: Text(
                          suggestion,
                          style: const TextStyle(fontSize: 13),
                        ),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.dividerColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onPressed: () {
                          _textController.text = suggestion;
                          _sendMessage(provider);
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getSuggestions(String languageCode) {
    switch (languageCode) {
      case 'ur':
        return [
          'فوٹو سنتھیسس کیا ہے؟',
          'مجھے الجبرا سکھائیں',
          'پانی کا فارمولا کیا ہے؟',
        ];
      case 'ps':
        return [
          'فوټوسنتیسس څه شی دی؟',
          'ماته الجبرا زده کړئ',
          'د اوبو فورمول څه دی؟',
        ];
      default:
        return [
          'What is photosynthesis?',
          'Teach me algebra basics',
          'Explain Newton\'s laws of motion',
        ];
    }
  }

  Widget _buildMessageList(AppProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: provider.messages.length + (provider.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.messages.length && provider.isLoading) {
          return _buildLoadingBubble(provider);
        }
        return _MessageBubble(
          message: provider.messages[index],
          languageCode: provider.languageCode,
          onSpeak: () {
            if (provider.isSpeaking) {
              provider.stopSpeaking();
            } else {
              provider.speakMessage(provider.messages[index].content);
            }
          },
          isSpeaking: provider.isSpeaking,
        );
      },
    );
  }

  Widget _buildLoadingBubble(AppProvider provider) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 8, right: 60),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.aiBubble,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryBlue.withOpacity(0.6),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              provider.languageCode == 'ur'
                  ? 'سوچ رہا ہے...'
                  : provider.languageCode == 'ps'
                      ? 'فکر کوي...'
                      : 'Thinking...',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(AppProvider provider) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Voice input button
          _buildVoiceButton(provider),
          const SizedBox(width: 8),

          // Text input
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: null,
                textDirection: provider.isRtl
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: _isListening
                      ? provider.tr('speakNow')
                      : provider.tr('typeMessage'),
                  hintStyle: const TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 15,
                  ),
                  filled: true,
                  fillColor: AppTheme.backgroundLightBlue,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryBlue,
                      width: 1.5,
                    ),
                  ),
                ),
                onSubmitted: (_) => _sendMessage(provider),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          Material(
            color: provider.isLoading
                ? AppTheme.textHint
                : AppTheme.primaryBlue,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: provider.isLoading
                  ? null
                  : () => _sendMessage(provider),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceButton(AppProvider provider) {
    return Material(
      color: _isListening
          ? AppTheme.errorColor.withOpacity(0.1)
          : AppTheme.backgroundLightBlue,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => _toggleListening(provider),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(
            _isListening ? Icons.stop_rounded : Icons.mic_rounded,
            color: _isListening
                ? AppTheme.errorColor
                : AppTheme.textSecondary,
            size: 22,
          ),
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(provider.tr('clearChat')),
        content: Text(provider.tr('clearChatConfirm')),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(provider.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              provider.clearConversation();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: Text(provider.tr('clear')),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final String languageCode;
  final VoidCallback onSpeak;
  final bool isSpeaking;

  const _MessageBubble({
    required this.message,
    required this.languageCode,
    required this.onSpeak,
    required this.isSpeaking,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final isRtl = languageCode == 'ur' || languageCode == 'ps';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 6,
          bottom: 6,
          left: isUser ? 60 : 0,
          right: isUser ? 0 : 60,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isError
                    ? AppTheme.errorColor.withOpacity(0.08)
                    : isUser
                        ? AppTheme.userBubble
                        : AppTheme.aiBubble,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft:
                      isUser ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight:
                      isUser ? const Radius.circular(4) : const Radius.circular(18),
                ),
                border: message.isError
                    ? Border.all(
                        color: AppTheme.errorColor.withOpacity(0.3),
                        width: 1,
                      )
                    : null,
              ),
              child: isUser
                  ? Text(
                      message.content,
                      style: const TextStyle(
                        color: AppTheme.userBubbleText,
                        fontSize: 15,
                        height: 1.4,
                      ),
                      textDirection:
                          isRtl ? TextDirection.rtl : TextDirection.ltr,
                    )
                  : MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: message.isError
                              ? AppTheme.errorColor
                              : AppTheme.aiBubbleText,
                          fontSize: 15,
                          height: 1.5,
                        ),
                        strong: TextStyle(
                          color: message.isError
                              ? AppTheme.errorColor
                              : AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        code: TextStyle(
                          backgroundColor:
                              AppTheme.primaryBlue.withOpacity(0.08),
                          color: AppTheme.primaryBlueDark,
                          fontSize: 13,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: AppTheme.textPrimary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        listBullet: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                        ),
                        h1: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        h2: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        h3: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      selectable: true,
                    ),
            ),

            // Action buttons for AI messages
            if (!isUser && !message.isError)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // TTS button
                    InkWell(
                      onTap: onSpeak,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSpeaking
                                  ? Icons.stop_rounded
                                  : Icons.volume_up_rounded,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isSpeaking
                                  ? (languageCode == 'ur'
                                      ? 'رکیں'
                                      : languageCode == 'ps'
                                          ? 'ودروئ'
                                          : 'Stop')
                                  : (languageCode == 'ur'
                                      ? 'سنیں'
                                      : languageCode == 'ps'
                                          ? 'واورئ'
                                          : 'Listen'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
