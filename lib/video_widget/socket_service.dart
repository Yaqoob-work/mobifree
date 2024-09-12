import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket _socket;

  void connect() {
    _socket = IO.io('https://65.2.6.179:3000', IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .build());

    _socket.onConnect((_) {
      print('Connected to socket server');
    });

    _socket.on('youtube_video_id', (data) {
      print('Received YouTube video ID: $data');
      // Handle the received data
    });

    _socket.onDisconnect((_) {
      print('Disconnected from socket server');
    });
  }

  void emitVideoIdRequest(String videoId) {
    _socket.emit('request_video_url', videoId);
  }

  void close() {
    _socket.disconnect();
  }
}
