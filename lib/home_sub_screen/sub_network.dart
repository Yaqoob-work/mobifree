import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:container_gradient_border/container_gradient_border.dart';
import 'package:mobi_tv_entertainment/main.dart';
import '../screens/v_o_d.dart';
import '../video_widget/video_movie_screen.dart';

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
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Material(
            //   elevation: 0,
              
                // child: 
                Container(
                  padding: const EdgeInsets.all(10.0),

                  child: AnimatedContainer(
                  // padding: const EdgeInsets.all(10.0),
                  
                    width: _focusNode.hasFocus ? screenwdt * 0.35 : screenwdt * 0.27,
                    height: _focusNode.hasFocus ? screenhgt * 0.23 : screenhgt * 0.2,
                    duration: const Duration(milliseconds: 400),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                  
                      color: hintColor,
                      border: Border.all(
                        color:hintColor,
                            // _focusNode.hasFocus ? primaryColor : Colors.transparent,
                        width: 10.0,
                  
                      ),
                  
                    ),
                    // child: Opacity(
                      // opacity: _focusNode.hasFocus ? 1 : 0.7,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Image.network(
                          widget.network.logo,
                          width:
                              _focusNode.hasFocus ? screenwdt * 0.35 : screenwdt * 0.27,
                          height:
                              _focusNode.hasFocus ? screenhgt * 0.23 : screenhgt * 0.2,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ),
              // ),
            // ),

            // const SizedBox(height: 8.0),
            // Container(
            //   width: _focusNode.hasFocus ? 180 : 120,
            //   child: Text(
            //     // entertainmentList[index]['name'] ?? 'Unknown',
            //       (widget.network.name).toUpperCase(),

            //     style: TextStyle(
            //       fontSize: 20,
            //       color: _focusNode.hasFocus
            //           ? highlightColor
            //           : Colors.white,
            //     ),

            //     textAlign: TextAlign.center,
            //     maxLines: 1,
            //     overflow: TextOverflow.ellipsis,
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
          // decoration: BoxDecoration(
          //   border: Border.all(
          //     color: _focusNode.hasFocus ? Colors.yellow : Colors.transparent,
          //     width: 3.0,
          //   ),
          // ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                // padding: EdgeInsets.all(10),
                width: _focusNode.hasFocus ? screenwdt * 0.35 : screenwdt * 0.27,
                height:
                    _focusNode.hasFocus ? screenhgt * 0.23 : screenhgt * 0.2,
                duration: const Duration(milliseconds: 400),
                decoration: BoxDecoration(
                  border: Border.all(
                    color:Colors.white,
                        // _focusNode.hasFocus ? primaryColor : Colors.transparent,
                    width: 10.0,
                  ),
                  borderRadius: BorderRadius.circular(5),

                ),

                // child: Opacity(
                //   opacity: _focusNode.hasFocus ? 1 : 0.7,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.network(
                    widget.content.banner,
                    width:
                        _focusNode.hasFocus ? screenwdt * 0.35 : screenwdt * 0.27,
                    height:
                        _focusNode.hasFocus ? screenhgt * 0.23 : screenhgt * 0.2,
                    fit: BoxFit.cover,
                  ),
                ),
                // ),
              ),

              // const SizedBox(height: 8.0),
              // Container(
              //   width: _focusNode.hasFocus ? 180 : 120,
              //   child: Text(
              //     // entertainmentList[index]['name'] ?? 'Unknown',
              //       (widget.content.name).toUpperCase(),

              //     style: TextStyle(
              //       fontSize: 20,
              //       color: _focusNode.hasFocus
              //           ? highlightColor
              //           : Colors.white,
              //     ),

              //     textAlign: TextAlign.center,
              //     maxLines: 1,
              //     overflow: TextOverflow.ellipsis,
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
class SubNetwork extends StatefulWidget {
  @override
  _SubNetworkState createState() => _SubNetworkState();
}

class _SubNetworkState extends State<SubNetwork> {
  List<NetworkApi> networks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNetworks().then((data) {
      setState(() {
        networks = data;
        isLoading = false;
      });
    }).catchError((error) {
      setState(() {
        isLoading = false;
      });
    });
  }

  void navigateToContent(int networkId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContentScreen(networkId: networkId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cardColor,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          :
          // Expanded(
          // child: GridView.builder(
          //   shrinkWrap: true,
          //   physics: NeverScrollableScrollPhysics(),
          //   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          //     crossAxisCount: 3,
          //     // childAspectRatio: 2 / 1,
          //   ),
          //   itemCount: networks.length,
          //   itemBuilder: (context, index) {
          //     return FocusableGridItem(
          //       network: networks[index],
          //       onTap: () => navigateToContent(networks[index].id),
          //     );
          //   },
          // ),
          // child:
          ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: networks.length,
              itemBuilder: (context, index) {
                return FocusableGridItem(
                  network: networks[index],
                  onTap: () => navigateToContent(networks[index].id),
                );
              },
            ),
      // ),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cardColor,
      body: FutureBuilder<List<ContentApi>>(
        future: fetchContent(widget.networkId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final contentList = snapshot.data ?? [];
            return GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                // childAspectRatio: 2 / 1,
              ),
              itemCount: contentList.length,
              itemBuilder: (context, index) {
                final content = contentList[index];
                return FocusableGridItemContent(
                    content: content,
                    onTap: () async {
                      final movieDetails = await fetchMovieDetails(content.id);
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
                              videoType: playLink['type']!,
                              videoTitle: '',
                              channelList: [],
                              videoBanner: '',
                              onFabFocusChanged: (bool focused) {},
                              genres: '', url: '', type: '',),
                        ),
                      );
                    });
              },
            );
          }
        },
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: SubNetwork(),
  ));
}
