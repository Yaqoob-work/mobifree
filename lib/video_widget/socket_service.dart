


// import 'dart:async';     //video_vidget

// import 'package:socket_io_client/socket_io_client.dart ' as IO;

// class SocketService {
//   static final SocketService _instance = SocketService._internal();
//   late IO.Socket socket;
//   bool _isConnected = false;  // To track connection status
//   Map<String, Completer<String>> _pendingUrlUpdates = {};

//   factory SocketService() {
//     return _instance;
//   }

//   SocketService._internal();

//   void initSocket() {
//   //   socket = IO.io('https://78.46.212.202:3000', <String, dynamic>{
//   //     'transports': ['websocket'],
//   //     'autoConnect': false,
//   //   });


//   socket = IO.io('https://78.46.212.202:3000', <String, dynamic>{
//    'transports': ['websocket'],
//    'autoConnect': true,  // Enable auto-connect
//    'reconnection': true,  // Automatically try to reconnect
//    'reconnectionAttempts': 3,  // Set max reconnection attempts
//    'reconnectionDelay': 5000,  // Delay between reconnection attempts
//  });

//     socket.connect();

//     socket.on('connect', (_) {
//       if (!_isConnected) {
//         _isConnected = true;  // Set connection status to true
//         print('Connected to socket server');  // Log only when first connected
//       }
//     });

//     socket.on('videoUrl', (data) {
//       print('Received video URL: $data');
//       if (data['youtubeId'] != null && data['videoUrl'] != null) {
//         _updateVideoUrl(data['youtubeId'], data['videoUrl']);
//       }
//     });

//     socket.on('error', (error) {
//       print('Socket error: $error');
//     });

//     socket.on('disconnect', (_) {
//       print('Disconnected from socket server');
//       _isConnected = false;  // Reset connection status
//       Future.delayed(Duration(seconds: 5), () {
//         if (!socket.connected) {
//           initSocket(); // Attempt to reconnect
//         }
//       });
//     });
//   }

//   void _updateVideoUrl(String youtubeId, String newUrl) {
//     if (_pendingUrlUpdates.containsKey(youtubeId)) {
//       _pendingUrlUpdates[youtubeId]!.complete(newUrl);
//       _pendingUrlUpdates.remove(youtubeId);
//     }
//   }

//   Future<String> getUpdatedUrl(String originalUrl) async {
//     if (!_pendingUrlUpdates.containsKey(originalUrl)) {
//       _pendingUrlUpdates[originalUrl] = Completer<String>();
//       _requestYoutubeUrl(originalUrl);
//     }

//     try {
//       return await _pendingUrlUpdates[originalUrl]!.future.timeout(
//         Duration(seconds: 60),
//         onTimeout: () => throw TimeoutException('Failed to get YouTube URL: Timeout'),
//       );
//     } catch (e) {
//       _pendingUrlUpdates.remove(originalUrl);
//       rethrow;
//     }
//   }

//   void _requestYoutubeUrl(String originalUrl, [int retryCount = 0]) {
//     if (!socket.connected) {
//       print('Socket disconnected. Attempting to reconnect...');
//       initSocket();
//     }

//     socket.emit('youtubeId', originalUrl);

//     // Set a timeout timer
//     Timer(Duration(seconds: 20), () {
//       if (_pendingUrlUpdates.containsKey(originalUrl) &&
//           !_pendingUrlUpdates[originalUrl]!.isCompleted) {
//         if (retryCount < 3) {
//           print('Retrying YouTube URL request. Attempt ${retryCount + 1}');
//           _requestYoutubeUrl(originalUrl, retryCount + 1);
//         } else {
//           print('Max retries reached for YouTube URL request');
//           _pendingUrlUpdates[originalUrl]!
//               .completeError(TimeoutException('Failed to get YouTube url'));
//         }
//       }
//     });
//   }

//   void dispose() {
//     socket.disconnect();
//   }
// }




import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart ' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late IO.Socket socket;
  bool _isConnected = false; // Track connection status
  Map<String, Completer<String>> _pendingUrlUpdates = {};
  Timer? _reconnectTimer; // Timer to prevent frequent reconnect attempts

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  void initSocket() {
    socket = IO.io('https://78.46.212.202:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 5, // Increased reconnection attempts
      'reconnectionDelay': 1000, // Delay of 10 seconds between reconnections
    });

    socket.connect();

    socket.on('connect', (_) {
      if (!_isConnected) {
        _isConnected = true; // Only set to true on first successful connection
        print('Connected to socket server');
      }
    });

    socket.on('videoUrl', (data) {
      print('Received video URL: $data');
      if (data['youtubeId'] != null && data['videoUrl'] != null) {
        _updateVideoUrl(data['youtubeId'], data['videoUrl']);
      }
    });

    socket.on('error', (error) {
      print('Socket error: $error');
    });

    socket.on('disconnect', (_) {
      if (_isConnected) {
        print('Disconnected from socket server');
        _isConnected = false; // Only log if the connection was previously active
        _scheduleReconnect();
      }
    });
  }

  void _scheduleReconnect() {
    if (_reconnectTimer == null || !_reconnectTimer!.isActive) {
      _reconnectTimer = Timer(Duration(seconds: 1), () {
        if (!socket.connected) {
          print('Attempting to reconnect to socket...');
          initSocket(); // Reconnect after a delay
        }
      });
    }
  }

  void _updateVideoUrl(String youtubeId, String newUrl) {
    if (_pendingUrlUpdates.containsKey(youtubeId)) {
      _pendingUrlUpdates[youtubeId]!.complete(newUrl);
      _pendingUrlUpdates.remove(youtubeId);
    }
  }

  Future<String> getUpdatedUrl(String originalUrl) async {
    if (!_pendingUrlUpdates.containsKey(originalUrl)) {
      _pendingUrlUpdates[originalUrl] = Completer<String>();
      _requestYoutubeUrl(originalUrl);
    }

    try {
      return await _pendingUrlUpdates[originalUrl]!.future.timeout(
        Duration(seconds: 60),
        onTimeout: () =>
            throw TimeoutException('Failed to get YouTube URL: Timeout'),
      );
    } catch (e) {
      _pendingUrlUpdates.remove(originalUrl);
      rethrow;
    }
  }

  void _requestYoutubeUrl(String originalUrl, [int retryCount = 0]) {
    if (!socket.connected) {
      print('Socket disconnected. Attempting to reconnect...');
      initSocket();
    }

    socket.emit('youtubeId', originalUrl);

    // Set a timeout timer
    Timer(Duration(seconds: 20), () {
      if (_pendingUrlUpdates.containsKey(originalUrl) &&
          !_pendingUrlUpdates[originalUrl]!.isCompleted) {
        if (retryCount < 3) {
          print('Retrying YouTube URL request. Attempt ${retryCount + 1}');
          _requestYoutubeUrl(originalUrl, retryCount + 1);
        } else {
          print('Max retries reached for YouTube URL request');
          _pendingUrlUpdates[originalUrl]!
              .completeError(TimeoutException('Failed to get YouTube URL'));
        }
      }
    });
  }

  void dispose() {
    socket.disconnect();
    _reconnectTimer?.cancel(); // Cancel any scheduled reconnections
  }
}
