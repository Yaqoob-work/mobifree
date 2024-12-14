




// import 'dart:async';
// import 'package:socket_io_client/socket_io_client.dart ' as IO;

// class SocketService {
//   static final SocketService _instance = SocketService._internal();
//   late IO.Socket socket;
//   bool _isConnected = false; // Track connection status
//   Map<String, Completer<String>> _pendingUrlUpdates = {};
//   Timer? _reconnectTimer; // Timer to prevent frequent reconnect attempts

//   factory SocketService() {
//     return _instance;
//   }

//   SocketService._internal();

//   void initSocket() {
//     socket = IO.io('https://78.46.212.202:3000', <String, dynamic>{
//       'transports': ['websocket'],
//       'autoConnect': true,
//       'reconnection': true,
//       'reconnectionAttempts': 3, // Increased reconnection attempts
//       'reconnectionDelay': 10000, // Delay of 10 seconds between reconnections
//     });

//     socket.connect();

//     socket.on('connect', (_) {
//       if (!_isConnected) {
//         _isConnected = true; // Only set to true on first successful connection
//         print('Connected to socket server');
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
//       if (_isConnected) {
//         print('Disconnected from socket server');
//         _isConnected = false; // Only log if the connection was previously active
//         _scheduleReconnect();
//       }
//     });
//   }

  

//   void _scheduleReconnect() {
//     if (_reconnectTimer == null || !_reconnectTimer!.isActive) {
//       _reconnectTimer = Timer(Duration(seconds: 10), () {
//         if (!socket.connected) {
//           print('Attempting to reconnect to socket...');
//           initSocket(); // Reconnect after a delay
//         }
//       });
//     }
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
//         onTimeout: () =>
//             throw TimeoutException('Failed to get YouTube URL: Timeout'),
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
//               .completeError(TimeoutException('Failed to get YouTube URL'));
//         }
//       }
//     });
//   }

//   void dispose() {
//     socket.disconnect();
//     _reconnectTimer?.cancel(); // Cancel any scheduled reconnections
//   }
// }



// import 'dart:async';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:socket_io_client/socket_io_client.dart' as IO;

// class SocketService {
//   static final SocketService _instance = SocketService._internal();
//   late IO.Socket socket;
//   bool _isConnected = false; // Track connection status
//   Map<String, Completer<String>> _pendingUrlUpdates = {};
//   Timer? _reconnectTimer; // Timer to prevent frequent reconnect attempts
//   final int _maxRetries = 5;



//   factory SocketService() {
//     return _instance;
//   }

//   SocketService._internal();

//   void initSocket() {

//     socket = IO.io('https://78.46.212.202:3000', <String, dynamic>{
//       'transports': ['websocket'],
//       'autoConnect': true,
//       'reconnection': true,
//       'reconnectionAttempts': 5, // Increased reconnection attempts
//       'reconnectionDelay': 5000, // Reduced delay of 5 seconds between reconnections
//     });

//     socket.connect();

//     socket.on('connect', (_) {
//       if (!_isConnected) {
//         _isConnected = true; // Only set to true on first successful connection
//         // print('Connected to socket server');
//       }
//     });

//     socket.on('videoUrl', (data) {
//       // print('Received video URL: $data');
//       if (data['youtubeId'] != null && data['videoUrl'] != null) {
//         _updateVideoUrl(data['youtubeId'], data['videoUrl']);
//       }
//     });

//     socket.on('error', (error) {
//       // print('Socket error: $error');
//     });

//     socket.on('disconnect', (_) {
//       if (_isConnected) {
//         // print('Disconnected from socket server');
//         _isConnected = false; // Only log if the connection was previously active
//         _scheduleReconnect();
//       }
//     });
//   }

//   void _scheduleReconnect() {
//     if (_reconnectTimer == null || !_reconnectTimer!.isActive) {
//       _reconnectTimer = Timer(Duration(seconds: 10), () {
//         if (!socket.connected) {
//           // print('Attempting to reconnect to socket...');
//           initSocket(); // Reconnect after a delay
//         }
//       });
//     }
//   }

  

//   void _updateVideoUrl(String youtubeId, String newUrl) {
//     if (_pendingUrlUpdates.containsKey(youtubeId)) {
//       _pendingUrlUpdates[youtubeId]!.complete(newUrl);
//       _pendingUrlUpdates.remove(youtubeId);
//     }
//   }



//   // void _requestYoutubeUrl(String originalUrl, [int retryCount = 0]) {
//   //   if (!socket.connected) {
//   //     // print('Socket disconnected. Attempting to reconnect...');
//   //     initSocket();
//   //   }

