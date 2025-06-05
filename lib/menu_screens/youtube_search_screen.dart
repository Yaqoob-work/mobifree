import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../provider/color_provider.dart';
import '../../provider/focus_provider.dart';
import '../../video_widget/socket_service.dart';
import '../../video_widget/video_screen.dart';
import '../../widgets/models/news_item_model.dart';
import '../../widgets/utils/color_service.dart';
import '../widgets/small_widgets/youtube.dart';

class YoutubeSearchScreen extends StatefulWidget {
  @override
  State<YoutubeSearchScreen> createState() => _YoutubeSearchScreenState();
}

class _YoutubeSearchScreenState extends State<YoutubeSearchScreen> {
  List<NewsItemModel> searchResults = [];
  bool isLoading = false;
  TextEditingController _searchController = TextEditingController();
  int selectedIndex = -1;
  final FocusNode _searchYoutubeFieldFocusNode = FocusNode();
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
    _searchYoutubeFieldFocusNode.addListener(() => setState(() {}));
    _youtubeSearchIconFocusNode.addListener(() => setState(() {}));
    _socketService.initSocket();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<FocusProvider>()
          .setYoutubeSearchIconFocusNode(_youtubeSearchIconFocusNode);
    });
    _shouldContinueLoading = true;
  }

  @override
  void dispose() {
    _shouldContinueLoading = false;
    _searchYoutubeFieldFocusNode.dispose();
    _youtubeSearchIconFocusNode.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    _itemFocusNodes.forEach((node) => node.dispose());
    _socketService.dispose();
    super.dispose();
  }

//   Future<void> _onItemTap(int index) async {
//     if (_isNavigating) return;
//     _isNavigating = true;
//     _showLoadingIndicator();

//     try {
//       String url = searchResults[index].videoId;
//       print('Initial URL: $url'); // Print initial URL
// if (Youtube.isYoutubeUrl(url)) {
//       url = await _socketService.getUpdatedUrl(url);

//         print('ValidYouTube URL detected: $url');
//       } else {
//         print('Invalid YouTube URL: $url');
//       }

