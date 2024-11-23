



import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
import 'package:mobi_tv_entertainment/menu_screens/home_sub_screen/sub_vod.dart';
import '../main.dart';
import '../video_widget/socket_service.dart';
import '../video_widget/video_screen.dart';
import '../widgets/models/news_item_model.dart';
import '../widgets/utils/color_service.dart';


  Future<List<NewsItemModel>> fetchFromApi(String searchTerm) async {
  try {
    final response = await https.get(
      // Uri.encodeComponent(searchTerm)
      Uri.parse('https://acomtv.com/android/searchContent/${searchTerm}/0'),
      headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
    );
    print("API Response Status Code: ${response.statusCode}");
    print("API Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);

      if (settings['tvenableAll'] == 0) {
        final enabledChannels = settings['channels']?.map((id) => id.toString()).toSet() ?? {};

        return responseData
            .where((channel) =>
                channel['name'] != null &&
                channel['name'].toString().toLowerCase().contains(searchTerm.toLowerCase()) &&
                enabledChannels.contains(channel['id'].toString()))
            .map((channel) => NewsItemModel.fromJson(channel))
            .toList();
      } else {
        return responseData
            .where((channel) =>
                channel['name'] != null &&
                channel['name'].toString().toLowerCase().contains(searchTerm.toLowerCase()))
            .map((channel) => NewsItemModel.fromJson(channel))
            .toList();
      }
    }
    throw Exception('Failed to load data from API');
  } catch (e) {
    print('Error fetching from API 1: $e');
    return [];
  }
}









Uint8List _getImageFromBase64String(String base64String) {
  // Split the base64 string to remove metadata if present
  return base64Decode(base64String.split(',').last);
}



Map<String, dynamic> settings = {};

Future<void> fetchSettings() async {
  try {
    final response = await https.get(
      Uri.parse('https://api.ekomflix.com/android/getSettings'),
      headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
    );

    if (response.statusCode == 200) {
      settings = json.decode(response.body);
    } else {
      throw Exception('Failed to load settings');
    }
  } catch (e) {
    print('Error fetching settings: $e');
  }
}