//       void _requestYoutubeUrl(String originalUrl, [int retryCount = 0]) async {
//     if (!socket.connected) {
//       print('Socket not connected. Waiting for connection...');
//       await Future.delayed(Duration(seconds: 2));
//       if (!socket.connected && retryCount < _maxRetries) {
//         _requestYoutubeUrl(originalUrl, retryCount + 1);
//         return;
//       }
//     }

//     socket.emit('youtubeId', originalUrl);

//     // Set a timeout timer
//     Timer(Duration(seconds: 3), () { // Reduced retry delay to 5 seconds
//       if (_pendingUrlUpdates.containsKey(originalUrl) &&
//           !_pendingUrlUpdates[originalUrl]!.isCompleted) {
//         if (retryCount < 3) {
//           // print('Retrying YouTube URL request. Attempt ${retryCount + 1}');
//           _requestYoutubeUrl(originalUrl, retryCount + 1);
//         } else {
//           // print('Max retries reached for YouTube URL request');
//           _pendingUrlUpdates[originalUrl]!
//               .completeError(TimeoutException('Failed to get YouTube URL'));
//         }
//       }
//     });
//   }

//   void dispose() {
//     socket.disconnect();
//     _reconnectTimer?.cancel(); // Cancel any scheduled reconnections
//   }

//   // Prefetch YouTube URLs in the background for faster playback
//   // Future<void> prefetchYouTubeUrls(List<String> videoUrls) async {
//   //   for (var videoUrl in videoUrls) {
//   //     getUpdatedUrl(videoUrl); // Pre-fetch URL
//   //   }
//   // }
//   Future<void> prefetchYouTubeUrls(List<String> videoUrls) async {
//   await Future.wait(videoUrls.map((url) => getUpdatedUrl(url)));
// }

//   Map<String, String> _urlCache = {};

//   Future<String> getUpdatedUrl(String originalUrl) async {
//     if (_urlCache.containsKey(originalUrl)) {
//       return _urlCache[originalUrl]!;
//     }

//     if (!_pendingUrlUpdates.containsKey(originalUrl)) {
//       _pendingUrlUpdates[originalUrl] = Completer<String>();
//       _requestYoutubeUrl(originalUrl);
//     }

//     String updatedUrl = await _pendingUrlUpdates[originalUrl]!.future.timeout(
//       Duration(seconds: 10),
//       onTimeout: () {
//         _pendingUrlUpdates.remove(originalUrl);
//         throw TimeoutException('Failed to get YouTube URL: Timeout');
//       },
//     );

//     _urlCache[originalUrl] = updatedUrl;
//     _saveUrlToCache(originalUrl, updatedUrl);
//     return updatedUrl;
//   }

//   Future<void> _saveUrlToCache(String originalUrl, String updatedUrl) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('url_cache_$originalUrl', updatedUrl);
//   }

//   Future<void> _loadCachedUrls() async {
//     final prefs = await SharedPreferences.getInstance();
//     final keys = prefs.getKeys();
//     for (var key in keys) {
//       if (key.startsWith('url_cache_')) {
//         final originalUrl = key.substring(10);
//         final updatedUrl = prefs.getString(key);
//         if (updatedUrl != null) {
//           _urlCache[originalUrl] = updatedUrl;
//         }
//       }
//     }
//   }
// }



