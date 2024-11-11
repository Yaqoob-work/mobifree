// import 'dart:async';
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:mobi_tv_entertainment/main.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:http/http.dart' as https;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../services/socket_service.dart';
// import '../../video_widget/socket_service.dart';
// import '../../video_widget/video_movie_screen.dart';
// import '../../video_widget/vlc_player_screen.dart';
// import '../../widgets/focussable_item_widget.dart';
// import '../../widgets/small_widgets/loading_indicator.dart';
// import '../../widgets/utils/color_service.dart';

// void main() {
//   runApp(SubVod());
// }

// Future<Color> fetchPaletteColor(String imageUrl) async {
//   return await PaletteColorService().getSecondaryColor(imageUrl);
// }

// // Helper function to decode base64 images
// Uint8List _getImageFromBase64String(String base64String) {
//   return base64Decode(base64String.split(',').last);
// }

// // Models
// class NetworkApi {
//   final int id;
//   final String name;
//   final String logo;

//   NetworkApi({required this.id, required this.name, required this.logo});

//   factory NetworkApi.fromJson(Map<String, dynamic> json) {
//     return NetworkApi(
//       id: json['id'] is int
//           ? json['id'] as int
//           : int.parse(json['id'].toString()),
//       name: json['name'] ?? 'No Name',
//       logo: json['logo'] ?? localImage,
//     );
//   }
// }

// class ContentApi {
//   final int id;
//   final String name;
//   final String banner;

//   ContentApi({required this.id, required this.name, required this.banner});

//   factory ContentApi.fromJson(Map<String, dynamic> json) {
//     return ContentApi(
//       id: json['id'] is int
//           ? json['id'] as int
//           : int.parse(json['id'].toString()),
//       name: json['name'] ?? 'No Name',
//       banner: json['banner'] ?? localImage,
//     );
//   }
// }

// class MovieDetailsApi {
//   final int id;
//   final String name;
//   final String banner;
//   final String poster;
//   final String genres;
//   final String status;

//   MovieDetailsApi({
//     required this.id,
//     required this.name,
//     required this.banner,
//     required this.poster,
//     required this.genres,
//     required this.status,
//   });

//   factory MovieDetailsApi.fromJson(Map<String, dynamic> json) {
//     return MovieDetailsApi(
//       id: json['id'] is int
//           ? json['id'] as int
//           : int.parse(json['id'].toString()),
//       name: json['name'] ?? 'No Name',
//       banner: json['banner'] ?? localImage,
//       poster: json['poster'] ?? localImage,
//       genres: json['genres'] ?? 'Unknown',
//       status: json['status'] ?? '0',
//     );
//   }
// }

// Future<List<NetworkApi>> fetchNetworks(BuildContext context) async {
//   final prefs = await SharedPreferences.getInstance();
//   final cachedNetworks = prefs.getString('networks');

//   List<NetworkApi> networks;

//   if (cachedNetworks != null) {
//     List<dynamic> body = json.decode(cachedNetworks);
//     networks = body.map((dynamic item) => NetworkApi.fromJson(item)).toList();
//   } else {
//     final response = await https.get(
//       Uri.parse('https://api.ekomflix.com/android/getNetworks'),
//       headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//     );

//     if (response.statusCode == 200) {
//       List<dynamic> body = json.decode(response.body);
//       prefs.setString('networks', response.body); // Cache the networks
//       networks = body.map((dynamic item) => NetworkApi.fromJson(item)).toList();
//     } else {
//       throw Exception('Failed to load networks');
//     }
//   }

//   // // Preload the network logo images
//   // for (var network in networks) {
//   //   print("Network Logo URL: ${network.logo}"); // Log the network logo URL
//   //   if (network.logo.isNotEmpty) {
//   //     await precacheImage(
//   //       CachedNetworkImageProvider(network.logo),
//   //       context,
//   //     );
//   //   }
//   // }

//   return networks;
// }

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
//       placeholder: (context, url) => CircularProgressIndicator(),
//       errorWidget: (context, url, error) => Icon(Icons.error),
//       fit: BoxFit.cover,
//       width: 100.0, // Customize width as per your need
//       height: 100.0, // Customize height as per your need
//     );
//   } else {
//     // Fallback for invalid image data
//     return Icon(Icons.broken_image, size: 100.0);
//   }
// }

// // Widget to handle image loading (either base64 or URL)
// Widget displayImage(
//   String imageUrl, {
//   double? width,
//   double? height,
// }) {
//   if (imageUrl.startsWith('data:image')) {
//     // Handle base64-encoded images
//     Uint8List imageBytes = _getImageFromBase64String(imageUrl);
//     return Image.memory(
//       imageBytes,
//       fit: BoxFit.fill,
//       width: width,
//       height: height,
//     );
//   } else if (imageUrl.startsWith('http') || imageUrl.startsWith('https')) {
//     // Handle URL images
//     return CachedNetworkImage(
//       imageUrl: imageUrl,
//       placeholder: (context, url) => localImage,
//       errorWidget: (context, url, error) => localImage,
//       fit: BoxFit.fill,
//       width: width,
//       height: height,
//     );
//   } else {
//     // Fallback for invalid image data
//     return localImage;
//   }
// }

