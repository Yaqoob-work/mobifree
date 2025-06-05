





import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobi_tv_entertainment/main.dart';
import 'package:mobi_tv_entertainment/provider/color_provider.dart';
import 'package:mobi_tv_entertainment/provider/focus_provider.dart';
import 'package:mobi_tv_entertainment/widgets/models/news_item_model.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobi_tv_entertainment/widgets/utils/color_service.dart';
import 'package:mobi_tv_entertainment/widgets/focussable_item_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sub_vod.dart';

class Movies extends StatefulWidget {
  final Function(bool)? onFocusChange;
  final FocusNode focusNode;

  const Movies({Key? key, this.onFocusChange, required this.focusNode}) 
      : super(key: key);

  @override
  _MoviesState createState() => _MoviesState();
}

class _MoviesState extends State<Movies> {
  List<dynamic> moviesList = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final PaletteColorService _paletteColorService = PaletteColorService();
  Map<String, FocusNode> movieFocusNodes = {};
  final ScrollController _scrollController = ScrollController();
  FocusNode? _viewAllFocusNode;
  Color _viewAllColor = Colors.grey;
  bool _isNavigating = false;
  int _maxRetries = 3;
  int _retryDelay = 5; // seconds

  @override
  void initState() {
    super.initState();
    _viewAllFocusNode = FocusNode()
      ..addListener(() {
        if (_viewAllFocusNode!.hasFocus) {
          setState(() {
            _viewAllColor = Colors.primaries[Random().nextInt(Colors.primaries.length)];
          });
        }
      });
    _loadCachedDataAndFetchMovies();
  //    WidgetsBinding.instance.addPostFrameCallback((_) {
  //   if (moviesList.isNotEmpty) {
  //     final firstMovieId = moviesList[0]['id'];
  //     if (movieFocusNodes.containsKey(firstMovieId)) {
  //       // YAHAN SET KARO
  //       context.read<FocusProvider>().setFirstManageMoviesFocusNode(
  //         movieFocusNodes[firstMovieId]!
  //       );
  //       print('🎬 Registered Movies FocusNode: ${movieFocusNodes[firstMovieId]}');
  //     }
  //   }
  // });
  _initializeMovieFocusNodes();
  }


  void _registerMoviesFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final focusProvider = context.read<FocusProvider>();
      
      if (moviesList.isNotEmpty) {
        final firstMovieId = moviesList[0]['id'];
        if (movieFocusNodes.containsKey(firstMovieId)) {
          focusProvider.setFirstManageMoviesFocusNode(
            movieFocusNodes[firstMovieId]!
          );
        }
      }
      
