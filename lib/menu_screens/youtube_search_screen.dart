// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_vlc_player/flutter_vlc_player.dart';
// import 'package:youtube_explode_dart/youtube_explode_dart.dart';
// import 'package:http/http.dart' as http;

// class NotificationScreen extends StatefulWidget {
//   const NotificationScreen({super.key});

//   @override
//   _NotificationScreenState createState() => _NotificationScreenState();
// }

// class _NotificationScreenState extends State<NotificationScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   VlcPlayerController? _playerController;
//   List<Map<String, dynamic>> _searchResults = [];
//   final yt = YoutubeExplode();
//   bool _isLoading = false;
//   String _errorMessage = '';

//   // Replace with your YouTube API key
//   final String API_KEY = 'YOUR_API_KEY';

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _playerController?.dispose();
//     yt.close();
//     super.dispose();
//   }

//   Future<void> searchYouTube(String searchQuery) async {
//     if (searchQuery.isEmpty) {
//       setState(() {
//         _errorMessage = 'Please enter a search term';
//       });
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//       _searchResults = [];
//     });

//     final String url = 'https://www.googleapis.com/youtube/v3/search?part=snippet&q=$searchQuery&type=video&key=$API_KEY&maxResults=10';

//     try {
//       final response = await http.get(Uri.parse(url));
//       print('Response status code: ${response.statusCode}');

//       if (response.statusCode != 200) {
//         setState(() {
//           _errorMessage = 'API Error: ${response.statusCode}\n${response.body}';
//           _isLoading = false;
//         });
//         return;
//       }

//       final data = json.decode(response.body);

//       if (data['items'] == null || data['items'].isEmpty) {
//         setState(() {
//           _errorMessage = 'No results found';
//           _isLoading = false;
//         });
//         return;
//       }

//       setState(() {
//         _searchResults = List<Map<String, dynamic>>.from(
//           data['items'].map((item) => {
//             'id': item['id']['videoId'],
//             'title': item['snippet']['title'],
//             'thumbnail': item['snippet']['thumbnails']['default']['url'],
//             'description': item['snippet']['description'],
//           })
//         );
//         _isLoading = false;
//       });
//     } catch (e) {
//       print('Error searching YouTube: $e');
//       setState(() {
//         _errorMessage = 'Error: $e';
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> playVideo(String videoId) async {
//     try {
//       // Get video manifest
//       var manifest = await yt.videos.streamsClient.getManifest(videoId);
//       var streamInfo = manifest.muxed.withHighestBitrate();
//       var videoUrl = streamInfo.url.toString();

//       // Dispose existing controller if any
//       if (_playerController != null) {
//         await _playerController!.dispose();
//       }

//       // Initialize new controller
//       _playerController = VlcPlayerController.network(
//         videoUrl,
//         hwAcc: HwAcc.full,
//         autoPlay: true,
//         options: VlcPlayerOptions(
//           advanced: VlcAdvancedOptions([
//             VlcAdvancedOptions.networkCaching(2000),
//           ]),
//           http: VlcHttpOptions([
//             VlcHttpOptions.httpReconnect(true),
//           ]),
//           video: VlcVideoOptions([
//             VlcVideoOptions.dropLateFrames(true),
//             VlcVideoOptions.skipFrames(true),
//           ]),
//         ),
//       );

//       setState(() {});

//       // Initialize the controller
//       await _playerController!.initialize();

//     } catch (e) {
//       print('Error playing video: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error playing video: $e')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('YouTube VLC Player'),
//         backgroundColor: Colors.blue,
//       ),
//       body: Column(
//         children: [
//           // Search Bar
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: 'Search YouTube videos...',
//                 suffixIcon: IconButton(
//                   icon: const Icon(Icons.search),
//                   onPressed: () => searchYouTube(_searchController.text),
//                 ),
//                 border: const OutlineInputBorder(),
//                 filled: true,
//                 fillColor: Colors.grey[100],
//               ),
//               onSubmitted: (value) => searchYouTube(value),
//             ),
//           ),

//           // Loading Indicator
//           if (_isLoading)
//             const Center(child: CircularProgressIndicator()),

//           // Error Message
//           if (_errorMessage.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Text(
//                 _errorMessage,
//                 style: const TextStyle(color: Colors.red),
//               ),
//             ),

//           // Video Player
//           if (_playerController != null)
//             AspectRatio(
//               aspectRatio: 16 / 9,
//               child: VlcPlayer(
//                 controller: _playerController!,
//                 aspectRatio: 16 / 9,
//                 placeholder: const Center(child: CircularProgressIndicator()),
//               ),
//             ),

//           // Video Controls
//           if (_playerController != null)
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 8.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.replay_10),
//                     onPressed: () => _playerController!.seekTo(Duration(seconds: _playerController!.value.position.inSeconds - 10)),
//                   ),
//                   IconButton(
//                     icon: Icon(_playerController!.value.isPlaying ? Icons.pause : Icons.play_arrow),
//                     onPressed: () => _playerController!.value.isPlaying ? _playerController!.pause() : _playerController!.play(),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.forward_10),
//                     onPressed: () => _playerController!.seekTo(Duration(seconds: _playerController!.value.position.inSeconds + 10)),
//                   ),
//                 ],
//               ),
//             ),

