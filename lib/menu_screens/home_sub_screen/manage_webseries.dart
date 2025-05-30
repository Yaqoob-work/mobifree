// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http;
// import 'package:mobi_tv_entertainment/main.dart';
// import 'package:mobi_tv_entertainment/menu_screens/home_sub_screen/sub_vod.dart';
// import 'package:mobi_tv_entertainment/menu_screens/home_sub_screen/webseries_details_page.dart';
// import 'package:mobi_tv_entertainment/provider/focus_provider.dart';
// import 'package:mobi_tv_entertainment/provider/color_provider.dart';
// // import 'package:mobi_tv_entertainment/widgets/focussable_manage_movies_widget.dart';
// import 'package:mobi_tv_entertainment/widgets/focussable_item_widget.dart';
// import 'package:mobi_tv_entertainment/widgets/utils/color_service.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:provider/provider.dart';
// import '../../widgets/models/news_item_model.dart';

// class ManageWebseries extends StatefulWidget {
//   const ManageWebseries({Key? key, required this.focusNode}) : super(key: key);

//   final FocusNode focusNode;

//   @override
//   State<ManageWebseries> createState() => _ManageWebseriesState();
// }

// class _ManageWebseriesState extends State<ManageWebseries> with AutomaticKeepAliveClientMixin {
//   List<dynamic> categories = [];
//   bool isLoading = true;
//   String debugMessage = "";

//   // Focus nodes for category items
//   Map<String, Map<String, FocusNode>> focusNodesMap = {};

//   // Track the current focused item's position
//   int currentCategoryIndex = 0;
//   int currentMovieIndex = 0;
//   final ScrollController _scrollController = ScrollController();

//   @override
//   bool get wantKeepAlive => true;

//   @override
//   void initState() {
//     super.initState();
//     print("ManageWebseries initState called");
//     _fetchDataWithRetry();
//   }

//   Future<void> _fetchDataWithRetry() async {
//     try {
//       await fetchData();
//     } catch (e) {
//       print("Error en fetchData inicial: $e");
//       // Intenta de nuevo después de un breve retraso
//       Future.delayed(Duration(seconds: 2), () {
//         if (mounted) {
//           fetchData();
//         }
//       });
//     }
//   }

//   @override
//   void dispose() {
//     print("ManageWebseries dispose called");
//     // Clean up all focus nodes
//     for (var categoryNodes in focusNodesMap.values) {
//       for (var node in categoryNodes.values) {
//         node.dispose();
//       }
//     }
//     _scrollController.dispose();
//     super.dispose();
//   }

//   Future<void> fetchData() async {
//     if (!mounted) return;

//     setState(() {
//       isLoading = true;
//       debugMessage = "Cargando datos...";
//     });

//     try {
//       print("Fetching data from API...");
//       final response = await http.get(
//         Uri.parse('https://mobifreetv.com/android/getAllWebSeries'),
//         headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
//       ).timeout(Duration(seconds: 15));

//       print("API response status code: ${response.statusCode}");

//       if (!mounted) return;

//       if (response.statusCode == 200) {
//         print("API response received successfully");
//         final responseBody = response.body;
//         print("Response body length: ${responseBody.length}");

//         if (responseBody.isEmpty) {
//           setState(() {
//             isLoading = false;
//             debugMessage = "Response body is empty";
//           });
//           return;
//         }

//         try {
//           final List<dynamic> data = jsonDecode(responseBody) as List<dynamic>;
//           print("Parsed JSON data. Category count: ${data.length}");

//           // Filter out empty categories
//           List<dynamic> nonEmptyCategories = data.where((category) {
//             if (!category.containsKey('web_series')) {
//               print("Category missing 'web_series' key: $category");
//               return false;
//             }

//             List<dynamic> web_series = category['web_series'] as List<dynamic>;
//             print("Category ${category['category'] ?? 'unknown'} has ${web_series.length} web_series");
//             return web_series.isNotEmpty;
//           }).toList();

//           print("Non-empty categories count: ${nonEmptyCategories.length}");

//           // Update the category count in the provider
//           if (mounted) {
//             Provider.of<FocusProvider>(context, listen: false)
//               .updateCategoryCountWebseries(nonEmptyCategories.length);
//           }

