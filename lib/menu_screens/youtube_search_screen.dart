// import 'dart:async';
// import 'dart:convert';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:http/http.dart' as https;
// import 'package:provider/provider.dart';

// import '../../main.dart';
// import '../../provider/color_provider.dart';
// import '../../provider/focus_provider.dart';
// import '../../video_widget/socket_service.dart';
// import '../../video_widget/video_screen.dart';
// import '../../widgets/models/news_item_model.dart';
// import '../../widgets/utils/color_service.dart';

// class YoutubeSearchScreen extends StatefulWidget {
//   @override
//   State<YoutubeSearchScreen> createState() => _YoutubeSearchScreenState();
// }

// class _YoutubeSearchScreenState extends State<YoutubeSearchScreen> {
//   List<NewsItemModel> searchResults = [];
//   bool isLoading = false;
//   TextEditingController _searchController = TextEditingController();
//   int selectedIndex = -1;
//   final FocusNode _searchYoutubeFieldFocusNode = FocusNode();
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
//     _searchYoutubeFieldFocusNode.addListener(() => setState(() {}));
//     _youtubeSearchIconFocusNode.addListener(() => setState(() {}));
//     _socketService.initSocket();

//   WidgetsBinding.instance.addPostFrameCallback((_) {
//   context.read<FocusProvider>().setYoutubeSearchIconFocusNode(_youtubeSearchIconFocusNode);
// });

//   }

//   @override
//   void dispose() {
//     _searchYoutubeFieldFocusNode.dispose();
//     _youtubeSearchIconFocusNode.dispose();
//     _searchController.dispose();
//     _debounce?.cancel();
//     _itemFocusNodes.forEach((node) => node.dispose());
//     _socketService.dispose();
//     super.dispose();
//   }

//   Future<List<NewsItemModel>> fetchYoutubeResults(String searchTerm) async {
//     try {
//       final response = await https.get(
//         Uri.parse('https://mobifreetv.com/android/youtube_videos?q=${Uri.encodeComponent(searchTerm)}&length=50'),
//         headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//       );

//       if (response.statusCode == 200) {
//         final jsonData = json.decode(response.body);
//         return (jsonData['data'] as List).map((video) {
//           return NewsItemModel(
//             id: video['id'] ?? '',
//             name: video['title'] ?? '',
//             url: 'https://www.youtube.com/watch?v=${video['videoId']}',
//             streamType: 'Youtube',
//             genres: '',
//             status: '1',
//             banner: video['thumbnail_high'] ?? '',
//             isFocused: false,
//           );
//         }).toList();
//       }
//     } catch (e) {
//       print('Error: $e');
//     }
//     return [];
//   }

//   void _toggleSearchField() {
//     setState(() {
//       _showSearchField = !_showSearchField;
//       if (_showSearchField) {

//         Future.delayed(Duration(milliseconds: 150), () {
//   if (mounted) _searchYoutubeFieldFocusNode.requestFocus();
// });

//       } else {
//         _youtubeSearchIconFocusNode.requestFocus();
//       }
//     });
//   }

//   void _performSearch(String searchTerm) {
//     if (_debounce?.isActive ?? false) _debounce?.cancel();

//     if (searchTerm.trim().isEmpty) {
//       setState(() {
//         isLoading = false;
//         searchResults.clear();
//         _itemFocusNodes.clear();
//       });
//       return;
//     }

//     _debounce = Timer(const Duration(milliseconds: 300), () async {
//       if (!mounted) return;
//       setState(() {
//         isLoading = true;
//         searchResults.clear();
//         _itemFocusNodes.clear();
//       });

//       final results = await fetchYoutubeResults(searchTerm);
//       if (!mounted) return;
//       setState(() {
//         searchResults = results;
//         _itemFocusNodes.addAll(List.generate(results.length, (index) => FocusNode()));
//         isLoading = false;
//       });

//       if (_itemFocusNodes.isNotEmpty) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           FocusScope.of(context).requestFocus(_itemFocusNodes[0]);
//         });
//       }
//     });
//   }

//   Future<void> _updateChannelUrlIfNeeded(int index) async {
//     if (searchResults[index].streamType == 'Youtube') {
//       for (int i = 0; i < _maxRetries; i++) {
//         if (!_shouldContinueLoading) break;
//         try {
//           String updatedUrl = await _socketService.getUpdatedUrl(searchResults[index].url);
//           setState(() {
//             searchResults[index] = searchResults[index].copyWith(url: updatedUrl, streamType: 'M3u8');
//           });
//           break;
//         } catch (e) {
//           if (i == _maxRetries - 1) rethrow;
//           await Future.delayed(Duration(seconds: _retryDelay));
//         }
//       }
//     }
//   }

