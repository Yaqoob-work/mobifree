import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobi_tv_entertainment/main.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_player/video_player.dart';

import '../video_widget/video_movie_screen.dart';
import 'v_o_d.dart';

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
      logo: json['logo'] ?? 'https://via.placeholder.com/150',
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
      banner: json['banner'] ?? 'https://via.placeholder.com/150',
    );
  }
}

class MovieDetailsApi {
  final int id;
  final String name;
  final String banner;

  MovieDetailsApi({required this.id, required this.name, required this.banner});

  factory MovieDetailsApi.fromJson(Map<String, dynamic> json) {
    return MovieDetailsApi(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      name: json['name'] ?? 'No Name',
      banner: json['banner'] ?? 'https://via.placeholder.com/150',
    );
  }
}

// Fetch Functions
Future<List<NetworkApi>> fetchNetworks() async {
  final response = await http.get(
    Uri.parse('https://mobifreetv.com/android/getNetworks'),
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
  final response = await http.get(
    Uri.parse(
        'https://mobifreetv.com/android/getAllContentsOfNetwork/$networkId'),
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
  final response = await http.get(
    Uri.parse('https://mobifreetv.com/android/getMovieDetails/$contentId'),
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
  final response = await http.get(
    Uri.parse('https://mobifreetv.com/android/getMoviePlayLinks/$movieId/0'),
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

// Widgets
class FocusableGridItem extends StatefulWidget {
  final NetworkApi network;
  final VoidCallback onTap;

  FocusableGridItem({required this.network, required this.onTap});

  @override
  _FocusableGridItemState createState() => _FocusableGridItemState();
}

class _FocusableGridItemState extends State<FocusableGridItem> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedContainer(
              width: _focusNode.hasFocus ? screenwdt * 0.35 : screenwdt * 0.27,
              height: _focusNode.hasFocus ? screenhgt * 0.23 : screenhgt * 0.2,
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color:hintColor,
                      // _focusNode.hasFocus ? hintColor : Colors.transparent,
                  width: 10.0,
                ),
                  borderRadius: BorderRadius.circular(5),

              ),
              // child: Opacity(
              //   opacity: _focusNode.hasFocus ? 1 : 0.7,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.network(
                    widget.network.logo,
                    fit: BoxFit.cover,
                    width:
                        _focusNode.hasFocus ? screenwdt * 0.35 : screenwdt * 0.3,
                    height:
                        _focusNode.hasFocus ? screenhgt * 0.23 : screenhgt * 0.2,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(child: Text('Image not available'));
                    },
                  ),
                ),
              // ),
            ),
            // Container(
            //   width: _focusNode.hasFocus ? screenwdt * 0.3 : screenwdt * 0.27,
            //   child: Text(
            //     (widget.network.name).toUpperCase(),
            //     textAlign: TextAlign.center,
            //     overflow: TextOverflow.ellipsis,
            //     maxLines: 1,
            //     style: TextStyle(
            //       color: _focusNode.hasFocus ? highlightColor : Colors.white,
            //       fontSize: _focusNode.hasFocus ? 20 : 18,
            //       fontWeight: FontWeight.bold,
            //     ),
            //   ),
            // ),
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
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(

                width: _focusNode.hasFocus ? screenwdt * 0.35 : screenwdt * 0.3,
              height: _focusNode.hasFocus ? screenhgt * 0.25 : screenhgt * 0.2,
              duration: const Duration(milliseconds: 400),
              decoration: BoxDecoration(
                color: hintColor,
                border: Border.all(
                  
                  color:hintColor,
                      // _focusNode.hasFocus ? hintColor : Colors.transparent,
                  width: 10.0,
                ),
                borderRadius: BorderRadius.circular(5),

              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Image.network(
                    widget.content.banner,
                    fit: BoxFit.cover,
                    width:
                        _focusNode.hasFocus ? screenwdt * 0.35 : screenwdt * 0.27,
                    height:
                        _focusNode.hasFocus ? screenhgt * 0.23 : screenhgt * 0.2,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(child: Text('Image not available'));
                    },
                  ),
              ),
              ),
              // Container(
              //   width: _focusNode.hasFocus ? screenwdt * 0.3 : screenwdt * 0.27,
              //   child: Text(
              //     (widget.content.name).toUpperCase(),
              //     textAlign: TextAlign.center,
              //     overflow: TextOverflow.ellipsis,
              //     maxLines: 1,
              //     style: TextStyle(
              //       color: _focusNode.hasFocus ? highlightColor : Colors.white,
              //       fontSize: _focusNode.hasFocus ? 20 : 18,
              //       fontWeight: FontWeight.bold,
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