//           // Initialize focus nodes for each movie in each category
//           Map<String, Map<String, FocusNode>> newFocusNodesMap = {};
//           for (int i = 0; i < nonEmptyCategories.length; i++) {
//             final categoryId = '${nonEmptyCategories[i]['id']}';
//             final webSeries = nonEmptyCategories[i]['web_series'] as List<dynamic>;

//             Map<String, FocusNode> webSeriesFocusNodes = {};
//             for (int j = 0; j < webSeries.length; j++) {
//               final movieId = '${webSeries[j]['id']}';
//               webSeriesFocusNodes[movieId] = FocusNode();
//             }

//             newFocusNodesMap[categoryId] = webSeriesFocusNodes;
//           }

//           if (mounted) {
//             setState(() {
//               categories = nonEmptyCategories;
//               focusNodesMap = newFocusNodesMap;
//               isLoading = false;
//               debugMessage = "Data loaded: ${nonEmptyCategories.length} categories";
//             });
//           }

//           // // Set focus to the first item after a short delay
//           // Future.delayed(Duration(milliseconds: 300), () {
//           //   if (mounted && categories.isNotEmpty &&
//           //       categories[0]['movies'] != null &&
//           //       (categories[0]['movies'] as List).isNotEmpty) {
//           //     final firstCategoryId = '${categories[0]['id']}';
//           //     final firstMovieId = '${(categories[0]['movies'] as List)[0]['id']}';
//           //     focusNodesMap[firstCategoryId]?[firstMovieId]?.requestFocus();
//           //   }
//           // });

//           Future.delayed(Duration(milliseconds: 300), () {
//   if (mounted && categories.isNotEmpty && categories[0]['web_series'].isNotEmpty) {
//     final firstCategoryId = '${categories[0]['id']}';
//     final firstMovieId = '${categories[0]['web_series'][0]['id']}';

//     final firstNode = focusNodesMap[firstCategoryId]?[firstMovieId];
//     if (firstNode != null) {
//       Provider.of<FocusProvider>(context, listen: false)
//         .setFirstManageWebseriesFocusNode(firstNode);
//     }
//   }
// });

//         } catch (parseError) {
//           print("JSON parse error: $parseError");
//           if (mounted) {
//             setState(() {
//               isLoading = false;
//               debugMessage = "JSON parse error: $parseError";
//             });
//           }
//         }
//       } else {
//         if (mounted) {
//           setState(() {
//             isLoading = false;
//             debugMessage = "API error: ${response.statusCode}";
//           });
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Something Went Wrong')),
//           );
//         }
//       }
//     } catch (e) {
//       print("Error fetching data: $e");
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//           debugMessage = "Error: $e";
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   // // Navigate to the details page with the selected movie
//   // void navigateToDetails(dynamic movie, String source, String banner, String name, int categoryIndex) {
//   //   try {
//   //     // Convert the movies in the selected category to NewsItemModel list
//   //     final List<dynamic> categoryMovies = categories[categoryIndex]['web_series'] as List<dynamic>;
//   //     final List<NewsItemModel> channelList = categoryMovies.map((movieItem) {
//   //       return NewsItemModel(
//   //         id: movieItem['id'],
//   //         name: movieItem['name'],
//   //         poster: movieItem['poster'],
//   //         banner: movieItem['banner'],
//   //         description: movieItem['description'] ?? '',
//   //         category: source,
//   //         index: '',
//   //         url: '',
//   //         videoId: '',
//   //         streamType: '',
//   //         type: '',
//   //         genres: '',
//   //         status: '',
//   //       );
//   //     }).toList();

//   //     Navigator.push(
//   //       context,
//   //       MaterialPageRoute(
//   //         builder: (context) => DetailsPage(
//   //           id: int.parse(movie['id']),
//   //           channelList: channelList,
//   //           source: 'manage-web_series',
//   //           banner: banner,
//   //           name: name,
//   //         ),
//   //       ),
//   //     );
//   //   } catch (e) {
//   //     print('Navigation error: $e');
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(content: Text('Navigation error: ${e.toString()}')),
//   //     );
//   //   }
//   // }

// // Now, let's modify the navigateToDetails function in ManageWebseries class