// Future<List<ContentApi>> fetchContent(
//     BuildContext context, int networkId) async {
//   final prefs = await SharedPreferences.getInstance();
//   final cachedContent = prefs.getString('content_$networkId');

//   List<ContentApi> content;

//   if (cachedContent != null) {
//     List<dynamic> body = json.decode(cachedContent);
//     content = body.map((dynamic item) => ContentApi.fromJson(item)).toList();
//   } else {
//     final response = await https.get(
//       Uri.parse(
//           'https://api.ekomflix.com/android/getAllContentsOfNetwork/$networkId'),
//       headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//     );

//     if (response.statusCode == 200) {
//       List<dynamic> body = json.decode(response.body);
//       prefs.setString('content_$networkId', response.body); // Cache the content
//       content = body.map((dynamic item) => ContentApi.fromJson(item)).toList();
//     } else {
//       throw Exception('Failed to load content');
//     }
//   }

//   // // Preload the content banners
//   // for (var item in content) {
//   //   print("Content Banner URL: ${item.banner}"); // Log the content banner URL
//   //   if (item.banner.isNotEmpty) {
//   //     await precacheImage(
//   //       CachedNetworkImageProvider(item.banner),
//   //       context,
//   //     );
//   //   }
//   // }

//   return content;
// }

// Future<MovieDetailsApi> fetchMovieDetails(
//     BuildContext context, int contentId) async {
//   final prefs = await SharedPreferences.getInstance();
//   final cachedMovieDetails = prefs.getString('movie_details_$contentId');

//   MovieDetailsApi movieDetails;

//   if (cachedMovieDetails != null) {
//     final Map<String, dynamic> body = json.decode(cachedMovieDetails);
//     movieDetails = MovieDetailsApi.fromJson(body);
//   } else {
//     final response = await https.get(
//       Uri.parse('https://api.ekomflix.com/android/getMovieDetails/$contentId'),
//       headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//     );

//     if (response.statusCode == 200) {
//       final Map<String, dynamic> body = json.decode(response.body);
//       prefs.setString(
//           'movie_details_$contentId', response.body); // Cache the movie details
//       movieDetails = MovieDetailsApi.fromJson(body);
//     } else {
//       throw Exception('Failed to load movie details');
//     }
//   }

//   // // Preload the banner and poster images
//   // if (movieDetails.banner.isNotEmpty) {
//   //   await precacheImage(
//   //     CachedNetworkImageProvider(movieDetails.banner),
//   //     context,
//   //   );
//   // }

//   // if (movieDetails.poster.isNotEmpty) {
//   //   await precacheImage(
//   //     CachedNetworkImageProvider(movieDetails.poster),
//   //     context,
//   //   );
//   // }

//   return movieDetails;
// }

// Future<Map<String, String>> fetchMoviePlayLink(int movieId) async {
//   final response = await https.get(
//     Uri.parse('https://api.ekomflix.com/android/getMoviePlayLinks/$movieId/0'),
//     headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//   );

//   if (response.statusCode == 200) {
//     final List<dynamic> body = json.decode(response.body);
//     if (body.isNotEmpty) {
//       final Map<String, dynamic> firstItem = body.first as Map<String, dynamic>;
//       return {'url': firstItem['url'] ?? '', 'type': firstItem['type'] ?? ''};
//     }
//     return {'url': '', 'type': ''};
//   } else {
//     throw Exception('Failed to load movie play link');
//   }
// }

// class SubVod extends StatefulWidget {
//   @override
//   _SubVodState createState() => _SubVodState();
// }

// class _SubVodState extends State<SubVod> {
//   late Future<List<NetworkApi>> _networksFuture;

//   @override
//   void initState() {
//     super.initState();
//     _networksFuture = _fetchAndUpdateUI();
//   }

//   Future<List<NetworkApi>> _fetchAndUpdateUI() async {
//     final prefs = await SharedPreferences.getInstance();
//     String? cachedNetworks = prefs.getString('subvod_networks');

//     if (cachedNetworks != null) {
//       List<dynamic> jsonBody = json.decode(cachedNetworks);
//       List<NetworkApi> cachedData =
//           jsonBody.map((e) => NetworkApi.fromJson(e)).toList();

//       // Fetch new data in the background and compare with the cache
//       _updateDataInBackground();
//       return cachedData;
//     } else {
//       return await _fetchAndCacheData(); // If no cache, fetch and cache data
//     }
//   }

//   Future<void> _updateDataInBackground() async {
//     final prefs = await SharedPreferences.getInstance();
//     final newNetworks = await fetchNetworks(context);
//     final newNetworksJson = json.encode(newNetworks);

