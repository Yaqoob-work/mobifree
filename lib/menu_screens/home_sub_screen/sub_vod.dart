import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobi_tv_entertainment/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
import '../../services/socket_service.dart';
import '../../video_widget/video_movie_screen.dart';
import '../../widgets/utils/color_service.dart';

void main() {
  runApp(SubVod());
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

// Fetch Functions
Future<List<NetworkApi>> fetchNetworks() async {
  final response = await https.get(
    Uri.parse('https://api.ekomflix.com/android/getNetworks'),
    headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
  );

  if (response.statusCode == 200) {
    List<dynamic> body = json.decode(response.body);
    return body.map((dynamic item) => NetworkApi.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load networks');
  }
}

Future<List<ContentApi>> fetchContent(int networkId) async {
  final response = await https.get(
    Uri.parse(
        'https://api.ekomflix.com/android/getAllContentsOfNetwork/$networkId'),
    headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
  );

  if (response.statusCode == 200) {
    List<dynamic> body = json.decode(response.body);
    return body.map((dynamic item) => ContentApi.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load content');
  }
}

Future<MovieDetailsApi> fetchMovieDetails(int contentId) async {
  final response = await https.get(
    Uri.parse('https://api.ekomflix.com/android/getMovieDetails/$contentId'),
    headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> body = json.decode(response.body);
    return MovieDetailsApi.fromJson(body);
  } else {
    throw Exception('Failed to load movie details');
  }
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

class FocusableGridItem extends StatefulWidget {
  final NetworkApi network;
  final VoidCallback onTap;

  FocusableGridItem({required this.network, required this.onTap});

  @override
  _FocusableGridItemState createState() => _FocusableGridItemState();
}

class _FocusableGridItemState extends State<FocusableGridItem> {
  bool isFocused = false;
  Color paletcolor = Colors.grey; // Default color
  final PaletteColorService _paletteColorService = PaletteColorService();

  @override
  void initState() {
    super.initState();
    // _loadPaletteColor(); // Load the palette color
    _updateSecondaryColor();
  }

  // // Fetch palette color using ColorUtils and update paletcolor
  // Future<void> _loadPaletteColor() async {
  //   Color paletteColor = await ColorUtils.getPaletteColor(widget.network.logo);
  //   setState(() {
  //     paletcolor = paletteColor; // Update palette color with fetched color
  //   });
  // }

  Future<void> _updateSecondaryColor() async {
    // if (widget.channel.status == '1') {
    Color color =
        await _paletteColorService.getSecondaryColor(widget.network.logo);
    setState(() {
      paletcolor = color;
    });
    // }
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onFocusChange: (hasFocus) {
        setState(() {
          isFocused = hasFocus;
        });
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent intent) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                AnimatedContainer(
                  width: screenwdt * 0.15,
                  height: isFocused ? screenhgt * 0.32 : screenhgt * 0.3,
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    border: isFocused
                        ? Border.all(
                            color: paletcolor,
                            width: 4.0,
                          )
                        : Border.all(
                            color: Colors.transparent,
                            width: 4.0,
                          ),
                    borderRadius: BorderRadius.circular(0),
                    boxShadow: isFocused
                        ? [
                            BoxShadow(
                              color: paletcolor,
                              blurRadius: 25,
                              spreadRadius: 10,
                            )
                          ]
                        : [],
                  ),
                  child: CachedNetworkImage(
                    imageUrl: widget.network.logo,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => localImage,
                    width: screenwdt * 0.15,
                    height: isFocused ? screenhgt * 0.32 : screenhgt * 0.3,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Container(
              width: screenwdt * 0.15,
              child: Column(
                children: [
                  Text(
                    widget.network.name.toUpperCase(),
                    style: TextStyle(
                      color: isFocused ? paletcolor : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FocusableGridItemContent extends StatefulWidget {
  final ContentApi content;
  final VoidCallback onTap;

  FocusableGridItemContent({required this.content, required this.onTap});

  @override
  _FocusableGridItemContentState createState() =>
      _FocusableGridItemContentState();
}

class _FocusableGridItemContentState extends State<FocusableGridItemContent> {
  bool isFocused = false;
  Color paletcolor = Colors.transparent; // Default border color
  final PaletteColorService _paletteColorService = PaletteColorService();

  @override
  void initState() {
    super.initState();
    // _loadPaletteColor();
    _updateSecondaryColor();
  }

  // Fetch palette color using ColorUtils and update paletcolor
  // Future<void> _loadPaletteColor() async {
  //   Color paletteColor =
  //       await ColorUtils.getPaletteColor(widget.content.banner);
  //   setState(() {
  //     paletcolor =
  //         paletteColor; // Update border color with fetched palette color
  //   });
  // }

  Future<void> _updateSecondaryColor() async {
    // if (widget.channel.status == '1') {
    Color color =
        await _paletteColorService.getSecondaryColor(widget.content.banner);
    setState(() {
      paletcolor = color;
    });
    // }
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onFocusChange: (hasFocus) {
        setState(() {
          isFocused = hasFocus;
        });
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent intent) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedContainer(
              // width: screenwdt * 0.15,
              // height: isFocused ? screenhgt * 0.22 : screenhgt * 0.2,

              width: screenwdt * 0.19,
              height: isFocused ? screenhgt * 0.24 : screenhgt * 0.21,
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                border: isFocused
                    ? Border.all(
                        color: paletcolor,
                        width: 3.0,
                      )
                    : Border.all(
                        color: Colors.transparent,
                        width: 3.0,
                      ),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: paletcolor,
                          blurRadius: 25,
                          spreadRadius: 10,
                        )
                      ]
                    : [],
              ),
              child: CachedNetworkImage(
                imageUrl: widget.content.banner,
                placeholder: (context, url) => localImage,
                fit: BoxFit.cover,
                // width: screenwdt * 0.15,
                // height: screenhgt * 0.2,

                width: screenwdt * 0.19,
                height: isFocused ? screenhgt * 0.24 : screenhgt * 0.21,
              ),
            ),
            SizedBox(height: 10),
            Container(
              width: screenwdt * 0.15,
              child: Text(
                widget.content.name,
                style: TextStyle(
                  color: isFocused ? paletcolor : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
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
    _networksFuture = fetchNetworks();
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
                    child: SpinKitFadingCircle(
                      color: borderColor,
                      size: 50.0,
                    ),
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
                      return FocusableGridItem(
                        network: networks[index],
                        onTap: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ContentScreen(networkId: networks[index].id),
                            ),
                          );
                        },
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
    _contentFuture = fetchContent(widget.networkId);
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
              child: SpinKitFadingCircle(
                color: borderColor,
                size: 50.0,
              ),
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
                  return FocusableGridItemContent(
                    content: content[index],
                    onTap: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailsPage(content: content[index]),
                        ),
                      );
                    },
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
    _loadMovieDetails();
  }

  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }

  Future<void> _loadMovieDetails() async {
    try {
      final details = await fetchMovieDetails(widget.content.id);
      setState(() {
        _movieDetails = details;
      });
    } catch (e) {
      print('Error loading movie details: $e');
      // Handle error (e.g., show a snackbar)
    }
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
                ? Center(child: CircularProgressIndicator())
                : _buildMovieDetailsUI(context, _movieDetails!),
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
              height: screenhgt * 0.5,
            ),
          Text(movieDetails.name,
              style: TextStyle(color: Colors.white, fontSize: 20)),
          SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 1,
              itemBuilder: (context, index) {
                return FocusableGridItemContent(
                  content: widget.content,
                  onTap: () => _playVideo(movieDetails),
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