// void navigateToDetails(dynamic movie, String source, String banner, String name, int categoryIndex) {
//   try {
//     // Convert the movies in the selected category to NewsItemModel list
//     final List<dynamic> categoryMovies = categories[categoryIndex]['web_series'] as List<dynamic>;
//     final List<NewsItemModel> channelList = categoryMovies.map((movieItem) {
//       return NewsItemModel(
//         id: movieItem['id'],
//         name: movieItem['name'],
//         poster: movieItem['poster'],
//         banner: movieItem['banner'],
//         description: movieItem['description'] ?? '',
//         category: source,
//         index: '',
//         url: '',
//         videoId: '',
//         streamType: '',
//         type: '',
//         genres: '',
//         status: '',
//       );
//     }).toList();

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => WebSeriesDetailsPage(
//           id: int.parse(movie['id']),
//           channelList: channelList,
//           source: 'manage-web_series',
//           banner: banner,
//           name: name,
//         ),
//       ),
//     );
//   } catch (e) {
//     print('Navigation error: $e');
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Navigation error: ${e.toString()}')),
//     );
//   }
// }

//   // // Function to scroll to the focused item
//   // void _scrollToFocusedItem(String categoryId, String movieId) {
//   //   if (focusNodesMap[categoryId]?[movieId] == null ||
//   //       !focusNodesMap[categoryId]![movieId]!.hasFocus) return;

//   //   try {
//   //     if (focusNodesMap[categoryId]![movieId]!.context != null) {
//   //       Scrollable.ensureVisible(
//   //         focusNodesMap[categoryId]![movieId]!.context!,
//   //         alignment: 0.05,
//   //         duration: Duration(milliseconds: 1000),
//   //         curve: Curves.linear,
//   //       );
//   //     }
//   //   } catch (e) {
//   //     print("Error scrolling to focused item: $e");
//   //   }
//   // }

// void _scrollToFocusedItem(String categoryId, String movieId) {
//   // सबसे पहले बेसिक नल चेक करें
//   if (focusNodesMap[categoryId]?[movieId] == null ||
//       !focusNodesMap[categoryId]![movieId]!.hasFocus) return;

//   try {
//     final focusNode = focusNodesMap[categoryId]![movieId];
//     if (focusNode != null &&
//         focusNode.context != null &&
//         _scrollController.hasClients) {

//       // BuildContext को सुरक्षित रूप से प्राप्त करें
//       final BuildContext? context = focusNode.context;
//       if (context != null && context.mounted) {
//         Scrollable.ensureVisible(
//           context,
//           alignment: 0.05,
//           duration: Duration(milliseconds: 1000),
//           curve: Curves.linear,
//         );
//       }
//     }
//   } catch (e) {
//     print("Error scrolling to focused item: $e");
//   }
// }

//   @override
//   Widget build(BuildContext context) {
//     super.build(context);

//     return Consumer<ColorProvider>(
//       builder: (context, colorProvider, child) {
//         // Use the same background color logic as in HomeCategory
//         Color backgroundColor = colorProvider.isItemFocused
//             ? colorProvider.dominantColor.withOpacity(0.3)
//             : Colors.black;

//         if (isLoading) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 SpinKitFadingCircle(
//                   color: Colors.black87 ,
//                   size: 50.0,
//                 ),
//                 SizedBox(height: 20),
//                 Text(
//                   debugMessage,
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ],
//             ),
//           );
//         }

//         if (categories.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 const Text(
//                   '...',
//                   style: TextStyle(color: Colors.white, fontSize: 18),
//                 ),
//               ],
//             ),
//           );
//         }

//         // Set the container background to match the HomeCategory style
//         return Container(
//           color: backgroundColor, // Use the background color from ColorProvider
//           child: Container(
//                   color: Colors.black54 ,

//             child: SingleChildScrollView(
//               physics: const BouncingScrollPhysics(),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: List.generate(
//                   categories.length,
//                   (categoryIndex) {
//                     final category = categories[categoryIndex];
//                     final web_series = category['web_series'] as List<dynamic>;
//                     final categoryId = '${category['id']}';

