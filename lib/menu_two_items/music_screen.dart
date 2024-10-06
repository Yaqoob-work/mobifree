import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobi_tv_entertainment/main.dart';
import 'package:mobi_tv_entertainment/menu_two_items/news_grid_screen.dart';
import 'package:mobi_tv_entertainment/video_widget/socket_service.dart';
import 'package:mobi_tv_entertainment/video_widget/video_screen.dart';
import 'package:mobi_tv_entertainment/widgets/items/news_item.dart';
import 'package:mobi_tv_entertainment/widgets/models/news_item_model.dart';
import 'package:mobi_tv_entertainment/widgets/services/api_service.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/empty_state.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/error_message.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/loading_indicator.dart';
import '../widgets/utils/random_light_color_widget.dart';
import 'channels_category.dart';

class MusicScreen extends StatefulWidget {
  @override
  _MusicScreenState createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final List<NewsItemModel> _entertainmentList = [];
  final SocketService _socketService = SocketService();
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isNavigating = false;
  int _maxRetries = 3;
  int _retryDelay = 5; // seconds
  String _selectedCategory = 'Live'; // Default category

  final List<String> categories = [
    'Live',
    'Entertainment',
    'Music',
    'Movie',
    'News',
    'Sports',
    'Religious'
  ];

  Map<String, FocusNode> categoryFocusNodes = {};
  late FocusNode moreFocusNode;

  @override
  void initState() {
    super.initState();
    _socketService.initSocket();
    fetchData();
    checkServerStatus();
    // Initialize focus nodes for each category
    for (var category in categories) {
      categoryFocusNodes[category] = FocusNode();
    }
    moreFocusNode = FocusNode();


  }

  void checkServerStatus() {
    Timer.periodic(Duration(seconds: 10), (timer) {
      // Check if the socket is connected, otherwise attempt to reconnect
      if (!_socketService.socket.connected) {
        print('YouTube server down, retrying...');
        _socketService.initSocket(); // Re-establish the socket connection
      }
    });
  }

