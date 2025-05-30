import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobi_tv_entertainment/main.dart';
import 'package:mobi_tv_entertainment/menu_screens/home_sub_screen/sub_vod.dart';
import 'package:mobi_tv_entertainment/provider/focus_provider.dart';
import 'package:mobi_tv_entertainment/provider/color_provider.dart';
// import 'package:mobi_tv_entertainment/widgets/focussable_manage_movies_widget.dart';
import 'package:mobi_tv_entertainment/widgets/focussable_item_widget.dart';
import 'package:mobi_tv_entertainment/widgets/utils/color_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../../widgets/models/news_item_model.dart';

class ManageMovies extends StatefulWidget {
  const ManageMovies({Key? key, required this.focusNode}) : super(key: key);

  final FocusNode focusNode;

  @override
  State<ManageMovies> createState() => _ManageMoviesState();
}

class _ManageMoviesState extends State<ManageMovies>
    with AutomaticKeepAliveClientMixin {
  List<dynamic> categories = [];
  bool isLoading = true;
  String debugMessage = "";

  // Focus nodes for category items
  Map<String, Map<String, FocusNode>> focusNodesMap = {};

  // Track the current focused item's position
  int currentCategoryIndex = 0;
  int currentMovieIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    print("ManageMovies initState called");
    _fetchDataWithRetry();
  }

  Future<void> _fetchDataWithRetry() async {
    try {
      await fetchData();
    } catch (e) {
      print("Error en fetchData inicial: $e");
      // Intenta de nuevo después de un breve retraso
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          fetchData();
        }
      });
    }
  }

  @override
  void dispose() {
    print("ManageMovies dispose called");
    // Clean up all focus nodes
    for (var categoryNodes in focusNodesMap.values) {
      for (var node in categoryNodes.values) {
        node.dispose();
      }
    }
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      debugMessage = "Cargando datos...";
    });

    try {
      print("Fetching data from API...");
      final response = await http.get(
        Uri.parse('https://mobifreetv.com/android/manage_movies'),
        headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
      ).timeout(Duration(seconds: 15));

      print("API response status code: ${response.statusCode}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        print("API response received successfully");
        final responseBody = response.body;
        print("Response body length: ${responseBody.length}");

        if (responseBody.isEmpty) {
          setState(() {
            isLoading = false;
            debugMessage = "Response body is empty";
          });
          return;
        }

        try {
          final List<dynamic> data = jsonDecode(responseBody) as List<dynamic>;
          print("Parsed JSON data. Category count: ${data.length}");

          // Filter out empty categories
          List<dynamic> nonEmptyCategories = data.where((category) {
            if (!category.containsKey('movies')) {
              print("Category missing 'movies' key: $category");
              return false;
            }

            List<dynamic> movies = category['movies'] as List<dynamic>;
            print(
                "Category ${category['category'] ?? 'unknown'} has ${movies.length} movies");
            return movies.isNotEmpty;
          }).toList();

          print("Non-empty categories count: ${nonEmptyCategories.length}");

          // Update the category count in the provider
          if (mounted) {
            Provider.of<FocusProvider>(context, listen: false)
                .updateCategoryCountMovies(nonEmptyCategories.length);
          }

          // Initialize focus nodes for each movie in each category
          Map<String, Map<String, FocusNode>> newFocusNodesMap = {};
          for (int i = 0; i < nonEmptyCategories.length; i++) {
            final categoryId = '${nonEmptyCategories[i]['id']}';
            final movies = nonEmptyCategories[i]['movies'] as List<dynamic>;

            Map<String, FocusNode> movieFocusNodes = {};
            for (int j = 0; j < movies.length; j++) {
              final movieId = '${movies[j]['id']}';
              movieFocusNodes[movieId] = FocusNode();
            }

            newFocusNodesMap[categoryId] = movieFocusNodes;
          }

          if (mounted) {
            setState(() {
              categories = nonEmptyCategories;
              focusNodesMap = newFocusNodesMap;
              isLoading = false;
              debugMessage =
                  "Data loaded: ${nonEmptyCategories.length} categories";
            });
          }

          // // Set focus to the first item after a short delay
          // Future.delayed(Duration(milliseconds: 300), () {
          //   if (mounted && categories.isNotEmpty &&
          //       categories[0]['movies'] != null &&
          //       (categories[0]['movies'] as List).isNotEmpty) {
          //     final firstCategoryId = '${categories[0]['id']}';
          //     final firstMovieId = '${(categories[0]['movies'] as List)[0]['id']}';
          //     focusNodesMap[firstCategoryId]?[firstMovieId]?.requestFocus();
          //   }
          // });

          Future.delayed(Duration(milliseconds: 300), () {
            if (mounted &&
                categories.isNotEmpty &&
                categories[0]['movies'].isNotEmpty) {
              final firstCategoryId = '${categories[0]['id']}';
              final firstMovieId = '${categories[0]['movies'][0]['id']}';

              final firstNode = focusNodesMap[firstCategoryId]?[firstMovieId];
              if (firstNode != null) {
                Provider.of<FocusProvider>(context, listen: false)
                    .setFirstManageMoviesFocusNode(firstNode);
              }
            }
          });
        } catch (parseError) {
          print("JSON parse error: $parseError");
          if (mounted) {
            setState(() {
              isLoading = false;
              debugMessage = "JSON parse error: $parseError";
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
            debugMessage = "API error: ${response.statusCode}";
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Something Went Wrong')),
          );
        }
      }
    } catch (e) {
      print("Error fetching data: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          debugMessage = "Error: $e";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  // Navigate to the details page with the selected movie
  void navigateToDetails(dynamic movie, String source, String banner,
      String name, int categoryIndex) {
    try {
      // Convert the movies in the selected category to NewsItemModel list
      final List<dynamic> categoryMovies =
          categories[categoryIndex]['movies'] as List<dynamic>;
      final List<NewsItemModel> channelList = categoryMovies.map((movieItem) {
        return NewsItemModel(
          id: movieItem['id'],
          name: movieItem['name'],
          poster: movieItem['poster'],
          banner: movieItem['banner'],
          description: movieItem['description'] ?? '',
          category: source,
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
          builder: (context) => DetailsPage(
            id: int.parse(movie['id']),
            channelList: channelList,
            source: 'manage-movies',
            banner: banner,
            name: name,
          ),
        ),
      );
    } catch (e) {
      print('Navigation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navigation error: ${e.toString()}')),
      );
    }
  }

  // // Function to scroll to the focused item
  // void _scrollToFocusedItem(String categoryId, String movieId) {
  //   if (focusNodesMap[categoryId]?[movieId] == null ||
  //       !focusNodesMap[categoryId]![movieId]!.hasFocus) return;

  //   try {
  //     if (focusNodesMap[categoryId]![movieId]!.context != null) {
  //       Scrollable.ensureVisible(
  //         focusNodesMap[categoryId]![movieId]!.context!,
  //         alignment: 0.05,
  //         duration: Duration(milliseconds: 1000),
  //         curve: Curves.linear,
  //       );
  //     }
  //   } catch (e) {
  //     print("Error scrolling to focused item: $e");
  //   }
  // }

  void _scrollToFocusedItem(String categoryId, String movieId) {
    // सबसे पहले बेसिक नल चेक करें
    if (focusNodesMap[categoryId]?[movieId] == null ||
        !focusNodesMap[categoryId]![movieId]!.hasFocus) return;

    try {
      final focusNode = focusNodesMap[categoryId]![movieId];
      if (focusNode != null &&
          focusNode.context != null &&
          _scrollController.hasClients) {
        // BuildContext को सुरक्षित रूप से प्राप्त करें
        final BuildContext? context = focusNode.context;
        if (context != null && context.mounted) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.05,
            duration: Duration(milliseconds: 1000),
            curve: Curves.linear,
          );
        }
      }
    } catch (e) {
      print("Error scrolling to focused item: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<ColorProvider>(
      builder: (context, colorProvider, child) {
        // Use the same background color logic as in HomeCategory
        Color backgroundColor = colorProvider.isItemFocused
            ? colorProvider.dominantColor.withOpacity(0.3)
            : Colors.black;

        if (isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SpinKitFadingCircle(
                  color: Colors.black87,
                  size: 50.0,
                ),
                SizedBox(height: 20),
                Text(
                  debugMessage,
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        }

        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  '...',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          );
        }

        // Set the container background to match the HomeCategory style
        return Container(
          color: backgroundColor, // Use the background color from ColorProvider
          child: Container(
            color: Colors.black54,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  categories.length,
                  (categoryIndex) {
                    final category = categories[categoryIndex];
                    final movies = category['movies'] as List<dynamic>;
                    final categoryId = '${category['id']}';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(0.0),
                          child: Text(
                            category['category'].toUpperCase(),
                            style: TextStyle(
                              color: hintColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height *
                              0.34, // Increased height to accommodate expanded items
                          child: ListView.builder(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                movies.length > 7 ? 8 : movies.length + 1,
                            itemBuilder: (context, movieIndex) {
                              // Show "View All" option at the end
                              if ((movies.length >= 7 && movieIndex == 7) ||
                                  (movies.length < 7 &&
                                      movieIndex == movies.length)) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 0),
                                  child: ViewAllWidget(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CategoryMoviesGridView(
                                            category: category,
                                            movies: movies,
                                          ),
                                        ),
                                      );
                                    },
                                    categoryText:
                                        category['category'].toUpperCase(),
                                  ),
                                );
                              }

                              final movie = movies[movieIndex];
                              final movieId = '${movie['id']}';

                              // Get or create focus node for this movie
                              FocusNode? focusNode =
                                  focusNodesMap[categoryId]?[movieId];
                              if (focusNode == null) {
                                focusNode = FocusNode();
                                if (focusNodesMap[categoryId] == null) {
                                  focusNodesMap[categoryId] = {};
                                }
                                focusNodesMap[categoryId]![movieId] = focusNode;
                              }

                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: 0),
                                child: FocusableItemWidget(
                                  imageUrl: movie['poster'],
                                  name: movie['name'],
                                  focusNode: focusNode,
                                  onFocusChange: (hasFocus) {
                                    if (hasFocus) {
                                      _scrollToFocusedItem(categoryId, movieId);
                                    }
                                  },
                                  onTap: () {
                                    navigateToDetails(
                                      movie,
                                      category['category'],
                                      movie['banner'],
                                      movie['name'],
                                      categoryIndex,
                                    );
                                  },
                                  fetchPaletteColor: (String imageUrl) {
                                    return PaletteColorService()
                                        .getSecondaryColor(imageUrl);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ViewAllWidget implementation
class ViewAllWidget extends StatefulWidget {
  final VoidCallback onTap;
  final String categoryText;

  ViewAllWidget({required this.onTap, required this.categoryText});

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
                              'Movies',
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

// Grid View implementation
class CategoryMoviesGridView extends StatefulWidget {
  final dynamic category;
  final List<dynamic> movies;

  CategoryMoviesGridView({required this.category, required this.movies});

  @override
  _CategoryMoviesGridViewState createState() => _CategoryMoviesGridViewState();
}

class _CategoryMoviesGridViewState extends State<CategoryMoviesGridView> {
  bool _isLoading = false;
  Map<String, FocusNode> _movieFocusNodes = {};

  @override
  void initState() {
    super.initState();
    // Initialize focus nodes for all movies
    for (var movie in widget.movies) {
      _movieFocusNodes['${movie['id']}'] = FocusNode();
    }
  }

  @override
  void dispose() {
    for (var node in _movieFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_isLoading) {
      setState(() {
        _isLoading = false;
      });
      return false;
    }
    return true;
  }

  void navigateToDetails(dynamic movie, String categoryName) {
    try {
      // Convert the movies to NewsItemModel list
      final List<NewsItemModel> channelList = widget.movies.map((movieItem) {
        return NewsItemModel(
          id: movieItem['id'],
          name: movieItem['name'],
          poster: movieItem['poster'],
          banner: movieItem['banner'],
          description: movieItem['description'] ?? '',
          category: categoryName,
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
          builder: (context) => DetailsPage(
            id: int.parse(movie['id']),
            channelList: channelList,
            source: 'manage_movies',
            banner: movie['banner'],
            name: movie['name'],
          ),
        ),
      );
    } catch (e) {
      print('Navigation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navigation error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ColorProvider>(builder: (context, colorProvider, child) {
      Color backgroundColor = colorProvider.isItemFocused
          ? colorProvider.dominantColor.withOpacity(0.3)
          : Colors.black;

      return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: Stack(
            children: [
              GridView.builder(
                padding: EdgeInsets.all(20),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: widget.movies.length,
                itemBuilder: (context, index) {
                  final movie = widget.movies[index];
                  final movieId = '${movie['id']}';
                  return FocusableItemWidget(
                    imageUrl: movie['poster'],
                    name: movie['name'],
                    focusNode: _movieFocusNodes[movieId],
                    onTap: () {
                      setState(() {
                        _isLoading = true;
                      });
                      navigateToDetails(movie, widget.category['category']);
                      setState(() {
                        _isLoading = false;
                      });
                    },
                    fetchPaletteColor: (String imageUrl) {
                      return PaletteColorService().getSecondaryColor(imageUrl);
                    },
                  );
                },
              ),
              if (_isLoading)
                Center(
                  child: SpinKitFadingCircle(
                    color: Colors.blue,
                    size: 50.0,
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}