//           // Search Results
//           Expanded(
//             child: ListView.builder(
//               itemCount: _searchResults.length,
//               itemBuilder: (context, index) {
//                 final result = _searchResults[index];
//                 return Card(
//                   margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
//                   child: ListTile(
//                     leading: Image.network(
//                       result['thumbnail'],
//                       errorBuilder: (context, error, stackTrace) =>
//                         const Icon(Icons.error),
//                     ),
//                     title: Text(
//                       result['title'],
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     subtitle: Text(
//                       result['description'],
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     onTap: () => playVideo(result['id']),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// import 'dart:async';
// import 'dart:convert';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:http/http.dart' as https;
// import 'package:mobi_tv_entertainment/menu_screens/home_sub_screen/sub_vod.dart';
// import 'package:mobi_tv_entertainment/provider/color_provider.dart';
// import 'package:provider/provider.dart';
// import '../main.dart';
// import '../provider/focus_provider.dart';
// import '../video_widget/socket_service.dart';
// import '../video_widget/video_screen.dart';
// import '../widgets/models/news_item_model.dart';
// import '../widgets/utils/color_service.dart';

// // Future<List<NewsItemModel>> fetchFromApi(String searchTerm) async {
// //   try {
// //     final response = await https.get(
// //       // Uri.encodeComponent(searchTerm)
// //       Uri.parse(
// //           'https://mobifreetv.com/android/youtube_search?text=${searchTerm}'),
// //       headers: {'x-api-key': 'm3kIohin4etg6YXF'},
// //     );

// //     if (response.statusCode == 200) {
// //       print(
// //           'Requesting: https://mobifreetv.com/android/youtube_search?text=${searchTerm}');
// // print('Headers: ${response.headers}');
// // print('Bodyyyyy: ${response.body}');

// //     print("API Response Status Code: ${response.statusCode}");
// //     print("API Response Body: ${response.body}");
// //       final List<dynamic> responseData = json.decode(response.body);

// //       if (
// //         settings['tvenableAll'] == 0
// //         ) {
// //         final enabledChannels =
// //             settings['channels']?.map((id) => id.toString()).toSet() ?? {};

// //         return responseData
// //             .where((channel) =>
// //                 channel['title'] != null &&
// //                 channel['title']
// //                     .toString()
// //                     .toLowerCase()
// //                     .contains(searchTerm.toLowerCase()) &&
// //                 enabledChannels.contains(channel['id'].toString()))
// //             .map((channel) => NewsItemModel.fromJson(channel))
// //             .toList();
// //       } else {
// //         return responseData
// //             .where((channel) =>
// //                 channel['title'] != null &&
// //                 channel['title']
// //                     .toString()
// //                     .toLowerCase()
// //                     .contains(searchTerm.toLowerCase()))
// //             .map((channel) => NewsItemModel.fromJson(channel))
// //             .toList();
// //       }
// //     }
// //     throw Exception('Failed to load data from API');
// //   } catch (e) {
// //     print('Error fetching from API 1: $e');
// //     return [];
// //   }
// // }

// Uint8List _getImageFromBase64String(String base64String) {
//   // Split the base64 string to remove metadata if present
//   return base64Decode(base64String.split(',').last);
// }

// Map<String, dynamic> settings = {};

// Future<void> fetchSettings() async {
//   try {
//     final response = await https.get(
//       Uri.parse('https://api.ekomflix.com/android/getSettings'),
//       headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//     );

//     if (response.statusCode == 200) {
//       settings = json.decode(response.body);
//     } else {
//       throw Exception('Failed to load settings');
//     }
//   } catch (e) {
//     print('Error fetching settings: $e');
//   }
// }

// class NotificationScreen extends StatefulWidget {
//   @override
//   _NotificationScreenState createState() => _NotificationScreenState();
// }

// class _NotificationScreenState extends State<NotificationScreen> {
//   List<NewsItemModel> searchResults = [];
//   bool isLoading = false;
//   TextEditingController _searchController = TextEditingController();
//   int selectedIndex = -1;
//   final FocusNode _searchFieldFocusNode = FocusNode();
//   final FocusNode _youtubeSearchIconFocusNode = FocusNode();
//   Timer? _debounce;
//   final List<FocusNode> _itemFocusNodes = [];
//   bool _isNavigating = false;
//   bool _showSearchField = false;
//   Color paletteColor = Colors.grey;
//   final PaletteColorService _paletteColorService = PaletteColorService();
//   final SocketService _socketService = SocketService();
//   final int _maxRetries = 3;
//   final int _retryDelay = 5;
//   bool _shouldContinueLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _searchFieldFocusNode.addListener(_onSearchFieldFocusChanged);
//     _youtubeSearchIconFocusNode.addListener(_onSearchIconFocusChanged);
//     _socketService.initSocket();
//     checkServerStatus();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context
//           .read<FocusProvider>()
//           .setSearchIconFocusNode(_youtubeSearchIconFocusNode);
//     });
//   }

//   @override
//   void dispose() {
//     _searchFieldFocusNode.removeListener(_onSearchFieldFocusChanged);
//     _youtubeSearchIconFocusNode.removeListener(_onSearchIconFocusChanged);
//     _searchFieldFocusNode.dispose();
//     _youtubeSearchIconFocusNode.dispose();
//     _searchController.dispose();
//     _debounce?.cancel();
//     _itemFocusNodes.forEach((node) => node.dispose());
//     _socketService.dispose();
//     super.dispose();
//   }

//   // Future<List<NewsItemModel>> fetchFromApi(String searchTerm) async {
//   //   if (searchTerm.isEmpty) {
//   //     setState(() {
//   //       searchResults.clear();
//   //       isLoading = false;
//   //     });
//   //     return [];
//   //   }

//   //   setState(() => isLoading = true);

//   //   try {
//   //     final response = await https.get(
//   //       Uri.parse(
//   //           'https://mobifreetv.com/android/youtube_search?text=$searchTerm'),
//   //       headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//   //     );

//   //     print('Headers: ${response.headers}');
//   //     print('Bodyyyyy: ${response.body}');

//   //     print("API Response Status Code: ${response.statusCode}");
//   //     print("API Response Body: ${response.body}");

//   //     if (response.statusCode == 200) {
//   //       final Map<String, dynamic> data = json.decode(response.body);

//   //       List<NewsItemModel> results = (data['videos'] as List)
//   //           .map((video) => NewsItemModel.fromJson(video))
//   //           .toList();

//   //       setState(() {
//   //         searchResults = results;
//   //         isLoading = false;
//   //       });

//   //       return results;
//   //     } else {
//   //       setState(() => isLoading = false);
//   //       print("Failed to load search results");
//   //       return [];
//   //     }
//   //   } catch (e) {
//   //     setState(() => isLoading = false);
//   //     print("Error fetching videos: $e");
//   //     return [];
//   //   }
//   // }

//   // Future<List<NewsItemModel>> fetchFromApi(String searchTerm) async {
//   //   if (searchTerm.isEmpty) {
//   //     setState(() {
//   //       searchResults.clear();
//   //       isLoading = false;
//   //     });
//   //     return [];
//   //   }

//   //   setState(() => isLoading = true);

//   //   try {
//   //     final response = await https.get(
//   //       Uri.parse(
//   //           'https://mobifreetv.com/android/youtube_search?text=${Uri.encodeComponent(searchTerm)}'),
//   //       headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//   //       // headers: {'x-api-key': 'm3kIohin4etg6YXF'},
//   //     );

//   //     print("API Response Status Code: ${response.statusCode}");
//   //     print("API Response Body: ${response.body}");

//   //     if (response.statusCode == 200) {
//   //       final Map<String, dynamic> data = json.decode(response.body);

//   //       if (data.containsKey('error')) {
//   //         print("API returned an error: ${data['error']}");
//   //         setState(() {
//   //           isLoading = false;
//   //           searchResults.clear();
//   //         });
//   //         return [];
//   //       }

//   //       // if (data.containsKey('videos') && data['videos'] is List) {
//   //       //   List<NewsItemModel> results = (data['videos'] as List)
//   //       //       .map((video) => NewsItemModel.fromJson(video))
//   //       //       .toList();

//   //       //   if (mounted) {
//   //       //     setState(() {
//   //       //       searchResults = results;
//   //       //       isLoading = false;
//   //       //     });
//   //       //   }

//   //       //   return results;
//   //       // }
//   //       if (data.containsKey('videos') && data['videos'] is List) {
//   //         List<NewsItemModel> results = (data['videos'] as List)
//   //             .map((video) => NewsItemModel.fromJson(video))
//   //             .toList();

//   //         if (mounted) {
//   //           setState(() {
//   //             searchResults = results;
//   //             isLoading = false;
//   //           });
//   //         }
//   //       } else {
//   //         print(
//   //             "API returned an invalid response. Setting empty search results.");
//   //         if (mounted) {
//   //           setState(() {
//   //             searchResults.clear();
//   //             isLoading = false;
//   //           });
//   //         }
//   //       }
//   //     } else {
//   //       print(
//   //           "Failed to load search results. HTTP Status: ${response.statusCode}");
//   //     }
//   //   } catch (e) {
//   //     print("Error fetching videos: $e");
//   //   }

//   //   setState(() => isLoading = false);
//   //   return [];
//   // }

// Future<List<NewsItemModel>> fetchFromApi(String searchTerm) async {
//   print("Fetching search results for: $searchTerm");

//   if (searchTerm.isEmpty) {
//     setState(() {
//       searchResults.clear();
//       isLoading = false;
//     });
//     print("Search term is empty, clearing results.");
//     return [];
//   }

//   setState(() => isLoading = true);

//   try {
//     final response = await https.get(
//       Uri.parse('https://mobifreetv.com/android/youtube_search?text=${Uri.encodeComponent(searchTerm)}'),
//       headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//     );

//     print("API Response Status Code: ${response.statusCode}");
//     print("API Response Body: ${response.body}");

//     if (response.statusCode == 200) {
//       final Map<String, dynamic> data = json.decode(response.body);

//       if (data.containsKey('error')) {
//         print("API returned an error: ${data['error']}");
//         print("Before setState - searchResults Length: ${searchResults.length}");
//         setState(() {
//           isLoading = false;
//           searchResults.clear();
//         });
//         print("After setState - searchResults Length: ${searchResults.length}");
//         return [];
//       }

//       if (data.containsKey('videos') && data['videos'] is List) {
//         List<NewsItemModel> results = (data['videos'] as List)
//             .map((video) => NewsItemModel.fromJson(video))
//             .toList();

//         print("Fetched ${results.length} search results");

//         if (mounted) {
//           setState(() {
//             searchResults = results;
//             isLoading = false;
//           });

//           // **Wait for UI update before returning results**
//           await Future.delayed(Duration(milliseconds: 200));
//         }

//         return results;
//       } else {
//         print("API returned an invalid response. Clearing results.");
//         if (mounted) {
//           print("Before setState - searchResults Length: ${searchResults.length}");
//           setState(() {
//             searchResults.clear();
//             isLoading = false;
//           });
//           print("After setState - searchResults Length: ${searchResults.length}");
//         }
//       }
//     } else {
//       print("Failed to load search results. HTTP Status: ${response.statusCode}");
//     }
//   } catch (e) {
//     print("Error fetching videos: $e");
//   }

//   setState(() => isLoading = false);
//   return [];
// }

//   /// Debounced Search Handling
//   void _onSearchChanged() {
//     if (_debounce?.isActive ?? false) _debounce?.cancel();
//     _debounce = Timer(const Duration(milliseconds: 500), () {
//       fetchFromApi(_searchController.text);
//     });
//   }

//   Future<void> _updateChannelUrlIfNeeded(
//       List<NewsItemModel> result, int index) async {
//     if (result[index].streamType == 'YoutubeLive' ||
//         result[index].streamType == 'Youtube') {
//       for (int i = 0; i < _maxRetries; i++) {
//         if (!_shouldContinueLoading) break;
//         try {
//           String updatedUrl =
//               await _socketService.getUpdatedUrl(result[index].url);
//           setState(() {
//             result[index] =
//                 result[index].copyWith(url: updatedUrl, streamType: 'M3u8');
//           });
//           break;
//         } catch (e) {
//           if (i == _maxRetries - 1) rethrow;
//           await Future.delayed(Duration(seconds: _retryDelay));
//         }
//       }
//     }
//   }

//   Future<void> _onItemTap(BuildContext context, int index) async {

//     if (_isNavigating) return;
//     _isNavigating = true;
//     _showLoadingIndicator(context);

//     try {
//       // await _updateChannelUrlIfNeeded(searchResults, index);
//       if (_shouldContinueLoading) {
//         await _navigateToVideoScreen(context, searchResults, index);
//       }
//     } catch (e) {
//       print('Error playing video: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Something Went Wrong')),
//       );
//     } finally {
//       _isNavigating = false;
//       _shouldContinueLoading = true;
//       _dismissLoadingIndicator();
//     }
//   }

//   void _showLoadingIndicator(BuildContext context) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return WillPopScope(
//           onWillPop: () async {
//             _shouldContinueLoading = false;
//             _dismissLoadingIndicator();
//             return Future.value(false);
//           },
//           child: Center(
//             child: SpinKitFadingCircle(
//               color: Colors.white,
//               size: 50.0,
//             ),
//           ),
//         );
//       },
//     );
//   }

//   void _performSearch(String searchTerm) {
//   if (_debounce?.isActive ?? false) _debounce?.cancel();

//   _debounce = Timer(const Duration(milliseconds: 300), () async {
//     if (!mounted) return;

//     setState(() {
//       isLoading = true;
//     });

//     try {
//       final apiResults = await fetchFromApi(searchTerm);

//       if (!mounted) return;

//       if (apiResults.isEmpty) {
//         print("No search results found.");
//         setState(() {
//           searchResults.clear();
//           isLoading = false;
//         });
//       } else {
//         setState(() {
//           searchResults = apiResults;
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         isLoading = false;
//       });
//       print("Search error: $e");
//     }
//   });
// }

//   Future<void> _navigateToVideoScreen(
//       BuildContext context, List<NewsItemModel> channels, int index) async {
//     if (index < 0 || index >= channels.length) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Invalid channel index')),
//       );
//       return;
//     }

//     final channel = channels[index];
//     final String? videoUrl = channel.url;
//     final String? streamType = channel.streamType;
//     final String? genres = channel.genres;
//     final int? parsedContentType = int.tryParse(channel.contentType);
//     if (parsedContentType == 1) {
//       print(
//           'Navigating to DetailsPage with ID: ${int.tryParse(channel.id) ?? 0}');

//       try {
//         await Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => DetailsPage(
//               channelList: searchResults,
//               id: int.tryParse(channel.id) ?? 0,
//               source: 'isSearchScreenViaDetailsPageChannelList',
//               banner: channel.thumbnail,
//               name: channel.name,
//             ),
//           ),
//         );
//       } catch (e) {
//         // print('Error navigating to details page: $e');
//       }
//       //         ScaffoldMessenger.of(context).showSnackBar(
//       //   SnackBar(content: Text('Video information is missing or invalid 1.Channel contentType: ${channel.contentType} 2. Parsed contentType: $parsedContentType')),
//       // );
//     }

//     if (videoUrl == null || videoUrl.isEmpty || streamType == null) {
//       // ScaffoldMessenger.of(context).showSnackBar(
//       //   SnackBar(content: Text('Video information is missing or invalid')),
//       // );
//       return;
//     }
//     bool liveStatus = false;

//     if (parsedContentType == 1) {
//       setState(() {
//         liveStatus = false;
//       });
//     } else {
//       setState(() {
//         liveStatus = true;
//       });
//     }

//     // print('Navigating to video with URL: $videoUrl');
//     // print('Stream type: $streamType');
//     // print('Content type: $parsedContentType');

//     try {
//       await Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => VideoScreen(
//             videoUrl: videoUrl,
//             startAtPosition: Duration.zero,
//             bannerImageUrl: channel.thumbnail,
//             videoType: streamType,
//             channelList: searchResults,
//             isLive: true,
//             isVOD: false,
//             isBannerSlider: false,
//             source: 'isSearchScreen',
//             isSearch: true,
//             videoId: int.tryParse(channel.id),
//             unUpdatedUrl: videoUrl,
//             name: channel.name,
//             liveStatus: liveStatus,
//           ),
//         ),
//       );
//     } catch (e) {
//       // print('Error navigating to video screen: $e');
//     }
//     // }
//   }

//   void _dismissLoadingIndicator() {
//     if (Navigator.of(context).canPop()) {
//       Navigator.of(context).pop();
//     }
//   }

//   void checkServerStatus() {
//     int retryCount = 0;
//     Timer.periodic(Duration(seconds: 10), (timer) {
//       if (!_socketService.socket.connected && retryCount < _maxRetries) {
//         retryCount++;
//         _socketService.initSocket();
//       } else {
//         timer.cancel();
//       }
//     });
//   }

//   void _onSearchFieldFocusChanged() {
//     setState(() {});
//   }

//   void _onSearchIconFocusChanged() {
//     setState(() {});
//   }

// //   void _performSearch(String searchTerm) {
// //   if (_debounce?.isActive ?? false) _debounce?.cancel();

// //   _debounce = Timer(const Duration(milliseconds: 300), () async {
// //     if (!mounted) return;

// //     setState(() {
// //       isLoading = true;
// //       searchResults.clear();
// //       _itemFocusNodes.clear();
// //     });

// //     try {
// //       final apiResults = await fetchFromApi(searchTerm);

// //       if (!mounted) return;

// //       setState(() {
// //         searchResults = apiResults;
// //         _itemFocusNodes.addAll(
// //             List.generate(searchResults.length, (index) => FocusNode()));
// //         isLoading = false;
// //       });

// //       await _preloadImages(searchResults);

// //     } catch (e) {
// //       if (!mounted) return;
// //       setState(() {
// //         isLoading = false;
// //       });
// //       print("Search error: $e");
// //     }
// //   });
// // }

//   // void _performSearch(String searchTerm) {
//   //   if (_debounce?.isActive ?? false) _debounce?.cancel();

//   //   _debounce = Timer(const Duration(milliseconds: 300), () async {
//   //     if (!mounted) return;

//   //     setState(() {
//   //       isLoading = true;
//   //       searchResults.clear();
//   //     });

//   //     try {
//   //       final apiResults = await fetchFromApi(searchTerm);

//   //       if (!mounted) return;

//   //       setState(() {
//   //         searchResults = apiResults;
//   //         isLoading = false;
//   //       });
//   //     } catch (e) {
//   //       if (!mounted) return;
//   //       setState(() {
//   //         isLoading = false;
//   //       });
//   //       print("Search error: $e");
//   //     }
//   //   });
//   // }

//   // void _performSearch(String searchTerm) {
//   //   if (_debounce?.isActive ?? false) _debounce?.cancel();

//   //   _debounce = Timer(const Duration(milliseconds: 300), () async {
//   //     if (!mounted) return;

//   //     setState(() {
//   //       isLoading = true;
//   //     });

//   //     try {
//   //       final apiResults = await fetchFromApi(searchTerm);

//   //       if (!mounted) return;

//   //       if (apiResults.isEmpty) {
//   //         print("No search results found.");
//   //         setState(() {
//   //           searchResults.clear();
//   //           isLoading = false;
//   //         });
//   //       } else {
//   //         setState(() {
//   //           searchResults = apiResults;
//   //           isLoading = false;
//   //         });
//   //       }
//   //     } catch (e) {
//   //       if (!mounted) return;
//   //       setState(() {
//   //         isLoading = false;
//   //       });
//   //       print("Search error: $e");
//   //     }
//   //   });
//   // }

//   // void _performSearch(String searchTerm) {
//   //   if (_debounce?.isActive ?? false) _debounce?.cancel();
//   //   _debounce = Timer(const Duration(milliseconds: 500), () async {
//   //     List<NewsItemModel> results = await fetchFromApi(searchTerm);

//   //     setState(() {
//   //       searchResults = results;
//   //       isLoading = false;
//   //       searchResults.clear();
//   //       _itemFocusNodes.clear();
//   //     });
//   //   });

//   //   // void _performSearch(String searchTerm) {
//   //   //   if (_debounce?.isActive ?? false) _debounce?.cancel();

//   //   //   if (searchTerm.trim().isEmpty) {
//   //   //     setState(() {
//   //   //       isLoading = false;
//   //   //       searchResults.clear();
//   //   //       _itemFocusNodes.clear();
//   //   //     });
//   //   //     return;
//   //   //   }

//   //   _debounce = Timer(const Duration(milliseconds: 300), () async {
//   //     if (!mounted) return;
//   //     setState(() {
//   //       isLoading = true;
//   //       searchResults.clear();
//   //       _itemFocusNodes.clear();
//   //     });

//   //     try {
//   //       final api1Results = await fetchFromApi(searchTerm);
//   //       if (!mounted) return;
//   //       setState(() {
//   //         searchResults = api1Results;
//   //         _itemFocusNodes.addAll(
//   //             List.generate(searchResults.length, (index) => FocusNode()));
//   //         isLoading = false;
//   //       });

//   //       await _preloadImages(searchResults);

//   //       if (!mounted) return;
//   //       WidgetsBinding.instance.addPostFrameCallback((_) {
//   //         if (_itemFocusNodes.isNotEmpty &&
//   //             _itemFocusNodes[0].context != null &&
//   //             mounted) {
//   //           FocusScope.of(context).requestFocus(_itemFocusNodes[0]);
//   //         }
//   //       });
//   //     } catch (e) {
//   //       if (!mounted) return;
//   //       setState(() {
//   //         isLoading = false;
//   //       });
//   //     }
//   //   });
//   // }

//   Future<void> _preloadImages(List<NewsItemModel> results) async {
//     for (var result in results) {
//       final imageUrl = result.thumbnail;
//       if (imageUrl.isNotEmpty) {
//         await precacheImage(CachedNetworkImageProvider(imageUrl), context);
//       }
//     }
//   }

//   // Future<void> _updatePaletteColor(String imageUrl) async {
//   //   try {
//   //     Color color = await _paletteColorService.getSecondaryColor(imageUrl);
//   //     if (!mounted) return;
//   //     setState(() {
//   //       paletteColor = color;
//   //     });
//   //   } catch (e) {
//   //     print('Error updating palette color: $e');
//   //     if (!mounted) return;
//   //     setState(() {
//   //       paletteColor = Colors.grey;
//   //     });
//   //   }
//   // }

//   // Update the _updatePaletteColor method:
//   Future<void> _updatePaletteColor(String imageUrl, bool isFocused) async {
//     try {
//       Color color = await _paletteColorService.getSecondaryColor(imageUrl);
//       if (!mounted) return;

//       setState(() {
//         paletteColor = color;
//       });

//       // Update the provider with both color and focus state
//       Provider.of<ColorProvider>(context, listen: false)
//           .updateColor(color, isFocused);
//     } catch (e) {
//       print('Error updating palette color: $e');
//       if (!mounted) return;

//       setState(() {
//         paletteColor = Colors.grey;
//       });

//       // Update with grey color in case of error
//       Provider.of<ColorProvider>(context, listen: false)
//           .updateColor(Colors.grey, isFocused);
//     }
//   }

//   void _toggleSearchField() {
//     setState(() {
//       _showSearchField = !_showSearchField;
//       if (_showSearchField) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           _searchFieldFocusNode.requestFocus();
//         });
//       } else {
//         _youtubeSearchIconFocusNode.requestFocus();
//       }
//     });
//   }

// @override
// Widget build(BuildContext context) {
//   return Consumer<ColorProvider>(builder: (context, colorProvider, child) {
//     // Get background color based on provider state
//     Color backgroundColor =
//         colorProvider.isItemFocused ? colorProvider.dominantColor : cardColor;
//     return Scaffold(
//       backgroundColor: backgroundColor,
//       body: Container(
//         color: Colors.black54,
//         child: Column(
//           children: [
//             _buildSearchBar(),
//             Expanded(
//               child: isLoading
//                   ? Center(
//                       child: SpinKitFadingCircle(
//                         color: borderColor,
//                         size: 50.0,
//                       ),
//                     )
//                   : searchResults.isEmpty
//                       ? Center(
//                           child: Text(
//                             'No results found',
//                             style: TextStyle(color: Colors.white),
//                           ),
//                         )
//                       : Padding(
//                           padding: EdgeInsets.symmetric(
//                               horizontal: screenwdt * 0.03),
//                           child: GridView.builder(
//                             gridDelegate:
//                                 const SliverGridDelegateWithFixedCrossAxisCount(
//                               crossAxisCount: 5,
//                             ),
//                             itemCount: searchResults.length,
//                             itemBuilder: (context, index) {
//                               print("Rendering item at index: $index");

//                               // Extra safety check
//                               if (searchResults.isEmpty || index >= searchResults.length) {
//                                 print("Skipping index $index due to empty list");
//                                 return SizedBox(); // Prevents crash
//                               }

//                               return GestureDetector(
//                                 onTap: () => _onItemTap(context, index),
//                                 child: _buildGridViewItem(context, index),
//                               );
//                             },
//                           ),
//                         ),
//             ),
//           ],
//         ),
//       ),
//     );
//   });
// }

//   Widget _buildSearchBar() {
//     return Container(
//       width: screenwdt * 0.93,
//       padding: EdgeInsets.only(top: screenhgt * 0.02),
//       height: screenhgt * 0.1,
//       child: Row(
//         children: [
//           if (!_showSearchField) Expanded(child: Text('')),
//           if (_showSearchField)
//             Expanded(
//               child: TextField(
//                 controller: _searchController,
//                 focusNode: _searchFieldFocusNode,
//                 decoration: InputDecoration(
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10.0),
//                     borderSide: BorderSide(color: Colors.grey, width: 4.0),
//                   ),
//                   labelText: 'Search By Name',
//                   labelStyle: TextStyle(color: Colors.white),
//                 ),
//                 style: TextStyle(color: Colors.white),
//                 textInputAction: TextInputAction.search,
//                 textAlignVertical: TextAlignVertical.center,
//                 onChanged: (value) {
//                   _performSearch(value);
//                 },
//                 onSubmitted: (value) {
//                   _performSearch(value);
//                   _toggleSearchField();
//                 },
//                 autofocus: true,
//               ),
//             ),
//           Focus(
//             focusNode: _youtubeSearchIconFocusNode,
//             onKey: (node, event) {
//               if (event is RawKeyDownEvent &&
//                   event.logicalKey == LogicalKeyboardKey.select) {
//                 _toggleSearchField();
//                 return KeyEventResult.handled;
//               }
//               return KeyEventResult.ignored;
//             },
//             child: IconButton(
//               icon: Icon(
//                 Icons.search,
//                 color:
//                     _youtubeSearchIconFocusNode.hasFocus ? borderColor : Colors.white,
//                 size: _youtubeSearchIconFocusNode.hasFocus ? 35 : 30,
//               ),
//               onPressed: _toggleSearchField,
//               focusColor: Colors.transparent,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Widget _buildGridViewItem(BuildContext context, int index) {