  Future<void> fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _apiService.fetchSettings();
      await _apiService.fetchEntertainment();
      setState(() {
        _entertainmentList.clear();
        // Use the selected category to determine which list to add
        switch (_selectedCategory.toLowerCase()) {
          case 'live':
            _entertainmentList.addAll(_apiService.allChannelList);
            break;
          case 'entertainment':
            _entertainmentList.addAll(_apiService.entertainmentList);
            break;
          case 'music':
            _entertainmentList.addAll(_apiService.musicList);
            break;
          case 'movie':
            _entertainmentList.addAll(_apiService.movieList);
            break;
          case 'news':
            _entertainmentList.addAll(_apiService.newsList);
            break;
          case 'sports':
            _entertainmentList.addAll(_apiService.sportsList);
            break;
          case 'religious':
            _entertainmentList.addAll(_apiService.religiousList);
            break;
          default:
            _entertainmentList.addAll(_apiService.musicList);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Something Went Wrong';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cardColor,
      body: Column(
        children: [
          // SizedBox(height: screenhgt * 0.03),
          _buildCategoryButtons(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

// Helper function to generate random light colors
  Color generateRandomLightColor() {
    Random random = Random();
    int red = random.nextInt(156) + 100; // Red values between 100 and 255
    int green = random.nextInt(156) + 100; // Green values between 100 and 255
    int blue = random.nextInt(156) + 100; // Blue values between 100 and 255

    return Color.fromRGBO(red, green, blue, 1.0); // Full opacity
  }

  // Widget _buildCategoryButtons() {
  //   return Container(
  //     margin: EdgeInsets.symmetric(vertical: screenhgt * 0.015),
  //     height: screenhgt * 0.085, // Parent container height
  //     child: ListView(
  //       scrollDirection: Axis.horizontal,
  //       children: [
  //         ...categories.asMap().entries.map((entry) {
  //           int index = entry.key;
  //           String category = entry.value;

  //           return Focus(
  //             focusNode: categoryFocusNodes[category],
  //             onKey: (FocusNode node, RawKeyEvent event) {
  //               if (event is RawKeyDownEvent) {
  //                 if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
  //                   if (index == categories.length - 1) {
  //                     FocusScope.of(context).requestFocus(moreFocusNode);
  //                   } else {
  //                     FocusScope.of(context).requestFocus(
  //                         categoryFocusNodes[categories[index + 1]]);
  //                   }
  //                   return KeyEventResult.handled;
  //                 } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
  //                   if (index == 0) {
  //                     FocusScope.of(context).requestFocus(moreFocusNode);
  //                   } else {
  //                     FocusScope.of(context).requestFocus(
  //                         categoryFocusNodes[categories[index - 1]]);
  //                   }
  //                   return KeyEventResult.handled;
  //                 } else if (event.logicalKey == LogicalKeyboardKey.enter ||
  //                     event.logicalKey == LogicalKeyboardKey.select) {
  //                   _selectCategory(category);
  //                   return KeyEventResult.handled;
  //                 }
  //               }
  //               return KeyEventResult.ignored;
  //             },
  //             child: Builder(
  //               builder: (BuildContext context) {
  //                 final bool hasFocus = Focus.of(context).hasFocus;

  //                 // Generate a random light color for the shadow and border when focused
  //                 Color randomBorderColor = hasFocus
  //                     ? generateRandomLightColor()
  //                     : Colors.transparent;

  //                 return Container(
  //                   margin: EdgeInsets.symmetric(horizontal: screenwdt * 0.02),
  //                   decoration: BoxDecoration(
  //                     color: hasFocus ? Colors.black : Colors.transparent,
  //                     boxShadow: [
  //                       if (hasFocus)
  //                         BoxShadow(
  //                           color: randomBorderColor
  //                           // .withOpacity(
  //                           // 0.8)
  //                           , // Adjust opacity for visibility
  //                           blurRadius:
  //                               15.0, // Reduced blur radius for sharper shadow
  //                           spreadRadius:
  //                               5.0, // Increased spread radius for more prominent shadow
  //                         ),
  //                     ],
  //                     borderRadius: BorderRadius.circular(8.0),
  //                     border: hasFocus
  //                         ? Border.all(
  //                             color:
  //                                 randomBorderColor, // Same color as the shadow
  //                             width: 2.0, // Adjust border width as needed
  //                           )
  //                         : null, // No border when not focused
  //                   ),
  //                   child: SizedBox(
  //                     height: screenhgt *
  //                         0.01, // Adjust height to control button size
  //                     child: Center(
  //                       child: TextButton(
  //                         onPressed: () => _selectCategory(category),
  //                         child: Text(
  //                           category,
  //                           style: TextStyle(
  //                             fontSize: menutextsz,
  //                             color: _selectedCategory == category
  //                                 ? borderColor
  //                                 : (hasFocus ? randomBorderColor : hintColor),
  //                             fontWeight:
  //                                 _selectedCategory == category || hasFocus
  //                                     ? FontWeight.bold
  //                                     : FontWeight.normal,
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 );
  //               },
  //             ),
  //           );
  //         }).toList(),
  //         Focus(
  //           focusNode: moreFocusNode,
  //           onKey: (FocusNode node, RawKeyEvent event) {
  //             if (event is RawKeyDownEvent) {
  //               if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
  //                 FocusScope.of(context)
  //                     .requestFocus(categoryFocusNodes[categories.first]);
  //                 return KeyEventResult.handled;
  //               } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
  //                 FocusScope.of(context)
  //                     .requestFocus(categoryFocusNodes[categories.last]);

  //                 return KeyEventResult.handled;
  //               } else if (event.logicalKey == LogicalKeyboardKey.enter ||
  //                   event.logicalKey == LogicalKeyboardKey.select) {
  //                 _navigateToChannelsCategory();
  //                 return KeyEventResult.handled;
  //               }
  //             }
  //             return KeyEventResult.ignored;
  //           },
  //           child: Builder(
  //             builder: (BuildContext context) {
  //               final bool hasFocus = Focus.of(context).hasFocus;

  //               // Generate a random light shadow color for the "More" button when focused
  //               Color randomBorderColor =
  //                   hasFocus ? generateRandomLightColor() : Colors.transparent;

  //               return Container(
  //                 margin: EdgeInsets.symmetric(horizontal: screenwdt * 0.02),
  //                 decoration: BoxDecoration(
  //                   color: hasFocus ? Colors.black : Colors.transparent,
  //                   boxShadow: [
  //                     if (hasFocus)
  //                       BoxShadow(
  //                         color: randomBorderColor
  //                         // .withOpacity(
  //                         // 0.8)
  //                         , // Adjust opacity for visibility
  //                         blurRadius:
  //                             15.0, // Reduced blur radius for sharper shadow
  //                         spreadRadius:
  //                             5.0, // Increased spread radius for more prominent shadow
  //                       ),
  //                   ],
  //                   borderRadius: BorderRadius.circular(8.0),
  //                   border: hasFocus
  //                       ? Border.all(
  //                           color:
  //                               randomBorderColor, // Same color as the shadow
  //                           width: 2.0, // Adjust border width as needed
  //                         )
  //                       : null, // No border when not focused
  //                 ),
  //                 child: SizedBox(
  //                   height: 40, // Adjust height to control button size
  //                   child: Center(
  //                     child: TextButton(
  //                       onPressed: _navigateToChannelsCategory,
  //                       child: Text(
  //                         'More',
  //                         style: TextStyle(
  //                           fontSize: menutextsz,
  //                           color: hasFocus ? randomBorderColor : hintColor,
  //                           fontWeight:
  //                               hasFocus ? FontWeight.bold : FontWeight.normal,
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               );
  //             },
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }



Widget _buildCategoryButtons() {
  return Container(
    // margin: EdgeInsets.symmetric(vertical: screenhgt * 0.015),
    height: screenhgt * 0.1, // Parent container height
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        ...categories.asMap().entries.map((entry) {
          int index = entry.key;
          String category = entry.value;

          return Focus(
            focusNode: categoryFocusNodes[category],
            onKey: (FocusNode node, RawKeyEvent event) {
              if (event is RawKeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                  if (index == categories.length - 1) {
                    FocusScope.of(context).requestFocus(moreFocusNode);
                  } else {
                    FocusScope.of(context).requestFocus(
                        categoryFocusNodes[categories[index + 1]]);
                  }
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                  if (index == 0) {
                    FocusScope.of(context).requestFocus(moreFocusNode);
                  } else {
                    FocusScope.of(context).requestFocus(
                        categoryFocusNodes[categories[index - 1]]);
                  }
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.select) {
                  _selectCategory(category);
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: Builder(
              builder: (BuildContext context) {
                final bool hasFocus = Focus.of(context).hasFocus;

                return Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: screenwdt * 0.019,
                    vertical: screenhgt * 0.015, // Add vertical margin for shadow space
                  ),
                  child: RandomLightColorWidget(
                    hasFocus: hasFocus,
                    childBuilder: (Color randomColor) {
                      return SizedBox(
                        height: screenhgt * 0.05, // Increase height to give space for shadow
                        child: Center(
                          child: TextButton(
                            onPressed: () => _selectCategory(category),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: menutextsz,
                                color: _selectedCategory == category
                                    ? borderColor
                                    : (hasFocus ? randomColor : hintColor),
                                fontWeight:
                                    _selectedCategory == category || hasFocus
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        }).toList(),

        // Add the "More" button back
        Focus(
          focusNode: moreFocusNode,
          onKey: (FocusNode node, RawKeyEvent event) {
            if (event is RawKeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                FocusScope.of(context)
                    .requestFocus(categoryFocusNodes[categories.first]);
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                FocusScope.of(context)
                    .requestFocus(categoryFocusNodes[categories.last]);

                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.select) {
                _navigateToChannelsCategory();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Builder(
            builder: (BuildContext context) {
              final bool hasFocus = Focus.of(context).hasFocus;

              return Container(
                margin: EdgeInsets.symmetric(
                  horizontal: screenwdt * 0.019,
                  vertical: screenhgt * 0.015, // Add vertical margin for shadow space
                ),
                child: RandomLightColorWidget(
                  hasFocus: hasFocus,
                  childBuilder: (Color randomColor) {
                    return SizedBox(
                      height: 40, // Adjust height to control button size
                      child: Center(
                        child: TextButton(
                          onPressed: _navigateToChannelsCategory,
                          child: Text(
                            'More',
                            style: TextStyle(
                              fontSize: menutextsz,
                              color: hasFocus ? randomColor : hintColor,
                              fontWeight:
                                  hasFocus ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}



  void _navigateToChannelsCategory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChannelsCategory(),
      ),
    );
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    fetchData();
  }

  Widget _buildBody() {
    if (_isLoading) {
      return LoadingIndicator();
    } else if (_errorMessage.isNotEmpty) {
      return ErrorMessage(message: _errorMessage);
    } else if (_entertainmentList.isEmpty) {
      return EmptyState(message: 'No items found for $_selectedCategory');
    } else {
      return _buildNewsList();
    }
  }

  Widget _buildNewsList() {
    int totalItems = _entertainmentList.length;
    bool showViewAll = totalItems > 10;

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: showViewAll ? 11 : totalItems,
      itemBuilder: (context, index) {
        if (showViewAll && index == 10) {
          return _buildViewAllItem();
        }
        return _buildNewsItem(_entertainmentList[index]);
      },
    );
  }

  Widget _buildViewAllItem() {
    return Focus(
      onKey: (FocusNode node, RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            // Prevent moving focus beyond "View All"
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: NewsItem(
        key: Key('view_all'),
        item: NewsItemModel(
          id: 'view_all',
          name: _selectedCategory.toUpperCase(),
          description: ' $_selectedCategory ',
          banner: '',
          url: '',
          streamType: '',
          genres: '',
          status: '',
        ),
        onTap: _navigateToViewAllScreen,
        onEnterPress: _handleEnterPress,
      ),
    );
  }

  Widget _buildNewsItem(NewsItemModel item) {
    return NewsItem(
      key: Key(item.id),
      hideDescription: true,
      item: item,
      onTap: () => _navigateToVideoScreen(item),
      onEnterPress: _handleEnterPress,
    );
  }

  void _handleEnterPress(String itemId) {
    if (itemId == 'view_all') {
      _navigateToViewAllScreen();
    } else {
      final selectedItem =
          _entertainmentList.firstWhere((item) => item.id == itemId);
      _navigateToVideoScreen(selectedItem);
    }
  }

  Future<void> _navigateToVideoScreen(NewsItemModel newsItem) async {
    if (_isNavigating) return;
    _isNavigating = true;

    bool shouldPlayVideo = true;
    bool shouldPop = true;

    // Show loading indicator while video is loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            shouldPlayVideo = false;
            shouldPop = false;
            return true;
          },
          child: LoadingIndicator(),
        );
      },
    );

    Timer(Duration(seconds: 10), () {
      _isNavigating = false;
    });

    try {
      if (newsItem.streamType == 'YoutubeLive') {
        // Retry fetching the updated URL if stream type is YouTube Live
        for (int i = 0; i < _maxRetries; i++) {
          try {
            String updatedUrl =
                await _socketService.getUpdatedUrl(newsItem.url);
            newsItem = NewsItemModel(
              id: newsItem.id,
              name: newsItem.name,
              description: newsItem.description,
              banner: newsItem.banner,
              url: updatedUrl,
              streamType: 'M3u8',
              genres: newsItem.genres,
              status: newsItem.status,
            );
            break; // Exit loop when URL is successfully updated
          } catch (e) {
            if (i == _maxRetries - 1) rethrow; // Rethrow error on last retry
            await Future.delayed(
                Duration(seconds: _retryDelay)); // Delay before next retry
          }
        }
      }

      if (shouldPop) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (shouldPlayVideo) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoScreen(
              videoUrl: newsItem.url,
              videoTitle: newsItem.name,
              channelList: _entertainmentList,
              genres: newsItem.genres,
              channels: [],
              initialIndex: 1,
              bannerImageUrl: newsItem.banner,
              startAtPosition: Duration.zero,
            ),
          ),
        );
      }
    } catch (e) {
      if (shouldPop) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something Went Wrong')),
      );
    } finally {
      _isNavigating = false;
    }
  }

  void _navigateToViewAllScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsGridScreen(newsList: _entertainmentList),
      ),
    );
  }

  @override
  void dispose() {
    _socketService.dispose();
    // Dispose focus nodes
    categoryFocusNodes.values.forEach((node) => node.dispose());
    super.dispose();
  }
}





