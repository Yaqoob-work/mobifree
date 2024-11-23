import 'package:flutter/material.dart';

class EmptyPage extends StatelessWidget {
  const EmptyPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('EmptyPage'),
      ),
      body: Center(
        child: Text('EmptyPage'),
      ),
    );
  }
}