      // Prepare webseries focus
      focusProvider.prepareWebseriesFocus();
    });
  }

  // Update this method
  void _initializeMovieFocusNodes() {
    movieFocusNodes.clear();
    for (var movie in moviesList) {
      movieFocusNodes[movie['id']] = FocusNode()
        ..addListener(() {
          if (movieFocusNodes[movie['id']]!.hasFocus) {
            _scrollToFocusedItem(movie['id']);
          }
        });
    }
    _registerMoviesFocus(); // Re-register after data load
  }

  Future<void> _loadCachedDataAndFetchMovies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Step 1: Load cached data
      await _loadCachedMoviesData();

      // Step 2: Fetch new data in the background and update UI if needed
      await _fetchMoviesInBackground();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load movies';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCachedMoviesData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedMovies = prefs.getString('movies_list');

      if (cachedMovies != null) {
        final List<dynamic> cachedData = json.decode(cachedMovies);
        setState(() {
          moviesList = cachedData;
          _initializeMovieFocusNodes();
          _isLoading = false; // Show cached data immediately
        });
      } else {
        // If no cached data, fetch from API immediately
        await _fetchMovies();
      }
    } catch (e) {
      print('Error loading cached movies data: $e');
      // If cache fails, try to fetch from API
      await _fetchMovies();
    }
  }

  Future<void> _fetchMoviesInBackground() async {
    try {
      // Fetch new data from API
      final response = await http.get(
        Uri.parse('https://mobifreetv.com/android/getAllMovies'),
        headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        
        // Sort data by API index if available
        if (data.isNotEmpty && data[0]['index'] != null) {
          data.sort((a, b) => a['index'].compareTo(b['index']));
        }

        // Compare with cached data
        final prefs = await SharedPreferences.getInstance();
        final cachedMovies = prefs.getString('movies_list');
        final String newMoviesJson = json.encode(data);

        if (cachedMovies == null || cachedMovies != newMoviesJson) {
          // Update cache if new data is different
          await prefs.setString('movies_list', newMoviesJson);

          // Update UI with new data
          setState(() {
            moviesList = data;
            _initializeMovieFocusNodes();
          });
        }
      }
    } catch (e) {
      print('Error fetching movies data: $e');
    }
  }

  Future<void> _fetchMovies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('https://mobifreetv.com/android/getAllMovies'),
        headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        
        // Sort data by API index if available
        if (data.isNotEmpty && data[0]['index'] != null) {
          data.sort((a, b) => a['index'].compareTo(b['index']));
        }

        // Save to cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('movies_list', json.encode(data));

        setState(() {
          moviesList = data;
          _initializeMovieFocusNodes();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load movies';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching data: $e';
        _isLoading = false;
      });
    }
  }



  void _scrollToFocusedItem(String itemId) {
    if (movieFocusNodes[itemId] != null && movieFocusNodes[itemId]!.hasFocus) {
      Scrollable.ensureVisible(
        movieFocusNodes[itemId]!.context!,
        alignment: 0.05,
        duration: Duration(milliseconds: 1000),
        curve: Curves.linear,
      );
    }
  }

  @override
  void dispose() {
    for (var node in movieFocusNodes.values) {
      node.dispose();
    }
    _viewAllFocusNode?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          SizedBox(height: screenhgt * 0.03),
          _buildTitle(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: screenwdt * 0.02),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'MOVIES',
            style: TextStyle(
              fontSize: menutextsz,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    } else if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage, style: TextStyle(color: Colors.white)));
    } else if (moviesList.isEmpty) {
      return Center(child: Text('No movies found', style: TextStyle(color: Colors.white)));
    } else {
      return _buildMoviesList();
    }
  }

  Widget _buildMoviesList() {
    bool showViewAll = moviesList.length > 7;
    return ListView.builder(
      
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      itemCount: showViewAll ? 8 : moviesList.length,
      itemBuilder: (context, index) {
        if (showViewAll && index == 7) {
          return _buildViewAllItem();
        }
        var movie = moviesList[index];
        return _buildMovieItem(movie, index);
      },
    );
  }

  Widget _buildViewAllItem() {
    bool isFocused = _viewAllFocusNode?.hasFocus ?? false;
    
    return Focus(
      focusNode: _viewAllFocusNode,
      onKey: (FocusNode node, RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            if (moviesList.isNotEmpty) {
              FocusScope.of(context).requestFocus(movieFocusNodes[moviesList[6]['id']]);
              return KeyEventResult.handled;
            }
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            context.read<FocusProvider>().requestSubVodFocus();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
// Also update the _buildViewAllItem arrow down handling:
  FocusScope.of(context).unfocus();
  print('⬇️ Arrow down pressed on Movie View All');
  
  Future.delayed(const Duration(milliseconds: 100), () {
    if (mounted) {
      context.read<FocusProvider>().requestFirstWebseriesFocus();
    }
  });
  return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.select) {
            _navigateToMoviesGrid();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: _navigateToMoviesGrid,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: MediaQuery.of(context).size.width * 0.19,
              height: isFocused 
                  ? MediaQuery.of(context).size.height * 0.22
                  : MediaQuery.of(context).size.height * 0.2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.0),
                color: Colors.grey[800],
                border: Border.all(
                  color: isFocused ? _viewAllColor : Colors.transparent,
                  width: 3.0,
                ),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: _viewAllColor,
                          blurRadius: 25.0,
                          spreadRadius: 10.0,
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
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'MOVIES',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8),
            Container(
              width: MediaQuery.of(context).size.width * 0.15,
              child: Text(
                'MOVIES',
                style: TextStyle(
                  color: isFocused ? _viewAllColor : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: nametextsz,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieItem(dynamic movie, int index) {
    movieFocusNodes.putIfAbsent(
      movie['id'],
      () => FocusNode()
        ..addListener(() {
          if (movieFocusNodes[movie['id']]!.hasFocus) {
            _scrollToFocusedItem(movie['id']);
          }
        }),
    );

    return Focus(
      focusNode: movieFocusNodes[movie['id']],
      onFocusChange: (hasFocus) async {
        if (hasFocus) {
          Color dominantColor = await _paletteColorService.getSecondaryColor(
            movie['poster'],
            fallbackColor: Colors.grey,
          );
          context.read<ColorProvider>().updateColor(dominantColor, true);
        } else {
          context.read<ColorProvider>().resetColor();
        }
      },
      // onKey: (FocusNode node, RawKeyEvent event) {
      //   if (event is RawKeyDownEvent) {
      //     if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      //       if (index < moviesList.length - 1 && index != 6) {
      //         FocusScope.of(context).requestFocus(movieFocusNodes[moviesList[index + 1]['id']]);
      //         return KeyEventResult.handled;
      //       } else if (index == 6 && moviesList.length > 7) {
      //         FocusScope.of(context).requestFocus(_viewAllFocusNode);
      //         return KeyEventResult.handled;
      //       }
      //     } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      //       if (index > 0) {
      //         FocusScope.of(context).requestFocus(movieFocusNodes[moviesList[index - 1]['id']]);
      //         return KeyEventResult.handled;
      //       }
      //     } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      //       context.read<FocusProvider>().requestSubVodFocus();
      //       return KeyEventResult.handled;
      //     } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      //       FocusScope.of(context).unfocus();
      //               print('⬇️ Arrow down pressed on Movie');
      //     context.read<FocusProvider>().requestFirstWebseriesFocus();
      //       return KeyEventResult.handled;
      //     } else if (event.logicalKey == LogicalKeyboardKey.select) {
      //       _handleMovieTap(movie);
      //       return KeyEventResult.handled;
      //     }
      //   }
      //   return KeyEventResult.ignored;
      // },

      onKey: (FocusNode node, RawKeyEvent event) {
  if (event is RawKeyDownEvent) {
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (index < moviesList.length - 1 && index != 6) {
        FocusScope.of(context).requestFocus(movieFocusNodes[moviesList[index + 1]['id']]);
        return KeyEventResult.handled;
      } else if (index == 6 && moviesList.length > 7) {
        FocusScope.of(context).requestFocus(_viewAllFocusNode);
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (index > 0) {
        FocusScope.of(context).requestFocus(movieFocusNodes[moviesList[index - 1]['id']]);
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      context.read<FocusProvider>().requestSubVodFocus();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      // Fix: Unfocus current and request webseries focus with delay
      FocusScope.of(context).unfocus();
      print('⬇️ Arrow down pressed on Movie');
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          context.read<FocusProvider>().requestFirstWebseriesFocus();
        }
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.select) {
      _handleMovieTap(movie);
      return KeyEventResult.handled;
    }
  }
  return KeyEventResult.ignored;
},
      child: GestureDetector(
        onTap: () => _handleMovieTap(movie),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMoviePoster(movie),
            SizedBox(height: 8),
            _buildMovieTitle(movie),
          ],
        ),
      ),
    );
  }

  Widget _buildMoviePoster(dynamic movie) {
    bool isFocused = movieFocusNodes[movie['id']]?.hasFocus ?? false;
    Color dominantColor = context.watch<ColorProvider>().dominantColor;

    return AnimatedContainer(
      curve: Curves.ease,
      width: MediaQuery.of(context).size.width * 0.19,
      height: isFocused
          ? MediaQuery.of(context).size.height * 0.22
          : MediaQuery.of(context).size.height * 0.2,
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        border: Border.all(
          color: isFocused ? dominantColor : Colors.transparent,
          width: 3.0,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                    color: dominantColor, blurRadius: 25.0, spreadRadius: 10.0)
              ]
            : [],
      ),
      child: CachedNetworkImage(
        imageUrl: movie['banner'],
        placeholder: (context, url) => Container(color: Colors.grey),
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildMovieTitle(dynamic movie) {
    bool isFocused = movieFocusNodes[movie['id']]?.hasFocus ?? false;
    Color dominantColor = context.watch<ColorProvider>().dominantColor;

    return Container(
      width: MediaQuery.of(context).size.width * 0.15,
      child: Text(
        movie['name'].toUpperCase(),
        style: TextStyle(
          fontSize: nametextsz,
          fontWeight: FontWeight.bold,
          color: isFocused ? dominantColor : Colors.white,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Future<void> _handleMovieTap(dynamic movie) async {
    if (_isNavigating) return;
    _isNavigating = true;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            _isNavigating = false;
            return true;
          },
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );

    try {
      // Convert all movies to NewsItemModel list
      List<NewsItemModel> allMovies = moviesList.map((m) => 
        NewsItemModel(
          id: m['id'],
          name: m['name'],
          banner: m['banner'],
          poster: m['poster'],
          description: m['description'] ?? '',
          url: m['url'] ?? '',
          streamType: m['streamType'] ?? '',
          type: m['type'] ?? '',
          genres: m['genres'] ?? '',
          status: m['status'] ?? '',
          videoId: m['videoId'] ?? '',
          index: m['index']?.toString() ?? '',
        )
      ).toList();

      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      // Navigate to details page
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailsPage(
            id: int.parse(movie['id']),
            channelList: allMovies,
            source: 'isMovieScreen',
            banner: movie['banner'],
            name: movie['name'],
          ),
        ),
      );
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      _isNavigating = false;
    }
  }

  void _navigateToMoviesGrid() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MoviesGridView(moviesList: moviesList),
      ),
    );
  }
}