//   //       if (index >= searchResults.length || index >= _itemFocusNodes.length) {
//   //     return SizedBox(); // Return empty widget if index is out of bounds
//   //   }
//   //   final result = searchResults[index];
//   //   final status = result.status;
//   //   final bool isBase64 = result.thumbnail.startsWith('data:image');
//   //   final colorProvider = Provider.of<ColorProvider>(context, listen: false);

//   //   return Focus(
//   //     focusNode: _itemFocusNodes[index],
//   //     onFocusChange: (hasFocus) async {
//   //       if (hasFocus) {
//   //         // Update palette color with focus state
//   //         await _updatePaletteColor(result.thumbnail, true);
//   //       } else {
//   //         // Reset color when focus is lost
//   //         colorProvider.resetColor();
//   //       }

//   //       setState(() {
//   //         selectedIndex = hasFocus ? index : -1;
//   //       });
//   //     },
//   //     onKeyEvent: (FocusNode node, KeyEvent event) {
//   //       if (event is KeyDownEvent &&
//   //           event.logicalKey == LogicalKeyboardKey.select) {
//   //         _onItemTap(context, index);
//   //         return KeyEventResult.handled;
//   //       }
//   //       return KeyEventResult.ignored;
//   //     },
//   //     child: Column(
//   //       crossAxisAlignment: CrossAxisAlignment.center,
//   //       mainAxisAlignment: MainAxisAlignment.center,
//   //       children: [
//   //         AnimatedContainer(
//   //           width: screenwdt * 0.19,
//   //           height: screenhgt * 0.2,
//   //           duration: const Duration(milliseconds: 300),
//   //           decoration: BoxDecoration(
//   //             border: selectedIndex == index
//   //                 ? Border.all(
//   //                     color: paletteColor,
//   //                     width: 3.0,
//   //                   )
//   //                 : Border.all(
//   //                     color: Colors.transparent,
//   //                     width: 3.0,
//   //                   ),
//   //             boxShadow: selectedIndex == index
//   //                 ? [
//   //                     BoxShadow(
//   //                       color: paletteColor,
//   //                       blurRadius: 25,
//   //                       spreadRadius: 10,
//   //                     )
//   //                   ]
//   //                 : [],
//   //           ),
//   //           child: status == '1'
//   //               ? ClipRRect(
//   //                   child: isBase64
//   //                       ? Image.memory(
//   //                           _getImageFromBase64String(result.thumbnail) ??
//   //                               localImage,
//   //                           width: screenwdt * 0.19,
//   //                           height: screenhgt * 0.2,
//   //                           fit: BoxFit.cover,
//   //                         )
//   //                       : CachedNetworkImage(
//   //                           imageUrl: result.thumbnail ?? localImage,
//   //                           placeholder: (context, url) => localImage,
//   //                           errorWidget: (context, url, error) => localImage,
//   //                           width: screenwdt * 0.19,
//   //                           height: screenhgt * 0.2,
//   //                           fit: BoxFit.cover,
//   //                         ),
//   //                 )
//   //               : null,
//   //         ),
//   //         Container(
//   //           width: MediaQuery.of(context).size.width * 0.15,
//   //           child: Text(
//   //             result.name.toUpperCase(),
//   //             style: TextStyle(
//   //               fontSize: 15,
//   //               color: selectedIndex == index ? paletteColor : Colors.white,
//   //             ),
//   //             textAlign: TextAlign.center,
//   //             maxLines: 1,
//   //             overflow: TextOverflow.ellipsis,
//   //           ),
//   //         ),
//   //       ],
//   //     ),
//   //   );
//   // }

