// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:mobi_tv_entertainment/main.dart';
// import 'package:mobi_tv_entertainment/video_widget/video_screen.dart';
// import 'package:mobi_tv_entertainment/widgets/models/news_item_model.dart';
// import 'package:mobi_tv_entertainment/widgets/models/season_model.dart';
// import 'package:mobi_tv_entertainment/widgets/models/episode_model.dart';

// import '../../video_widget/socket_service.dart';

// import 'dart:convert';
// import 'package:http/http.dart' as http;

// Future<List<NewsItemModel>> fetchEpisodesFromApi(String seasonId) async {
//   try {
//     final response = await http.get(
//       Uri.parse('https://mobifreetv.com/android/getEpisodes/$seasonId/0'),
//       headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//     ).timeout(Duration(seconds: 15));

//     if (response.statusCode == 200 && response.body.isNotEmpty) {
//       final List<dynamic> data = jsonDecode(response.body);
//       return data.map((e) => NewsItemModel.fromJson(e)).toList();
//     } else {
//       return [];
//     }
//   } catch (e) {
//     print("Error fetching episodes: $e");
//     return [];
//   }
// }


// class WebSeriesDetailsPage extends StatefulWidget {
//   final int id;
//   final List<NewsItemModel> channelList;
//   final String source;
//   final String banner;
//   final String name;

//   WebSeriesDetailsPage({
//     required this.id,
//     required this.channelList,
//     required this.source,
//     required this.banner,
//     required this.name,
//   });

//   @override
//   _WebSeriesDetailsPageState createState() => _WebSeriesDetailsPageState();
// }

// class _WebSeriesDetailsPageState extends State<WebSeriesDetailsPage>
//     with WidgetsBindingObserver {
//   final SocketService _socketService = SocketService();
  
//   bool isLoading = true;
//   List<NewsItemModel> seasons = [];
//   Map<String, List<NewsItemModel>> episodesMap = {};
//   int selectedSeasonIndex = 0;
//   int selectedEpisodeIndex = 0; // Track the currently selected episode
//   Map<String, FocusNode> seasonFocusNodes = {};
//   Map<String, FocusNode> episodeFocusNodes = {};
//   final FocusNode _mainFocusNode = FocusNode(); // Main focus node for the page
//   String errorMessage = "";
//   bool _isInitialFocusSet = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _fetchSeasons();

//     // Request focus when the page loads
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       FocusScope.of(context).requestFocus(_mainFocusNode);
//     });
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();

//     // Set initial focus again in case it was lost
//     if (!_isInitialFocusSet) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         FocusScope.of(context).requestFocus(_mainFocusNode);
//         _isInitialFocusSet = true;
//       });
//     }
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       // When app is resumed, make sure focus is set correctly
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         FocusScope.of(context).requestFocus(_mainFocusNode);

//         final currentSeasonId =
//             seasons.isNotEmpty ? seasons[selectedSeasonIndex].id : "";
//         final episodes = episodesMap[currentSeasonId] ?? [];

//         if (episodes.isNotEmpty && selectedEpisodeIndex < episodes.length) {
//           FocusScope.of(context).requestFocus(
//               episodeFocusNodes[episodes[selectedEpisodeIndex].id]);
//         }
//       });
//     }
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     // Dispose focus nodes
//     _mainFocusNode.dispose();
//     for (var node in seasonFocusNodes.values) {
//       node.dispose();
//     }
//     for (var node in episodeFocusNodes.values) {
//       node.dispose();
//     }
//         try {
//       _socketService.dispose();
//     } catch (e) {
//       print("Error disposing socket service: $e");
//     }
//     super.dispose();
//   }

//   Future<void> _fetchSeasons() async {
//     setState(() {
//       isLoading = true;
//       errorMessage = "Loading seasons...";
//     });

//     try {
//       final response = await http.get(
//         Uri.parse('https://mobifreetv.com/android/getSeasons/${widget.id}'),
//         headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//       ).timeout(Duration(seconds: 15));

//       print("Seasons API response status code: ${response.statusCode}");

//       if (response.statusCode == 200) {
//         final responseBody = response.body;

//         if (responseBody.isEmpty) {
//           setState(() {
//             isLoading = false;
//             errorMessage = "No seasons found";
//           });
//           return;
//         }

//         try {
//           final List<dynamic> data = jsonDecode(responseBody) as List<dynamic>;
//           print("Parsed seasons data. Count: ${data.length}");