//                     return Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Padding(
//                           padding: const EdgeInsets.all(0.0),
//                           child: Text(
//                             category['category'].toUpperCase(),
//                             style: const TextStyle(
//                               color: Colors.grey,
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                         SizedBox(
//                           height: MediaQuery.of(context).size.height * 0.34, // Increased height to accommodate expanded items
//                           child: ListView.builder(
//                             controller: _scrollController,
//                             scrollDirection: Axis.horizontal,
//                             itemCount: web_series.length > 7 ? 8 : web_series.length + 1,
//                             itemBuilder: (context, movieIndex) {
//                               // Show "View All" option at the end
//                               if ((web_series.length >= 7 && movieIndex == 7) ||
//                                   (web_series.length < 7 && movieIndex == web_series.length)) {
//                                 return Padding(
//                                   padding: EdgeInsets.symmetric(horizontal: 0),
//                                   child: ViewAllWidget(
//                                     onTap: () {
//                                       Navigator.push(
//                                         context,
//                                         MaterialPageRoute(
//                                           builder: (context) => CategoryMoviesGridView(
//                                             category: category,
//                                             web_series: web_series,
//                                           ),
//                                         ),
//                                       );
//                                     },
//                                     categoryText: category['category'].toUpperCase(),
//                                   ),
//                                 );
//                               }

//                               final movie = web_series[movieIndex];
//                               final movieId = '${movie['id']}';

//                               // Get or create focus node for this movie
//                               FocusNode? focusNode = focusNodesMap[categoryId]?[movieId];
//                               if (focusNode == null) {
//                                 focusNode = FocusNode();
//                                 if (focusNodesMap[categoryId] == null) {
//                                   focusNodesMap[categoryId] = {};
//                                 }
//                                 focusNodesMap[categoryId]![movieId] = focusNode;
//                               }

//                               return Padding(
//                                 padding: EdgeInsets.symmetric(horizontal: 0),
//                                 child: FocusableItemWidget(
//                                   imageUrl: movie['poster'],
//                                   name: movie['name'],
//                                   focusNode: focusNode,
//                                   onFocusChange: (hasFocus) {
//                                     if (hasFocus) {
//                                       _scrollToFocusedItem(categoryId, movieId);
//                                     }
//                                   },
//                                   onTap: () {
//                                     navigateToDetails(
//                                       movie,
//                                       category['category'],
//                                       movie['banner'],
//                                       movie['name'],
//                                       categoryIndex,
//                                     );
//                                   },
//                                   fetchPaletteColor: (String imageUrl) {
//                                     return PaletteColorService().getSecondaryColor(imageUrl);
//                                   },
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                       ],
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// // ViewAllWidget implementation
// class ViewAllWidget extends StatefulWidget {
//   final VoidCallback onTap;
//   final String categoryText;

//   ViewAllWidget({required this.onTap, required this.categoryText});

//   @override
//   _ViewAllWidgetState createState() => _ViewAllWidgetState();
// }

// class _ViewAllWidgetState extends State<ViewAllWidget> {
//   bool isFocused = false;
//   Color focusColor = highlightColor;
//   FocusNode _focusNode = FocusNode();

//   @override
//   void initState() {
//     super.initState();
//     _focusNode.addListener(() {
//       setState(() {
//         isFocused = _focusNode.hasFocus;
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _focusNode.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final double normalHeight = screenhgt * 0.21;
//     final double focusedHeight = screenhgt * 0.24;
//     final double heightGrowth = focusedHeight - normalHeight;
//     final double verticalOffset = isFocused ? -(heightGrowth / 2) : 0;

