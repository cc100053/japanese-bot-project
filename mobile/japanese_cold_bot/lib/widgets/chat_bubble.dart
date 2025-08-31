import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/message.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onPlayVoice;

  const ChatBubble({
    Key? key,
    required this.message,
    this.onPlayVoice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) _buildCharacterAvatar(),
          const SizedBox(width: 12),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              child: Column(
                crossAxisAlignment: message.isUser 
                    ? CrossAxisAlignment.end 
                    : CrossAxisAlignment.start,
                children: [
                  // 說話者名稱
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      message.speaker,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'NotoSansJP',
                        color: message.isUser 
                            ? Colors.blue[300] 
                            : Colors.pink[300],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // 對話框
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: message.isUser 
                          ? Colors.blue[600]?.withOpacity(0.95)
                          : Colors.white.withOpacity(0.98),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: TextStyle(
                            fontSize: 17,
                            fontFamily: 'NotoSansJP',
                            color: message.isUser ? Colors.white : Colors.black87,
                            height: 1.2,
                            fontWeight: message.isUser ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(message.timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: message.isUser 
                                    ? Colors.white70 
                                    : Colors.grey[600],
                              ),
                            ),
                            if (!message.isUser && onPlayVoice != null) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: onPlayVoice,
                                child: Icon(
                                  Icons.volume_up,
                                  size: 16,
                                  color: Colors.pink[400],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (message.isUser) _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildCharacterAvatar() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.pink[300]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.pink[300]!.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Image.asset(
          'assets/images/char.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.pink[100],
              child: Icon(
                Icons.person,
                color: Colors.pink[400],
                size: 30,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.blue[400],
        boxShadow: [
          BoxShadow(
            color: Colors.blue[400]!.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.person,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }
}