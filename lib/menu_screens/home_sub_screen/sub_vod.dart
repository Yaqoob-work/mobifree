import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mobi_tv_entertainment/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as https;
import 'package:mobi_tv_entertainment/provider/color_provider.dart';
import 'package:mobi_tv_entertainment/provider/focus_provider.dart';
import 'package:mobi_tv_entertainment/provider/music_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../video_widget/socket_service.dart';
import '../../video_widget/video_screen.dart';
import '../../widgets/focussable_item_widget.dart';
import '../../widgets/models/news_item_model.dart';
import '../../widgets/small_widgets/loading_indicator.dart';
import '../../widgets/utils/color_service.dart';

Future<MovieDetailsApi> fetchMovieDetails(
    BuildContext context, int contentId) async {
  final prefs = await SharedPreferences.getInstance();
  final cachedMovieDetails = prefs.getString('movie_details_$contentId');

  // Step 1: Return cached data immediately if available
  if (cachedMovieDetails != null) {
    final Map<String, dynamic> body = json.decode(cachedMovieDetails);
    return MovieDetailsApi.fromJson(body);
  }

  // Step 2: Fetch API data if no cache is available
  final response = await https.get(
    Uri.parse('https://api.ekomflix.com/android/getMovieDetails/$contentId'),
    headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> body = json.decode(response.body);
    final movieDetails = MovieDetailsApi.fromJson(body);

    // Step 3: Cache the fetched data
    prefs.setString('movie_details_$contentId', response.body);

    // Return the fetched data
    return movieDetails;
  } else {
    throw Exception('Failed to load movie details');
  }
}

// Future<Color> fetchPaletteColor(String imageUrl) async {
//   return await PaletteColorService().getSecondaryColor(imageUrl);
// }

Future<Color> fetchPaletteColor(String imageUrl) async {
  try {
    return await PaletteColorService().getSecondaryColor(imageUrl);
  } catch (e) {
    print('Error fetching palette color for $imageUrl: $e');
    return Colors.grey; // Fallback color
  }
}

// Helper function to decode base64 images
Uint8List _getImageFromBase64String(String base64String) {
  return base64Decode(base64String.split(',').last);
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
  final prefs = await SharedPreferences.getInstance();
  final cachedNetworks = prefs.getString('networks');

  List<NetworkApi> networks = [];
  List<NetworkApi> apiNetworks;

  // Step 1: Use cached data for fast UI rendering
  if (cachedNetworks != null) {
    List<dynamic> cachedBody = json.decode(cachedNetworks);
    networks =
        cachedBody.map((dynamic item) => NetworkApi.fromJson(item)).toList();
  }

  // Step 2: Fetch API data in the background
  final response = await https.get(
    Uri.parse('https://api.ekomflix.com/android/getNetworks'),
    headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
  );

  if (response.statusCode == 200) {
    List<dynamic> body = json.decode(response.body);
    apiNetworks =
        body.map((dynamic item) => NetworkApi.fromJson(item)).toList();

    // Step 3: Compare cached data with API data
    if (!listEquals(networks, apiNetworks)) {
      // If data differs, update cache
      prefs.setString('networks', response.body);
      return apiNetworks; // Return updated networks list
    }
  } else {
    throw Exception('Failed to load networks');
  }

  return networks; // Return cached data if no changes
}

Future<List<NewsItemModel>> fetchContent(
    BuildContext context, int networkId) async {
  final prefs = await SharedPreferences.getInstance();
  final cachedContent = prefs.getString('content_$networkId');

  // Step 1: Use cached data for fast UI rendering
  List<NewsItemModel> content = [];
  if (cachedContent != null) {
    List<dynamic> cachedBody = json.decode(cachedContent);
    content =
        cachedBody.map((dynamic item) => NewsItemModel.fromJson(item)).toList();
  }

  // Step 2: Fetch API data in the background
  List<NewsItemModel> apiContent;
  final response = await https.get(
    Uri.parse(
        'https://api.ekomflix.com/android/getAllContentsOfNetwork/$networkId'),
    headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
  );

  if (response.statusCode == 200) {
    List<dynamic> body = json.decode(response.body);
    apiContent =
        body.map((dynamic item) => NewsItemModel.fromJson(item)).toList();

    // Step 3: Compare cached data with API data
    if (!listEquals(content, apiContent)) {
      // If data differs, update cache and return new data
      prefs.setString('content_$networkId', response.body);
      return apiContent; // Return updated content list
    }
  } else {
    throw Exception('Failed to load content');
  }

  return content; // Return cached data if no changes
}