//   Future<void> _onItemTap(int index) async {
//     if (_isNavigating) return;
//     _isNavigating = true;
//     _showLoadingIndicator();

//     try {
//       await _updateChannelUrlIfNeeded(index);
//       if (_shouldContinueLoading) {
//         await Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => VideoScreen(
//               videoUrl: searchResults[index].url,
//               startAtPosition: Duration.zero,
//               bannerImageUrl: searchResults[index].banner,
//               videoType: searchResults[index].streamType,
//               channelList: searchResults,
//               isLive: true,
//               isVOD: false,
//               isBannerSlider: false,
//               source: 'youtubeSearchScreen',
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
//       _isNavigating = false;
//       _shouldContinueLoading = true;
//       _dismissLoadingIndicator();
//     }
//   }

//   void _showLoadingIndicator() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => Center(
//         child: SpinKitFadingCircle(color: Colors.white, size: 50.0),
//       ),
//     );
//   }

//   void _dismissLoadingIndicator() {
//     if (Navigator.of(context).canPop()) {
//       Navigator.of(context).pop();
//     }
//   }

//   Future<void> _updatePaletteColor(String imageUrl, bool isFocused) async {
//     try {
//       Color color = await _paletteColorService.getSecondaryColor(imageUrl);
//       if (!mounted) return;
//       setState(() {
//         paletteColor = color;
//       });
//       Provider.of<ColorProvider>(context, listen: false).updateColor(color, isFocused);
//     } catch (e) {
//       Provider.of<ColorProvider>(context, listen: false).updateColor(Colors.grey, isFocused);
//     }
//   }

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
//                 focusNode: _searchYoutubeFieldFocusNode,
//                 decoration: InputDecoration(
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10.0),
//                     borderSide: BorderSide(color: Colors.grey, width: 4.0),
//                   ),
//                   labelText: 'Search YouTube Videos',
//                   labelStyle: TextStyle(color: Colors.white),
//                 ),
//                 style: TextStyle(color: Colors.white),
//                 textInputAction: TextInputAction.search,
//                 textAlignVertical: TextAlignVertical.center,
//                 // onChanged: _performSearch,
//                 onSubmitted: (value) {
//                   _performSearch(value);
//                   _toggleSearchField();
//                 },
//                 autofocus: _showSearchField,
//               ),
//             ),
//           Focus(
//             focusNode: _youtubeSearchIconFocusNode,
//             onKey: (node, event) {
//               if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.select) {
//                 _toggleSearchField();
//                 return KeyEventResult.handled;
//               }
//               return KeyEventResult.ignored;
//             },
//             child: IconButton(
//               icon: Icon(
//                 Icons.search,
//                 color: _youtubeSearchIconFocusNode.hasFocus ? borderColor : Colors.white,
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

// //   Widget _buildGridItem(int index) {
// //     final result = searchResults[index];
// //     return Focus(
// //       focusNode: _itemFocusNodes[index],
// //       onFocusChange: (hasFocus) async {
// //         if (hasFocus) await _updatePaletteColor(result.banner, true);
// //         setState(() => selectedIndex = hasFocus ? index : -1);
// //       },
// //       onKeyEvent: (node, event) {
// //         if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.select) {
// //           _onItemTap(index);
// //           return KeyEventResult.handled;
// //         }
// //         return KeyEventResult.ignored;
// //       },
// //       child: Column(
// //         children: [
// //           // AnimatedContainer(
// //           //   duration: Duration(milliseconds: 300),
// //           //   width: screenwdt * 0.19,
// //           //   height: screenhgt * 0.2,
// //           //   decoration: BoxDecoration(
// //           //     border: Border.all(color: selectedIndex == index ? paletteColor : Colors.transparent, width: 3.0),
// //           //     boxShadow: selectedIndex == index ? [BoxShadow(color: paletteColor, blurRadius: 25, spreadRadius: 10)] : [],
// //           //   ),
// //           //   child: CachedNetworkImage(
// //           //     imageUrl: result.banner,
// //           //     width: screenwdt * 0.19,
// //           //     height: screenhgt * 0.2,
// //           //     fit: BoxFit.cover,
// //           //   ),
// //           // ),

