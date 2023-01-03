class MsgModel {
  MsgModel(
      {required this.type,
      required this.sender,
      required this.msg,
      required this.date});
  final String type;
  final String sender;
  final String msg;
  final String date;
}