Future<Map<String, String>> fetchMoviePlayLink(int movieId) async {
  final prefs = await SharedPreferences.getInstance();
  final cachedPlayLink = prefs.getString('movie_playlink_$movieId');

  if (cachedPlayLink != null) {
    final Map<String, dynamic> cachedData = json.decode(cachedPlayLink);
    return {'url': cachedData['url'] ?? '', 'type': cachedData['type'] ?? ''};
  }

  final response = await https.get(
    Uri.parse('https://api.ekomflix.com/android/getMoviePlayLinks/$movieId/0'),
    headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
  );

  if (response.statusCode == 200) {
    final List<dynamic> body = json.decode(response.body);
    if (body.isNotEmpty) {
      final Map<String, dynamic> firstItem = body.first as Map<String, dynamic>;
      prefs.setString('movie_playlink_$movieId', json.encode(firstItem));
      return {'url': firstItem['url'] ?? '', 'type': firstItem['type'] ?? ''};
    }
    return {'url': '', 'type': ''};
  } else {
    throw Exception('Failed to load movie play link');
  }
}

// // Widget to handle image loading (either base64 or URL)
// Widget displayImage(String imageUrl) {
//   if (imageUrl.startsWith('data:image')) {
//     // Handle base64-encoded images
//     Uint8List imageBytes = _getImageFromBase64String(imageUrl);
//     return Image.memory(
//       imageBytes,
//       fit: BoxFit.cover,
//       width: 100.0, // Customize width as per your need
//       height: 100.0, // Customize height as per your need
//     );
//   } else if (imageUrl.startsWith('http') || imageUrl.startsWith('https')) {
//     // Handle URL images
//     return CachedNetworkImage(
//       imageUrl: imageUrl,
//       placeholder: (context, url) => localImage,
//       errorWidget: (context, url, error) => localImage,
//       fit: BoxFit.cover,
//       width: 100.0, // Customize width as per your need
//       height: 100.0, // Customize height as per your need
//     );
//   } else {
//     // Fallback for invalid image data
//     return localImage;
//   }
// }

// Widget to handle image loading (either base64 or URL)
Widget displayImage(
  String imageUrl, {
  double? width,
  double? height,
}) {
  if (imageUrl.startsWith('data:image')) {
    // Handle base64-encoded images
    Uint8List imageBytes = _getImageFromBase64String(imageUrl);
    return Image.memory(
      imageBytes,
      fit: BoxFit.fill,
      width: width,
      height: height,
    );
  } else if (imageUrl.startsWith('http') || imageUrl.startsWith('https')) {
    // Handle URL images
    return CachedNetworkImage(
      imageUrl: imageUrl,
      placeholder: (context, url) => localImage,
      errorWidget: (context, url, error) => localImage,
      fit: BoxFit.fill,
      width: width,
      height: height,
    );
  } else {
    // Fallback for invalid image data
    return localImage;
  }
}

// class SubVod extends StatefulWidget {
//   final Function(bool)? onFocusChange; // Add this

//   const SubVod({Key? key, this.onFocusChange, required FocusNode focusNode})
//       : super(key: key);

//   @override
//   _SubVodState createState() => _SubVodState();
// }

// class _SubVodState extends State<SubVod> {
//   List<NetworkApi> _networks = [];
//   bool _isLoading = true;
//   bool _cacheLoaded = false; // To track if cache has been loaded
//   // FocusNode firstSubVodFocusNode = FocusNode();
//   late FocusNode firstSubVodFocusNode;

//   @override
//   void initState() {
//     super.initState();
//     firstSubVodFocusNode = FocusNode();

//         // Add key event listener
//     firstSubVodFocusNode.onKey = (node, event) {
//       if (event is RawKeyDownEvent) {
//         if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
//           // // Get the HomeCategory focus node from provider and request focus
//           // final homeCategoryFocusNode = context.read<FocusProvider>().getHomeCategoryFirstItemFocusNode();
//           // if (homeCategoryFocusNode != null) {
//           //   homeCategoryFocusNode.requestFocus();
//           //   return KeyEventResult.handled;
//           // }
//         }
//         if (event.logicalKey == LogicalKeyboardKey.arrowUp) {

//                     // if (_musicList.isNotEmpty) {
//                     //   // Request focus for first news item
//                     //   final firstItemId = _musicList[0].id;
//                     //   if (newsItemFocusNodes.containsKey(firstItemId)) {
//                     //     FocusScope.of(context)
//                     //         .requestFocus(newsItemFocusNodes[firstItemId]);
//                     //     return KeyEventResult.handled;
//                     //   }
//                     // }
//         }
//       }
//       return KeyEventResult.ignored;
//     };

//     // Register the first SubVod focus node in the FocusProvider
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context
//           .read<FocusProvider>()
//           .setFirstSubVodFocusNode(firstSubVodFocusNode);
//       print("First SubVod FocusNode registered"); // Debug log
//     });
//     // firstItemFocusNode = FocusNode()