class Network extends StatefulWidget {
  @override
  _NetworkState createState() => _NetworkState();
}

class _NetworkState extends State<Network> {
  late Future<List<NetworkApi>> futureNetworks;

  @override
  void initState() {
    super.initState();
    futureNetworks = fetchNetworks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cardColor,
      body: Center(
        child: FutureBuilder<List<NetworkApi>>(
          future: futureNetworks,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              final networks = snapshot.data!;
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  // mainAxisSpacing: 10,
                  // crossAxisSpacing: 10,
                  // childAspectRatio: 0.80,
                ),
                itemCount: networks.length,
                itemBuilder: (context, index) {
                  final network = networks[index];
                  return FocusableGridItem(
                    network: network,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              NetworkContentsScreen(networkId: network.id),
                        ),
                      );
                    },
                  );
                },
              );
            } else {
              return Text('No data available');
            }
          },
        ),
      ),
    );
  }
}

class NetworkContentsScreen extends StatefulWidget {
  final int networkId;

  NetworkContentsScreen({required this.networkId});

  @override
  _NetworkContentsScreenState createState() => _NetworkContentsScreenState();
}

class _NetworkContentsScreenState extends State<NetworkContentsScreen> {
  late Future<List<ContentApi>> futureContent;

  @override
  void initState() {
    super.initState();
    futureContent = fetchContent(widget.networkId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cardColor,
      body: Center(
        child: FutureBuilder<List<ContentApi>>(
          future: futureContent,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              final contents = snapshot.data!;
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  // mainAxisSpacing: 10,
                  // crossAxisSpacing: 10,
                ),
                itemCount: contents.length,
                itemBuilder: (context, index) {
                  final content = contents[index];
                  return FocusableGridItemContent(
                      content: content,
                      
                      onTap: () async {
                        final movieDetails =
                            await fetchMovieDetails(content.id);
                        final playLink =
                            await fetchMoviePlayLink(movieDetails.id);

                        if (playLink['type'] == 'Youtube') {
                          final response = await http.get(
                            Uri.parse(
                                'https://test.gigabitcdn.net/yt-dlp.php?v=' +
                                    playLink['url']!),
                            headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
                          );

                          if (response.statusCode == 200) {
                            playLink['url'] = json.decode(response.body)['url'];
                            playLink['type'] = "M3u8";
                            
                          } else {
                            throw Exception('Failed to load networks');
                          }
                        }
                        // print('saddam $playLink');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoMovieScreen(
                              videoUrl: playLink['url']!,
                              videoType: playLink['type']!, videoTitle: '', channelList: [], videoBanner: '', onFabFocusChanged: (bool focused) {  }, genres: '', url: '', type: '',
                            ),
                          ),
                        );
                      });
                },
              );
            } else {
              return Text('No data available');
            }
          },
        ),
      ),
    );
  }
}



// this code is just copy of other page (VOD)
//  void _onItemTap(BuildContext context, int index) async {
  //   if (searchResults[index]['stream_type'] == 'YoutubeLive') {
  //     final response = await http.get(
  //       Uri.parse('https://test.gigabitcdn.net/yt-dlp.php?v=' +
  //           searchResults[index]['url']),
  //       headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
  //     );

  //     if (response.statusCode == 200 &&
  //         json.decode(response.body)['url'] != '') {
  //       searchResults[index]['url'] = json.decode(response.body)['url'];
  //       searchResults[index]['stream_type'] = "M3u8";
  //     } else {
  //       throw Exception('Failed to load networks');
  //     }
  //   }
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => VideoScreen(
  //         videoUrl: searchResults[index]['url'] ?? '',
  //         videoTitle: searchResults[index]['name'] ?? 'Unknown',
  //         channelList: searchResults,
  //         onFabFocusChanged: _handleFabFocusChanged,
  //         genres: '',
  //       ),
  //     ),
  //   );
  // }
