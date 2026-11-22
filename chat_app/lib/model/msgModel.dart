/// A chat message from the server, or a system notice such as
/// "Sara joined the chat".
class MsgModel {
  const MsgModel({
    required this.sender,
    required this.msg,
    required this.date,
    this.senderId = '',
    this.isSystem = false,
  });

  /// Builds a user message from the server's "message" / "history" payload.
  factory MsgModel.fromJson(Map<String, dynamic> json) {
    return MsgModel(
      senderId: (json['senderId'] ?? '').toString(),
      sender: (json['sender'] ?? 'Unknown').toString(),
      msg: (json['msg'] ?? '').toString(),
      date: DateTime.tryParse((json['date'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
    );
  }

  /// Builds a notice from the server's "system" payload.
  factory MsgModel.system(Map<String, dynamic> json) {
    return MsgModel(
      sender: '',
      msg: (json['text'] ?? '').toString(),
      date: DateTime.tryParse((json['date'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      isSystem: true,
    );
  }

  final String senderId;
  final String sender;
  final String msg;
  final DateTime date;
  final bool isSystem;

  /// "14:05" style time for the bubble footer.
  String get time =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