//   Widget _buildGridViewItem(BuildContext context, int index) {
//   if (index >= searchResults.length || index >= _itemFocusNodes.length) {
//     return SizedBox(); // Return empty widget if index is out of bounds
//   }
//   final result = searchResults[index];
//   final status = result.status;
//   final bool isBase64 = result.thumbnail.startsWith('data:image');
//   final colorProvider = Provider.of<ColorProvider>(context, listen: false);

//   return Focus(
//     focusNode: _itemFocusNodes[index],
//     onFocusChange: (hasFocus) async {
//       if (hasFocus) {
//         // Update palette color with focus state
//         await _updatePaletteColor(result.thumbnail, true);
//       } else {
//         // Reset color when focus is lost
//         colorProvider.resetColor();
//       }

//       setState(() {
//         selectedIndex = hasFocus ? index : -1;
//       });
//     },
//     onKeyEvent: (FocusNode node, KeyEvent event) {
//       if (event is KeyDownEvent &&
//           event.logicalKey == LogicalKeyboardKey.select) {
//         _onItemTap(context, index);
//         return KeyEventResult.handled;
//       }
//       return KeyEventResult.ignored;
//     },
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         AnimatedContainer(
//           width: screenwdt * 0.19,
//           height: screenhgt * 0.2,
//           duration: const Duration(milliseconds: 300),
//           decoration: BoxDecoration(
//             border: selectedIndex == index
//                 ? Border.all(
//                     color: paletteColor,
//                     width: 3.0,
//                   )
//                 : Border.all(
//                     color: Colors.transparent,
//                     width: 3.0,
//                   ),
//             boxShadow: selectedIndex == index
//                 ? [
//                     BoxShadow(
//                       color: paletteColor,
//                       blurRadius: 25,
//                       spreadRadius: 10,
//                     )
//                   ]
//                 : [],
//           ),
//           child:  ClipRRect(
//                   child: isBase64
//                       ? Image.memory(
//                           _getImageFromBase64String(result.thumbnail) ??
//                               localImage,
//                           width: screenwdt * 0.19,
//                           height: screenhgt * 0.2,
//                           fit: BoxFit.cover,
//                         )
//                       : CachedNetworkImage(
//                           imageUrl: result.thumbnail ?? localImage,
//                           placeholder: (context, url) => localImage,
//                           errorWidget: (context, url, error) => localImage,
//                           width: screenwdt * 0.19,
//                           height: screenhgt * 0.2,
//                           fit: BoxFit.cover,
//                         ),
//                 )
//         ),
//         Container(
//           width: MediaQuery.of(context).size.width * 0.15,
//           child: Text(
//             result.name.toUpperCase(),
//             style: TextStyle(
//               fontSize: 15,
//               color: selectedIndex == index ? paletteColor : Colors.white,
//             ),
//             textAlign: TextAlign.center,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       ],
//     ),
//   );
// }
// }

import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
import 'package:mobi_tv_entertainment/menu_screens/home_sub_screen/sub_vod.dart';
import 'package:mobi_tv_entertainment/provider/color_provider.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../provider/focus_provider.dart';
import '../video_widget/socket_service.dart';
import '../video_widget/video_screen.dart';
import '../widgets/models/news_item_model.dart';
import '../widgets/utils/color_service.dart';

Uint8List _getImageFromBase64String(String base64String) {
  // Split the base64 string to remove metadata if present
  return base64Decode(base64String.split(',').last);
}

Map<String, dynamic> settings = {};

// Future<void> fetchSettings() async {
//   try {
//     final response = await https.get(
//       Uri.parse('https://api.ekomflix.com/android/getSettings'),
//       headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//     );

//     if (response.statusCode == 200) {
//       settings = json.decode(response.body);
//     } else {
//       throw Exception('Failed to load settings');
//     }
//   } catch (e) {
//     print('Error fetching settings: $e');
//   }
// }

class YoutubeSearchScreen extends StatefulWidget {
  @override
  _YoutubeSearchScreenState createState() => _YoutubeSearchScreenState();
}

class _YoutubeSearchScreenState extends State<YoutubeSearchScreen> {
  List<NewsItemModel> searchResults = [];
  bool isLoading = false;
  TextEditingController _searchController = TextEditingController();
  int selectedIndex = -1;
  final FocusNode _searchFieldFocusNode = FocusNode();
  final FocusNode _youtubeSearchIconFocusNode = FocusNode();
  Timer? _debounce;
  final List<FocusNode> _itemFocusNodes = [];
  bool _isNavigating = false;
  bool _showSearchField = false;
  Color paletteColor = Colors.grey;
  final PaletteColorService _paletteColorService = PaletteColorService();
  final SocketService _socketService = SocketService();
  final int _maxRetries = 3;
  final int _retryDelay = 5;
  bool _shouldContinueLoading = true;

  @override
  void initState() {
    super.initState();
    _searchFieldFocusNode.addListener(_onSearchFieldFocusChanged);
    _youtubeSearchIconFocusNode.addListener(_onSearchIconFocusChanged);
    _socketService.initSocket();
    checkServerStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<FocusProvider>()
          .setYoutubeSearchIconFocusNode(_youtubeSearchIconFocusNode);
    });
  }

  @override
  void dispose() {
    _searchFieldFocusNode.removeListener(_onSearchFieldFocusChanged);
    _youtubeSearchIconFocusNode.removeListener(_onSearchIconFocusChanged);
    _searchFieldFocusNode.dispose();
    _youtubeSearchIconFocusNode.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    _itemFocusNodes.forEach((node) => node.dispose());
    _socketService.dispose();
    super.dispose();
  }

  Future<List<NewsItemModel>> fetchFromApi(String searchTerm) async {
    print("Fetching search results for: $searchTerm");

    if (searchTerm.isEmpty) {
      setState(() {
        searchResults.clear();
        isLoading = false;
      });
      print("Search term is empty, clearing results.");
      return [];
    }

    setState(() => isLoading = true);

    try {
      final response = await https.get(
        Uri.parse(
            'https://mobifreetv.com/android/youtube_search?text=${Uri.encodeComponent(searchTerm)}'),
        headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
      );

      print("API Response Status Code: ${response.statusCode}");
      print("API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('error')) {
          print("API returned an error: ${data['error']}");
          print(
              "Before setState - searchResults Length: ${searchResults.length}");
          setState(() {
            isLoading = false;
            searchResults.clear();
          });
          print(
              "After setState - searchResults Length: ${searchResults.length}");
          return [];
        }

        if (data.containsKey('videos') && data['videos'] is List) {
          List<NewsItemModel> results = (data['videos'] as List)
              .map((video) => NewsItemModel.fromJson(video))
              .toList();

          print("Fetched ${results.length} search results");

          if (mounted) {
            setState(() {
              // searchResults = results;
              isLoading = false;
            });

            // **Wait for UI update before returning results**
            await Future.delayed(Duration(milliseconds: 200));
          }

          return results;
        } else {
          print("API returned an invalid response. Clearing results.");
          if (mounted) {
            print(
                "Before setState - searchResults Length: ${searchResults.length}");
            setState(() {
              searchResults.clear();
              isLoading = false;
            });
            print(
                "After setState - searchResults Length: ${searchResults.length}");
          }
        }
      } else {
        print(
            "Failed to load search results. HTTP Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching videos: $e");
    }

    setState(() => isLoading = false);
    return [];
  }

  Future<void> _updateChannelUrlIfNeeded(
      List<NewsItemModel> result, int index) async {
    if (result[index].streamType == 'YoutubeLive' ||
        result[index].streamType == 'Youtube') {
      for (int i = 0; i < _maxRetries; i++) {
        if (!_shouldContinueLoading) break;
        try {
          String updatedUrl =
              await _socketService.getUpdatedUrl(result[index].url);
          setState(() {
            result[index] =
                result[index].copyWith(url: updatedUrl, streamType: 'M3u8');
          });
          break;
        } catch (e) {
          if (i == _maxRetries - 1) rethrow;
          await Future.delayed(Duration(seconds: _retryDelay));
        }
      }
    }
  }

  Future<void> _onItemTap(BuildContext context, int index) async {
    if (_isNavigating) return;
    _isNavigating = true;
    _showLoadingIndicator(context);

    try {
      // await _updateChannelUrlIfNeeded(searchResults, index);
      if (_shouldContinueLoading) {
        await _navigateToVideoScreen(context, searchResults, index);
      }
    } catch (e) {
      print('Error playing video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something Went Wrong')),
      );
    } finally {
      _isNavigating = false;
      _shouldContinueLoading = true;
      _dismissLoadingIndicator();
    }
  }

  void _showLoadingIndicator(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            _shouldContinueLoading = false;
            _dismissLoadingIndicator();
            return Future.value(false);
          },
          child: Center(
            child: SpinKitFadingCircle(
              color: Colors.white,
              size: 50.0,
            ),
          ),
        );
      },
    );
  }

  bool isYoutubeUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }

    url = url.toLowerCase().trim();

    // First check if it's a YouTube ID (exactly 11 characters)
    bool isYoutubeId = RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url);
    if (isYoutubeId) {
      print("Matched YouTube ID pattern: $url");
      return true;
    }

    // Then check for regular YouTube URLs
    bool isYoutubeUrl = url.contains('youtube.com') ||
        url.contains('youtu.be') ||
        url.contains('youtube.com/shorts/');
    if (isYoutubeUrl) {
      print("Matched YouTube URL pattern: $url");
      return true;
    }

    print("Not a YouTube URL/ID: $url");
    return false;
  }

  String formatUrl(String url, {Map<String, String>? params}) {
    if (url.isEmpty) {
      print("Warning: Empty URL provided");
      throw Exception("Empty URL provided");
    }

    // Handle YouTube ID by converting to full URL if needed
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) {
      print("Converting YouTube ID to full URL");
      url = "https://www.youtube.com/watch?v=$url";
    }

    // Remove any existing query parameters
    url = url.split('?')[0];

    // Add new query parameters
    if (params != null && params.isNotEmpty) {
      url += '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
    }

    print("Formatted URL: $url");
    return url;
  }

  Future<void> _navigateToVideoScreen(
      BuildContext context, List<NewsItemModel> channels, int index) async {
    if (index < 0 || index >= channels.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid channel index')),
      );
      return;
    }

    final channel = channels[index];
    String? videoUrl = channel.videoId;
    final String? streamType = channel.streamType;
    final String? genres = channel.genres;
    final int? parsedContentType = int.tryParse(channel.contentType);
    if (parsedContentType == 1) {
      print(
          'Navigating to DetailsPage with ID: ${int.tryParse(channel.id) ?? 0}');

      if (isYoutubeUrl(videoUrl)) {
        print("Processing YouTube URL from last played videos");
        videoUrl = await _socketService.getUpdatedUrl(videoUrl);
      }

      try {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsPage(
              channelList: searchResults,
              id: int.tryParse(channel.id) ?? 0,
              source: 'isSearchScreenViaDetailsPageChannelList',
              banner: channel.thumbnail,
              name: channel.name,
            ),
          ),
        );
      } catch (e) {
        // print('Error navigating to details page: $e');
      }
      //         ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Video information is missing or invalid 1.Channel contentType: ${channel.contentType} 2. Parsed contentType: $parsedContentType')),
      // );
    }

    // if (videoUrl == null || videoUrl.isEmpty || streamType == null) {
    //   // ScaffoldMessenger.of(context).showSnackBar(
    //   //   SnackBar(content: Text('Video information is missing or invalid')),
    //   // );
    //   return;
    // }
    bool liveStatus = false;

    if (parsedContentType == 1) {
      setState(() {
        liveStatus = false;
      });
    } else {
      setState(() {
        liveStatus = true;
      });
    }

    // print('Navigating to video with URL: $videoUrl');
    // print('Stream type: $streamType');
    // print('Content type: $parsedContentType');

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoScreen(
            videoUrl: videoUrl ?? '',
            startAtPosition: Duration.zero,
            bannerImageUrl: channel.thumbnail,
            videoType: '',
            channelList: searchResults,
            isLive: true,
            isVOD: false,
            isBannerSlider: false,
            source: 'isSearchScreen',
            isSearch: true,
            videoId: int.tryParse(channel.id),
            unUpdatedUrl: videoUrl ?? '',
            name: channel.name,
            liveStatus: liveStatus,
          ),
        ),
      );
    } catch (e) {
      // print('Error navigating to video screen: $e');
    }
    // }
  }

  void _dismissLoadingIndicator() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void checkServerStatus() {
    int retryCount = 0;
    Timer.periodic(Duration(seconds: 10), (timer) {
      if (!_socketService.socket.connected && retryCount < _maxRetries) {
        retryCount++;
        _socketService.initSocket();
      } else {
        timer.cancel();
      }
    });
  }

  void _onSearchFieldFocusChanged() {
    setState(() {});
  }

  void _onSearchIconFocusChanged() {
    setState(() {});
  }

  void _performSearch(String searchTerm) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    if (searchTerm.trim().isEmpty) {
      setState(() {
        isLoading = false;
        searchResults.clear();
        _itemFocusNodes.clear();
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() {
        isLoading = true;
        searchResults.clear();
        _itemFocusNodes.clear();
      });

      try {
        final api1Results = await fetchFromApi(searchTerm);
        if (!mounted) return;
        setState(() {
          searchResults = api1Results;
          _itemFocusNodes.addAll(
              List.generate(searchResults.length, (index) => FocusNode()));
          isLoading = false;
        });

        await _preloadImages(searchResults);

        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_itemFocusNodes.isNotEmpty &&
              _itemFocusNodes[0].context != null &&
              mounted) {
            FocusScope.of(context).requestFocus(_itemFocusNodes[0]);
          }
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  Future<void> _preloadImages(List<NewsItemModel> results) async {
    for (var result in results) {
      final imageUrl = result.thumbnail;
      if (imageUrl.isNotEmpty) {
        await precacheImage(CachedNetworkImageProvider(imageUrl), context);
      }
    }
  }

  // Future<void> _updatePaletteColor(String imageUrl) async {
  //   try {
  //     Color color = await _paletteColorService.getSecondaryColor(imageUrl);
  //     if (!mounted) return;
  //     setState(() {
  //       paletteColor = color;
  //     });
  //   } catch (e) {
  //     print('Error updating palette color: $e');
  //     if (!mounted) return;
  //     setState(() {
  //       paletteColor = Colors.grey;
  //     });
  //   }
  // }

  // Update the _updatePaletteColor method:
  Future<void> _updatePaletteColor(String imageUrl, bool isFocused) async {
    try {
      Color color = await _paletteColorService.getSecondaryColor(imageUrl);
      if (!mounted) return;

      setState(() {
        paletteColor = color;
      });

      // Update the provider with both color and focus state
      Provider.of<ColorProvider>(context, listen: false)
          .updateColor(color, isFocused);
    } catch (e) {
      print('Error updating palette color: $e');
      if (!mounted) return;

      setState(() {
        paletteColor = Colors.grey;
      });

      // Update with grey color in case of error
      Provider.of<ColorProvider>(context, listen: false)
          .updateColor(Colors.grey, isFocused);
    }
  }

  void _toggleSearchField() {
    setState(() {
      _showSearchField = !_showSearchField;
      if (_showSearchField) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFieldFocusNode.requestFocus();
        });
      } else {
        _youtubeSearchIconFocusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ColorProvider>(builder: (context, colorProvider, child) {
      // Get background color based on provider state
      Color backgroundColor =
          colorProvider.isItemFocused ? colorProvider.dominantColor : cardColor;
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Container(
          color: Colors.black54,
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: isLoading
                    ? Center(
                        child: SpinKitFadingCircle(
                          color: borderColor,
                          size: 50.0,
                        ),
                      )
                    : searchResults.isEmpty
                        ? Center(
                            child: Text(
                              'No results found',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        : Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: screenwdt * 0.03),
                            child: GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                              ),
                              itemCount: searchResults.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () => _onItemTap(context, index),
                                  child: _buildGridViewItem(context, index),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSearchBar() {
    return Container(
      width: screenwdt * 0.93,
      padding: EdgeInsets.only(top: screenhgt * 0.02),
      height: screenhgt * 0.1,
      child: Row(
        children: [
          if (!_showSearchField) Expanded(child: Text('')),
          if (_showSearchField)
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFieldFocusNode,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: Colors.grey, width: 4.0),
                  ),
                  labelText: 'Search By Name',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                style: TextStyle(color: Colors.white),
                textInputAction: TextInputAction.search,
                textAlignVertical: TextAlignVertical.center,
                onChanged: (value) {
                  // _performSearch(value);
                },
                onSubmitted: (value) {
                  _performSearch(value);
                  _toggleSearchField();
                },
                autofocus: true,
              ),
            ),
          Focus(
            focusNode: _youtubeSearchIconFocusNode,
            onKey: (node, event) {
              if (event is RawKeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.arrowUp) {
                context.read<FocusProvider>().requestYoutubeSearchNavigationFocus();
                return KeyEventResult.handled;
              } else if (event is RawKeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.select) {
                _toggleSearchField();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: IconButton(
              icon: Icon(
                Icons.search,
                color: _youtubeSearchIconFocusNode.hasFocus
                    ? borderColor
                    : Colors.white,
                size: _youtubeSearchIconFocusNode.hasFocus ? 35 : 30,
              ),
              onPressed: _toggleSearchField,
              focusColor: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridViewItem(BuildContext context, int index) {
    final result = searchResults[index];
    final status = result.status;
    final bool isBase64 = result.thumbnail.startsWith('data:image');
    final colorProvider = Provider.of<ColorProvider>(context, listen: false);

    return Focus(
      focusNode: _itemFocusNodes[index],
      onFocusChange: (hasFocus) async {
        if (hasFocus) {
          // Update palette color with focus state
          await _updatePaletteColor(result.banner, true);
        } else {
          // Reset color when focus is lost
          colorProvider.resetColor();
        }

        setState(() {
          selectedIndex = hasFocus ? index : -1;
        });
      },
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.select) {
          _onItemTap(context, index);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
              width: screenwdt * 0.19,
              height: screenhgt * 0.2,
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                border: selectedIndex == index
                    ? Border.all(
                        color: paletteColor,
                        width: 3.0,
                      )
                    : Border.all(
                        color: Colors.transparent,
                        width: 3.0,
                      ),
                boxShadow: selectedIndex == index
                    ? [
                        BoxShadow(
                          color: paletteColor,
                          blurRadius: 25,
                          spreadRadius: 10,
                        )
                      ]
                    : [],
              ),
              child:
                  // status == '1'
                  // ?
                  ClipRRect(
                child: isBase64
                    ? Image.memory(
                        _getImageFromBase64String(result.thumbnail) ??
                            localImage,
                        width: screenwdt * 0.19,
                        height: screenhgt * 0.2,
                        fit: BoxFit.cover,
                      )
                    : CachedNetworkImage(
                        imageUrl: result.thumbnail ?? localImage,
                        placeholder: (context, url) => localImage,
                        errorWidget: (context, url, error) => localImage,
                        width: screenwdt * 0.19,
                        height: screenhgt * 0.2,
                        fit: BoxFit.cover,
                      ),
              )
              // : null,
              ),
          Container(
            width: MediaQuery.of(context).size.width * 0.15,
            child: Text(
              result.name.toUpperCase(),
              style: TextStyle(
                fontSize: 15,
                color: selectedIndex == index ? paletteColor : Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