//           List<NewsItemModel> seasonsList =
//               data.map((season) => NewsItemModel.fromJson(season)).toList();

//           // Initialize focus nodes for each season
//           for (var season in seasonsList) {
//             seasonFocusNodes[season.id] = FocusNode();
//           }

//           setState(() {
//             seasons = seasonsList;
//             isLoading = false;
//             errorMessage = "";
//           });

//           // Fetch episodes for the first season if available
//           if (seasons.isNotEmpty) {
//             _fetchEpisodes(seasons[0].id);
//           }
//         } catch (parseError) {
//           print("JSON parse error: $parseError");
//           setState(() {
//             isLoading = false;
//             errorMessage = "Error parsing seasons data: $parseError";
//           });
//         }
//       } else {
//         setState(() {
//           isLoading = false;
//           errorMessage = "API error: ${response.statusCode}";
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//               content: Text('Something Went Wrong while fetching seasons')),
//         );
//       }
//     } catch (e) {
//       print("Error fetching seasons data: $e");
//       setState(() {
//         isLoading = false;
//         errorMessage = "Error: $e";
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: ${e.toString()}')),
//       );
//     }
//   }




//   Future<void> _fetchEpisodes(String seasonId) async {
//     // Check if we already have episodes for this season
//     if (episodesMap.containsKey(seasonId)) {
//       setState(() {
//         selectedSeasonIndex =
//             seasons.indexWhere((season) => season.id == seasonId);
//         selectedEpisodeIndex = 0; // Reset to first episode when changing season
//       });

//       // Set focus to the first episode
//       _setFocusToFirstEpisode();
//       return;
//     }

//     setState(() {
//       isLoading = true;
//       errorMessage = "Loading episodes...";
//     });

//     try {
//       final response = await http.get(
//         Uri.parse('https://mobifreetv.com/android/getEpisodes/$seasonId/0'),
//         headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//       ).timeout(Duration(seconds: 15));

//       print("Episodes API response status code: ${response.statusCode}");

//       if (response.statusCode == 200) {
//         final responseBody = response.body;

//         if (responseBody.isEmpty) {
//           setState(() {
//             isLoading = false;
//             errorMessage = "No episodes found";
//             episodesMap[seasonId] = [];
//           });
//           return;
//         }

//         try {
//           final List<dynamic> data = jsonDecode(responseBody) as List<dynamic>;
//           print("Parsed episodes data. Count: ${data.length}");

//           List<NewsItemModel> episodesList =
//               data.map((episode) => NewsItemModel.fromJson(episode)).toList();

//           // Initialize focus nodes for each episode
//           for (var episode in episodesList) {
//             episodeFocusNodes[episode.id] = FocusNode();
//           }

//           setState(() {
//             episodesMap[seasonId] = episodesList;
//             selectedSeasonIndex =
//             seasons.indexWhere((season) => season.id == seasonId);
//             selectedEpisodeIndex = 0; // Set first episode as selected
//             isLoading = false;
//             errorMessage = "";
//           });

//           // Now that episodes are loaded, set focus to first episode
//           _setFocusToFirstEpisode();
//         } catch (parseError) {
//           print("JSON parse error: $parseError");
//           setState(() {
//             isLoading = false;
//             errorMessage = "Error parsing episodes data: $parseError";
//           });
//         }
//       } else {
//         setState(() {
//           isLoading = false;
//           errorMessage = "API error: ${response.statusCode}";
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//               content: Text('Something Went Wrong while fetching episodes')),
//         );
//       }
//     } catch (e) {
//       print("Error fetching episodes data: $e");
//       setState(() {
//         isLoading = false;
//         errorMessage = "Error: $e";
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: ${e.toString()}')),
//       );
//     }
//   }

//   // Helper method to set focus to first episode
//   void _setFocusToFirstEpisode() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final currentSeasonId = seasons[selectedSeasonIndex].id;
//       final episodes = episodesMap[currentSeasonId] ?? [];

//       if (episodes.isNotEmpty) {
//         // Make sure the main focus node has focus first
//         FocusScope.of(context).requestFocus(_mainFocusNode);

//         // Then focus the first episode with a slight delay
//         Future.delayed(Duration(milliseconds: 100), () {
//           if (mounted) {
//             print("Setting focus to first episode");
//             setState(() {
//               selectedEpisodeIndex = 0;
//             });
//             FocusScope.of(context)
//                 .requestFocus(episodeFocusNodes[episodes[0].id]);
//           }
//         });
//       }
//     });
//   }