//     // ..addListener(() {
//     //   // if (firstItemFocusNode.hasFocus) {
//     //   //   widget.onFocusChange?.call(true);
//     //   // }

//     //         if (firstItemFocusNode.hasFocus) {
//     //   context.read<FocusProvider>().setSubVodFocusNode(firstItemFocusNode);
//     // }
//     // });
//     // Fetch networks from cache first
//     _loadCachedNetworks();
//     // Fetch data from API in the background and update if necessary
//     _fetchNetworksInBackground();
//   }

//   // Load cached data
//   Future<void> _loadCachedNetworks() async {
//     final prefs = await SharedPreferences.getInstance();
//     final cachedNetworks = prefs.getString('networks');

//     if (cachedNetworks != null) {
//       List<dynamic> cachedBody = json.decode(cachedNetworks);
//       setState(() {
//         _networks = cachedBody
//             .map((dynamic item) => NetworkApi.fromJson(item))
//             .toList();
//         _isLoading = false; // Stop loading, show cached data
//         _cacheLoaded = true; // Cache has been successfully loaded
//       });
//     } else {
//       print('No cache found');
//     }
//   }

//   // Fetch API data in the background
//   Future<void> _fetchNetworksInBackground() async {
//     try {
//       final fetchedNetworks = await fetchNetworks(context);
//       if (!listEquals(_networks, fetchedNetworks)) {
//         setState(() {
//           _networks =
//               fetchedNetworks; // Update UI with new data if it's different
//         });
//       }
//     } catch (e) {
//       // print('Error fetching networks: $e');
//       if (!_cacheLoaded) {
//         // Only show error message if cache is not available
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to fetch networks.')),
//         );
//       }
//     } finally {
//       if (!_cacheLoaded) {
//         // If no cache and no API data, stop loading
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<ColorProvider>(builder: (context, colorProvider, child) {
//       // Use provider's color for background
//       Color backgroundColor = colorProvider.isItemFocused
//           ? colorProvider.dominantColor.withOpacity(0.3)
//           : Colors.black87;

//       return Scaffold(
//         backgroundColor: Colors.transparent,
//         body: _isLoading
//             ? Center(
//                 child:
//                     LoadingIndicator()) // Show loading only if no cached data
//             : _buildNetworksList(),
//       );
//     });
//   }

//   @override
//   void dispose() {
//     print("SubVod disposed");
//     super.dispose();
//   }

// // @override
// // void didChangeDependencies() {
// //   super.didChangeDependencies();
// //   WidgetsBinding.instance.addPostFrameCallback((_) {
// //     context.read<FocusProvider>().requestSubVodFocus(context);
// //   });
// // }

//   Widget _buildNetworksList() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start, // Align heading to the left
//       children: [
//         Consumer<ColorProvider>(builder: (context, colorProvider, child) {
//           // Use provider's color for text
//           Color textColor = colorProvider.isItemFocused
//               ? colorProvider.dominantColor
//               : Colors.white;

//           return Padding(
//             padding:
//                 const EdgeInsets.all(8.0), // Add some padding around the text
//             child: Text(
//               'Contents',
//               style: TextStyle(
//                 fontSize: 24.0,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white, // Adjust this color to match your theme
//               ),
//             ),
//           );
//         }),
//         Expanded(
//           child: _networks.isEmpty
//               ? Center(child: Text('No Networks Available'))
//               : ListView.builder(
//                   scrollDirection: Axis.horizontal,
//                   itemCount: _networks.length,
//                   itemBuilder: (context, index) {
//                     return FocusableItemWidget(
//                       imageUrl: _networks[index].logo,
//                       name: _networks[index].name,
//                       focusNode: index == 0 ? firstSubVodFocusNode : null,
//                       onTap: () async {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) =>
//                                 ContentScreen(networkId: _networks[index].id),
//                           ),
//                         );
//                       },
//                       fetchPaletteColor: fetchPaletteColor,
//                       //                       onFocusChange: (hasFocus) {
//                       //   if (hasFocus) {
//                       //     print('${_networks[index].name} is focused');
//                       //   }
//                       // },
//                     );
//                   },
//                 ),
//         ),
//       ],
//     );
//   }
// }





class SubVod extends StatefulWidget {
  final Function(bool)? onFocusChange; // Add this

  const SubVod({Key? key, this.onFocusChange, required FocusNode focusNode})
      : super(key: key);

  @override
  _SubVodState createState() => _SubVodState();
}

class _SubVodState extends State<SubVod> {
  List<NetworkApi> _networks = [];
  bool _isLoading = true;
  bool _cacheLoaded = false; // To track if cache has been loaded
  // FocusNode firstSubVodFocusNode = FocusNode();
  late FocusNode firstSubVodFocusNode;
  

  @override
  void initState() {
    super.initState();
    firstSubVodFocusNode = FocusNode();

    // Add key event listener
    firstSubVodFocusNode.onKey = (node, event) {
      if (event is RawKeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          // Get the HomeCategory focus node from provider and request focus
          final homeCategoryFocusNode =
              context.read<FocusProvider>().getHomeCategoryFirstItemFocusNode();
          if (homeCategoryFocusNode != null) {
            homeCategoryFocusNode.requestFocus();
            return KeyEventResult.handled;
          }
        }else



if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
  print("⬆️ SubVod: Up Arrow pressed, requesting music item focus");

  context.read<FocusProvider>().requestMusicItemFocus(context);
  return KeyEventResult.handled;
}





      }
      return KeyEventResult.ignored;
    };

    // Register the first SubVod focus node in the FocusProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<FocusProvider>()
          .setFirstSubVodFocusNode(firstSubVodFocusNode);
      print("First SubVod FocusNode registered"); // Debug log
    });
    // firstItemFocusNode = FocusNode()

    // ..addListener(() {
    //   // if (firstItemFocusNode.hasFocus) {
    //   //   widget.onFocusChange?.call(true);
    //   // }

    //         if (firstItemFocusNode.hasFocus) {
    //   context.read<FocusProvider>().setSubVodFocusNode(firstItemFocusNode);
    // }
    // });
    // Fetch networks from cache first
    _loadCachedNetworks();
    // Fetch data from API in the background and update if necessary
    _fetchNetworksInBackground();
  }

  // Load cached data
  Future<void> _loadCachedNetworks() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedNetworks = prefs.getString('networks');

    if (cachedNetworks != null) {
      List<dynamic> cachedBody = json.decode(cachedNetworks);
      setState(() {
        _networks = cachedBody
            .map((dynamic item) => NetworkApi.fromJson(item))
            .toList();
        _isLoading = false; // Stop loading, show cached data
        _cacheLoaded = true; // Cache has been successfully loaded
      });
    } else {
      print('No cache found');
    }
  }

  // Fetch API data in the background
  Future<void> _fetchNetworksInBackground() async {
    try {
      final fetchedNetworks = await fetchNetworks(context);
      if (!listEquals(_networks, fetchedNetworks)) {
        setState(() {
          _networks =
              fetchedNetworks; // Update UI with new data if it's different
        });
      }
    } catch (e) {
      // print('Error fetching networks: $e');
      if (!_cacheLoaded) {
        // Only show error message if cache is not available
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch networks.')),
        );
      }
    } finally {
      if (!_cacheLoaded) {
        // If no cache and no API data, stop loading
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ColorProvider>(builder: (context, colorProvider, child) {
      // Use provider's color for background
      Color backgroundColor = colorProvider.isItemFocused
          ? colorProvider.dominantColor.withOpacity(0.3)
          : Colors.black87;

      return Scaffold(
        backgroundColor: Colors.transparent,
        body: _isLoading
            ? Center(
                child:
                    LoadingIndicator()) // Show loading only if no cached data
            : _buildNetworksList(),
      );
    });
  }

  @override
  void dispose() {
    print("SubVod disposed");
    super.dispose();
  }

// @override
// void didChangeDependencies() {
//   super.didChangeDependencies();
//   WidgetsBinding.instance.addPostFrameCallback((_) {
//     context.read<FocusProvider>().requestSubVodFocus(context);
//   });
// }

  Widget _buildNetworksList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Align heading to the left
      children: [
        Consumer<ColorProvider>(builder: (context, colorProvider, child) {
          // Use provider's color for text
          Color textColor = colorProvider.isItemFocused
              ? colorProvider.dominantColor
              : Colors.white;

          return Padding(
            padding:
                const EdgeInsets.all(8.0), // Add some padding around the text
            child: Text(
              'Contents',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Adjust this color to match your theme
              ),
            ),
          );
        }),
        Expanded(
          child: _networks.isEmpty
              ? Center(child: Text('No Networks Available'))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _networks.length,
                  itemBuilder: (context, index) {
                    final focusNode = index == 0 ? firstSubVodFocusNode : FocusNode()
                      ..onKey = (node, event) {
                        if (event is RawKeyDownEvent) {
                          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                            print("⬆️ SubVod: Up Arrow pressed, requesting music item focus");
                            context.read<FocusProvider>().requestMusicItemFocus(context);
                            return KeyEventResult.handled;
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                            final homeCategoryFocusNode =
                                context.read<FocusProvider>().getHomeCategoryFirstItemFocusNode();
                            if (homeCategoryFocusNode != null) {
                              homeCategoryFocusNode.requestFocus();
                              return KeyEventResult.handled;
                            }
                          }
                        }
                        return KeyEventResult.ignored;
                      };

                    return FocusableItemWidget(
                      imageUrl: _networks[index].logo,
                      name: _networks[index].name,
                      // focusNode: index == 0 ? firstSubVodFocusNode : null,
                      focusNode: focusNode,
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ContentScreen(networkId: _networks[index].id),
                          ),
                        );
                      },
                      fetchPaletteColor: fetchPaletteColor,
                      //                       onFocusChange: (hasFocus) {
                      //   if (hasFocus) {
                      //     print('${_networks[index].name} is focused');
                      //   }
                      // },
                    );
                  },
                ),
        ),
      ],
    );
  }
}