import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late IO.Socket socket;
  bool _isConnected = false;
  Map<String, Completer<String>> _pendingUrlUpdates = {};
  Timer? _reconnectTimer;
  final int _maxRetries = 5;
  Map<String, String> _urlCache = {};
  bool _isInitialized = false;

  factory SocketService() {
    return _instance;
  }

  SocketService._internal() {
    if (!_isInitialized) {
      initSocket();
      _loadCachedUrls(); // Load cached URLs when service is created
      _isInitialized = true;
    }
  }

  void initSocket() {
    try {
      socket = IO.io('https://78.46.212.202:3000', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 5000,
        'timeout': 10000,
      });

      socket.onConnect((_) {
        _isConnected = true;
        print('Connected to socket server');
      });

      socket.on('videoUrl', (data) {
        print('Received video URL: $data');
        if (data['youtubeId'] != null && data['videoUrl'] != null) {
          _updateVideoUrl(data['youtubeId'], data['videoUrl']);
        }
      });

      socket.onError((error) {
        print('Socket error: $error');
      });

      socket.onDisconnect((_) {
        _isConnected = false;
        print('Disconnected from socket server');
        _scheduleReconnect();
      });

      socket.connect();
    } catch (e) {
      print('Error initializing socket: $e');
    }
  }

  void _scheduleReconnect() {
    if (_reconnectTimer == null || !_reconnectTimer!.isActive) {
      _reconnectTimer = Timer(Duration(seconds: 5), () {
        if (!socket.connected) {
          print('Attempting to reconnect socket...');
          socket.connect();
        }
      });
    }
  }

  void _updateVideoUrl(String youtubeId, String newUrl) {
    print('Updating URL for $youtubeId: $newUrl');
    if (_pendingUrlUpdates.containsKey(youtubeId)) {
      if (!_pendingUrlUpdates[youtubeId]!.isCompleted) {
        _pendingUrlUpdates[youtubeId]!.complete(newUrl);
      }
      _pendingUrlUpdates.remove(youtubeId);
    }
    // Update cache
    _urlCache[youtubeId] = newUrl;
    _saveUrlToCache(youtubeId, newUrl);
  }

  Future<void> _requestYoutubeUrl(String originalUrl, [int retryCount = 0]) async {
    if (!socket.connected) {
      print('Socket not connected. Attempting to connect...');
      socket.connect();
      await Future.delayed(Duration(seconds: 2));
      
      if (!socket.connected && retryCount < _maxRetries) {
        print('Retry attempt ${retryCount + 1}');
        return _requestYoutubeUrl(originalUrl, retryCount + 1);
      }
    }

    print('Requesting YouTube URL for: $originalUrl');
    socket.emit('youtubeId', originalUrl);

    // Set timeout for response
    Timer(Duration(seconds: 10), () {
      if (_pendingUrlUpdates.containsKey(originalUrl) &&
          !_pendingUrlUpdates[originalUrl]!.isCompleted) {
        if (retryCount < _maxRetries - 1) {
          print('Request timed out, retrying...');
          _pendingUrlUpdates.remove(originalUrl);
          _requestYoutubeUrl(originalUrl, retryCount + 1);
        } else {
          print('Max retries reached for: $originalUrl');
          _pendingUrlUpdates[originalUrl]!
              .completeError(TimeoutException('Failed to get YouTube URL'));
        }
      }
    });
  }

  Future<String> getUpdatedUrl(String originalUrl) async {
    try {
      // First check cache
      if (_urlCache.containsKey(originalUrl)) {
        print('Returning cached URL for: $originalUrl');
        return _urlCache[originalUrl]!;
      }

      // Create new request if not already pending
      if (!_pendingUrlUpdates.containsKey(originalUrl)) {
        _pendingUrlUpdates[originalUrl] = Completer<String>();
        await _requestYoutubeUrl(originalUrl);
      }

      // Wait for response with timeout
      final updatedUrl = await _pendingUrlUpdates[originalUrl]!.future.timeout(
        Duration(seconds: 15),
        onTimeout: () {
          _pendingUrlUpdates.remove(originalUrl);
          throw TimeoutException('Failed to get YouTube URL: Timeout');
        },
      );

      // Cache the result
      _urlCache[originalUrl] = updatedUrl;
      await _saveUrlToCache(originalUrl, updatedUrl);
      
      return updatedUrl;
    } catch (e) {
      print('Error getting updated URL: $e');
      rethrow;
    }
  }

  Future<void> prefetchYoutubeUrls(List<String> videoUrls) async {
    try {
      await Future.wait(
        videoUrls.map((url) => getUpdatedUrl(url).catchError((e) {
          print('Error prefetching URL $url: $e');
          return url; // Return original URL on error
        })),
      );
    } catch (e) {
      print('Error in prefetch: $e');
    }
  }

  Future<void> _saveUrlToCache(String originalUrl, String updatedUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('url_cache_$originalUrl', updatedUrl);
    } catch (e) {
      print('Error saving to cache: $e');
    }
  }

  Future<void> _loadCachedUrls() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (var key in keys) {
        if (key.startsWith('url_cache_')) {
          final originalUrl = key.substring(10);
          final updatedUrl = prefs.getString(key);
          if (updatedUrl != null) {
            _urlCache[originalUrl] = updatedUrl;
          }
        }
      }
    } catch (e) {
      print('Error loading cached URLs: $e');
    }
  }

  void clearCache() async {
    try {
      _urlCache.clear();
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (var key in keys) {
        if (key.startsWith('url_cache_')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  void dispose() {
    try {
      socket.disconnect();
      _reconnectTimer?.cancel();
      _pendingUrlUpdates.clear();
    } catch (e) {
      print('Error disposing socket service: $e');
    }
  }
}