//     return Focus(
//       focusNode: _focusNode,
//       onKey: (FocusNode node, RawKeyEvent event) {
//         if (event is RawKeyDownEvent) {
//           if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
//             return KeyEventResult.handled;
//           } else if (event.logicalKey == LogicalKeyboardKey.enter ||
//               event.logicalKey == LogicalKeyboardKey.select) {
//             widget.onTap();
//             return KeyEventResult.handled;
//           }
//         }
//         return KeyEventResult.ignored;
//       },
//       child: GestureDetector(
//         onTap: () {
//           widget.onTap();
//           _focusNode.requestFocus();
//         },
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // Using Stack for true bidirectional expansion
//             Container(
//               width: screenwdt * 0.19,
//               height: normalHeight, // Fixed container height is the normal height
//               child: Stack(
//                 clipBehavior: Clip.none, // Allow items to overflow the stack
//                 alignment: Alignment.center,
//                 children: [
//                   AnimatedPositioned(
//                     duration: const Duration(milliseconds: 400),
//                     top: isFocused ? -(heightGrowth / 2) : 0, // Move up when focused
//                     left: 0,
//                     width: screenwdt * 0.19,
//                     height: isFocused ? focusedHeight : normalHeight,
//                     child: Container(
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(4.0),
//                         border: isFocused
//                             ? Border.all(
//                                 color: focusColor,
//                                 width: 4.0,
//                               )
//                             : Border.all(
//                                 color: Colors.transparent,
//                                 width: 4.0,
//                               ),
//                         color: Colors.grey[800],
//                         boxShadow: isFocused
//                             ? [
//                                 BoxShadow(
//                                   color: focusColor,
//                                   blurRadius: 25,
//                                   spreadRadius: 10,
//                                 )
//                               ]
//                             : [],
//                       ),
//                       child: Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Text(
//                               'View All',
//                               style: TextStyle(
//                                 color: isFocused ? focusColor : hintColor,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                             Text(
//                               widget.categoryText,
//                               style: TextStyle(
//                                 color: isFocused ? focusColor : hintColor,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 15,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                             Text(
//                               'web_series',
//                               style: TextStyle(
//                                 color: isFocused ? focusColor : hintColor,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 10),
//             Container(
//               width: screenwdt * 0.17,
//               child: Column(
//                 children: [
//                   Text(
//                     (widget.categoryText),
//                     style: TextStyle(
//                       color: isFocused ? focusColor : Colors.grey,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 15,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                     maxLines: 1,
//                     textAlign: TextAlign.center,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // Grid View implementation
// class CategoryMoviesGridView extends StatefulWidget {
//   final dynamic category;
//   final List<dynamic> web_series;

//   CategoryMoviesGridView({
//     required this.category,
//     required this.web_series
//   });

//   @override
//   _CategoryMoviesGridViewState createState() => _CategoryMoviesGridViewState();
// }

// class _CategoryMoviesGridViewState extends State<CategoryMoviesGridView> {
//   bool _isLoading = false;
//   Map<String, FocusNode> _movieFocusNodes = {};

//   @override
//   void initState() {
//     super.initState();
//     // Initialize focus nodes for all movies
//     for (var movie in widget.web_series) {
//       _movieFocusNodes['${movie['id']}'] = FocusNode();
//     }
//   }

//   @override
//   void dispose() {
//     for (var node in _movieFocusNodes.values) {
//       node.dispose();
//     }
//     super.dispose();
//   }

//   Future<bool> _onWillPop() async {
//     if (_isLoading) {
//       setState(() {
//         _isLoading = false;
//       });
//       return false;
//     }
//     return true;
//   }

//   // void navigateToDetails(dynamic movie, String categoryName) {
//   //   try {
//   //     // Convert the movies to NewsItemModel list
//   //     final List<NewsItemModel> channelList = widget.web_series.map((movieItem) {
//   //       return NewsItemModel(
//   //         id: movieItem['id'],
//   //         name: movieItem['name'],
//   //         poster: movieItem['poster'],
//   //         banner: movieItem['banner'],
//   //         description: movieItem['description'] ?? '',
//   //         category: categoryName,
//   //         index: '',
//   //         url: '',
//   //         videoId: '',
//   //         streamType: '',
//   //         type: '',
//   //         genres: '',
//   //         status: '',
//   //       );
//   //     }).toList();

//   //     Navigator.push(
//   //       context,
//   //       MaterialPageRoute(
//   //         builder: (context) => DetailsPage(
//   //           id: int.parse(movie['id']),
//   //           channelList: channelList,
//   //           source: 'manage_web_series',
//   //           banner: movie['banner'],
//   //           name: movie['name'],
//   //         ),
//   //       ),
//   //     );
//   //   } catch (e) {
//   //     print('Navigation error: $e');
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(content: Text('Navigation error: ${e.toString()}')),
//   //     );
//   //   }
//   // }