// class SubVod extends StatefulWidget {
//     final Function(bool)? onFocusChange; // Add this

//   const SubVod({Key? key, this.onFocusChange, required FocusNode focusNode})
//       : super(key: key);
//   @override
//   _SubVodState createState() => _SubVodState();
// }

// class _SubVodState extends State<SubVod> {
//   List<NetworkApi> _networks = [];
//   bool _isLoading = true;
//   bool _cacheLoaded = false; // To track if cache has been loaded

//   @override
//   void initState() {
//     super.initState();
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//       FocusNode firstVodFocusNode = FocusNode();
//       context
//           .read<FocusProvider>()
//           .setFirstVodBannerFocusNode(firstVodFocusNode);
//     });
//     // Fetch networks from cache first
//     _loadCachedNetworks();
//     // Fetch data from API in the background and update if necessary
//     _fetchNetworksInBackground();
//   }

//   // Load cached data
//   Future<void> _loadCachedNetworks() async {
//     final prefs = await SharedPreferences.getInstance();
//     final cachedNetworks = prefs.getString('networks');

//     if (cachedNetworks != null) {
//       List<dynamic> cachedBody = json.decode(cachedNetworks);
//       setState(() {
//         _networks = cachedBody
//             .map((dynamic item) => NetworkApi.fromJson(item))
//             .toList();
//         _isLoading = false; // Stop loading, show cached data
//         _cacheLoaded = true; // Cache has been successfully loaded
//       });
//     } else {
//       print('No cache found');
//     }
//   }