// // AnimatedContainer(
// //   duration: Duration(milliseconds: 300),
// //   curve: Curves.easeInOut,
// //   decoration: BoxDecoration(
// //     border: Border.all(
// //       color: selectedIndex == index ? paletteColor : Colors.transparent,
// //       width: 3.0,
// //     ),
// //     boxShadow: selectedIndex == index
// //         ? [BoxShadow(color: paletteColor, blurRadius: 25, spreadRadius: 10)]
// //         : [],
// //   ),
// //   child: Transform.scale(
// //     scale: selectedIndex == index ? 1.15 : 1.0, // Scale up if focused
// //     child: CachedNetworkImage(
// //       imageUrl: result.banner,
// //       width: screenwdt * 0.19,
// //       height: screenhgt * 0.2,
// //       fit: BoxFit.cover,
// //     ),
// //   ),
// // ),

// //           SizedBox(height: 6),
// //           Container(
// //             width: screenwdt * 0.15,
// //             child: Text(
// //               result.name.toUpperCase(),
// //               textAlign: TextAlign.center,
// //               maxLines: 1,
// //               overflow: TextOverflow.ellipsis,
// //               style: TextStyle(color: selectedIndex == index ? paletteColor : Colors.white),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// Widget _buildGridItem(int index) {
//   final result = searchResults[index];
//   final isFocused = selectedIndex == index;

//   return Focus(
//     focusNode: _itemFocusNodes[index],
//     onFocusChange: (hasFocus) async {
//       if (hasFocus) await _updatePaletteColor(result.banner, true);
//       setState(() => selectedIndex = hasFocus ? index : -1);
//     },
//     onKeyEvent: (node, event) {
//       if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.select) {
//         _onItemTap(index);
//         return KeyEventResult.handled;
//       }
//       return KeyEventResult.ignored;
//     },
//     child: Stack(
//       clipBehavior: Clip.none, // So focused image can overflow
//       children: [
//         AnimatedContainer(
//           duration: Duration(milliseconds: 300),
//           curve: Curves.easeInOut,
//           decoration: BoxDecoration(
//             border: Border.all(
//               color: isFocused ? paletteColor : Colors.transparent,
//               width: 3.0,
//             ),
//             boxShadow: isFocused
//                 ? [BoxShadow(color: paletteColor, blurRadius: 25, spreadRadius: 10)]
//                 : [],
//           ),
//           child: OverflowBox(
//             maxWidth: screenwdt * 0.25,
//             maxHeight: screenhgt * 0.28,
//             alignment: Alignment.center,
//             child: Transform.scale(
//               scale: isFocused ? 1.2 : 1.0,
//               child: CachedNetworkImage(
//                 imageUrl: result.banner,
//                 width: screenwdt * 0.19,
//                 height: screenhgt * 0.2,
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//         ),
//         if (isFocused)
//           Positioned(
//             bottom: -screenhgt * 0.03,
//             child: Container(
//               width: screenwdt * 0.15,
//               alignment: Alignment.center,
//               child: Text(
//                 result.name.toUpperCase(),
//                 textAlign: TextAlign.center,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: TextStyle(color: paletteColor, fontWeight: FontWeight.bold),
//               ),
//             ),
//           ),
//       ],
//     ),
//   );
// }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<ColorProvider>(builder: (context, colorProvider, child) {
//       Color backgroundColor = colorProvider.isItemFocused ? colorProvider.dominantColor : Colors.black;
//       return Scaffold(
//         backgroundColor: backgroundColor,
//         body: Column(
//           children: [
//             _buildSearchBar(),
//             Expanded(
//               child: isLoading
//                   ? Center(child: SpinKitFadingCircle(color: borderColor))
//                   : searchResults.isEmpty
//                       ? Center(child: Text('No results found', style: TextStyle(color: Colors.white)))
//                       : Padding(
//                           padding: EdgeInsets.symmetric(horizontal: screenwdt * 0.03),
//                           child: GridView.builder(
//                             gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
//                             itemCount: searchResults.length,
//                             itemBuilder: (context, index) => GestureDetector(
//                               onTap: () => _onItemTap(index),
//                               child: _buildGridItem(index),
//                             ),
//                           ),
//                         ),
//             ),
//           ],
//         ),
//       );
//     });
//   }
// }

