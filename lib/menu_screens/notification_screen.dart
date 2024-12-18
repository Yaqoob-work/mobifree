
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;


class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final TextEditingController _searchController = TextEditingController();
  VlcPlayerController? _playerController;
  List<Map<String, dynamic>> _searchResults = [];
  final yt = YoutubeExplode();
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Replace with your YouTube API key
  final String API_KEY = 'YOUR_API_KEY';

  @override
  void dispose() {
    _searchController.dispose();
    _playerController?.dispose();
    yt.close();
    super.dispose();
  }

  Future<void> searchYouTube(String searchQuery) async {
    if (searchQuery.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a search term';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _searchResults = [];
    });

    final String url = 'https://www.googleapis.com/youtube/v3/search?part=snippet&q=$searchQuery&type=video&key=$API_KEY&maxResults=10';
    
    try {
      final response = await http.get(Uri.parse(url));
      print('Response status code: ${response.statusCode}');

      if (response.statusCode != 200) {
        setState(() {
          _errorMessage = 'API Error: ${response.statusCode}\n${response.body}';
          _isLoading = false;
        });
        return;
      }

      final data = json.decode(response.body);
      
      if (data['items'] == null || data['items'].isEmpty) {
        setState(() {
          _errorMessage = 'No results found';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(
          data['items'].map((item) => {
            'id': item['id']['videoId'],
            'title': item['snippet']['title'],
            'thumbnail': item['snippet']['thumbnails']['default']['url'],
            'description': item['snippet']['description'],
          })
        );
        _isLoading = false;
      });
    } catch (e) {
      print('Error searching YouTube: $e');
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> playVideo(String videoId) async {
    try {
      // Get video manifest
      var manifest = await yt.videos.streamsClient.getManifest(videoId);
      var streamInfo = manifest.muxed.withHighestBitrate();
      var videoUrl = streamInfo.url.toString();

      // Dispose existing controller if any
      if (_playerController != null) {
        await _playerController!.dispose();
      }

      // Initialize new controller
      _playerController = VlcPlayerController.network(
        videoUrl,
        hwAcc: HwAcc.full,
        autoPlay: true,
        options: VlcPlayerOptions(
          advanced: VlcAdvancedOptions([
            VlcAdvancedOptions.networkCaching(2000),
          ]),
          http: VlcHttpOptions([
            VlcHttpOptions.httpReconnect(true),
          ]),
          video: VlcVideoOptions([
            VlcVideoOptions.dropLateFrames(true),
            VlcVideoOptions.skipFrames(true),
          ]),
        ),
      );

      setState(() {});
      
      // Initialize the controller
      await _playerController!.initialize();

    } catch (e) {
      print('Error playing video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing video: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube VLC Player'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search YouTube videos...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => searchYouTube(_searchController.text),
                ),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onSubmitted: (value) => searchYouTube(value),
            ),
          ),

          // Loading Indicator
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),

          // Error Message
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          // Video Player
          if (_playerController != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: VlcPlayer(
                controller: _playerController!,
                aspectRatio: 16 / 9,
                placeholder: const Center(child: CircularProgressIndicator()),
              ),
            ),

          // Video Controls
          if (_playerController != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10),
                    onPressed: () => _playerController!.seekTo(Duration(seconds: _playerController!.value.position.inSeconds - 10)),
                  ),
                  IconButton(
                    icon: Icon(_playerController!.value.isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () => _playerController!.value.isPlaying ? _playerController!.pause() : _playerController!.play(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_10),
                    onPressed: () => _playerController!.seekTo(Duration(seconds: _playerController!.value.position.inSeconds + 10)),
                  ),
                ],
              ),
            ),

          // Search Results
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    leading: Image.network(
                      result['thumbnail'],
                      errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.error),
                    ),
                    title: Text(
                      result['title'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      result['description'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => playVideo(result['id']),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}