//     // Compare new data with cached data
//     String? cachedNetworks = prefs.getString('subvod_networks');
//     if (cachedNetworks == null || cachedNetworks != newNetworksJson) {
//       // Cache the new data and update the UI only if there's a change
//       prefs.setString('subvod_networks', newNetworksJson);
//       setState(() {
//         _networksFuture = Future.value(newNetworks);
//       });
//     }
//   }

//   Future<List<NetworkApi>> _fetchAndCacheData() async {
//     final response = await https.get(
//       Uri.parse('https://api.ekomflix.com/android/getNetworks'),
//       headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//     );

//     if (response.statusCode == 200) {
//       List<dynamic> body = json.decode(response.body);
//       final prefs = await SharedPreferences.getInstance();
//       prefs.setString('subvod_networks', response.body);
//       return body.map((dynamic item) => NetworkApi.fromJson(item)).toList();
//     } else {
//       throw Exception('Failed to load networks');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: cardColor,
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Contents',
//             style: TextStyle(
//               fontSize: 20.0,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//           Expanded(
//             child: FutureBuilder<List<NetworkApi>>(
//               future: _networksFuture,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return Center(
//                     child: LoadingIndicator(),
//                   );
//                 } else if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                   return Center(child: Text('No Networks Available'));
//                 } else {
//                   final networks = snapshot.data!;
//                   return ListView.builder(
//                     scrollDirection: Axis.horizontal,
//                     itemCount: networks.length,
//                     itemBuilder: (context, index) {
//                       return FocusableItemWidget(
//                         imageUrl: networks[index].logo,
//                         name: networks[index].name,
//                         onTap: () async {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) =>
//                                   ContentScreen(networkId: networks[index].id),
//                             ),
//                           );
//                         },
//                         fetchPaletteColor: fetchPaletteColor,
//                       );
//                     },
//                   );
//                 }
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class VOD extends StatefulWidget {
//   @override
//   _VODState createState() => _VODState();
// }

// class _VODState extends State<VOD> {
//   late Future<List<NetworkApi>> _networksFuture;

//   @override
//   void initState() {
//     super.initState();
//     _networksFuture = _fetchAndUpdateUI();
//   }

//   Future<List<NetworkApi>> _fetchAndUpdateUI() async {
//     final prefs = await SharedPreferences.getInstance();
//     String? cachedNetworks = prefs.getString('subvod_networks');

//     if (cachedNetworks != null) {
//       List<dynamic> jsonBody = json.decode(cachedNetworks);
//       List<NetworkApi> cachedData =
//           jsonBody.map((e) => NetworkApi.fromJson(e)).toList();

//       _updateDataInBackground();
//       return cachedData;
//     } else {
//       return await _fetchAndCacheData(); // If no cache, fetch and cache data
//     }
//   }

//   Future<void> _updateDataInBackground() async {
//     final prefs = await SharedPreferences.getInstance();
//     final newNetworks = await fetchNetworks(context);
//     final newNetworksJson = json.encode(newNetworks);

//     String? cachedNetworks = prefs.getString('subvod_networks');
//     if (cachedNetworks == null || cachedNetworks != newNetworksJson) {
//       prefs.setString('subvod_networks', newNetworksJson);
//       setState(() {
//         _networksFuture = Future.value(newNetworks);
//       });
//     }
//   }

//   Future<List<NetworkApi>> _fetchAndCacheData() async {
//     final response = await https.get(
//       Uri.parse('https://api.ekomflix.com/android/getNetworks'),
//       headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//     );

//     if (response.statusCode == 200) {
//       List<dynamic> body = json.decode(response.body);
//       final prefs = await SharedPreferences.getInstance();
//       prefs.setString('networks', response.body);
//       return body.map((dynamic item) => NetworkApi.fromJson(item)).toList();
//     } else {
//       throw Exception('Failed to load networks');
//     }
//   }

//   Future<void> _updateUIIfChanged(int networkId) async {
//     final prefs = await SharedPreferences.getInstance();

//     final newContent = await fetchContent(context, networkId);
//     final newContentJson = json.encode(newContent);

//     String? cachedContent = prefs.getString('content_$networkId');
//     if (cachedContent == null || cachedContent != newContentJson) {
//       prefs.setString('content_$networkId', newContentJson);
//       setState(() {
//         _networksFuture =
//             Future.value(newContent as FutureOr<List<NetworkApi>>?);
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: cardColor,
//       body: FutureBuilder<List<NetworkApi>>(
//         future: _networksFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(
//               child: LoadingIndicator(),
//             );
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return Center(child: Text('No Networks Available'));
//           } else {
//             final networks = snapshot.data!;
//             return Container(
//               child: Padding(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: screenwdt * 0.03,
//                 ),
// child: GridView.builder(
//   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//     crossAxisCount: 5,
//     childAspectRatio: 0.8,
//   ),
//                   itemCount: networks.length,
//                   itemBuilder: (context, index) {
//                     return FocusableItemWidget(
//                       imageUrl: networks[index].logo,
//                       name: networks[index].name,
//                       onTap: () async {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) =>
//                                 ContentScreen(networkId: networks[index].id),
//                           ),
//                         );
//                       },
//                       fetchPaletteColor: fetchPaletteColor,
//                     );
//                   },
//                 ),
//               ),
//             );
//           }
//         },
//       ),
//     );
//   }
// }

// class ContentScreen extends StatefulWidget {
//   final int networkId;

//   ContentScreen({required this.networkId});

//   @override
//   _ContentScreenState createState() => _ContentScreenState();
// }

// class _ContentScreenState extends State<ContentScreen> {
//   late Future<List<ContentApi>> _contentFuture;
//   final SocketService _socketService = SocketService();

//   @override
//   void initState() {
//     super.initState();
//     _contentFuture = fetchContent(context, widget.networkId);
//     _contentFuture.then((content) {
//       List<String> videoUrls = content.map((c) => c.banner).toList();
//       _socketService.prefetchYouTubeUrls(videoUrls);
//     });
//     _contentFuture = fetchContent(context, widget.networkId);
//     _contentFuture.then((content) {
//       for (var item in content) {
//         // Cache banner image URL
//         cacheUrlsIfNeeded(context, item.id, item.banner);

//         // Prefetch video URLs (if available) and cache them
//         _socketService.prefetchYouTubeUrls([item.banner]);
//       }
//     });
//   }

//   Future<void> cacheUrlsIfNeeded(
//       BuildContext context, int contentId, String imageUrl) async {
//     final prefs = await SharedPreferences.getInstance();

//     // Check if the image URL is already cached
//     String? cachedImageUrl = prefs.getString('image_url_$contentId');

//     // If the URL is not cached or has changed, update the cache and preload the image
//     if (cachedImageUrl == null || cachedImageUrl != imageUrl) {
//       await prefs.setString('image_url_$contentId', imageUrl);
//       await precacheImage(CachedNetworkImageProvider(imageUrl), context);
//       print("Image cached and preloaded: $imageUrl");
//     }
//   }

//   Future<List<ContentApi>> fetchContent(
//       BuildContext context, int networkId) async {
//     final prefs = await SharedPreferences.getInstance();
//     final cachedContent = prefs.getString('content_$networkId');

//     if (cachedContent != null) {
//       List<dynamic> body = json.decode(cachedContent);
//       return body.map((dynamic item) => ContentApi.fromJson(item)).toList();
//     }

//     // If not cached, fetch from API
//     final response = await https.get(
//       Uri.parse(
//           'https://api.ekomflix.com/android/getAllContentsOfNetwork/$networkId'),
//       headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//     );

//     if (response.statusCode == 200) {
//       List<dynamic> body = json.decode(response.body);
//       prefs.setString('content_$networkId', response.body); // Cache the content
//       return body.map((dynamic item) => ContentApi.fromJson(item)).toList();
//     } else {
//       throw Exception('Failed to load content');
//     }
//   }

//   Future<void> _updateUIIfChanged(int networkId) async {
//     final prefs = await SharedPreferences.getInstance();

//     // Fetch new content from API
//     final newContent = await fetchContent(context, networkId);
//     final newContentJson = json.encode(newContent);

//     // Compare with cached content
//     String? cachedContent = prefs.getString('content_$networkId');
//     if (cachedContent == null || cachedContent != newContentJson) {
//       // Cache the new data and update the UI
//       prefs.setString('content_$networkId', newContentJson);
//       setState(() {
//         _contentFuture = Future.value(newContent);
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: cardColor,
//       body: FutureBuilder<List<ContentApi>>(
//         future: _contentFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(
//               child: LoadingIndicator(),
//             );
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return Center(child: Text('No Content Available'));
//           } else {
//             final content = snapshot.data!;
//             return Padding(
//               padding: EdgeInsets.symmetric(
//                   horizontal: screenwdt * 0.03, vertical: screenhgt * 0.01),
//               child: GridView.builder(
//                 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 5,
//                     // crossAxisSpacing: 10,
//                     // mainAxisSpacing: 10,
//                     childAspectRatio: 0.8),
//                 itemCount: content.length,
//                 itemBuilder: (context, index) {
//                   return FocusableItemWidget(
//                     imageUrl: content[index].banner,
//                     name: content[index].name,
//                     onTap: () async {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) =>
//                               DetailsPage(content: content[index]),
//                         ),
//                       );
//                     },
//                     fetchPaletteColor: fetchPaletteColor,
//                   );
//                 },
//               ),
//             );
//           }
//         },
//       ),
//     );
//   }
// }

// class DetailsPage extends StatefulWidget {
//   final ContentApi content;

//   DetailsPage({required this.content});

//   @override
//   _DetailsPageState createState() => _DetailsPageState();
// }

// class _DetailsPageState extends State<DetailsPage> {
//   final SocketService _socketService = SocketService();
//   final int _maxRetries = 3;
//   final int _retryDelay = 5; // seconds
//   bool _shouldContinueLoading = true;
//   bool _isLoading = false;
//   MovieDetailsApi? _movieDetails;
//   bool _isVideoPlaying = false;

//   @override
//   void initState() {
//     super.initState();
//     _socketService.initSocket();
//     checkServerStatus();
//     _loadMovieDetails();
//   }

//   @override
//   void dispose() {
//     _socketService.dispose();
//     super.dispose();
//   }

//   // Future<void> _loadMovieDetails() async {
//   //   try {
//   //     final details = await fetchMovieDetails(context, widget.content.id);
//   //     setState(() {
//   //       _movieDetails = details;
//   //     });
//   //   } catch (e) {
//   //     print('Something Went Wrong');
//   //     // Handle error (e.g., show a snackbar)
//   //   }
//   // }

//   Future<void> _updateUIIfChanged() async {
//     final prefs = await SharedPreferences.getInstance();

//     // Fetch new data from API
//     final newMovieDetails = await fetchMovieDetails(context, widget.content.id);
//     final newDetailsJson = json.encode(newMovieDetails);

//     // Compare with cached data
//     String? cachedDetails =
//         prefs.getString('movie_details_${widget.content.id}');
//     if (cachedDetails == null || cachedDetails != newDetailsJson) {
//       // Cache the new data and update UI
//       prefs.setString('movie_details_${widget.content.id}', newDetailsJson);
//       setState(() {
//         _movieDetails = newMovieDetails;
//       });
//     }
//   }

//   Future<void> cacheVideoUrlsIfNeeded(int contentId, String videoUrl) async {
//     final prefs = await SharedPreferences.getInstance();

//     // Check if the video URL is already cached
//     String? cachedVideoUrl = prefs.getString('video_url_$contentId');

//     // If the URL is not cached or has changed, update the cache
//     if (cachedVideoUrl == null || cachedVideoUrl != videoUrl) {
//       await prefs.setString('video_url_$contentId', videoUrl);
//       print("Video URL cached: $videoUrl");
//     }
//   }

//   Future<void> _loadMovieDetails() async {
//     final prefs = await SharedPreferences.getInstance();
//     String? cachedDetails =
//         prefs.getString('movie_details_${widget.content.id}');

//     if (cachedDetails != null) {
//       setState(() {
//         _movieDetails = MovieDetailsApi.fromJson(json.decode(cachedDetails));
//       });
//     } else {
//       // If no cache, fetch from API
//       final details = await fetchMovieDetails(context, widget.content.id);
//       setState(() {
//         _movieDetails = details;
//       });
//       prefs.setString(
//           'movie_details_${widget.content.id}', json.encode(details));
//     }
//   }

//   // Add this method to check the server status and reconnect if needed
//   void checkServerStatus() {
//     Timer.periodic(Duration(seconds: 10), (timer) {
//       if (!_socketService.socket.connected) {
//         print('YouTube server down, retrying...');
//         _socketService.initSocket(); // Re-establish the socket connection
//       }
//     });
//   }

//   Future<void> _updateUrlIfNeeded(Map<String, String> playLink) async {
//     if (playLink['type'] == 'Youtube' || playLink['type'] == 'YoutubeLive') {
//       for (int i = 0; i < _maxRetries; i++) {
//         if (!_shouldContinueLoading) break;
//         try {
//           String updatedUrl =
//               await _socketService.getUpdatedUrl(playLink['url']!);
//           playLink['url'] = updatedUrl;
//           playLink['type'] = 'M3u8';
//           break;
//         } catch (e) {
//           if (i == _maxRetries - 1) rethrow;
//           await Future.delayed(Duration(seconds: _retryDelay));
//         }
//       }
//     }
//   }

//   Future<bool> _onWillPop() async {
//     if (_isLoading) {
//       setState(() {
//         _isLoading = false;
//         _shouldContinueLoading = false;
//       });
//       return false;
//     }
//     return true;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: _onWillPop,
//       child: Scaffold(
//         backgroundColor: cardColor,
//         body: Stack(
//           children: [
//             _movieDetails == null
//                 ? Center(child: LoadingIndicator())
//                 : Padding(
//                     padding: EdgeInsets.symmetric(horizontal: screenwdt * 0.03),
//                     child: _buildMovieDetailsUI(context, _movieDetails!),
//                   ),
//             if (_isLoading) Center(child: LoadingIndicator()),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMovieDetailsUI(
//       BuildContext context, MovieDetailsApi movieDetails) {
//     return Container(
//       padding: const EdgeInsets.all(20.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           if (movieDetails.status == '1')
//             // CachedNetworkImage(
//             //   imageUrl: movieDetails.banner,
//             //   placeholder: (context, url) => localImage,
//             //   fit: BoxFit.cover,
//             //   width: screenwdt * 0.7,
//             //   height: screenhgt * 0.55,
//             // ),
//             displayImage(
//               movieDetails.banner,
//               width: screenwdt * 0.7, // Custom width
//               height: screenhgt * 0.55, // Custom height
//             ),
//           Text(movieDetails.name,
//               style: TextStyle(color: Colors.white, fontSize: nametextsz)),
//           SizedBox(height: 10),
//           Expanded(
//             child: ListView.builder(
//               scrollDirection: Axis.horizontal,
//               itemCount: 1,
//               itemBuilder: (context, index) {
//                 return FocusableItemWidget(
//                   imageUrl: widget.content
//                       .banner, // Replace with actual image URL if available
//                   name: '',
//                   onTap: () => _playVideo(movieDetails),
//                   fetchPaletteColor: fetchPaletteColor,
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Future<void> _playVideo(MovieDetailsApi movieDetails) async {
//   //   setState(() {
//   //     _isLoading = true;
//   //   });
//   //   _shouldContinueLoading = true;

//   //   try {
//   //     final playLink = await fetchMoviePlayLink(widget.content.id);
//   //     await _updateUrlIfNeeded(playLink);

//   //     if (_shouldContinueLoading) {
//   //       if (playLink['type'] == 'VLC' || playLink['type'] == 'VLC') {
//   //         //   // Navigate to VLC Player screen when stream type is VLC
//   //         await Navigator.push(
//   //           context,
//   //           MaterialPageRoute(
//   //             builder: (context) => VlcPlayerScreen(
//   //               videoUrl: playLink['url']!,
//   //               // videoTitle: movieDetails.name,
//   //               channelList: [],
//   //               genres: movieDetails.genres,
//   //               // channels: [],
//   //               // initialIndex: 1,
//   //               bannerImageUrl: movieDetails.banner,
//   //               startAtPosition: Duration.zero,
//   //               // onFabFocusChanged: (bool) {},
//   //               isLive: false,
//   //             ),
//   //           ),
//   //         );
//   //       } else {
//   //         await Navigator.push(
//   //           context,
//   //           MaterialPageRoute(
//   //             builder: (context) => VideoMovieScreen(
//   //               videoUrl: playLink['url']!,
//   //               videoTitle: movieDetails.name,
//   //               channelList: [],
//   //               videoBanner: movieDetails.banner,
//   //               onFabFocusChanged: (bool focused) {},
//   //               genres: movieDetails.genres,
//   //               videoType: playLink['type']!,
//   //               url: playLink['url']!,
//   //               type: playLink['type']!,
//   //             ),
//   //           ),
//   //         );
//   //       }
//   //     }
//   //   } catch (e) {
//   //     _handleVideoError(context,e);
//   //   } finally {
//   //     setState(() {
//   //       _isLoading = false;
//   //     });
//   //   }
//   // }

//   // void _handleVideoError(BuildContext context) {
//   //   ScaffoldMessenger.of(context).showSnackBar(
//   //     SnackBar(
//   //         content:
//   //             Text('Something Went Wrong', style: TextStyle(fontSize: 20))),
//   //   );
//   // }

//   //  Future<void> _playVideo(MovieDetailsApi movieDetails) async {
//   //   setState(() {
//   //     _isLoading = true;
//   //   });
//   //   _shouldContinueLoading = true;

//   //   try {
//   //     final playLink = await fetchMoviePlayLink(widget.content.id);
//   //     int retryCount = 0;
//   //     while (retryCount < 3) {
//   //       try {
//   //         await _updateUrlIfNeeded(playLink);
//   //         break;
//   //       } catch (e) {
//   //         retryCount++;
//   //         if (retryCount == 3) rethrow;
//   //         await Future.delayed(Duration(seconds: 1));
//   //       }
//   //     }

//   //     if (_shouldContinueLoading) {
//   //       if (playLink['type'] == 'VLC') {
//   //         await Navigator.push(
//   //           context,
//   //           MaterialPageRoute(
//   //             builder: (context) => VlcPlayerScreen(
//   //               videoUrl: playLink['url']!,
//   //               channelList: [],
//   //               genres: movieDetails.genres,
//   //               bannerImageUrl: movieDetails.banner,
//   //               startAtPosition: Duration.zero,
//   //               isLive: false,
//   //             ),
//   //           ),
//   //         );
//   //       } else {
//   //         await Navigator.push(
//   //           context,
//   //           MaterialPageRoute(
//   //             builder: (context) => VideoMovieScreen(
//   //               videoUrl: playLink['url']!,
//   //               videoTitle: movieDetails.name,
//   //               channelList: [],
//   //               videoBanner: movieDetails.banner,
//   //               onFabFocusChanged: (bool focused) {},
//   //               genres: movieDetails.genres,
//   //               videoType: playLink['type']!,
//   //               url: playLink['url']!,
//   //               type: playLink['type']!,
//   //             ),
//   //           ),
//   //         );
//   //       }
//   //     }
//   //   } catch (e) {
//   //     _handleVideoError(context, e);
//   //   } finally {
//   //     setState(() {
//   //       _isLoading = false;
//   //     });
//   //   }
//   // }

//   void _handleVideoError(BuildContext context, dynamic error) {
//     String errorMessage = 'Something Went Wrong';
//     if (error is TimeoutException) {
//       errorMessage = 'Connection timed out. Please try again.';
//     }
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(errorMessage, style: TextStyle(fontSize: 20))),
//     );
//   }

//   Future<void> _playVideo(MovieDetailsApi movieDetails) async {
//     if (_isVideoPlaying) {
//       return; // Agar ek video already play ho raha hai to naya video mat play karo
//     }

//     setState(() {
//       _isLoading = true;
//       _isVideoPlaying = true;
//     });
//     _shouldContinueLoading = true;

//     try {
//       final playLink = await fetchMoviePlayLink(widget.content.id);
//       int retryCount = 0;
//       while (retryCount < 3) {
//         try {
//           await _updateUrlIfNeeded(playLink);
//           break;
//         } catch (e) {
//           retryCount++;
//           if (retryCount == 3) rethrow;
//           await Future.delayed(Duration(seconds: 1)); // Reduced delay
//         }
//       }

//       if (_shouldContinueLoading) {
//         if (playLink['type'] == 'VLC') {
//           await Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => VlcPlayerScreen(
//                 videoUrl: playLink['url']!,
//                 channelList: [],
//                 genres: movieDetails.genres,
//                 bannerImageUrl: movieDetails.banner,
//                 startAtPosition: Duration.zero,
//                 isLive: false,
//               ),
//             ),
//           );
//         } else {
//           await Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => VideoMovieScreen(
//                 videoUrl: playLink['url']!,
//                 videoTitle: movieDetails.name,
//                 channelList: [],
//                 videoBanner: movieDetails.banner,
//                 onFabFocusChanged: (bool focused) {},
//                 genres: movieDetails.genres,
//                 videoType: playLink['type']!,
//                 url: playLink['url']!,
//                 type: playLink['type']!,
//               ),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       _handleVideoError(context, e);
//     } finally {
//       setState(() {
//         _isLoading = false;
//         _isVideoPlaying = false;
//       });
//     }
//   }
// }






import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:mobi_tv_entertainment/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import '../../video_widget/socket_service.dart';
import '../../video_widget/video_movie_screen.dart';
import '../../video_widget/video_screen.dart';
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

class ContentApi {
  final int id;
  final String name;
  final String banner;
  final String url;

  ContentApi({required this.id, required this.name, required this.banner, required this.url});

  factory ContentApi.fromJson(Map<String, dynamic> json) {
    return ContentApi(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      name: json['name'] ?? 'No Name',
      banner: json['banner'] ?? localImage,
      url: json['url'] ?? '',
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

Future<List<ContentApi>> fetchContent(
    BuildContext context, int networkId) async {
  final prefs = await SharedPreferences.getInstance();
  final cachedContent = prefs.getString('content_$networkId');

  // Step 1: Use cached data for fast UI rendering
  List<ContentApi> content = [];
  if (cachedContent != null) {
    List<dynamic> cachedBody = json.decode(cachedContent);
    content =
        cachedBody.map((dynamic item) => ContentApi.fromJson(item)).toList();
  }

  // Step 2: Fetch API data in the background
  List<ContentApi> apiContent;
  final response = await https.get(
    Uri.parse(
        'https://api.ekomflix.com/android/getAllContentsOfNetwork/$networkId'),
    headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
  );

  if (response.statusCode == 200) {
    List<dynamic> body = json.decode(response.body);
    apiContent = body.map((dynamic item) => ContentApi.fromJson(item)).toList();
    

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

// Future<Map<String, String>> fetchMoviePlayLink(int movieId) async {
//   final response = await https.get(
//     Uri.parse('https://api.ekomflix.com/android/getMoviePlayLinks/$movieId/0'),
//     headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//   );

//   if (response.statusCode == 200) {
//     final List<dynamic> body = json.decode(response.body);
//     if (body.isNotEmpty) {
//       final Map<String, dynamic> firstItem = body.first as Map<String, dynamic>;
//       return {'url': firstItem['url'] ?? '', 'type': firstItem['type'] ?? ''};
//     }
//     return {'url': '', 'type': ''};
//   } else {
//     throw Exception('Failed to load movie play link');
//   }
// }



// Future<Map<String, String>> fetchMoviePlayLink(int movieId) async {
//   final prefs = await SharedPreferences.getInstance();
//   final cachedPlayLink = prefs.getString('movie_playlink_$movieId');

//   // Step 1: Return cached play link immediately if available
//   if (cachedPlayLink != null) {
//     final Map<String, dynamic> cachedData = json.decode(cachedPlayLink);
//     return {'url': cachedData['url'] ?? '', 'type': cachedData['type'] ?? ''};
//   }

//   // Step 2: Fetch the play link from the API if no cache is available
//   final response = await https.get(
//     Uri.parse('https://api.ekomflix.com/android/getMoviePlayLinks/$movieId/0'),
//     headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//   );

//   if (response.statusCode == 200) {
//     final List<dynamic> body = json.decode(response.body);
//     if (body.isNotEmpty) {
//       final Map<String, dynamic> firstItem = body.first as Map<String, dynamic>;

//       // Cache the fetched play link
//       prefs.setString('movie_playlink_$movieId', json.encode(firstItem));

//       // Return the fetched data
//       return {'url': firstItem['url'] ?? '', 'type': firstItem['type'] ?? ''};
//     }
//     return {'url': '', 'type': ''};
//   } else {
//     throw Exception('Failed to load movie play link');
//   }
// }


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

class SubVod extends StatefulWidget {
  @override
  _SubVodState createState() => _SubVodState();
}

class _SubVodState extends State<SubVod> {
  List<NetworkApi> _networks = [];
  bool _isLoading = true;
  bool _cacheLoaded = false; // To track if cache has been loaded

  @override
  void initState() {
    super.initState();
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
    return Scaffold(
      backgroundColor: cardColor,
      body: _isLoading
          ? Center(
              child: LoadingIndicator()) // Show loading only if no cached data
          : _buildNetworksList(),
    );
  }

  Widget _buildNetworksList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Align heading to the left
      children: [
        Padding(
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
        ),
        Expanded(
          child: _networks.isEmpty
              ? Center(child: Text('No Networks Available'))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _networks.length,
                  itemBuilder: (context, index) {
                    return FocusableItemWidget(
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
                ),
        ),
      ],
    );
  }
}

class VOD extends StatefulWidget {
  @override
  _VODState createState() => _VODState();
}

class _VODState extends State<VOD> {
  List<NetworkApi> _networks = [];
  bool _isLoading = true;
  bool _cacheLoaded = false; // To track if cache has been loaded

  @override
  void initState() {
    super.initState();
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
    return Scaffold(
      backgroundColor: cardColor,
      body: _isLoading
          ? Center(child: LoadingIndicator())
          : _networks != null
              ? _buildNetworksList()
              : Center(child: Text('...')),
    );
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
          return FocusableItemWidget(
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
  List<ContentApi> _content = [];
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
            .map((dynamic item) => ContentApi.fromJson(item))
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
    return Scaffold(
      backgroundColor: cardColor,
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
                    builder: (context) => DetailsPage(content: _content[index],channelList: _content,),
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
  final ContentApi content;
  final List<ContentApi> channelList;

  DetailsPage({required this.content, required this.channelList, });

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

  @override
  void initState() {
    super.initState();
    _socketService.initSocket();
    checkServerStatus();

    Future.delayed(Duration(milliseconds: 100), () async {
      _loadCachedAndFetchMovieDetails();
      firstItemFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _socketService.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadCachedAndFetchMovieDetails() async {
    FocusScope.of(context).unfocus();
    try {
      final cachedDetails = await fetchMovieDetails(context, widget.content.id);
      // await Future.delayed(Duration(milliseconds: 10));

      setState(() {
        _movieDetails = cachedDetails;
        _isLoading =
            false; // Stop showing the spinner since we have data to show
      });

      // Step 2: Fetch new data in the background and update UI if needed
      final apiDetails = await fetchMovieDetails(context, widget.content.id);
      if (_movieDetails != apiDetails) {
        setState(() {
          _movieDetails = apiDetails;
        });
      }
    } catch (e) {
      print('Error loading movie details: $e');
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
      backgroundColor: cardColor,
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
                  child: Text(movieDetails.name,
                      style: TextStyle(
                          color: Colors.white, fontSize: Headingtextsz * 1.5)),
                ),
                Spacer(),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 1,
                    itemBuilder: (context, index) {
                      return FocusableItemWidget(
                        focusNode: firstItemFocusNode,
                        imageUrl: widget.content.banner,
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
      final playLink = await fetchMoviePlayLink(widget.content.id);
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

        if (_shouldContinueLoading) {
          // if (playLink['type'] == 'VLC') {
          //   await Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //       builder: (context) => VlcPlayerScreen(
          //         videoUrl: playLink['url']!,
          //         channelList: [],
          //         genres: movieDetails.genres,
          //         bannerImageUrl: movieDetails.banner,
          //         startAtPosition: Duration.zero,
          //         isLive: false,
          //       ),
          //     ),
          //   );
          // } else {

            await Navigator.push(
              
              context,
              MaterialPageRoute(
                // builder: (context) => VideoMovieScreen(
                //   videoUrl: playLink['url']!,
                //   videoTitle: movieDetails.name,
                //   channelList: [],
                //   videoBanner: movieDetails.banner,
                //   onFabFocusChanged: (bool focused) {},
                //   genres: movieDetails.genres,
                //   videoType: playLink['type']!,
                //   url: playLink['url']!,
                //   // type: playLink['type']!,
                // ),
                builder: (context) => VideoScreen(
                  videoUrl: playLink['url']!,
                  // videoTitle: movieDetails.name,
                  channelList: widget.channelList,
                  // videoBanner: movieDetails.banner,
                  // onFabFocusChanged: (bool focused) {},
                  // genres: movieDetails.genres,
                  videoType: playLink['type']!,
                  bannerImageUrl: playLink['banner'] ?? '',
                  startAtPosition: Duration.zero,
                  isLive: false, isVOD: true,

                  // url: playLink['url']!,
                  // type: playLink['type']!,
                ),
              ),
            );
          // }
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
