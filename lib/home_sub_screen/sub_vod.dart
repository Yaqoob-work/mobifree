import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobi_tv_entertainment/main.dart';
import '../video_widget/video_movie_screen.dart';


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
  final String poster;
  final String genres;

  MovieDetailsApi(
      {required this.id,
      required this.name,
      required this.banner,
      required this.poster,
      required this.genres});

  factory MovieDetailsApi.fromJson(Map<String, dynamic> json) {
    return MovieDetailsApi(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      name: json['name'] ?? 'No Name',
      banner: json['banner'] ?? 'https://via.placeholder.com/150',
      poster: json['poster'] ?? 'https://via.placeholder.com/150',
      genres: json['genres'] ?? 'Unknown',
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
            Container(
                padding: EdgeInsets.symmetric(horizontal: 10),

              child: AnimatedContainer(
                width: _focusNode.hasFocus ? screenwdt * 0.35 : screenwdt * 0.27,
                height: _focusNode.hasFocus ? screenhgt * 0.23 : screenhgt * 0.2,
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _focusNode.hasFocus ?borderColor: hintColor,
                    width: 5.0,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
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
                height:
                    _focusNode.hasFocus ? screenhgt * 0.23 : screenhgt * 0.2,
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _focusNode.hasFocus ?borderColor: hintColor,
                    width: 5.0,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.network(
                    widget.content.banner,
                    fit: BoxFit.cover,
                    width: _focusNode.hasFocus
                        ? screenwdt * 0.35
                        : screenwdt * 0.3,
                    height: _focusNode.hasFocus
                        ? screenhgt * 0.23
                        : screenhgt * 0.2,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(child: Text('Image not available'));
                    },
                  ),
                ),
              ),
              // SizedBox(height: 5),
              // Container(
              //   width: _focusNode.hasFocus ? screenwdt * 0.33 : screenwdt * 0.3,
              //   child: Text(
              //     widget.content.name,
              //     style: TextStyle(
              //       color: _focusNode.hasFocus ? Colors.yellow : Colors.white,
              //       fontSize: _focusNode.hasFocus ? 20 : 16,
              //     ),
              //     textAlign: TextAlign.center,
              //     overflow: TextOverflow.ellipsis,
              //     maxLines: 2,
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

// Pages
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
    print('Building SubVod'); // Debug print
    return Scaffold(
      backgroundColor: cardColor,
      body: FutureBuilder<List<NetworkApi>>(
        future: _networksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Failed to load networks'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No networks available'));
          } else {
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final network = snapshot.data![index];
                return FocusableGridItem(
                  network: network,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NetworkContentsScreen(
                          network: network,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}


class NetworkContentsScreen extends StatelessWidget {
  final NetworkApi network;

  NetworkContentsScreen({required this.network});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cardColor,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: FutureBuilder<List<ContentApi>>(
          future: fetchContent(network.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Failed to load content'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No content available'));
            } else {
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  // mainAxisSpacing: 10,
                  // crossAxisSpacing: 10,
                  // childAspectRatio: 1.0,
                ),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final content = snapshot.data![index];
                  return FocusableGridItemContent(
                    content: content,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailsPage(
                            // contentId: content.id,
                             content: content,
                          ),
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
    );
  }
}




class DetailsPage extends StatelessWidget {
  final ContentApi content;

  DetailsPage({required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cardColor,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: FutureBuilder<MovieDetailsApi>(
          future: fetchMovieDetails(content.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Failed to load movie details'));
            } else if (!snapshot.hasData) {
              return Center(child: Text('No movie details available'));
            } else {
              final movieDetails = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: screenhgt * 0.5,
                    width: screenwdt ,
                  alignment: Alignment.center,
                  child: Image.network(
                    movieDetails.poster,
                    fit: BoxFit.cover,
                    height: screenhgt * 0.5,
                    width: screenwdt ,
                  ),
                  ),
                  Center(
                    child: Text(
                      movieDetails.name,
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 1, // Assume we have only one detail item
                      itemBuilder: (context, index) {
                        return FocusableGridItemContent(
                          content: content,
                          onTap: () async {
                            final playLink = await fetchMoviePlayLink(content.id);
                            // final movieDetails =
                            // await fetchMovieDetails(content.id);
                        // final playLink =
                        //     await fetchMoviePlayLink(movieDetails.id);

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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoMovieScreen(
                               videoUrl: playLink['url']!, videoTitle: '', channelList: [], videoBanner: '', onFabFocusChanged: (bool focused) {  }, genres: '', videoType: '', url: '', type: '',
                             ),
                                //   playLink: playLink['url']!,
                                // ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}