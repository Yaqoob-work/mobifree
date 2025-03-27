// import 'dart:async';
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:mobi_tv_entertainment/video_widget/video_screen.dart';

// class NetworkReconnectionScreen extends StatefulWidget {
//   final String videoUrl;
//   final String name;
//   final bool liveStatus;
//   final String unUpdatedUrl;
//   final List<dynamic> channelList;
//   final String bannerImageUrl;
//   final Duration startAtPosition;
//   final bool isLive;
//   final bool isVOD;
//   final bool isSearch;
//   final bool? isHomeCategory;
//   final bool isBannerSlider;
//   final String videoType;
//   final int? videoId;
//   final String source;
//   final Duration? totalDuration;
//   final int selectedChannelIndex; // Added selectedChannelIndex

//   const NetworkReconnectionScreen({
//     Key? key,
//     required this.videoUrl,
//     required this.name,
//     required this.liveStatus,
//     required this.unUpdatedUrl,
//     required this.channelList,
//     required this.bannerImageUrl,
//     required this.startAtPosition,
//     required this.isLive,
//     required this.isVOD,
//     required this.isSearch,
//     this.isHomeCategory,
//     required this.isBannerSlider,
//     required this.videoType,
//     required this.videoId,
//     required this.source,
//     this.totalDuration,
//     required this.selectedChannelIndex,
//   }) : super(key: key);

//   @override
//   _NetworkReconnectionScreenState createState() =>
//       _NetworkReconnectionScreenState();
// }

// class _NetworkReconnectionScreenState extends State<NetworkReconnectionScreen> {
//   late Timer _redirectTimer;
//   int _countdown = 2;

//   @override
//   void initState() {
//     super.initState();

//     // Start a countdown timer
//     _redirectTimer = Timer.periodic(Duration(seconds: 1), (timer) {
//       setState(() {
//         _countdown--;
//       });

//       if (_countdown <= 0) {
//         timer.cancel();
//         _navigateToVideoScreen();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _redirectTimer.cancel();
//     super.dispose();
//   }

//   void _navigateToVideoScreen() {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (context) => VideoScreen(
//           videoUrl: widget.videoUrl,
//           name: widget.name,
//           liveStatus: widget.liveStatus,
//           unUpdatedUrl: widget.unUpdatedUrl,
//           channelList: widget.channelList,
//           bannerImageUrl: widget.bannerImageUrl,
//           startAtPosition: widget.startAtPosition,
//           isLive: widget.isLive,
//           isVOD: widget.isVOD,
//           isSearch: widget.isSearch,
//           isHomeCategory: widget.isHomeCategory,
//           isBannerSlider: widget.isBannerSlider,
//           videoType: widget.videoType,
//           videoId: widget.videoId,
//           source: widget.source,
//           totalDuration: widget.totalDuration,
//           // isNetworkReconnection: true,
//           // initialFocusedIndex: widget
//               // .selectedChannelIndex, // Pass selectedChannelIndex as initialFocusedIndex
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // Rainbow or circular loading indicator
//             CircularProgressIndicator(
//               valueColor: AlwaysStoppedAnimation<Color>(
//                 const Color.fromARGB(211, 155, 40, 248),
//               ),
//               strokeWidth: 3,
//             ),
//             SizedBox(height: 20),
//             Text(
//               'Network Reconnected',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: 10),
//             Text(
//               'Resuming "${widget.name}"...',
//               style: TextStyle(
//                 color: Colors.white70,
//                 fontSize: 16,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: 20),
//             Text(
//               'Auto-redirecting in $_countdown seconds',
//               style: TextStyle(
//                 color: Colors.white60,
//                 fontSize: 14,
//               ),
//             ),
//             SizedBox(height: 30),
//             // Thumbnail/banner if available
//             if (widget.bannerImageUrl.isNotEmpty)
//               Container(
//                 width: MediaQuery.of(context).size.width * 0.6,
//                 height: MediaQuery.of(context).size.height * 0.2,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(8),
//                   image: DecorationImage(
//                     image: widget.bannerImageUrl.startsWith('data:image')
//                         ? MemoryImage(
//                             _getImageFromBase64String(widget.bannerImageUrl))
//                         : NetworkImage(widget.bannerImageUrl) as ImageProvider,
//                     fit: BoxFit.cover,
//                     opacity: 0.7,
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Helper function to convert base64 to image
//   Uint8List _getImageFromBase64String(String base64String) {
//     try {
//       return base64Decode(base64String.split(',').last);
//     } catch (e) {
//       print("Error decoding base64 image: $e");
//       return Uint8List(0);
//     }
//   }
// }



// Add this class to your project (e.g., in network_reconnect_handler.dart)

