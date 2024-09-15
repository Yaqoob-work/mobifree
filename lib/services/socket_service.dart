import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late IO.Socket socket;
  Map<String, Completer<String>> _pendingUrlUpdates = {};

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  void initSocket() {
    socket = IO.io('https://65.2.6.179:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();
    socket.on('connect', (_) {
      print('Connected to socket server');
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
      print('Disconnected from socket server');
      Future.delayed(Duration(seconds: 1), () {
        if (!socket.connected) {
          initSocket(); // Attempt to reconnect
        }
      });
    });
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
        Duration(seconds: 20),
        onTimeout: () => throw TimeoutException('Timeout'),
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
    Timer(Duration(seconds: 5), () {
      if (_pendingUrlUpdates.containsKey(originalUrl) &&
          !_pendingUrlUpdates[originalUrl]!.isCompleted) {
        if (retryCount < 3) {
          print('Retrying YouTube URL request. Attempt ${retryCount + 1}');
          _requestYoutubeUrl(originalUrl, retryCount + 1);
        } else {
          print('Max retries reached for YouTube URL request');
          _pendingUrlUpdates[originalUrl]!
              .completeError(TimeoutException('Failed to get YouTube url'));
        }
      }
    });
  }

  void dispose() {
    socket.disconnect();
  }
}


