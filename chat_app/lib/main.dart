import 'package:flutter/material.dart';

void main() {
  MaterialApp(
    home: MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(child: Text('Hello world!')),
      ),
    );
  }
}