//   // Fetch API data in the background
//   Future<void> _fetchNetworksInBackground() async {
//     try {
//       final fetchedNetworks = await fetchNetworks(context);
//       if (!listEquals(_networks, fetchedNetworks)) {
//         setState(() {
//           _networks =
//               fetchedNetworks; // Update UI with new data if it's different
//         });
//       }
//     } catch (e) {
//       // print('Error fetching networks: $e');
//       if (!_cacheLoaded) {
//         // Only show error message if cache is not available
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to fetch networks.')),
//         );
//       }
//     } finally {
//       if (!_cacheLoaded) {
//         // If no cache and no API data, stop loading
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<ColorProvider>(builder: (context, colorProvider, child) {
//       // Use provider's color for background
//       Color backgroundColor = colorProvider.isItemFocused
//           ? colorProvider.dominantColor.withOpacity(0.3)
//           : Colors.black87;

//       return Scaffold(
//         backgroundColor: Colors.transparent,
//         body: _isLoading
//             ? Center(
//                 child:
//                     LoadingIndicator()) // Show loading only if no cached data
//             : _buildNetworksList(),
//       );
//     });
//   }

//   Widget _buildNetworksList() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start, // Align heading to the left
//       children: [
//         Consumer<ColorProvider>(builder: (context, colorProvider, child) {
//           // Use provider's color for text
//           Color textColor = colorProvider.isItemFocused
//               ? colorProvider.dominantColor
//               : Colors.white;

//           return Padding(
//             padding:
//                 const EdgeInsets.all(8.0), // Add some padding around the text
//             child: Text(
//               'Contents',
//               style: TextStyle(
//                 fontSize: 24.0,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white, // Adjust this color to match your theme
//               ),
//             ),
//           );
//         }),
//         Expanded(
//           child: _networks.isEmpty
//               ? Center(child: Text('No Networks Available'))
//               : ListView.builder(
//                   scrollDirection: Axis.horizontal,
//                   itemCount: _networks.length,
//                   itemBuilder: (context, index) {
//                     return FocusableItemWidget(
//                       imageUrl: _networks[index].logo,
//                       name: _networks[index].name,
//                       onTap: () async {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) =>
//                                 ContentScreen(networkId: _networks[index].id),
//                           ),
//                         );
//                       },
//                       fetchPaletteColor: fetchPaletteColor,
//                     );
//                   },
//                 ),
//         ),
//       ],
//     );
//   }
// }

class VOD extends StatefulWidget {
  @override
  _VODState createState() => _VODState();
}

class _VODState extends State<VOD> {
  List<NetworkApi> _networks = [];
  bool _isLoading = true;
  bool _cacheLoaded = false; // To track if cache has been loaded
  late FocusNode firstVodFocusNode;
  Map<int, FocusNode> firstRowFocusNodes = {};


  @override
  void initState() {
    super.initState();
    // FocusNode firstVodFocusNode = FocusNode();

     // Initialize focus nodes for first row items
    for (int i = 0; i < 5; i++) {
      final focusNode = FocusNode();
      firstRowFocusNodes[i] = focusNode;
      
      // Add key event listener for each focus node in first row
      focusNode.onKey = (node, event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            context.read<FocusProvider>().requestVodMenuFocus();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      };
    }

    // Set first item's focus node in provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (firstRowFocusNodes.containsKey(0)) {
        context
            .read<FocusProvider>()
            .setFirstVodBannerFocusNode(firstRowFocusNodes[0]!);
            
        // Request focus for first item
        firstRowFocusNodes[0]?.requestFocus();
      }
    });

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   context
    //       .read<FocusProvider>()
    //       .setFirstVodBannerFocusNode(firstVodFocusNode);
    // });


    // Fetch networks from cache first
    _loadCachedNetworks();
    // Fetch data from API in the background and update if necessary
    _fetchNetworksInBackground();

    // Add key event listener
    // firstVodFocusNode.onKey = (node, event) {
    //   if (event is RawKeyDownEvent) {
    //     // if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
    //     //   // // Get the HomeCategory focus node from provider and request focus
    //     //   // final homeCategoryFocusNode = context.read<FocusProvider>().getHomeCategoryFirstItemFocusNode();
    //     //   // if (homeCategoryFocusNode != null) {
    //     //   //   homeCategoryFocusNode.requestFocus();
    //     //   //   return KeyEventResult.handled;
    //     //   // }
    //     // }
    //     if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
    //       context.read<FocusProvider>().requestVodMenuFocus();

    //       // if (_musicList.isNotEmpty) {
    //       //   // Request focus for first news item
    //       //   final firstItemId = _musicList[0].id;
    //       //   if (newsItemFocusNodes.containsKey(firstItemId)) {
    //       //     FocusScope.of(context)
    //       //         .requestFocus(newsItemFocusNodes[firstItemId]);
    //       //     return KeyEventResult.handled;
    //       //   }
    //       // }
    //     }
    //   }
    //   return KeyEventResult.ignored;
    // };
  }

  // Load cached data
  Future<void> _loadCachedNetworks() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedNetworks = prefs.getString('networks');

    if (cachedNetworks != null) {
      List<dynamic> cachedBody = json.decode(cachedNetworks);

      setState(() {
        _networks = cachedBody
            .map((dynamic item) => NetworkApi.fromJson(item))
            .toList();
        _isLoading = false; // Stop loading, show cached data
        _cacheLoaded = true; // Cache has been successfully loaded
      });
    } else {
      print('No cache found');
    }
  }

  // Fetch API data in the background
  Future<void> _fetchNetworksInBackground() async {
    try {
      final fetchedNetworks = await fetchNetworks(context);
      if (!listEquals(_networks, fetchedNetworks)) {
        setState(() {
          _networks =
              fetchedNetworks; // Update UI with new data if it's different
        });
      }
    } catch (e) {
      // print('Error fetching networks: $e');
      if (!_cacheLoaded) {
        // Only show error message if cache is not available
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch networks.')),
        );
      }
    } finally {
      if (!_cacheLoaded) {
        // If no cache and no API data, stop loading
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: cardColor,
  //     body: _isLoading
  //         ? Center(
  //             child: LoadingIndicator()) // Show loading only if no cached data
  //         : _buildNetworksList(),
  //   );
  // }
  Widget build(BuildContext context) {
    return Consumer<ColorProvider>(builder: (context, colorProvider, child) {
      // Get background color based on provider state
      Color backgroundColor =
          colorProvider.isItemFocused ? colorProvider.dominantColor : cardColor;
      return Scaffold(
        backgroundColor: backgroundColor,
        body: _isLoading
            ? Center(child: LoadingIndicator())
            : _networks != null
                ? Container(color: Colors.black54, child: _buildNetworksList())
                : Center(child: Text('...')),
      );
    });
  }

    @override
  void dispose() {
    firstRowFocusNodes.values.forEach((node) => node.dispose());
    super.dispose();
  }

  Widget _buildNetworksList() {
    if (_networks.isEmpty) {
      return Center(child: Text('No Networks Available'));
    } else {
      return
          // ListView.builder(
          //   scrollDirection: Axis.horizontal,
          GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 0.8,
        ),
        itemCount: _networks.length,
        itemBuilder: (context, index) {
          final isFirstRow = index < 5;
          return FocusableItemWidget(
            // focusNode: index == 0
            //     ? context.read<FocusProvider>().firstVodBannerFocusNode
            //     : null,
            focusNode: isFirstRow ? firstRowFocusNodes[index] : null,
            imageUrl: _networks[index].logo,
            name: _networks[index].name,
            onTap: () async {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ContentScreen(networkId: _networks[index].id),
                ),
              );
            },
            fetchPaletteColor: fetchPaletteColor,
          );
        },
      );
    }
  }
}

