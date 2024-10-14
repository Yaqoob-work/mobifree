import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobi_tv_entertainment/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
// import 'package:shared_preferences/shared_preferences.dart';
import '../../services/socket_service.dart';
import '../../video_widget/socket_service.dart';
import '../../video_widget/video_movie_screen.dart';
import '../../video_widget/vlc_player_screen.dart';
import '../../widgets/focussable_item_widget.dart';
import '../../widgets/small_widgets/loading_indicator.dart';
import '../../widgets/utils/color_service.dart';

void main() {
  runApp(SubVod());
}

Future<Color> fetchPaletteColor(String imageUrl) async {
  return await PaletteColorService().getSecondaryColor(imageUrl);
}

// Models
class NetworkApi {
  final int id;
  final String name;
  final String logo;

  NetworkApi({required this.id, required this.name, required this.logo});

  factory NetworkApi.fromJson(Map<String, dynamic> json) {
    return NetworkApi(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      name: json['name'] ?? 'No Name',
      logo: json['logo'] ?? localImage,
    );
  }
}

class ContentApi {
  final int id;
  final String name;
  final String banner;

  ContentApi({required this.id, required this.name, required this.banner});

  factory ContentApi.fromJson(Map<String, dynamic> json) {
    return ContentApi(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      name: json['name'] ?? 'No Name',
      banner: json['banner'] ?? localImage,
    );
  }
}

class MovieDetailsApi {
  final int id;
  final String name;
  final String banner;
  final String poster;
  final String genres;
  final String status;

  MovieDetailsApi({
    required this.id,
    required this.name,
    required this.banner,
    required this.poster,
    required this.genres,
    required this.status,
  });

  factory MovieDetailsApi.fromJson(Map<String, dynamic> json) {
    return MovieDetailsApi(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      name: json['name'] ?? 'No Name',
      banner: json['banner'] ?? localImage,
      poster: json['poster'] ?? localImage,
      genres: json['genres'] ?? 'Unknown',
      status: json['status'] ?? '0',
    );
  }
}



Future<List<NetworkApi>> fetchNetworks(BuildContext context) async {
  // final prefs = await SharedPreferences.getInstance();
  // final cachedNetworks = prefs.getString('networks');

  List<NetworkApi> networks;

  // if (cachedNetworks != null) {
  //   List<dynamic> body = json.decode(cachedNetworks);
  //   networks = body.map((dynamic item) => NetworkApi.fromJson(item)).toList();
  // } else {
    final response = await https.get(
      Uri.parse('https://api.ekomflix.com/android/getNetworks'),
      headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
    );

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      // prefs.setString('networks', response.body); // Cache the networks
      networks = body.map((dynamic item) => NetworkApi.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load networks');
    }
  // }

  // Preload the network logo images
  for (var network in networks) {
    if (network.logo.isNotEmpty) {
      await precacheImage(
        CachedNetworkImageProvider(network.logo),
        context,
      );
    }
  }

  return networks;
}

Future<List<ContentApi>> fetchContent(BuildContext context, int networkId) async {
  // final prefs = await SharedPreferences.getInstance();
  // final cachedContent = prefs.getString('content_$networkId');

  List<ContentApi> content;

  // if (cachedContent != null) {
  //   List<dynamic> body = json.decode(cachedContent);
  //   content = body.map((dynamic item) => ContentApi.fromJson(item)).toList();
  // } else {
    final response = await https.get(
      Uri.parse('https://api.ekomflix.com/android/getAllContentsOfNetwork/$networkId'),
      headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
    );

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      // prefs.setString('content_$networkId', response.body); // Cache the content
      content = body.map((dynamic item) => ContentApi.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load content');
    }
  // }

  // Preload the content banners
  for (var item in content) {
    if (item.banner.isNotEmpty) {
      await precacheImage(
        CachedNetworkImageProvider(item.banner),
        context,
      );
    }
  }

  return content;
}


