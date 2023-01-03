import 'dart:convert';
import 'package:chat_app/model/msgModel.dart';
import 'package:chat_app/widget/msg.dart';
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
  List<Widget> listMsg = [];
  FocusNode focusNode = FocusNode();
  @override
  void initState() {
    initSocket();
    // TODO: implement initState
    super.initState();
  }

  send(String msge, String sender) {
    socket.emit('send', {
      'type': 'sender',
      'sender': sender,
      'msg': msge,
      'date': DateTime.now().toString()
    });
    msgController.clear();
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
    socket.on('res', (data) {
      listMsg.add(Msg(msg: data['msg']));
      setState(() {});
    });
    socket.on('getRes', (data) {
      listMsg.add(getMsg(msg: data['msg']));
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          body: Column(children: [
        Expanded(
            child: ListView.builder(
          itemCount: listMsg.length,
          itemBuilder: (BuildContext context, int index) {
            return listMsg[index];
          },
        )),
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
