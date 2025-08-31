import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../widgets/typing_text.dart';

// Custom AudioSource for just_audio to play a stream of bytes
class MyStreamAudioSource extends StreamAudioSource {
  final Stream<List<int>> bytesStream;

  MyStreamAudioSource(this.bytesStream) : super(tag: 'MyStreamAudioSource');

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    return StreamAudioResponse(
      sourceLength: null, // We don't know the total length
      contentLength: null, // We don't know the total length
      offset: 0,
      stream: bytesStream,
      contentType: 'audio/wav',
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ApiService _apiService = ApiService();

  // CORRECTED: The load configuration is passed to the player's constructor.
  final AudioPlayer _audioPlayer = AudioPlayer(
    audioLoadConfiguration: AudioLoadConfiguration(
      androidLoadControl: const AndroidLoadControl(
        // Start playing after 0.5s of buffer
        bufferForPlaybackDuration: Duration(milliseconds: 500),
        // After rebuffer, wait 1s
        bufferForPlaybackAfterRebufferDuration: Duration(milliseconds: 1000),
        // Min buffer size is 1s (must be >= bufferForPlaybackAfterRebufferDuration)
        minBufferDuration: Duration(milliseconds: 1000),
        // Max buffer size is 2s
        maxBufferDuration: Duration(seconds: 2),
      ),
      darwinLoadControl: const DarwinLoadControl(
        preferredForwardBufferDuration: Duration(seconds: 5),
      ),
    ),
  );

  List<Message> _messages = [];
  bool _isTyping = false;
  bool _isPlayingVoice = false;
  bool _isAutoMode = false;
  bool _showBacklog = false;
  bool _showSettings = false;
  bool _showInputArea = false;

  late AnimationController _characterAnimationController;
  late AnimationController _dialogAnimationController;
  late AnimationController _nextIndicatorController;

  late Animation<double> _characterAnimation;
  late Animation<double> _dialogAnimation;
  late Animation<double> _nextIndicatorAnimation;

  static const Color primaryColor = Color(0xFFFF6EA8);
  static const Color secondaryColor = Color(0xFF5AC8FA);
  static const Color backgroundColor = Color(0xFF1A1A1A);
  static const Color dialogBoxColor = Color(0xE1FFFFFF);

  final List<String> _initialGreetings = [
    "おはよう...今日も来たんだ。別に嬉しくないけど。",
    "ふーん、また来たんだ。何か用？",
    "別に待ってたわけじゃないけど...。で、要件は？",
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupAudioPlayerListeners();
    _showInitialGreeting();
  }

  void _setupAnimations() {
    _characterAnimationController = AnimationController(duration: const Duration(milliseconds: 1600), vsync: this);
    _dialogAnimationController = AnimationController(duration: const Duration(milliseconds: 160), vsync: this);
    _nextIndicatorController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);

    _characterAnimation = CurvedAnimation(parent: _characterAnimationController, curve: Curves.easeOutCubic);
    _dialogAnimation = CurvedAnimation(parent: _dialogAnimationController, curve: Curves.easeOut);
    _nextIndicatorAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _nextIndicatorController, curve: Curves.easeInOut));

    _characterAnimationController.forward();
    _dialogAnimationController.forward();
    _nextIndicatorController.repeat(reverse: true);
  }

  void _showInitialGreeting() async {
    final random = Random();
    final greeting = _initialGreetings[random.nextInt(_initialGreetings.length)];
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();

    final initialMessage = Message(
      id: messageId,
      text: greeting,
      speaker: "涼宮ハルヒ",
      timestamp: DateTime.now(),
      isUser: false,
    );
    _addMessage(initialMessage);

    _streamAndPlayVoice(greeting, messageId);
  }

  void _setupAudioPlayerListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingVoice = state.playing;
        });
      }
      if (state.processingState == ProcessingState.completed) {
        if (mounted) {
          setState(() {
            _isPlayingVoice = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _characterAnimationController.dispose();
    _dialogAnimationController.dispose();
    _nextIndicatorController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _addMessage(Message message) {
    setState(() {
      _messages.add(message);
    });
    _dialogAnimationController.reset();
    _dialogAnimationController.forward();
  }

  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;

    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: _textController.text,
      speaker: "あなた",
      timestamp: DateTime.now(),
      isUser: true,
    );

    _addMessage(userMessage);
    _textController.clear();
    setState(() => _showInputArea = false);
    setState(() => _isTyping = true);

    try {
      final response = await _apiService.sendMessage(userMessage.text);
      final aiText = response['response'];
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();

      final aiMessage = Message(
        id: messageId,
        text: aiText,
        speaker: "涼宮ハルヒ",
        timestamp: DateTime.now(),
        isUser: false,
        audioPath: "streaming", // Placeholder to show the button
      );
      
      setState(() => _isTyping = false);
      _addMessage(aiMessage);

      _streamAndPlayVoice(aiText, messageId);

    } catch (e) {
      if (!mounted) return;
      setState(() => _isTyping = false);
      _addMessage(Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: "...何か問題があるみたい。",
        speaker: "涼宮ハルヒ",
        timestamp: DateTime.now(),
        isUser: false,
      ));
    }
  }

  Future<void> _streamAndPlayVoice(String text, String messageId) async {
    if (!mounted) return;
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.stop();
      }

      final streamedResponse = await _apiService.getVoiceStream(text);
      final audioSource = MyStreamAudioSource(streamedResponse.stream);

      // The configuration is now set in the player's constructor, so we just set the source.
      await _audioPlayer.setAudioSource(audioSource);
      _audioPlayer.play();

    } catch (e) {
      if(mounted) setState(() => _isPlayingVoice = false);
      _showErrorSnackBar('音声ストリームエラー: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Message? currentMessage = _messages.isNotEmpty ? _messages.last : null;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/classroom.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.35), Colors.transparent],
                    stops: [0.0, 0.3],
                  ),
                ),
              ),
            ),
            
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedBuilder(
                  animation: _characterAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _characterAnimation.value,
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.65,
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 30,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/char.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 24,
              right: 24,
              child: _buildTitleBar(),
            ),
            
            if (_showInputArea)
              _buildStylizedInputArea()
            else if (currentMessage != null)
              _buildDialogueArea(currentMessage),

            if (_showBacklog) _buildBacklogOverlay(),
            if (_showSettings) _buildSettingsOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogueArea(Message currentMessage) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16,
      left: 24,
      right: 24,
      child: GestureDetector(
        onTap: () {
          if (!currentMessage.isUser) {
            setState(() => _showInputArea = true);
          }
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedBuilder(
              animation: _dialogAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - _dialogAnimation.value)),
                  child: Opacity(
                    opacity: _dialogAnimation.value,
                    child: _buildDialogBoxContents(currentMessage),
                  ),
                );
              },
            ),
            Positioned(
              top: -20,
              left: 20,
              child: _buildNameplate(currentMessage),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameplate(Message message) {
    final color = message.isUser ? secondaryColor : primaryColor;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: Offset(0, 2))]
      ),
      child: Text(message.speaker, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, fontFamily: 'NotoSansJP')),
    );
  }

  Widget _buildDialogBoxContents(Message message) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: dialogBoxColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Color(0x33FFFFFF), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 20),
              TypingText(
                message.text,
                key: ValueKey(message.id),
                style: TextStyle(fontSize: 18, fontFamily: 'NotoSansJP', color: Color(0xFF1B1B1B), height: 1.2, fontWeight: FontWeight.w400),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!message.isUser)
                    Container(
                      margin: EdgeInsets.only(right: 16),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.72), shape: BoxShape.circle),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(_isPlayingVoice ? Icons.pause : Icons.volume_up, color: Color(0xFF1B1B1B), size: 20),
                        onPressed: () => _streamAndPlayVoice(message.text, message.id),
                      ),
                    ),
                  AnimatedBuilder(
                    animation: _nextIndicatorController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _nextIndicatorAnimation.value,
                        child: Icon(Icons.play_arrow, color: message.isUser ? secondaryColor : primaryColor, size: 24),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "涼宮ハルヒとの会話",
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'NotoSansJP',
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _showSettings = true),
            icon: Icon(Icons.settings, color: Colors.white.withOpacity(0.4), size: 24),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.4), size: 24),
            onSelected: (value) {
              if (value == 'backlog') setState(() => _showBacklog = true);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'backlog', child: Text('履歴')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStylizedInputArea() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16,
      left: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Color(0x33FFFFFF), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _textController,
                    autofocus: true,
                    style: TextStyle(color: Color(0xFF1B1B1B), fontSize: 16, fontFamily: 'NotoSansJP'),
                    decoration: InputDecoration(
                      hintText: "メッセージを入力...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => setState(() => _showInputArea = false), child: Text("キャンセル")),
                      SizedBox(width: 12),
                      ElevatedButton(onPressed: _sendMessage, child: Text("送信")),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBacklogOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("会話履歴", style: TextStyle(color: Colors.white, fontSize: 24)),
                  IconButton(icon: Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _showBacklog = false)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return ListTile(
                    title: Text(message.speaker, style: TextStyle(color: message.isUser ? secondaryColor : primaryColor)),
                    subtitle: Text(message.text, style: TextStyle(color: Colors.white)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("設定", style: TextStyle(color: Colors.white, fontSize: 24)),
            // Add settings widgets here
            ElevatedButton(onPressed: () => setState(() => _showSettings = false), child: Text("閉じる")),
          ],
        ),
      ),
    );
  }
}
