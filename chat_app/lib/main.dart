import 'dart:convert';

import 'package:chat_app/module/msgModel.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(
    MaterialApp(
      home: SafeArea(child: Scaffold(body: MyApp())),
    ),
  );
}

class MyApp extends StatefulWidget {
  MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late IO.Socket socket;
  TextEditingController msgController = TextEditingController();
  String now = DateTime.now().toString();
  FocusNode focusNode = FocusNode();
  @override
  void initState() {
    initSocket();
    // TODO: implement initState
    super.initState();
  }

  send(String msg, String sender) {
    socket.emit('send',
        {'sender': sender, 'msg': msg, 'time': DateTime.now().toString()});
    msgController.text = '';
  }

  initSocket() {
    socket = IO.io('http://192.168.1.105:4000', <String, dynamic>{
      'autoConnect': false,
      'transports': ['websocket'],
    });
    socket.connect();
    socket.onConnect((_) {
      print('Connection established');
    });
    socket.onDisconnect((_) => print('Connection Disconnection'));
    socket.onConnectError((err) => print(err));
    socket.onError((err) => print(err));
    socket.on('fromServer', (data) => print(data));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          body: Column(children: [
        Expanded(child: Container()),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  focusNode: focusNode,
                  controller: msgController,
                  decoration:
                      InputDecoration(border: const OutlineInputBorder()),
                ),
              ),
              IconButton(
                  color: Colors.blue,
                  iconSize: 30,
                  onPressed: () {
                    send(msgController.text, 'ahmad');
                  },
                  icon: Icon(Icons.send))
            ],
          ),
        )
      ])),
    );
  }
}