// // Similarly, update the navigateToDetails function in CategoryMoviesGridView class
// void navigateToDetails(dynamic movie, String categoryName) {
//   try {
//     // Convert the movies to NewsItemModel list
//     final List<NewsItemModel> channelList = widget.web_series.map((movieItem) {
//       return NewsItemModel(
//         id: movieItem['id'],
//         name: movieItem['name'],
//         poster: movieItem['poster'],
//         banner: movieItem['banner'],
//         description: movieItem['description'] ?? '',
//         category: categoryName,
//         index: '',
//         url: '',
//         videoId: '',
//         streamType: '',
//         type: '',
//         genres: '',
//         status: '',
//       );
//     }).toList();

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => WebSeriesDetailsPage(
//           id: int.parse(movie['id']),
//           channelList: channelList,
//           source: 'manage_web_series',
//           banner: movie['banner'],
//           name: movie['name'],
//         ),
//       ),
//     );
//   } catch (e) {
//     print('Navigation error: $e');
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Navigation error: ${e.toString()}')),
//     );
//   }
// }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<ColorProvider>(builder: (context, colorProvider, child) {
//       Color backgroundColor = colorProvider.isItemFocused
//           ? colorProvider.dominantColor.withOpacity(0.3)
//           : Colors.black;

//       return WillPopScope(
//         onWillPop: _onWillPop,
//         child: Scaffold(
//           backgroundColor: backgroundColor,
//           body: Stack(
//             children: [
//               GridView.builder(
//                 padding: EdgeInsets.all(20),
//                 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 5,
//                   childAspectRatio: 0.7,
//                   crossAxisSpacing: 10,
//                   mainAxisSpacing: 10,
//                 ),
//                 itemCount: widget.web_series.length,
//                 itemBuilder: (context, index) {
//                   final web_series = widget.web_series[index];
//                   final web_seriesId = '${web_series['id']}';
//                   return FocusableItemWidget(
//                     imageUrl: web_series['poster'],
//                     name: web_series['name'],
//                     focusNode: _movieFocusNodes[web_seriesId],
//                     onTap: () {
//                       setState(() {
//                         _isLoading = true;
//                       });
//                       navigateToDetails(web_series, widget.category['category']);
//                       setState(() {
//                         _isLoading = false;
//                       });
//                     },
//                     fetchPaletteColor: (String imageUrl) {
//                       return PaletteColorService().getSecondaryColor(imageUrl);
//                     },
//                   );
//                 },
//               ),
//               if (_isLoading)
//                 Center(
//                   child: SpinKitFadingCircle(
//                     color: Colors.blue,
//                     size: 50.0,
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       );
//     });
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobi_tv_entertainment/main.dart';
import 'package:mobi_tv_entertainment/menu_screens/home_sub_screen/sub_vod.dart';
import 'package:mobi_tv_entertainment/menu_screens/home_sub_screen/webseries_details_page.dart';
import 'package:mobi_tv_entertainment/provider/focus_provider.dart';
import 'package:mobi_tv_entertainment/provider/color_provider.dart';
import 'package:mobi_tv_entertainment/widgets/focussable_item_widget.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/loading_indicator.dart';
import 'package:mobi_tv_entertainment/widgets/utils/color_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

import '../../widgets/models/news_item_model.dart';

class ManageWebseries extends StatefulWidget {
  final FocusNode focusNode;
  const ManageWebseries({Key? key, required this.focusNode}) : super(key: key);

  @override
  _ManageWebseriesState createState() => _ManageWebseriesState();
}

