import 'package:chat_app/main.dart';
import 'package:chat_app/model/msgModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('name screen asks for a name before joining', (tester) async {
    await tester.pumpWidget(const ChatApp());

    expect(find.text('Chat App'), findsOneWidget);
    await tester.tap(find.text('Join chat'));
    await tester.pump();

    expect(find.text('Please enter a name'), findsOneWidget);
    expect(find.byType(NameScreen), findsOneWidget);
  });

  test('MsgModel parses server messages', () {
    final m = MsgModel.fromJson({
      'senderId': 'abc',
      'sender': 'Sara',
      'msg': 'Salam',
      'date': '2026-11-22T10:05:00.000Z',
    });
    expect(m.sender, 'Sara');
    expect(m.msg, 'Salam');
    expect(m.isSystem, isFalse);
    expect(m.time, matches(RegExp(r'^\d{2}:\d{2}$')));
  });

  test('MsgModel parses system notices', () {
    final m = MsgModel.system({'text': 'Omar joined the chat'});
    expect(m.isSystem, isTrue);
    expect(m.msg, 'Omar joined the chat');
  });
}