class MoviesGridView extends StatefulWidget {
  final List<dynamic> moviesList;

  const MoviesGridView({Key? key, required this.moviesList}) : super(key: key);

  @override
  _MoviesGridViewState createState() => _MoviesGridViewState();
}

class _MoviesGridViewState extends State<MoviesGridView> {
  late Map<String, FocusNode> _movieFocusNodes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _movieFocusNodes = {
      for (var movie in widget.moviesList) movie['id']: FocusNode()
    };
  }

  @override
  void dispose() {
    for (var node in _movieFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GridView.builder(
            padding: EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemCount: widget.moviesList.length,
            itemBuilder: (context, index) {
              final movie = widget.moviesList[index];
              return FocusableItemWidget(
                imageUrl: movie['banner'],
                name: movie['name'],
                focusNode: _movieFocusNodes[movie['id']]!,
                onTap: () {
                  // Convert all movies to NewsItemModel list
                  List<NewsItemModel> allMovies = widget.moviesList.map((m) => 
                    NewsItemModel(
                      id: m['id'],
                      name: m['name'],
                      banner: m['banner'],
                      poster: m['poster'],
                      description: m['description'] ?? '',
                      url: m['url'] ?? '',
                      streamType: m['streamType'] ?? '',
                      type: m['type'] ?? '',
                      genres: m['genres'] ?? '',
                      status: m['status'] ?? '',
                      videoId: m['videoId'] ?? '',
                      index: m['index']?.toString() ?? '',
                    )
                  ).toList();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailsPage(
                        id: int.parse(movie['id']),
                        channelList: allMovies,
                        source: 'isMovieScreen',
                        banner: movie['banner'],
                        name: movie['name'],
                      ),
                    ),
                  );
                },
                fetchPaletteColor: (url) => PaletteColorService()
                    .getSecondaryColor(url),
              );
            },
          ),
          if (_isLoading) Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}