import 'package:flutter/material.dart';
import 'package:mobi_tv_entertainment/video_widget/video_screen.dart';
import 'dart:async';
import 'package:mobi_tv_entertainment/widgets/small_widgets/rainbow_spinner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ReconnectionHandlerScreen extends StatefulWidget {
  final Map<String, dynamic> videoParams;
  final Function(BuildContext) onReconnectComplete;

  const ReconnectionHandlerScreen({
    Key? key,
    required this.videoParams,
    required this.onReconnectComplete,
  }) : super(key: key);

  @override
  _ReconnectionHandlerScreenState createState() => _ReconnectionHandlerScreenState();
}

class _ReconnectionHandlerScreenState extends State<ReconnectionHandlerScreen> {
  int _countdown = 3;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer.cancel();
        widget.onReconnectComplete(context);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/network_reconnect.png', // Create this asset or use another appropriate image
              width: 100,
              height: 100,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.wifi,
                size: 100,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Reconnecting to Network',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Resuming playback in $_countdown seconds...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
          ],
        ),
      ),
    );
  }
}




// Create a new file called network_reconnect_manager.dart


class NetworkReconnectManager {
  // Singleton instance
  static final NetworkReconnectManager _instance = NetworkReconnectManager._internal();
  
  factory NetworkReconnectManager() {
    return _instance;
  }
  
  NetworkReconnectManager._internal();
  
  // Store reconnection parameters in memory and persistence
  Future<void> saveReconnectParams(Map<String, dynamic> params) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert complex objects to JSON strings
      Map<String, dynamic> serializedParams = {};
      
      params.forEach((key, value) {
        if (key == 'channelList') {
          // For channelList, we need special handling
          serializedParams[key] = 'complex_object';
        } else if (value is Duration) {
          serializedParams[key] = value.inMilliseconds;
        } else if (value is bool || value is String || value is int || value is double) {
          serializedParams[key] = value;
        } else {
          // For other complex objects, store as string
          try {
            serializedParams[key] = json.encode(value);
          } catch (e) {
            print("Could not serialize parameter $key: $e");
            serializedParams[key] = null;
          }
        }
      });
      
      // Store the serialized map
      await prefs.setString('network_reconnect_params', json.encode(serializedParams));
      
      print("Network reconnect parameters saved successfully");
    } catch (e) {
      print("Error saving reconnect parameters: $e");
    }
  }
  
  // Get the original channel list instance - this must be passed separately
  // since we can't properly serialize and deserialize complex objects
  Map<String, dynamic> getReconnectParams(List<dynamic> originalChannelList) {
    // This function should be called with the original channelList from the previous screen
    Map<String, dynamic> params = {
      'channelList': originalChannelList,
    };
    
    return params;
  }
  
  // Clear stored parameters after successful reconnection
  Future<void> clearReconnectParams() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('network_reconnect_params');
    } catch (e) {
      print("Error clearing reconnect parameters: $e");
    }
  }
}





// class NetworkReconnectionAnimation extends StatefulWidget {
//   final Map<String, dynamic> videoParams;
//   final Function(BuildContext) onReconnectComplete;
//   final int countdownSeconds;

//   const NetworkReconnectionAnimation({
//     Key? key,
//     required this.videoParams,
//     required this.onReconnectComplete,
//     this.countdownSeconds = 3,
//   }) : super(key: key);

//   @override
//   _NetworkReconnectionAnimationState createState() => _NetworkReconnectionAnimationState();
// }

// class _NetworkReconnectionAnimationState extends State<NetworkReconnectionAnimation> with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _fadeInOut;
//   late Animation<double> _scaleAnimation;
//   late int _countdown;
//   late Timer _timer;

//   @override
//   void initState() {
//     super.initState();
//     _countdown = widget.countdownSeconds;
    
//     // Setup animations
//     _animationController = AnimationController(
//       vsync: this,
//       duration: Duration(milliseconds: 1500),
//     );
    
//     _fadeInOut = Tween<double>(begin: 0.3, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: Curves.easeInOut,
//       ),
//     );
    
//     _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: Curves.elasticInOut,
//       ),
//     );
    
//     // Loop the animation
//     _animationController.repeat(reverse: true);
    
//     // Start countdown
//     _startCountdown();
//   }
  