// Focused image zoom with clean overlay and Grid maintained

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
  }

  @override
  void dispose() {
    _searchYoutubeFieldFocusNode.dispose();
    _youtubeSearchIconFocusNode.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    _itemFocusNodes.forEach((node) => node.dispose());
    _socketService.dispose();
    super.dispose();
  }

  Future<List<NewsItemModel>> fetchYoutubeResults(String searchTerm) async {
    try {
      final response = await https.get(
        Uri.parse(
            'https://mobifreetv.com/android/youtube_videos?q=${Uri.encodeComponent(searchTerm)}&length=50'),
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

  // Widget _buildGridItem(int index) {
  //   final result = searchResults[index];
  //   return Focus(
  //     focusNode: _itemFocusNodes[index],
  //     onFocusChange: (hasFocus) async {
  //       if (hasFocus) await _updatePaletteColor(result.banner, true);
  //       setState(() => selectedIndex = hasFocus ? index : -1);
  //     },
  //     child: Container(
  //       decoration: BoxDecoration(
  //         border: Border.all(
  //           color: selectedIndex == index ? paletteColor : Colors.transparent,
  //           width: 1.5,
  //         ),
  //       ),
  //       child: CachedNetworkImage(
  //         imageUrl: result.banner,
  //         width: screenwdt * 0.19,
  //         height: screenhgt * 0.2,
  //         fit: BoxFit.cover,
  //       ),
  //     ),
  //   );
  // }

  Future<void> _onItemTap(int index) async {
    if (_isNavigating) return;
    _isNavigating = true;
    _showLoadingIndicator();

    try {
      await _updateChannelUrlIfNeeded(index);
      if (_shouldContinueLoading) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoScreen(
              videoUrl: searchResults[index].url,
              startAtPosition: Duration.zero,
              bannerImageUrl: searchResults[index].banner,
              videoType: searchResults[index].streamType,
              channelList: searchResults,
              isLive: true,
              isVOD: false,
              isBannerSlider: false,
              source: 'youtubeSearchScreen',
              isSearch: true,
              videoId: int.tryParse(searchResults[index].id),
              unUpdatedUrl: searchResults[index].url,
              name: searchResults[index].name,
              liveStatus: true,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error navigating: $e');
    } finally {
      _isNavigating = false;
      _shouldContinueLoading = true;
      _dismissLoadingIndicator();
    }
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

  Future<void> _updateChannelUrlIfNeeded(int index) async {
    if (searchResults[index].streamType == 'Youtube') {
      for (int i = 0; i < _maxRetries; i++) {
        if (!_shouldContinueLoading) break;
        try {
          String updatedUrl =
              await _socketService.getUpdatedUrl(searchResults[index].url);
          setState(() {
            searchResults[index] = searchResults[index]
                .copyWith(url: updatedUrl, streamType: 'M3u8');
          });
          break;
        } catch (e) {
          if (i == _maxRetries - 1) rethrow;
          await Future.delayed(Duration(seconds: _retryDelay));
        }
      }
    }
  }

  Widget _buildGridItem(int index) {
    final result = searchResults[index];
    final isFocused = selectedIndex == index;

    return FocusableActionDetector(
      focusNode: _itemFocusNodes[index],
      onShowFocusHighlight: (_) {},
      onFocusChange: (hasFocus) async {
        if (hasFocus) await _updatePaletteColor(result.banner, true);
        setState(() => selectedIndex = hasFocus ? index : -1);
      },
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => _onItemTap(index),
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
    final double imageWidth = screenwdt * 0.19;
    final double imageHeight = screenhgt * 0.3;

    final double zoomFactor = 1.5;
    final double newWidth = imageWidth * zoomFactor;
    final double newHeight = imageHeight * zoomFactor;

    // ✅ Correct top and left to shift image up/left equally
    final double shiftLeft = (newWidth - imageWidth) / 2;
    final double shiftTop = (newHeight - imageHeight) / 0.8;

    return Positioned(
      left: position.dx - shiftLeft,
      top: position.dy - shiftTop,
      child: Container(
        width: newWidth,
        height: newHeight,
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
  Widget build(BuildContext context) {
    return Consumer<ColorProvider>(builder: (context, colorProvider, child) {
      Color backgroundColor = colorProvider.isItemFocused
          ? colorProvider.dominantColor
          : Colors.black;
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Stack(
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
                    ? paletteColor
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
