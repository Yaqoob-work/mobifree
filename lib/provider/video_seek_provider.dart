// import 'package:flutter/foundation.dart';
// import 'package:flutter/widgets.dart';
// import 'dart:async';

// import 'package:flutter_vlc_player/flutter_vlc_player.dart';

// class VideoSeekController extends ChangeNotifier {
//   int _accumulatedSeekForward = 0;
//   int _accumulatedSeekBackward = 0;
//   Timer? _seekTimer;
//   final int seekDuration = 10; // seconds
//   final int seekDelay = 300; // milliseconds
  
//   // Add duration getters for current video state
//   Duration _currentPosition = Duration.zero;
//   Duration _totalDuration = Duration.zero;
//   Duration _previewPosition = Duration.zero;
  
//   Duration get currentPosition => _currentPosition;
//   Duration get totalDuration => _totalDuration;
//   Duration get previewPosition => _previewPosition;
  
//   void updateVideoState(Duration current, Duration total) {
//     _currentPosition = current;
//     _totalDuration = total;
//     _previewPosition = current;
//     notifyListeners();
//   }

//   void _seekForward(VlcPlayerController controller, FocusNode forwardButtonFocusNode, BuildContext context) {
//     _accumulatedSeekForward += seekDuration;
    
//     // Update preview position immediately
//     _previewPosition = _currentPosition + Duration(seconds: _accumulatedSeekForward);
//     notifyListeners();
    
//     // Reset any existing timer
//     _seekTimer?.cancel();
    
//     // Set new timer
//     _seekTimer = Timer(Duration(milliseconds: seekDelay), () {
//       if (controller != null) {
//         final newPosition = controller.value.position + Duration(seconds: _accumulatedSeekForward);
//         controller.seekTo(newPosition);
//         _currentPosition = newPosition;
//         _previewPosition = newPosition;
//         _accumulatedSeekForward = 0; // Reset accumulated time after seeking
//         notifyListeners();
//       }
      
//       Future.delayed(Duration(milliseconds: 50), () {
//         FocusScope.of(context).requestFocus(forwardButtonFocusNode);
//       });
//     });
//   }

//   void _seekBackward(VlcPlayerController controller, FocusNode backwardButtonFocusNode, BuildContext context) {
//     _accumulatedSeekBackward += seekDuration;
    
//     // Update preview position immediately
//     Duration newPreviewPosition = _currentPosition - Duration(seconds: _accumulatedSeekBackward);
//     _previewPosition = newPreviewPosition > Duration.zero ? newPreviewPosition : Duration.zero;
//     notifyListeners();
    
//     // Reset any existing timer
//     _seekTimer?.cancel();
    
//     // Set new timer
//     _seekTimer = Timer(Duration(milliseconds: seekDelay), () {
//       if (controller != null) {
//         final currentPosition = controller.value.position;
//         final seekAmount = Duration(seconds: _accumulatedSeekBackward);
//         final newPosition = currentPosition - seekAmount;
        
//         final finalPosition = newPosition > Duration.zero ? newPosition : Duration.zero;
//         controller.seekTo(finalPosition);
//         _currentPosition = finalPosition;
//         _previewPosition = finalPosition;
//         _accumulatedSeekBackward = 0; // Reset accumulated time after seeking
//         notifyListeners();
//       }
      
//       Future.delayed(Duration(milliseconds: 50), () {
//         FocusScope.of(context).requestFocus(backwardButtonFocusNode);
//       });
//     });
//   }

//   void dispose() {
//     _seekTimer?.cancel();
//     super.dispose();
//   }
// }