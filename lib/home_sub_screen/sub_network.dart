


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:container_gradient_border/container_gradient_border.dart';
import 'package:mobi_tv_entertainment/main.dart';
import '../screens/v_o_d.dart';


// Models
class NetworkApi {
  final int id;
  final String name;
  final String logo;

  NetworkApi({required this.id, required this.name, required this.logo});

  factory NetworkApi.fromJson(Map<String, dynamic> json) {
    return NetworkApi(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
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
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
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
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
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
    Uri.parse('https://mobifreetv.com/android/getAllContentsOfNetwork/$networkId'),
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

Future<String> fetchMoviePlayLink(int movieId) async {
  final response = await http.get(
    Uri.parse('https://mobifreetv.com/android/getMoviePlayLinks/$movieId/0'),
    headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
  );

  if (response.statusCode == 200) {
    final List<dynamic> body = json.decode(response.body);
    if (body.isNotEmpty) {
      final Map<String, dynamic> firstItem = body.first as Map<String, dynamic>;
      return firstItem['url'] ?? '';
    }
    return '';
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
      onKey: (node, event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        // child: Container(
        //   decoration: BoxDecoration(
        //     border: Border.all(
        //       color: _focusNode.hasFocus ? Colors.yellow : Colors.transparent,
        //       width: 3.0,
        //     ),
        //   ),
          
            // margin: EdgeInsets.all(5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _focusNode.hasFocus ? 220 : 120,
            height: _focusNode.hasFocus ? 170 : 120,
             child:   ContainerGradientBorder(
                  width: _focusNode.hasFocus ? 200 : 110,
                  height: _focusNode.hasFocus ? 150 : 110,
                  start: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  borderWidth: 7,
                  colorList: _focusNode.hasFocus
                      ? [AppColors.primaryColor, AppColors.highlightColor,AppColors.primaryColor, AppColors.highlightColor,AppColors.primaryColor, AppColors.highlightColor,AppColors.primaryColor, AppColors.highlightColor,]
                      : [AppColors.primaryColor, AppColors.highlightColor,],
                  borderRadius: 10,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.network(
                      widget.network.logo,
                      fit: BoxFit.cover,
                      width: _focusNode.hasFocus ? 180 : 100,
                      height: _focusNode.hasFocus ? 130 : 100,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(child: Text('Image not available'));
                      },
                    ),
                  ),
                ),),
                SizedBox(height: 8),
                Container(
                      width: _focusNode.hasFocus ? 180 : 100,

                  child: Text(
                    widget.network.name,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: _focusNode.hasFocus ? AppColors.highlightColor : Colors.white,
                      fontSize: _focusNode.hasFocus ? 20 : 18,
                      fontWeight: FontWeight.bold,
                      
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
  _FocusableGridItemContentState createState() => _FocusableGridItemContentState();
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
      onKey: (node, event) {
        if (event is RawKeyDownEvent) {
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
              children: [
                AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _focusNode.hasFocus ? 220 : 120,
            height: _focusNode.hasFocus ? 170 : 120,
             child:
                ContainerGradientBorder(
                  width: _focusNode.hasFocus ? 200 : 110,
                  height: _focusNode.hasFocus ? 150 : 110,
                  start: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  borderWidth: 7,
                  colorList: _focusNode.hasFocus
                      ? [AppColors.primaryColor, AppColors.highlightColor,AppColors.primaryColor, AppColors.highlightColor,AppColors.primaryColor, AppColors.highlightColor,AppColors.primaryColor, AppColors.highlightColor,]
                      : [AppColors.primaryColor, AppColors.highlightColor,],
                  borderRadius: 10,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.network(
                      widget.content.banner,
                      fit: BoxFit.cover,
                      width: _focusNode.hasFocus ? 180 : 100,
                      height: _focusNode.hasFocus ? 130 : 100,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(child: Text('Image not available'));
                      },
                    ),
                  ),
                ),),),
                Container(
                      width: _focusNode.hasFocus ? 160 : 100,

                  child: Text(
                    widget.content.name,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: _focusNode.hasFocus ? AppColors.highlightColor : Colors.white,
                      fontSize: _focusNode.hasFocus ? 20 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
      backgroundColor: AppColors.cardColor,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Expanded(
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
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: networks.length,
                itemBuilder: (context, index) {
                  return FocusableGridItem(
                    network: networks[index],
                    onTap: () => navigateToContent(networks[index].id),
                  );
                },
              ),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardColor,

      body: FutureBuilder<List<ContentApi>>(
        future: fetchContent(widget.networkId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final contentList = snapshot.data ?? [];
            return Expanded(
              child: GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  // childAspectRatio: 2 / 1,
                ),
                itemCount: contentList.length,
                itemBuilder: (context, index) {
                  final content = contentList[index];
                  return FocusableGridItemContent(
                    content: content,
                    onTap: () async {
                      try {
                        final movieDetails = await fetchMovieDetails(content.id);
                        final videoUrl = await fetchMoviePlayLink(movieDetails.id);
                        if (videoUrl.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoScreen(
                                videoUrl: videoUrl,
                                videoTitle: movieDetails.name,
                                channelList: [], videoBanner: '', onFabFocusChanged: (bool focused) {  }, genres: '',
                              ),
                            ),
                          );
                        } else {
                          print('Video URL is empty');
                         
                        }
                      } catch (error) {
                        print('Error fetching video URL: $error');
                        
                      }
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

void main() {
  runApp(MaterialApp(
    home: SubNetwork(),
  ));
}