Future<MovieDetailsApi> fetchMovieDetails(BuildContext context, int contentId) async {
  // final prefs = await SharedPreferences.getInstance();
  // final cachedMovieDetails = prefs.getString('movie_details_$contentId');

  MovieDetailsApi movieDetails;

  // if (cachedMovieDetails != null) {
  //   final Map<String, dynamic> body = json.decode(cachedMovieDetails);
  //   movieDetails = MovieDetailsApi.fromJson(body);
  // } else {
    final response = await https.get(
      Uri.parse('https://api.ekomflix.com/android/getMovieDetails/$contentId'),
      headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = json.decode(response.body);
      // prefs.setString('movie_details_$contentId', response.body); // Cache the movie details
      movieDetails = MovieDetailsApi.fromJson(body);
    } else {
      throw Exception('Failed to load movie details');
    }
  // }

  // Preload the banner and poster images
  if (movieDetails.banner.isNotEmpty) {
    await precacheImage(
      CachedNetworkImageProvider(movieDetails.banner),
      context,
    );
  }

  if (movieDetails.poster.isNotEmpty) {
    await precacheImage(
      CachedNetworkImageProvider(movieDetails.poster),
      context,
    );
  }

  return movieDetails;
}


Future<Map<String, String>> fetchMoviePlayLink(int movieId) async {
  final response = await https.get(
    Uri.parse('https://api.ekomflix.com/android/getMoviePlayLinks/$movieId/0'),
    headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
  );

  if (response.statusCode == 200) {
    final List<dynamic> body = json.decode(response.body);
    if (body.isNotEmpty) {
      final Map<String, dynamic> firstItem = body.first as Map<String, dynamic>;
      return {'url': firstItem['url'] ?? '', 'type': firstItem['type'] ?? ''};
    }
    return {'url': '', 'type': ''};
  } else {
    throw Exception('Failed to load movie play link');
  }
}

class SubVod extends StatefulWidget {
  @override
  _SubVodState createState() => _SubVodState();
}

class _SubVodState extends State<SubVod> {
  late Future<List<NetworkApi>> _networksFuture;