class ContentScreen extends StatefulWidget {
  final int networkId;

  ContentScreen({required this.networkId});

  @override
  _ContentScreenState createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  List<NewsItemModel> _content = [];
  bool _isLoading = true;
  bool _cacheLoaded = false;
  FocusNode firstItemFocusNode = FocusNode();
  List<String> channelList = [];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 50), () async {
      // Load cached content first
      _loadCachedContent();
      firstItemFocusNode.requestFocus();
    });
    // Fetch content from API in the background
    _fetchContentInBackground();
  }

  Future<void> _loadCachedContent() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedContent = prefs.getString('content_${widget.networkId}');

    if (cachedContent != null) {
      List<dynamic> cachedBody = json.decode(cachedContent);
      // await Future.delayed(Duration(milliseconds: 50));
      setState(() {
        _content = cachedBody
            .map((dynamic item) => NewsItemModel.fromJson(item))
            .toList();
        _isLoading = false;
        _cacheLoaded = true;
      });
    } else {
      print('No cache found for content');
    }
  }

  Future<void> _fetchContentInBackground() async {
    try {
      final fetchedContent = await fetchContent(context, widget.networkId);

      if (!listEquals(_content, fetchedContent)) {
        setState(() {
          _content = fetchedContent;
        });
      }
    } catch (e) {
      // print('Error fetching content: $e');
      if (!_cacheLoaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch content.')),
        );
      }
    } finally {
      if (!_cacheLoaded) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ColorProvider>(builder: (context, colorProvider, child) {
      // Use provider's color for background
      Color backgroundColor = colorProvider.isItemFocused
          ? colorProvider.dominantColor.withOpacity(0.3)
          : Colors.black87;

      return Scaffold(
        backgroundColor: backgroundColor,
        // body:
        //     _isLoading ? Center(child: Text('...')) : _buildContentList(),
        body: _isLoading
            ? !_cacheLoaded
                ? Center(child: Text('...'))
                : Center(child: LoadingIndicator())
            : _content != null
                ? _buildContentList()
                : Center(child: Text('...')),
      );
    });
  }

  Widget _buildContentList() {
    if (_content.isEmpty) {
      return Center(child: Text('No Content Available'));
    } else {
      return Padding(
        padding: EdgeInsets.symmetric(
            horizontal: screenwdt * 0.03, vertical: screenhgt * 0.01),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5, childAspectRatio: 0.8),
          itemCount: _content.length,
          itemBuilder: (context, index) {
            return FocusableItemWidget(
              focusNode: index == 0 ? firstItemFocusNode : null,
              imageUrl: _content[index].banner,
              name: _content[index].name,
              onTap: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailsPage(
                      id: int.tryParse(_content[index].id) ?? 0,
                      channelList: _content,
                      source: 'isContentScreenViaDetailsPageChannelLIst',
                      banner: _content[index].banner,
                      name: _content[index].name ?? '',
                    ),
                  ),
                );
              },
              fetchPaletteColor: fetchPaletteColor,
            );
          },
        ),
      );
    }
  }
}