class _ManageWebseriesState extends State<ManageWebseries>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> categories = [];
  bool isLoading = true;
  String debugMessage = "";

  // categoryId → (seriesId → FocusNode)
  Map<String, Map<String, FocusNode>> focusNodesMap = {};
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchDataWithRetry();
  }

  Future<void> _fetchDataWithRetry() async {
    try {
      await fetchData();
    } catch (_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) fetchData();
      });
    }
  }

  @override
  void dispose() {
    for (var cat in focusNodesMap.values) {
      for (var node in cat.values) node.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      debugMessage = "Loading...";
    });

    try {
      final response = await http.get(
        Uri.parse('https://mobifreetv.com/android/getAllWebSeries'),
        headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        // 1. Decode flat list
        final List<dynamic> flatData = jsonDecode(response.body);

        // 2. Group by custom_tag.custom_tags_name
        final Map<String, List<dynamic>> grouped = {};
        for (var item in flatData) {
          final tagName = item['custom_tag']?['custom_tags_name'] ?? 'Unknown';
          grouped.putIfAbsent(tagName, () => []).add(item);
        }

        // 3. Shape into [{ id, category, web_series: […] }, …]
        final List<Map<String, dynamic>> nonEmptyCategories = grouped.entries
            .map((e) => {
                  'id': e.value.first['custom_tag']?['custom_tags_id'] ?? '0',
                  'category': e.key,
                  'web_series': e.value,
                })
            .toList();

        // 4. Update provider & build focus nodes
        Provider.of<FocusProvider>(context, listen: false)
            .updateCategoryCountWebseries(nonEmptyCategories.length);

        final Map<String, Map<String, FocusNode>> newFocusMap = {};
        for (var cat in nonEmptyCategories) {
          final cid = '${cat['id']}';
          newFocusMap[cid] = {
            for (var series in cat['web_series']) '${series['id']}': FocusNode()
          };
        }

        // 5. Set state
        setState(() {
          categories = nonEmptyCategories;
          focusNodesMap = newFocusMap;
          isLoading = false;
          debugMessage = "Loaded ${nonEmptyCategories.length} categories";
        });

        // 6. Give first item initial focus
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && categories.isNotEmpty) {
            final firstCid = '${categories[0]['id']}';
            final firstSid =
                '${(categories[0]['web_series'] as List).first['id']}';
            final node = focusNodesMap[firstCid]?[firstSid];
            if (node != null) {
              Provider.of<FocusProvider>(context, listen: false)
                  .setFirstManageWebseriesFocusNode(node);
            }
          }
        });
      } else {
        setState(() {
          isLoading = false;
          debugMessage = "Error: ${response.statusCode}";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        debugMessage = "Error: $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void navigateToDetails(
      dynamic movie, String source, String banner, String name, int idx) {
    final List<NewsItemModel> channelList =
        (categories[idx]['web_series'] as List<dynamic>)
            .map((m) => NewsItemModel(
                  id: m['id'],
                  name: m['name'],
                  poster: m['poster'],
                  banner: m['banner'],
                  description: m['description'] ?? '',
                  category: source,
                  index: '',
                  url: '',
                  videoId: '',
                  streamType: '',
                  type: '',
                  genres: '',
                  status: '',
                ))
            .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WebSeriesDetailsPage(
          id: int.parse(movie['id']),
          channelList: channelList,
          source: 'manage-web_series',
          banner: banner,
          name: name,
        ),
      ),
    );
  }

  void _scrollToFocusedItem(String catId, String seriesId) {
    final node = focusNodesMap[catId]?[seriesId];
    if (node?.hasFocus != true || !_scrollController.hasClients) return;
    final ctx = node!.context;
    if (ctx != null && mounted) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.05,
        duration: const Duration(milliseconds: 400),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // for AutomaticKeepAliveClientMixin
    return Consumer<ColorProvider>(
      builder: (context, colorProv, child) {
        final bgColor = colorProv.isItemFocused
            ? colorProv.dominantColor.withOpacity(0.3)
            : Colors.black;

        if (isLoading) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoadingIndicator(),
                const SizedBox(height: 12),
                Text(debugMessage, style: const TextStyle(color: Colors.white)),
              ],
            ),
          );
        }

        if (categories.isEmpty) {
          return const Center(
            child: Text('No Content', style: TextStyle(color: Colors.white)),
          );
        }

        return Container(
          color: bgColor,
          child: Container(
            color: Colors.black54,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: List.generate(categories.length, (catIdx) {
                  final cat = categories[catIdx];
                  final list = cat['web_series'] as List<dynamic>;
                  final catId = '${cat['id']}';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          cat['category'].toString().toUpperCase(),
                          style: TextStyle(
                            color: hintColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.34,
                        child: ListView.builder(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: list.length > 7 ? 8 : list.length + 1,
                          itemBuilder: (_, idx) {
                            if ((list.length >= 7 && idx == 7) ||
                                (list.length < 7 && idx == list.length)) {
                              return ViewAllWidget(
                                categoryText: cat['category'],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CategoryMoviesGridView(
                                        category: cat,
                                        web_series: list,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }

                            final item = list[idx];
                            final sid = '${item['id']}';
                            final node = focusNodesMap[catId]?[sid];

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: FocusableItemWidget(
                                imageUrl: item['poster'],
                                name: item['name'],
                                focusNode: node!,
                                onFocusChange: (hasFocus) {
                                  if (hasFocus)
                                    _scrollToFocusedItem(catId, sid);
                                },
                                onTap: () => navigateToDetails(
                                  item,
                                  cat['category'],
                                  item['banner'],
                                  item['name'],
                                  catIdx,
                                ),
                                fetchPaletteColor: (url) =>
                                    PaletteColorService()
                                        .getSecondaryColor(url),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ----------------------------------------------
// View All button at end of row
// ----------------------------------------------
class ViewAllWidget extends StatefulWidget {
  final VoidCallback onTap;
  final String categoryText;
  const ViewAllWidget({
    Key? key,
    required this.onTap,
    required this.categoryText,
  }) : super(key: key);

  @override
  _ViewAllWidgetState createState() => _ViewAllWidgetState();
}

class _ViewAllWidgetState extends State<ViewAllWidget> {
  bool isFocused = false;
  Color focusColor = highlightColor;
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double normalHeight = screenhgt * 0.21;
    final double focusedHeight = screenhgt * 0.24;
    final double heightGrowth = focusedHeight - normalHeight;
    final double verticalOffset = isFocused ? -(heightGrowth / 2) : 0;

    return Focus(
      focusNode: _focusNode,
      onKey: (FocusNode node, RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () {
          widget.onTap();
          _focusNode.requestFocus();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Using Stack for true bidirectional expansion
            Container(
              width: screenwdt * 0.19,
              height:
                  normalHeight, // Fixed container height is the normal height
              child: Stack(
                clipBehavior: Clip.none, // Allow items to overflow the stack
                alignment: Alignment.center,
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 400),
                    top: isFocused
                        ? -(heightGrowth / 2)
                        : 0, // Move up when focused
                    left: 0,
                    width: screenwdt * 0.19,
                    height: isFocused ? focusedHeight : normalHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.0),
                        border: isFocused
                            ? Border.all(
                                color: focusColor,
                                width: 4.0,
                              )
                            : Border.all(
                                color: Colors.transparent,
                                width: 4.0,
                              ),
                        color: Colors.grey[800],
                        boxShadow: isFocused
                            ? [
                                BoxShadow(
                                  color: focusColor,
                                  blurRadius: 25,
                                  spreadRadius: 10,
                                )
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'View All',
                              style: TextStyle(
                                color: isFocused ? focusColor : hintColor,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              widget.categoryText,
                              style: TextStyle(
                                color: isFocused ? focusColor : hintColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                overflow: TextOverflow.ellipsis,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'web_series',
                              style: TextStyle(
                                color: isFocused ? focusColor : hintColor,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Container(
              width: screenwdt * 0.17,
              child: Column(
                children: [
                  Text(
                    (widget.categoryText),
                    style: TextStyle(
                      color: isFocused ? focusColor : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------
// Full–screen grid when “View All” is tapped
// ----------------------------------------------
class CategoryMoviesGridView extends StatefulWidget {
  final Map<String, dynamic> category;
  final List<dynamic> web_series;
  const CategoryMoviesGridView({
    Key? key,
    required this.category,
    required this.web_series,
  }) : super(key: key);

  @override
  _CategoryMoviesGridViewState createState() => _CategoryMoviesGridViewState();
}

class _CategoryMoviesGridViewState extends State<CategoryMoviesGridView> {
  bool _isLoading = false;
  late Map<String, FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _nodes = {for (var m in widget.web_series) '${m['id']}': FocusNode()};
  }

  @override
  void dispose() {
    for (var node in _nodes.values) node.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_isLoading) {
      setState(() => _isLoading = false);
      return false;
    }
    return true;
  }

  void navigateToDetails(dynamic movie) {
    final channelList = widget.web_series.map((m) {
      return NewsItemModel(
        id: m['id'],
        name: m['name'],
        poster: m['poster'],
        banner: m['banner'],
        description: m['description'] ?? '',
        category: widget.category['category'],
        index: '',
        url: '',
        videoId: '',
        streamType: '',
        type: '',
        genres: '',
        status: '',
      );
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WebSeriesDetailsPage(
          id: int.parse(movie['id']),
          channelList: channelList,
          source: 'manage_web_series',
          banner: movie['banner'],
          name: movie['name'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.7,
              ),
              itemCount: widget.web_series.length,
              itemBuilder: (_, idx) {
                final m = widget.web_series[idx];
                final id = '${m['id']}';
                return FocusableItemWidget(
                  imageUrl: m['poster'],
                  name: m['name'],
                  focusNode: _nodes[id]!,
                  onTap: () {
                    setState(() => _isLoading = true);
                    navigateToDetails(m);
                    setState(() => _isLoading = false);
                  },
                  fetchPaletteColor: (url) =>
                      PaletteColorService().getSecondaryColor(url),
                );
              },
            ),
            if (_isLoading) Center(child: LoadingIndicator()),
          ],
        ),
      ),
    );
  }
}