  @override
  void initState() {
    super.initState();
    _networksFuture = fetchNetworks(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cardColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contents', // Heading text
            style: TextStyle(
              fontSize: 20.0, // You can change the size as needed
              fontWeight: FontWeight.bold,
              color: Colors.white, // Customize text color if needed
            ),
          ),
          Expanded(
            child: FutureBuilder<List<NetworkApi>>(
              future: _networksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: LoadingIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No Networks Available'));
                } else {
                  final networks = snapshot.data!;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: networks.length,
                    itemBuilder: (context, index) {
                      return FocusableItemWidget(
                        imageUrl: networks[index].logo,
                        name: networks[index].name,
                        onTap: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ContentScreen(networkId: networks[index].id),
                            ),
                          );
                        },
                        fetchPaletteColor: fetchPaletteColor,
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ContentScreen extends StatefulWidget {
  final int networkId;

  ContentScreen({required this.networkId});

  @override
  _ContentScreenState createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  late Future<List<ContentApi>> _contentFuture;

  @override
  void initState() {
    super.initState();
    _contentFuture = fetchContent(context,widget.networkId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cardColor,
      body: FutureBuilder<List<ContentApi>>(
        future: _contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: LoadingIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No Content Available'));
          } else {
            final content = snapshot.data!;
            return Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: screenwdt * 0.03, vertical: screenhgt * 0.01),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    // crossAxisSpacing: 10,
                    // mainAxisSpacing: 10,
                    childAspectRatio: 0.8),
                itemCount: content.length,
                itemBuilder: (context, index) {
                  return FocusableItemWidget(
                    imageUrl: content[index].banner,
                    name: content[index].name,
                    onTap: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailsPage(content: content[index]),
                        ),
                      );
                    },
                    fetchPaletteColor: fetchPaletteColor,
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}




class DetailsPage extends StatefulWidget {
  final ContentApi content;

  DetailsPage({required this.content});

  @override
  _DetailsPageState createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  final SocketService _socketService = SocketService();
  final int _maxRetries = 3;
  final int _retryDelay = 5; // seconds
  bool _shouldContinueLoading = true;
  bool _isLoading = false;
  MovieDetailsApi? _movieDetails;

  @override
  void initState() {
    super.initState();
    _socketService.initSocket();
    checkServerStatus();
    _loadMovieDetails();
  }

  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }

  Future<void> _loadMovieDetails() async {
    try {
      final details = await fetchMovieDetails(context,widget.content.id);
      setState(() {
        _movieDetails = details;
      });
    } catch (e) {
      print('Something Went Wrong');
      // Handle error (e.g., show a snackbar)
    }
  }

  // Add this method to check the server status and reconnect if needed
  void checkServerStatus() {
    Timer.periodic(Duration(seconds: 10), (timer) {
      if (!_socketService.socket.connected) {
        print('YouTube server down, retrying...');
        _socketService.initSocket(); // Re-establish the socket connection
      }
    });
  }

  Future<void> _updateUrlIfNeeded(Map<String, String> playLink) async {
    if (playLink['type'] == 'Youtube' || playLink['type'] == 'YoutubeLive') {
      for (int i = 0; i < _maxRetries; i++) {
        if (!_shouldContinueLoading) break;
        try {
          String updatedUrl =
              await _socketService.getUpdatedUrl(playLink['url']!);
          playLink['url'] = updatedUrl;
          playLink['type'] = 'M3u8';
          break;
        } catch (e) {
          if (i == _maxRetries - 1) rethrow;
          await Future.delayed(Duration(seconds: _retryDelay));
        }
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_isLoading) {
      setState(() {
        _isLoading = false;
        _shouldContinueLoading = false;
      });
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: cardColor,
        body: Stack(
          children: [
            _movieDetails == null
                ? Center(child: LoadingIndicator())
                : Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenwdt * 0.03),
                    child: _buildMovieDetailsUI(context, _movieDetails!),
                  ),
            if (_isLoading)
              Center(
                child: SpinKitFadingCircle(
                  color: borderColor,
                  size: 50.0,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieDetailsUI(
      BuildContext context, MovieDetailsApi movieDetails) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (movieDetails.status == '1')
            CachedNetworkImage(
              imageUrl: movieDetails.banner,
              placeholder: (context, url) => localImage,
              fit: BoxFit.cover,
              width: screenwdt * 0.7,
              height: screenhgt * 0.55,
            ),
          Text(movieDetails.name,
              style: TextStyle(color: Colors.white, fontSize: nametextsz)),
          SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 1,
              itemBuilder: (context, index) {
                return FocusableItemWidget(
                  imageUrl: widget.content
                      .banner, // Replace with actual image URL if available
                  name: '',
                  onTap: () => _playVideo(movieDetails),
                  fetchPaletteColor: fetchPaletteColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _playVideo(MovieDetailsApi movieDetails) async {
    setState(() {
      _isLoading = true;
    });
    _shouldContinueLoading = true;

    try {
      final playLink = await fetchMoviePlayLink(widget.content.id);
      await _updateUrlIfNeeded(playLink);

      if (_shouldContinueLoading) {
        if (playLink['type'] == 'VLC' || playLink['type'] == 'VLC') {
          //   // Navigate to VLC Player screen when stream type is VLC
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VlcPlayerScreen(
                videoUrl: playLink['url']!,
                // videoTitle: movieDetails.name,
                channelList: [],
                genres: movieDetails.genres,
                // channels: [],
                // initialIndex: 1,
                bannerImageUrl: movieDetails.banner,
                startAtPosition: Duration.zero,
                // onFabFocusChanged: (bool) {},
                isLive: false,
              ),
            ),
          );
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoMovieScreen(
                videoUrl: playLink['url']!,
                videoTitle: movieDetails.name,
                channelList: [],
                videoBanner: movieDetails.banner,
                onFabFocusChanged: (bool focused) {},
                genres: movieDetails.genres,
                videoType: playLink['type']!,
                url: playLink['url']!,
                type: playLink['type']!,
              ),
            ),
          );
        }
      }
    } catch (e) {
      _handleVideoError(context);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleVideoError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Something Went Wrong', style: TextStyle(fontSize: 20))),
    );
  }
}