class DetailsPage extends StatefulWidget {
  // final NewsItemModel content;
  final int id;
  final List<NewsItemModel> channelList;
  final String source;
  final String banner;
  final String name;

  DetailsPage({
    required this.id,
    required this.channelList,
    required this.source,
    required this.banner,
    required this.name,
  });

  @override
  _DetailsPageState createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  final SocketService _socketService = SocketService();
  MovieDetailsApi? _movieDetails;
  final int _maxRetries = 3;
  final int _retryDelay = 5; // seconds
  bool _shouldContinueLoading = true;
  bool _isLoading = false;
  bool _isVideoPlaying = false;
  Timer? _timer;
  bool _isReturningFromVideo = false;
  FocusNode firstItemFocusNode = FocusNode();
  Color headingColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _socketService.initSocket();
    checkServerStatus();
    Future.delayed(Duration(milliseconds: 100), () async {
      await _loadCachedAndFetchMovieDetails(widget.id);
      if (_movieDetails != null) {
        _fetchAndSetHeadingColor(_movieDetails!.banner);
      }
      firstItemFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _socketService.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAndSetHeadingColor(String bannerUrl) async {
    try {
      Color paletteColor = await fetchPaletteColor(bannerUrl);
      setState(() {
        headingColor = paletteColor;
      });
    } catch (e) {
      print('Error fetching palette color: $e');
    }
  }

  Future<void> _loadCachedAndFetchMovieDetails(int contentId) async {
    try {
      final cachedDetails = await fetchMovieDetails(context, contentId);
      if (!mounted) return;
      setState(() {
        _movieDetails = cachedDetails;
        _isLoading = false;
      });

      final apiDetails = await fetchMovieDetails(context, contentId);
      if (_movieDetails != apiDetails && mounted) {
        setState(() {
          _movieDetails = apiDetails;
          // Fetch updated heading color when details are updated
          _fetchAndSetHeadingColor(_movieDetails!.banner);
        });
      }
    } catch (e) {
      print('Error fetching movie details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _movieDetails = null;
        });
      }
    }
  }