//       if (_shouldContinueLoading && mounted) {
//         await Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => VideoScreen(
//               videoUrl: url,
//               startAtPosition: Duration.zero,
//               bannerImageUrl: searchResults[index].banner,
//               videoType: searchResults[index].streamType,
//               channelList: searchResults,
//               isLive: true,
//               isVOD: false,
//               isBannerSlider: false,
//               source: 'isYoutubeSearchScreen',
//               isSearch: true,
//               videoId: int.tryParse(searchResults[index].id),
//               unUpdatedUrl: searchResults[index].url,
//               name: searchResults[index].name,
//               liveStatus: true,
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       print('Error navigating: $e');
//     } finally {
//       if (mounted) {
//         _isNavigating = false;
//         _shouldContinueLoading = true;
//         _dismissLoadingIndicator();
//       }
//     }
//   }



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



 Future<void> _onItemTap(int index) async {
    if (_isNavigating) return;
    _isNavigating = true;
    _showLoadingIndicator();

    try {
      final result = searchResults[index];
      String updatedUrl = result.videoId; // FIX 1: Use .url instead of .videoId
      String type = result.streamType;
      String originalUrl = updatedUrl;

      if (isYoutubeUrl(updatedUrl)) {
        updatedUrl = await _socketService.getUpdatedUrl(updatedUrl);
print( 'FinalURL after conversion: $updatedUrl'); // Debugging line

      }
print( 'FinalURL after conversion: $updatedUrl'); // Debugging line
      

      if (_shouldContinueLoading && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoScreen(
              videoUrl: updatedUrl,
              startAtPosition: Duration.zero,
              bannerImageUrl: result.banner,
              videoType: 'm3u8', // Use updated type
              channelList: searchResults,
              // FIX 3: Correct live/VOD flags
              isLive: false,   // YouTube videos are VOD, not live
              isVOD: true,    // Mark as video-on-demand
              isBannerSlider: false,
              source: 'isYoutubeSearchScreen',
              isSearch: true,
              videoId: int.tryParse(result.id),
              unUpdatedUrl: originalUrl,
              name: result.name,
              liveStatus: false, // Not live content
            ),
          ),
        );
      }
    } catch (e) {
      print('Error navigating: $e');
      // FIX 4: Add proper error handling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to play video'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        _isNavigating = false;
        _dismissLoadingIndicator();
      }
    }
  }


  Future<List<NewsItemModel>> fetchYoutubeResults(String searchTerm) async {
    try {
      final response = await https.get(
        Uri.parse(
            'https://mobifreetv.com/android/youtube_videos?q=${Uri.encodeComponent(searchTerm)}&length=30'),
        headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return (jsonData['data'] as List).map((video) {
          return NewsItemModel(
            id: video['id'] ?? '',
            name: video['title'] ?? '',
            url: 'https://www.youtube.com/watch?v=${video['videoId']}',
            streamType: 'Youtube',
            genres: '',
            status: '1',
            banner: video['thumbnail_high'] ?? '',
            isFocused: false,
          );
        }).toList();
      }
    } catch (e) {
      print('Error: $e');
    }
    return [];
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

      final results = await fetchYoutubeResults(searchTerm);
      if (!mounted) return;
      setState(() {
        searchResults = results;
        _itemFocusNodes
            .addAll(List.generate(results.length, (index) => FocusNode()));
        isLoading = false;
      });

      if (_itemFocusNodes.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context).requestFocus(_itemFocusNodes[0]);
        });
      }
    });
  }


  void _showLoadingIndicator() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: SpinKitFadingCircle(color: Colors.white, size: 50.0),
      ),
    );
  }

  void _dismissLoadingIndicator() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }





  Widget _buildGridItem(int index) {
    final result = searchResults[index];
    final isFocused = selectedIndex == index;

    return
     FocusableActionDetector(
      focusNode: _itemFocusNodes[index],
      onShowFocusHighlight: (value) => setState(() {}),
      onFocusChange: (hasFocus) async {
        if (hasFocus) await _updatePaletteColor(result.banner, true);
        setState(() => selectedIndex = hasFocus ? index : -1);
      },
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.select): ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (intent) {
            _onItemTap(index);
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: () => _onItemTap(index),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isFocused ? paletteColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: CachedNetworkImage(
            imageUrl: result.banner,
            width: screenwdt * 0.19,
            height: screenhgt * 0.2,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }




Widget _buildFocusedOverlayItem(int index) {
  if (index < 0 || index >= searchResults.length) return SizedBox.shrink();
  final result = searchResults[index];
  final nodeContext = _itemFocusNodes[index].context;
  if (nodeContext == null) return SizedBox.shrink();

  final box = nodeContext.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return SizedBox.shrink();

  final position = box.localToGlobal(Offset.zero);
  final double imageWidth = screenwdt * 0.22;
  final double imageHeight = screenhgt * 0.28;

  final double zoomFactor = 1.5;
  final double newWidth = imageWidth * zoomFactor;
  final double newHeight = imageHeight * zoomFactor;

  // Calculate the center point of the original image
  final double centerX = position.dx + imageWidth / 2;
  final double centerY = position.dy + imageHeight / 8;

  // Calculate initial position to center the zoomed image
  double left = centerX - newWidth / 2;
  double top = centerY - newHeight / 2;

  // Get screen dimensions and safe area
  final MediaQueryData mediaQuery = MediaQuery.of(context);
  final double screenWidth = mediaQuery.size.width;
  final double screenHeight = mediaQuery.size.height;
  final EdgeInsets padding = mediaQuery.padding;
  
  // Define safe margins from screen edges
  final double margin = 20.0;
  
  // Adjust horizontal position to stay within screen bounds
  if (left < margin) {
    left = margin;
  } else if (left + newWidth > screenWidth - margin) {
    left = screenWidth - newWidth - margin;
  }
  
  // Adjust vertical position to stay within screen bounds
  if (top < padding.top + margin) {
    top = padding.top + margin;
  } else if (top + newHeight > screenHeight - padding.bottom - margin) {
    top = screenHeight - newHeight - padding.bottom - margin;
  }

  // Additional check to ensure the image doesn't exceed screen bounds
  // If the zoomed image is larger than available space, adjust the size
  double finalWidth = newWidth;
  double finalHeight = newHeight;
  
  if (newWidth > screenWidth - (2 * margin)) {
    finalWidth = screenWidth - (2 * margin);
    left = margin;
  }
  
  if (newHeight > screenHeight - padding.top - padding.bottom - (2 * margin)) {
    finalHeight = screenHeight - padding.top - padding.bottom - (2 * margin);
    top = padding.top + margin;
  }

  return Positioned(
    left: left,
    top: top,
    child: Container(
      width: finalWidth,
      height: finalHeight,
      decoration: BoxDecoration(
        border: Border.all(color: paletteColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: paletteColor.withOpacity(0.6),
            blurRadius: 15,
            spreadRadius: 6,
          ),
        ],
      ),
      child: CachedNetworkImage(
        imageUrl: result.banner,
        fit: BoxFit.cover,
      ),
    ),
  );
}


  Future<void> _updatePaletteColor(String imageUrl, bool isFocused) async {
    try {
      Color color = await _paletteColorService.getSecondaryColor(imageUrl);
      if (!mounted) return;
      setState(() {
        paletteColor = color;
      });
      Provider.of<ColorProvider>(context, listen: false)
          .updateColor(color, isFocused);
    } catch (e) {
      Provider.of<ColorProvider>(context, listen: false)
          .updateColor(Colors.grey, isFocused);
    }
  }

  @override
  Widget 
  
  build(BuildContext context) {
    return 
    PopScope(
    canPop: false, // Back button se page pop nahi hoga
    onPopInvoked: (didPop) {
      if (!didPop) {
        // Back button dabane par ye function call hoga
        context.read<FocusProvider>().requestWatchNowFocus();
      }
    },
    child:
    Consumer<ColorProvider>(builder: (context, colorProvider, child) {
      Color backgroundColor = colorProvider.isItemFocused
          ? colorProvider.dominantColor
          : Colors.black;
      return Container(
        // color: Colors.black54 ,
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: Container(
        color: Colors.black54 ,

            child: Stack(
              children: [
                Column(
                  children: [
                    _buildSearchBar(),
                    Expanded(
                      child: isLoading
                          ? Center(child: SpinKitFadingCircle(color: paletteColor))
                          : searchResults.isEmpty
                              ? Center(
                                  child: Text('No results found',
                                      style: TextStyle(color: Colors.white)))
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: screenwdt * 0.03),
                                  child: GridView.builder(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 5,
                                      mainAxisSpacing: 20,
                                      crossAxisSpacing: 10,
                                    ),
                                    itemCount: searchResults.length,
                                    itemBuilder: (context, index) =>
                                        _buildGridItem(index),
                                  ),
                                ),
                    ),
                  ],
                ),
                if (selectedIndex != -1) _buildFocusedOverlayItem(selectedIndex),
              ],
            ),
          ),
        ),
      );
    })
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
                focusNode: _searchYoutubeFieldFocusNode,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: Colors.grey, width: 4.0),
                  ),
                  labelText: 'Search YouTube Videos',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                style: TextStyle(color: Colors.white),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  _performSearch(value);
                  _toggleSearchField();
                },
              ),
            ),
          Focus(
            focusNode: _youtubeSearchIconFocusNode,
            onKey: (node, event) {
              if (event is RawKeyDownEvent &&
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
                    ? Colors.orange
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

  void _toggleSearchField() {
    setState(() {
      _showSearchField = !_showSearchField;
      if (_showSearchField) {
        Future.delayed(Duration(milliseconds: 150), () {
          if (mounted) _searchYoutubeFieldFocusNode.requestFocus();
        });
      } else {
        _youtubeSearchIconFocusNode.requestFocus();
      }
    });
  }
}
