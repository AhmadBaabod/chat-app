import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

class Msg extends StatelessWidget {
  Msg({super.key, required this.msg});
  final String msg;
  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: AlignmentDirectional.topEnd,
        color: Colors.green,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(msg),
        ));
  }
}

class getMsg extends StatelessWidget {
  getMsg({super.key, required this.msg});
  final String msg;
  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: AlignmentDirectional.topStart,
        color: Colors.red,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(msg),
        ));
  }
}