  Future<void> _updateUrlIfNeeded(Map<String, String> playLink) async {
    if (playLink['type'] == 'Youtube' || playLink['type'] == 'YoutubeLive') {
      for (int i = 0; i < _maxRetries; i++) {
        if (!_shouldContinueLoading) break;
        try {
          String updatedUrl =
              await _socketService.getUpdatedUrl(playLink['url']!);
          // 'https://www.youtube.com/watch?v=${playLink['url']!}';
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

  void checkServerStatus() {
    Timer.periodic(Duration(seconds: 10), (timer) {
      if (!_socketService.socket.connected) {
        _socketService.initSocket(); // Re-establish the socket connection
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: _isLoading
          ? Center(child: LoadingIndicator())
          : _isReturningFromVideo // Check if returning from video
              ? Center(
                  child: Text(
                    '', // Ya koi aur text jo aap chahte hain
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                )
              : _movieDetails != null
                  ? _buildMovieDetailsUI(context, _movieDetails!)
                  : Center(child: Text('...')),
    );
  }

  Widget _buildMovieDetailsUI(
      BuildContext context, MovieDetailsApi movieDetails) {
    return Container(
      // padding: const EdgeInsets.all(20.0),
      child: Stack(
        children: [
          if (movieDetails.status == '1')
            displayImage(
              movieDetails.banner,
              width: screenwdt, // Custom width
              height: screenhgt, // Custom height
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenwdt * 0.03),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: screenhgt * 0.05,
                ),
                Container(
                  child: Text(
                    movieDetails.name,
                    style: TextStyle(
                      color: headingColor, // Dynamic heading color
                      fontSize: Headingtextsz * 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Spacer(),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 1,
                    itemBuilder: (context, index) {
                      return FocusableItemWidget(
                        focusNode: firstItemFocusNode,
                        imageUrl: movieDetails.poster,
                        name: '',
                        onTap: () => _playVideo(movieDetails),
                        fetchPaletteColor: fetchPaletteColor,
                      );
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _playVideo(MovieDetailsApi movieDetails) async {
    if (_isVideoPlaying) {
      return; // Agar ek video already play ho raha hai to naya video mat play karo
    }

    setState(() {
      _isLoading = true;
      _isVideoPlaying = true;
    });
    _shouldContinueLoading = true;

    try {
      final playLink = await fetchMoviePlayLink(widget.id);
      String originalUrl = playLink['url']!;
      if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
        int retryCount = 0;
        while (retryCount < 3) {
          try {
            await _updateUrlIfNeeded(playLink);
            break;
          } catch (e) {
            retryCount++;
            if (retryCount == 3) rethrow;
            await Future.delayed(Duration(seconds: 2)); // Reduced delay
          }
        }

        bool liveStatus = false;

        if (_shouldContinueLoading) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoScreen(
                videoUrl: playLink['url']!,
                videoId: widget.id,
                channelList: widget.channelList,
                videoType: playLink['type']!,
                bannerImageUrl: widget.banner,
                startAtPosition: Duration.zero,
                isLive: false,
                isVOD: true,
                isBannerSlider: false,
                source: widget.source,
                isSearch: false,
                unUpdatedUrl: originalUrl,
                name: widget.name,
                liveStatus: liveStatus,
              ),
            ),
          );
        }

        setState(() {
          _isLoading = false;
          _isReturningFromVideo = true;
        });
        // // Video screen se wapas aane ke baad 1 second ka delay
        // await Future.delayed(Duration(
        //   milliseconds: 100,
        // ));

        setState(() {
          _isReturningFromVideo = false;
        });
      }
    } catch (e) {
      _handleVideoError(
        context,
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isVideoPlaying = false;
      });
    }
  }
}

void _handleVideoError(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Something Went Wrong', style: TextStyle(fontSize: 20)),
    ),
  );
}