void main() {
  runApp(MaterialApp(home: SearchScreen()));
}

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<NewsItemModel> searchResults = [];
  bool isLoading = false;
  TextEditingController _searchController = TextEditingController();
  int selectedIndex = -1;
  final FocusNode _searchFieldFocusNode = FocusNode();
  final FocusNode _searchIconFocusNode = FocusNode();
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
    _searchIconFocusNode.addListener(_onSearchIconFocusChanged);
    _socketService.initSocket();
    checkServerStatus();
  }

  @override
  void dispose() {
    _searchFieldFocusNode.removeListener(_onSearchFieldFocusChanged);
    _searchIconFocusNode.removeListener(_onSearchIconFocusChanged);
    _searchFieldFocusNode.dispose();
    _searchIconFocusNode.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    _itemFocusNodes.forEach((node) => node.dispose());
    _socketService.dispose();
    super.dispose();
  }

  Future<void> _updateChannelUrlIfNeeded(List<NewsItemModel> result, int index) async {
    if (result[index].streamType == 'YoutubeLive' || result[index].streamType == 'Youtube') {
      for (int i = 0; i < _maxRetries; i++) {
        if (!_shouldContinueLoading) break;
        try {
          String updatedUrl = await _socketService.getUpdatedUrl(result[index].url);
          setState(() {
            result[index] = result[index].copyWith(url: updatedUrl, streamType: 'M3u8');
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
      await _updateChannelUrlIfNeeded(searchResults, index);
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


//   Future<void> _onItemTap(BuildContext context, int index) async {
//   if (_isNavigating) return;
//   _isNavigating = true;
//   _showLoadingIndicator(context);

//   try {
//     await _updateChannelUrlIfNeeded(searchResults, index);
//     if (_shouldContinueLoading) {
//       final channel = searchResults[index];
//       final int? parsedContentType = int.tryParse(channel.contentType ?? "0");

//       if (parsedContentType == 1) {
//         // Filter the list with content_type == 1 for DetailsPage
//         final filteredList = searchResults
//             .where((item) => int.tryParse(item.contentType ?? "0") == 1)
//             .toList();

//         await Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => DetailsPage(
//               channelList: filteredList,
//               id: int.tryParse(channel.id) ?? 0,
//               source: 'isSearchScreenViaDetailsPageChannelList',
//             ),
//           ),
//         );
//       } else {
//         // Filter the remaining items (content_type != 1) for VideoScreen
//         final otherList = searchResults
//             .where((item) => int.tryParse(item.contentType ?? "0") != 1)
//             .toList();

//         await Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => VideoScreen(
//               videoUrl: channel.url,
//               startAtPosition: Duration.zero,
//               bannerImageUrl: channel.banner,
//               videoType: channel.streamType,
//               channelList: otherList, // Pass the filtered list
//               isLive: true,
//               isVOD: false,
//               isBannerSlider: false,
//               source: 'isSearchScreen',
//               isSearch: true,
//             ),
//           ),
//         );
//       }
//     }
//   } catch (e) {
//     print('Error playing video: $e');
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Something Went Wrong')),
//     );
//   } finally {
//     _isNavigating = false;
//     _shouldContinueLoading = true;
//     _dismissLoadingIndicator();
//   }
// }



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


Future<void> _navigateToVideoScreen(BuildContext context, List<NewsItemModel> channels, int index) async {
  if (index < 0 || index >= channels.length) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invalid channel index')),
    );
    return;
  }

  final channel = channels[index];
  final String? videoUrl = channel.url;
  final String? streamType = channel.streamType;
  final String? genres = channel.genres;
  final int? parsedContentType = int.tryParse(channel.contentType);


    if (parsedContentType == 1) {
    
  print('Navigating to DetailsPage with ID: ${int.tryParse(channel.id) ?? 0}');




    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailsPage(
            channelList: 
            searchResults
            ,
            id: int.tryParse(channel.id) ?? 0,
            source: 'isSearchScreenViaDetailsPageChannelList',
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

  if (videoUrl == null || videoUrl.isEmpty || streamType == null) {
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('Video information is missing or invalid')),
    // );
    return;
  }

  // print('Navigating to video with URL: $videoUrl');
  // print('Stream type: $streamType');
  // print('Content type: $parsedContentType');


    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoScreen(
            videoUrl: videoUrl,
            startAtPosition: Duration.zero,
            bannerImageUrl: channel.banner,
            videoType: streamType,
            channelList: 
            searchResults
            ,
            isLive: true,
            isVOD: false,isBannerSlider: false,
            source: 'isSearchScreen',isSearch: true,
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
          _itemFocusNodes.addAll(List.generate(searchResults.length, (index) => FocusNode()));
          isLoading = false;
        });

        await _preloadImages(searchResults);

        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_itemFocusNodes.isNotEmpty && _itemFocusNodes[0].context != null && mounted) {
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
      final imageUrl = result.banner;
      if (imageUrl.isNotEmpty) {
        await precacheImage(CachedNetworkImageProvider(imageUrl), context);
      }
    }
  }

  Future<void> _updatePaletteColor(String imageUrl) async {
    try {
      Color color = await _paletteColorService.getSecondaryColor(imageUrl);
      if (!mounted) return;
      setState(() {
        paletteColor = color;
      });
    } catch (e) {
      print('Error updating palette color: $e');
      if (!mounted) return;
      setState(() {
        paletteColor = Colors.grey;
      });
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
        _searchIconFocusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cardColor,
      body: Column(
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
                        padding: EdgeInsets.symmetric(horizontal: screenwdt * 0.03),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
    );
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
                  _performSearch(value);
                },
                onSubmitted: (value) {
                  _performSearch(value);
                  _toggleSearchField();
                },
                autofocus: true,
              ),
            ),
          Focus(
            focusNode: _searchIconFocusNode,
            onKey: (node, event) {
              if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.select) {
                _toggleSearchField();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: IconButton(
              icon: Icon(
                Icons.search,
                color: _searchIconFocusNode.hasFocus ? borderColor : Colors.white,
                size: _searchIconFocusNode.hasFocus ? 35 : 30,
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
    final bool isBase64 = result.banner.startsWith('data:image');

    return Focus(
      focusNode: _itemFocusNodes[index],
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.select) {
          _onItemTap(context, index);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      onFocusChange: (hasFocus) {
        _updatePaletteColor(result.banner);
        setState(() {
          selectedIndex = hasFocus ? index : -1;
        });
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
            child: status == '1'
                ? ClipRRect(
                    child: 
                     isBase64
                      ? Image.memory(
                          _getImageFromBase64String(result.banner),
                          width: screenwdt * 0.19,
                          height: screenhgt * 0.2,
                          fit: BoxFit.cover,
                        )
                      :
                    CachedNetworkImage(
                      imageUrl: result.banner,
                      placeholder: (context, url) => localImage,
                      width: screenwdt * 0.19,
                      height: screenhgt * 0.2,
                      fit: BoxFit.cover,
                    ),
                  )
                : null,
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