//     bool isYoutubeUrl(String? url) {
//     if (url == null || url.isEmpty) {
//       return false;
//     }

//     url = url.toLowerCase().trim();

//     // First check if it's a YouTube ID (exactly 11 characters)
//     bool isYoutubeId = RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url);
//     if (isYoutubeId) {
//       print("Matched YouTube ID pattern: $url");
//       return true;
//     }

//     // Then check for regular YouTube URLs
//     bool isYoutubeUrl = url.contains('youtube.com') ||
//         url.contains('youtu.be') ||
//         url.contains('youtube.com/shorts/');
//     if (isYoutubeUrl) {
//       print("Matched YouTube URL pattern: $url");
//       return true;
//     }

//     print("Not a YouTube URL/ID: $url");
//     return false;
//   }

//   void _playEpisode(NewsItemModel episode) async{
//     // Get the current list of episodes to pass to VideoScreen
//     final currentSeasonId = seasons[selectedSeasonIndex].id;
//     final episodes = episodesMap[currentSeasonId] ?? [];
    
//     // Find the current episode index in the list
//     final currentEpisodeIndex = episodes.indexWhere((e) => e.id == episode.id);

//        String updatedUrl = episode.url;

//         // Check if it's a YouTube URL
//         if (isYoutubeUrl(updatedUrl)) {
//           print("Processing YouTube URL from last played videos");
//           updatedUrl = await _socketService.getUpdatedUrl(updatedUrl);
//         }
    
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => VideoScreen(
//           videoUrl: updatedUrl,
//           unUpdatedUrl: episode.url,
//           channelList: episodes,
//           bannerImageUrl: widget.banner,
//           startAtPosition: Duration.zero,
//           videoType: widget.source,
//           isLive: false,
//           isVOD: false,
//           isSearch: false,
//           isBannerSlider: false,
//           videoId: int.tryParse(episode.id),
//           source: 'webseries_details_page',
//           name: episode.name,
//           liveStatus: false,
//         ),
//       ),
//     );
//   }

//   // Improved keyboard navigation
//   void _handleKeyEvent(RawKeyEvent event, List<NewsItemModel> episodes) {
//     if (event is RawKeyDownEvent) {
//       if (episodes.isEmpty) return;

//       // Print debug information
//       // print(
//       //     "Key event: ${event.logicalKey.keyLabel}, Current Episode: $selectedEpisodeIndex");

//       if (event.logicalKey == LogicalKeyboardKey.arrowDown || false) {
//         // Replace with 'false' or remove this condition if unnecessary
//         // print("Moving focus DOWN");
//         if (selectedEpisodeIndex < episodes.length - 1) {
//           setState(() {
//             selectedEpisodeIndex++;
//           });
//           // Delay focus request to ensure the UI has updated
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             FocusScope.of(context).requestFocus(
//                 episodeFocusNodes[episodes[selectedEpisodeIndex].id]);
//             print("Focus moved to episode: $selectedEpisodeIndex");
//           });
//         }
//       } else if (event.logicalKey == LogicalKeyboardKey.arrowUp || false) {
//         // Replace with 'false' or remove this condition if unnecessary
//         // print("Moving focus UP");
//         if (selectedEpisodeIndex > 0) {
//           setState(() {
//             selectedEpisodeIndex--;
//           });
//           // Delay focus request to ensure the UI has updated
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             FocusScope.of(context).requestFocus(
//                 episodeFocusNodes[episodes[selectedEpisodeIndex].id]);
//             // print("Focus moved to episode: $selectedEpisodeIndex");
//           });
//         }
//       } else if (event.logicalKey == LogicalKeyboardKey.select ||
//           event.logicalKey == LogicalKeyboardKey.enter ||
//           event.logicalKey == LogicalKeyboardKey.gameButtonA ||
//           event.logicalKey == LogicalKeyboardKey.gameButtonStart) {
//         // print("Playing episode: $selectedEpisodeIndex");
//         _playEpisode(episodes[selectedEpisodeIndex]);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentSeasonId =
//         seasons.isNotEmpty ? seasons[selectedSeasonIndex].id : "";
//     final episodes = episodesMap[currentSeasonId] ?? [];

//     // Make sure the main focus node has focus
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!_mainFocusNode.hasFocus) {
//         FocusScope.of(context).requestFocus(_mainFocusNode);
//       }
//     });

//     return Scaffold(
//       backgroundColor: Colors.black,
//       extendBodyBehindAppBar: true, // Allow content to extend behind AppBar
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             Text(''),
//             Text(widget.name),
//           ],
//         ),
//       ),
//       body: RawKeyboardListener(
//         focusNode: _mainFocusNode,
//         autofocus: true,
//         onKey: (event) => _handleKeyEvent(event, episodes),
//         child: Stack(
//           alignment: Alignment.center,
//           children: [
//             // Full screen background image
//             Image.network(
//               widget.banner,
//               fit: BoxFit.cover,
//               errorBuilder: (context, error, stackTrace) {
//                 return Container(color: Colors.black);
//               },
//             ),

//             // Dark gradient overlay
//             Positioned.fill(
//               child: Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: [
//                       Colors.black.withOpacity(0.5),
//                       Colors.black.withOpacity(0.7),
//                       Colors.black.withOpacity(0.9),
//                       Colors.black,
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//             // Main content - scrollable
//             isLoading && seasons.isEmpty
//                 ? _buildLoadingWidget()
//                 : _buildScrollableContent(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLoadingWidget() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           SpinKitFadingCircle(
//             color: Colors.white,
//             size: 50.0,
//           ),
//           SizedBox(height: 20),
//           Text(
//             errorMessage,
//             style: TextStyle(color: Colors.white),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildScrollableContent() {
//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           // Space for header - adjust based on your AppBar height
//           SizedBox(height: MediaQuery.of(context).size.height * 0.12),

//           SizedBox(height: 16),

//           // Episodes section
//           if (seasons.isNotEmpty) ...[
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Text(
//                 "EPISODES",
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: Headingtextsz * 1.5,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             SizedBox(height: 8),
//             isLoading &&
//                     !episodesMap.containsKey(seasons[selectedSeasonIndex].id)
//                 ? Container(
//                     height: 200,
//                     child: _buildLoadingWidget(),
//                   )
//                 : _buildEpisodesListView(),
//           ],

//           // Add some padding at the bottom
//           SizedBox(height: 24),
//         ],
//       ),
//     );
//   }

//   Widget _buildEpisodesListView() {
//     final currentSeasonId = seasons[selectedSeasonIndex].id;
//     final episodes = episodesMap[currentSeasonId] ?? [];

//     if (episodes.isEmpty) {
//       return Container(
//         height: 100,
//         child: Center(
//           child: Text(
//             "No episodes available for this season",
//             style: TextStyle(color: Colors.white),
//           ),
//         ),
//       );
//     }

//     // Ensure the selected episode is visible by scrolling to it
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (episodes.isNotEmpty && selectedEpisodeIndex < episodes.length) {
//         // This will ensure the selected episode is focused after the list is built
//         FocusScope.of(context)
//             .requestFocus(episodeFocusNodes[episodes[selectedEpisodeIndex].id]);
//       }
//     });

//     return ListView.builder(
//       key: PageStorageKey('episodes-list-${currentSeasonId}'),
//       padding: EdgeInsets.symmetric(horizontal: 16),
//       shrinkWrap: true,
//       physics: NeverScrollableScrollPhysics(),
//       itemCount: episodes.length,
//       itemBuilder: (context, index) {
//         final episode = episodes[index];
//         final bool isSelected = index == selectedEpisodeIndex;

//         return FocusTraversalOrder(
//             order: NumericFocusOrder(index.toDouble()),
//             child: Focus(
//               focusNode: episodeFocusNodes[episode.id],
//               onFocusChange: (hasFocus) {
//                 if (hasFocus && selectedEpisodeIndex != index) {
//                   print("Focus gained for episode $index");
//                   setState(() {
//                     selectedEpisodeIndex = index;
//                   });
//                 }
//               },
//               child: GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     selectedEpisodeIndex = index;
//                     FocusScope.of(context)
//                         .requestFocus(episodeFocusNodes[episode.id]);
//                   });
//                   _playEpisode(episode);
//                 },
//                 child: Container(
//                   margin: EdgeInsets.symmetric(
//                       vertical: screenhgt * 0.01, horizontal: screenwdt * 0.05),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[900]?.withOpacity(0.8),
//                     borderRadius: BorderRadius.circular(8),
//                     border: isSelected
//                         ? Border.all(color: highlightColor, width: 2)
//                         : null,
//                   ),
//                   child: Row(
//                     children: [
//                       Container(
//                         width: 120,
//                         height: 80,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.only(
//                             topLeft: Radius.circular(8),
//                             bottomLeft: Radius.circular(8),
//                           ),
//                         ),
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.only(
//                             topLeft: Radius.circular(8),
//                             bottomLeft: Radius.circular(8),
//                           ),
//                           child: Image.network(
//                             widget.banner,
//                             fit: BoxFit.cover,
//                             errorBuilder: (context, error, stackTrace) {
//                               return Container(
//                                 color: Colors.grey[800],
//                                 child: Center(
//                                   child: Text(
//                                     "EP ${episode.order}",
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 18,
//                                     ),
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                       ),
//                       Expanded(
//                         child: Padding(
//                           padding: const EdgeInsets.all(12.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 episode.name,
//                                 style: TextStyle(
//                                   color: isSelected
//                                       ? highlightColor
//                                       : Colors.white,
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                               if (episode.description.isNotEmpty) ...[
//                                 SizedBox(height: 4),
//                                 Text(
//                                   episode.description,
//                                   style: TextStyle(
//                                     color: Colors.grey[400],
//                                     fontSize: 12,
//                                   ),
//                                   maxLines: 2,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ],
//                             ],
//                           ),
//                         ),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.all(12.0),
//                         child: Icon(
//                           Icons.play_circle_outline,
//                           color: isSelected ? highlightColor : Colors.white,
//                           size: 32,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ));
//       },
//     );
//   }
// }



import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mobi_tv_entertainment/main.dart';
import 'package:mobi_tv_entertainment/video_widget/video_screen.dart';
import 'package:mobi_tv_entertainment/widgets/models/news_item_model.dart';
import '../../video_widget/socket_service.dart';

class WebSeriesDetailsPage extends StatefulWidget {
  final int id;
  final List<NewsItemModel> channelList;
  final String source;
  final String banner;
  final String name;

  const WebSeriesDetailsPage({
    Key? key,
    required this.id,
    required this.channelList,
    required this.source,
    required this.banner,
    required this.name,
  }) : super(key: key);

  @override
  _WebSeriesDetailsPageState createState() => _WebSeriesDetailsPageState();
}

class _WebSeriesDetailsPageState extends State<WebSeriesDetailsPage>
    with WidgetsBindingObserver {
  final SocketService _socketService = SocketService();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _mainFocusNode = FocusNode();
  
  bool _isLoading = true;
  List<NewsItemModel> _seasons = [];
  Map<String, List<NewsItemModel>> _episodesMap = {};
  int _selectedSeasonIndex = 0;
  int _selectedEpisodeIndex = 0;
  final Map<String, FocusNode> _episodeFocusNodes = {};
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePage();
  }

  void _initializePage() async {
    await _fetchSeasons();
    if (_seasons.isNotEmpty) {
      await _fetchEpisodes(_seasons.first.id);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_mainFocusNode);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _mainFocusNode.dispose();
    _episodeFocusNodes.values.forEach((node) => node.dispose());
    _socketService.dispose();
    super.dispose();
  }

  Future<void> _fetchSeasons() async {
    try {
      final response = await http.get(
        Uri.parse('https://mobifreetv.com/android/getSeasons/${widget.id}'),
        headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _seasons = data.map((season) => NewsItemModel.fromJson(season)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error loading seasons: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchEpisodes(String seasonId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      final response = await http.get(
        Uri.parse('https://mobifreetv.com/android/getEpisodes/$seasonId/0'),
        headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _episodeFocusNodes.clear();
        
        final episodes = data.map((e) => NewsItemModel.fromJson(e)).toList();
        for (var episode in episodes) {
          _episodeFocusNodes[episode.id] = FocusNode();
        }

        setState(() {
          _episodesMap[seasonId] = episodes;
          _selectedSeasonIndex = _seasons.indexWhere((s) => s.id == seasonId);
          _selectedEpisodeIndex = 0;
          _isLoading = false;
        });
        _setInitialFocus();
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error loading episodes: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  void _setInitialFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentEpisodes.isNotEmpty) {
        _scrollAndFocus(0);
      }
    });
  }

  Future<void> _scrollToIndex(int index) async {
    if (index < 0 || index >= _currentEpisodes.length) return;
    
    final context = _episodeFocusNodes[_currentEpisodes[index].id]?.context;
    if (context != null) {
      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.35,
      );
    }
  }

  void _scrollAndFocus(int index) async {
    await _scrollToIndex(index);
    if (mounted && index < _currentEpisodes.length) {
      FocusScope.of(context).requestFocus(
        _episodeFocusNodes[_currentEpisodes[index].id],
      );
    }
  }

  void _handleKeyEvent(RawKeyEvent event) {
    final episodes = _currentEpisodes;
    if (episodes.isEmpty) return;

    if (event is RawKeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowDown:
          if (_selectedEpisodeIndex < episodes.length - 1) {
            final newIndex = _selectedEpisodeIndex + 1;
            setState(() => _selectedEpisodeIndex = newIndex);
            _scrollAndFocus(newIndex);
          }
          break;

        case LogicalKeyboardKey.arrowUp:
          if (_selectedEpisodeIndex > 0) {
            final newIndex = _selectedEpisodeIndex - 1;
            setState(() => _selectedEpisodeIndex = newIndex);
            _scrollAndFocus(newIndex);
          }
          break;

        case LogicalKeyboardKey.enter:
          _playEpisode(episodes[_selectedEpisodeIndex]);
          break;

        default:
          break;
      }
    }
  }

  bool _isYoutubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  void _playEpisode(NewsItemModel episode) async {
    String url = episode.url;
    if (_isYoutubeUrl(url)) {
      url = await _socketService.getUpdatedUrl(url);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoScreen(
          videoUrl: url,
          unUpdatedUrl: episode.url,
          channelList: _currentEpisodes,
          bannerImageUrl: widget.banner,
          startAtPosition: Duration.zero,
          videoType: widget.source,
          isLive: false,
          isVOD: false,
          isSearch: false,
          isBannerSlider: false,
          videoId: int.tryParse(episode.id),
          source: 'webseries_details_page',
          name: episode.name,
          liveStatus: false,
        ),
      ),
    );
  }

  List<NewsItemModel> get _currentEpisodes =>
      _episodesMap[_seasons[_selectedSeasonIndex].id] ?? [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.name),
      ),
      body: RawKeyboardListener(
        focusNode: _mainFocusNode,
        autofocus: true,
        onKey: _handleKeyEvent,
        child: Stack(
          children: [
            _buildBackground(),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() => Positioned.fill(
        child: Image.network(
          widget.banner,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: Colors.black),
        ),
      );

  Widget _buildContent() => Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.7),
                Colors.black,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: _isLoading ? _buildLoading() : _buildEpisodeList(),
        ),
      );

  Widget _buildLoading() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SpinKitFadingCircle(color: Colors.white, size: 50),
            const SizedBox(height: 20),
            Text(
              _errorMessage.isNotEmpty ? _errorMessage : "Loading...",
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      );

  Widget _buildEpisodeList() => ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 100, bottom: 40),
        cacheExtent: 1000,
        itemCount: _currentEpisodes.length,
        itemBuilder: (context, index) => _buildEpisodeItem(index),
      );

  Widget _buildEpisodeItem(int index) {
    final episode = _currentEpisodes[index];
    final isFocused = index == _selectedEpisodeIndex;

    return Focus(
      focusNode: _episodeFocusNodes[episode.id],
      onFocusChange: (hasFocus) {
        if (hasFocus) setState(() => _selectedEpisodeIndex = index);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isFocused ? Colors.purpleAccent : Colors.transparent,
              width: 2,
            ),
            boxShadow: isFocused
                ? [BoxShadow(color: Colors.purple.withOpacity(0.5), blurRadius: 10)]
                : [],
          ),
          child: ListTile(
            leading: _buildThumbnail(episode),
            title: Text(
              episode.name,
              style: TextStyle(
                color: isFocused ? Colors.purpleAccent : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              episode.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[400]),
            ),
            trailing: Icon(
              Icons.play_arrow,
              color: isFocused ? Colors.purpleAccent : Colors.white,
            ),
            onTap: () => _playEpisode(episode),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(NewsItemModel episode) => Container(
        width: 100,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: NetworkImage(widget.banner),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Text(
            "EP ${episode.order}",
            style: const TextStyle(
              color: Colors.transparent,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black, blurRadius: 5)],
            ),
          ),
        ),
      );
}