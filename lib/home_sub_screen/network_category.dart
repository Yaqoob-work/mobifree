import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobi_tv_entertainment/main.dart';
import 'dart:convert';
import 'package:video_player/video_player.dart';

// Model class for Content
class Content {
  final String id;
  final String title;
  final String description;
  final String poster;
  final String banner;
  final String genres;

  Content({
    required this.id,
    required this.title,
    required this.description,
    required this.poster,
    required this.banner,
    required this.genres,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      id: json['id'] ?? 'N/A',
      title: json['name'] ?? 'No title',
      description: json['description'] ?? 'No description',
      poster: json['poster'] ?? '',
      banner: json['banner'] ?? '',
      genres: json['genres'] ?? 'Unknown',
    );
  }
}

// Network Page
class NetworkCategory extends StatefulWidget {
  @override
  _NetworkCategoryState createState() => _NetworkCategoryState();
}

class _NetworkCategoryState extends State<NetworkCategory> {
  Map<String, List<Content>> categorizedContents = {};
  bool isLoading = false;
  bool hasMoreIds = true;
  final Map<String, FocusNode> focusNodes = {};

  @override
  void initState() {
    super.initState();
    fetchAllIds();
  }

  Future<void> fetchAllIds() async {
    setState(() {
      isLoading = true;
    });

    int id = 0;

    while (hasMoreIds) {
      try {
        final headers = {
          'x-api-key': 'vLQTuPZUxktl5mVW',
        };

        final response = await http.get(
          Uri.parse(
              'https://mobifreetv.com/android/getAllContentsOfNetwork/$id'),
          headers: headers,
        );

        print('Response body: ${response.body}');

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);

          if (data.isEmpty) {
            setState(() {
              hasMoreIds = false;
            });
          } else {
            final newContents =
                data.map((item) => Content.fromJson(item)).toList();

            for (var content in newContents) {
              if (content.genres.isNotEmpty) {
                if (categorizedContents.containsKey(content.genres)) {
                  categorizedContents[content.genres]!.add(content);
                } else {
                  categorizedContents[content.genres] = [content];
                  focusNodes[content.genres] =
                      FocusNode(); // Initialize focus nodes
                }
              }
            }

            setState(() {
              id++;
            });
          }
        } else {
          print('Error: ${response.statusCode}');
          setState(() {
            hasMoreIds = false;
          });
        }
      } catch (e) {
        print('Error fetching data: $e');
        setState(() {
          hasMoreIds = false;
        });
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  void _onCategoryTap(String genre) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryContentPage(
          genre: genre,
          contents: categorizedContents[genre] ?? [],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: categorizedContents.keys.length,
              itemBuilder: (context, index) {
                final genre = categorizedContents.keys.elementAt(index);
                final focusNode = focusNodes[genre]!;

                return Focus(
                  focusNode: focusNode,
                  onFocusChange: (hasFocus) {
                    setState(() {}); // Update the UI to reflect the focus state
                  },
                  onKey: (FocusNode node, RawKeyEvent event) {
                    if (event is RawKeyDownEvent &&
                        (event.logicalKey == LogicalKeyboardKey.select ||
                            event.logicalKey == LogicalKeyboardKey.enter)) {
                      _onCategoryTap(genre);
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: GestureDetector(
                    onTap: () => _onCategoryTap(genre),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: focusNode.hasFocus
                                    ? AppColors.primaryColor
                                    : Colors.transparent,
                                width: 3.0,
                              ),
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            // child: GridTile(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: Image.network(
                                categorizedContents[genre]!.isNotEmpty
                                    ? categorizedContents[genre]![0].banner
                                    : '',
                                fit: BoxFit.cover,
                                width: focusNode.hasFocus ? 120 : 90,
                                height: focusNode.hasFocus ? 90 : 70,
                              ),
                            ),
                          ),
                          // footer: GridTileBar(
                          // backgroundColor: Colors.black54,
                          // title:
                          Text(
                            genre,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: focusNode.hasFocus
                                  ? AppColors.highlightColor
                                  : AppColors.hintColor,
                            ),
                          ),
                          // ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// CategoryContentPage
class CategoryContentPage extends StatefulWidget {
  final String genre;
  final List<Content> contents;

  CategoryContentPage({required this.genre, required this.contents});

  @override
  _CategoryContentPageState createState() => _CategoryContentPageState();
}

class _CategoryContentPageState extends State<CategoryContentPage> {
  final Map<String, FocusNode> focusNodes = {};

  @override
  void initState() {
    super.initState();
    // Initialize focus nodes for each content item
    for (var content in widget.contents) {
      focusNodes[content.id] = FocusNode();
    }
  }

  @override
  void dispose() {
    // Dispose all focus nodes to avoid memory leaks
    for (var node in focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _onBannerTap(BuildContext context, String id) async {
    final playUrl = await _fetchPlayUrl(id);

    if (playUrl != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayVideoPage(url: playUrl),
        ),
      );
    } else {
      print('No URL found for this content');
    }
  }

  Future<String?> _fetchPlayUrl(String id) async {
    try {
      final headers = {
        'x-api-key': 'vLQTuPZUxktl5mVW',
      };

      final response = await http.get(
        Uri.parse('https://mobifreetv.com/android/getMoviePlayLinks/$id/0'),
        headers: headers,
      );

      print('Play URL response: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.contains('No Data Avaliable')) {
          print('No Data Available for this content');
          return null;
        }

        try {
          final List<dynamic> data = jsonDecode(response.body);

          if (data.isNotEmpty && data[0] is Map<String, dynamic>) {
            final url = data[0]['url'] as String?;
            return url;
          } else {
            print('Invalid data format');
            return null;
          }
        } catch (e) {
          print('Error parsing JSON response: $e');
          return null;
        }
      } else {
        print('Error fetching play URL: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching play URL: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: widget.contents.length,
        itemBuilder: (context, index) {
          final content = widget.contents[index];
          final focusNode = focusNodes[content.id]!;

          return Focus(
            focusNode: focusNode,
            onFocusChange: (hasFocus) {
              setState(() {}); // Update the UI to reflect the focus state
            },
            onKey: (FocusNode node, RawKeyEvent event) {
              if (event is RawKeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.select ||
                      event.logicalKey == LogicalKeyboardKey.enter)) {
                _onBannerTap(context, content.id);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: GestureDetector(
              onTap: () => _onBannerTap(context, content.id),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: focusNode.hasFocus
                              ? AppColors.primaryColor
                              : Colors.transparent,
                          width: 3.0,
                        ),
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Image.network(
                          content.banner,
                          fit: BoxFit.cover,
                          width: focusNode.hasFocus ? 120 : 90,
                          height: focusNode.hasFocus ? 90 : 70,
                        ),
                      ),
                    ),

                    Text(
                      '${content.id} - ${content.title}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: focusNode.hasFocus
                            ? AppColors.highlightColor
                            : AppColors.hintColor,
                      ),
                    ),
                    // ),
                    // ),
                  ],
                ),
              ),
            ),
            // ),
          );
        },
      ),
    );
  }
}

// PlayVideoPage (for demonstration)
class PlayVideoPage extends StatefulWidget {
  final String url;

  PlayVideoPage({required this.url});

  @override
  _PlayVideoPageState createState() => _PlayVideoPageState();
}

class _PlayVideoPageState extends State<PlayVideoPage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        setState(() {});
        _controller.play(); // Auto-play the video when initialized
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio:16/9,
                child: VideoPlayer(_controller),
              )
            : CircularProgressIndicator(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