//   void _startCountdown() {
//     _timer = Timer.periodic(Duration(seconds: 1), (timer) {
//       if (_countdown > 0) {
//         setState(() {
//           _countdown--;
//         });
//       } else {
//         _timer.cancel();
//         widget.onReconnectComplete(context);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _timer.cancel();
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenSize = MediaQuery.of(context).size;
    
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Container(
//         width: screenSize.width,
//         height: screenSize.height,
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Colors.black,
//               Color(0xFF1E0033), // Deep purple
//             ],
//           ),
//         ),
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // Network icon with animation
//               AnimatedBuilder(
//                 animation: _animationController,
//                 builder: (context, child) {
//                   return Transform.scale(
//                     scale: _scaleAnimation.value,
//                     child: Opacity(
//                       opacity: _fadeInOut.value,
//                       child: Container(
//                         width: 120,
//                         height: 120,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: Colors.purple.withOpacity(0.2),
//                         ),
//                         child: Center(
//                           child: Icon(
//                             Icons.wifi,
//                             size: 80,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
              
//               SizedBox(height: 40),
              
//               // Status text
//               Text(
//                 'Network Connection Restored',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
              
//               SizedBox(height: 16),
              
//               // Countdown text
//               Text(
//                 'Resuming your video in $_countdown ${_countdown == 1 ? 'second' : 'seconds'}...',
//                 style: TextStyle(
//                   color: Colors.white.withOpacity(0.8),
//                   fontSize: 18,
//                 ),
//               ),
              
//               SizedBox(height: 40),
              
//               // Rainbow spinner from your existing widgets
//               SizedBox(
//                 width: 60,
//                 height: 60,
//                 child: RainbowSpinner(),
//               ),
              
//               SizedBox(height: 60),
              
//               // Channel info if available
//               if (widget.videoParams['name'] != null)
//                 Container(
//                   padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.5),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(
//                     'Resuming: ${widget.videoParams['name']}',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }





class NetworkReconnectionAnimation extends StatefulWidget {
  final Map<String, dynamic> videoParams;
  final Function(BuildContext) onReconnectComplete;

  NetworkReconnectionAnimation({
    required this.videoParams,
    required this.onReconnectComplete,
  });

  @override
  _NetworkReconnectionAnimationState createState() => _NetworkReconnectionAnimationState();
}

class _NetworkReconnectionAnimationState extends State<NetworkReconnectionAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _countdown = 3;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    
    // Animation setup
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // Start countdown after a short delay
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 1) {
          _countdown--;
        } else {
          timer.cancel();
          // Complete the reconnection process
          widget.onReconnectComplete(context);
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Reconnection animation
            RotationTransition(
              turns: _animation,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/refresh.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),
            
            // Connection message
            Text(
              'Network Connection Restored',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 16),
            
            // Media info
            Text(
              'Reconnecting to:',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
            
            SizedBox(height: 8),
            
            Text(
              widget.videoParams['name'] ?? 'Media',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            SizedBox(height: 24),
            
            // Countdown
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.purple, width: 3),
              ),
              child: Center(
                child: Text(
                  '$_countdown',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Position info if applicable
            if (widget.videoParams['isLive'] == false && 
                widget.videoParams['startAtPosition'] != null && 
                widget.videoParams['startAtPosition'] is Duration &&
                widget.videoParams['startAtPosition'].inSeconds > 0)
              Text(
                'Resuming from ${_formatDuration(widget.videoParams['startAtPosition'])}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : '';
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours$minutes:$seconds';
  }
}





class VideoBufferScreen extends StatefulWidget {
  final Map<String, dynamic> videoParams;
  final VoidCallback cleanupOldController;
  
  VideoBufferScreen({
    required this.videoParams,
    required this.cleanupOldController,
  });
  
  @override
  _VideoBufferScreenState createState() => _VideoBufferScreenState();
}

class _VideoBufferScreenState extends State<VideoBufferScreen> {
  @override
  void initState() {
    super.initState();
    
    // First show this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Then clean up the old controller
      widget.cleanupOldController();
      
      // Wait a moment to ensure resources are freed
      Future.delayed(Duration(milliseconds: 300), () {
        // Then launch the new VideoScreen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => VideoScreen(
                videoUrl: widget.videoParams['videoUrl'],
                unUpdatedUrl: widget.videoParams['unUpdatedUrl'],
                channelList: widget.videoParams['channelList'],
                bannerImageUrl: widget.videoParams['bannerImageUrl'],
                startAtPosition: widget.videoParams['startAtPosition'],
                videoType: widget.videoParams['videoType'],
                isLive: widget.videoParams['isLive'],
                isVOD: widget.videoParams['isVOD'],
                isSearch: widget.videoParams['isSearch'],
                isHomeCategory: widget.videoParams['isHomeCategory'],
                isBannerSlider: widget.videoParams['isBannerSlider'],
                videoId: widget.videoParams['videoId'],
                source: widget.videoParams['source'],
                name: widget.videoParams['name'],
                liveStatus: widget.videoParams['liveStatus'],
                totalDuration: widget.videoParams['totalDuration'],
              ),
            ),
          );
        }
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
            SizedBox(height: 30),
            Text(
              'Reconnecting...',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            SizedBox(height: 10),
            Text(
              'Preparing video stream',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}