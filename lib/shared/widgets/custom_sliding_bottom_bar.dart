import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

@Preview()
Widget previewMyWiget()=> Test();

class Test extends StatefulWidget {
  const Test({super.key});

  @override
  State<Test> createState() => _TestState();
}

class _TestState extends State<Test> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}