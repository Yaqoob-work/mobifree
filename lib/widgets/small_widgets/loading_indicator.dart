// import 'package:mobi_tv_entertainment/main.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';

// class LoadingIndicator extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: SpinKitFadingCircle(
//         color: borderColor,
//         size: 50.0,
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingIndicator extends StatelessWidget {
  final Color? backgroundColor; // Optional background color

  LoadingIndicator({this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.transparent, // Use transparent if no color is provided
      child: Center(
        child: SpinKitFadingCircle(
          color: Theme.of(context).primaryColor, // Adjust to your app's theme
          size: 50.0,
        ),
      ),
    );
  }
}
