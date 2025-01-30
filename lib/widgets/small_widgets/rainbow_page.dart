import 'package:flutter/material.dart';
import 'rainbow_spinner.dart';

class RainbowPage extends StatelessWidget {
  final Color backgroundColor; // पेज का बैकग्राउंड कलर

  const RainbowPage({
    Key? key,
    this.backgroundColor = Colors.white, // डिफ़ॉल्ट कलर
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // पूरे पेज का बैकग्राउंड कलर
      backgroundColor: backgroundColor,
      body: Center(
        child: RainbowSpinner(
          size: 100.0,
        ),
      ),
    );
  }
}