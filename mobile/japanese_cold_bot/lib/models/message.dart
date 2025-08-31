class Message {
  final String id;
  final String text;
  final String speaker;
  final DateTime timestamp;
  final bool isUser;
  final String? audioPath;

  Message({
    required this.id,
    required this.text,
    required this.speaker,
    required this.timestamp,
    required this.isUser,
    this.audioPath,
  });

  // ADDED: copyWith method for easily creating a modified copy
  Message copyWith({
    String? id,
    String? text,
    String? speaker,
    DateTime? timestamp,
    bool? isUser,
    String? audioPath,
    bool? forceAudioPathToNull, // Helper to explicitly set audioPath to null
  }) {
    return Message(
      id: id ?? this.id,
      text: text ?? this.text,
      speaker: speaker ?? this.speaker,
      timestamp: timestamp ?? this.timestamp,
      isUser: isUser ?? this.isUser,
      audioPath: forceAudioPathToNull == true ? null : audioPath ?? this.audioPath,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      text: json['text'],
      speaker: json['speaker'],
      timestamp: DateTime.parse(json['timestamp']),
      isUser: json['isUser'],
      audioPath: json['audioPath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'speaker': speaker,
      'timestamp': timestamp.toIso8601String(),
      'isUser': isUser,
      'audioPath': audioPath,
    };
  }
}
