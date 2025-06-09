
import 'package:flutter/material.dart';
import 'package:mobi_tv_entertainment/main.dart';

class FocusProvider extends ChangeNotifier {
  // ScrollController for managing scroll position
  final ScrollController scrollController = ScrollController();

  // Focus state variables
  bool _isButtonFocused = false;
  bool _isLastPlayedFocused = false;
  bool _isVodfirstbannerFocussed = false;
  int _focusedVideoIndex = -1;
  Color? _currentFocusColor;

  // Focus nodes for navigation
  FocusNode? watchNowFocusNode;
  FocusNode? firstLastPlayedFocusNode;
  FocusNode? firstMusicItemFocusNode;
  FocusNode? firstSubVodFocusNode;

  // Store global keys for elements that need scrolling
  final Map<String, GlobalKey> _elementKeys = {};

  // Getters
  bool get isButtonFocused => _isButtonFocused;
  bool get isLastPlayedFocused => _isLastPlayedFocused;
  bool get isVodfirstbannerFocussed => _isVodfirstbannerFocussed;
  int get focusedVideoIndex => _focusedVideoIndex;
  Color? get currentFocusColor => _currentFocusColor;

  // // Register element keys for scrolling
  // void registerElementKey(String identifier, GlobalKey key) {
  //   _elementKeys[identifier] = key;
  // }


  


  FocusNode? _firstLastPlayedFocusNode;

  void setFirstLastPlayedFocusNode(FocusNode node) {
    _firstLastPlayedFocusNode = node;
  }

  void requestFirstLastPlayedFocus() {
    _firstLastPlayedFocusNode?.requestFocus();
    notifyListeners();
  }



  FocusNode? _firstSubVodFocusNode;

 FocusNode? _homeCategoryFirstItemFocusNode;

  FocusNode? getHomeCategoryFirstItemFocusNode() => _homeCategoryFirstItemFocusNode;

  void setHomeCategoryFirstItemFocusNode(FocusNode focusNode) {
    print("HomeCategory first item FocusNode registered");
    _homeCategoryFirstItemFocusNode = focusNode;
    notifyListeners();
  }

  void requestHomeCategoryFirstItemFocus() {
    if (_homeCategoryFirstItemFocusNode != null) {
      print("Requesting focus on HomeCategory first item");
      _homeCategoryFirstItemFocusNode!.requestFocus();
    } else {
      print("First HomeCategory FocusNode is not registered.");
    }
  }


  // 4. FocusProvider में scroll functionality add करें
ScrollController? _moviesScrollController;

void setMoviesScrollController(ScrollController controller) {
  _moviesScrollController = controller;
}

void _scrollToFirstMovieItem() {
  if (_moviesScrollController != null && _moviesScrollController!.hasClients) {
    _moviesScrollController!.animateTo(
      0.0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}



// 3. FocusProvider में ये method add करें (MusicScreen pattern follow करते हुए)
void requestFirstMoviesFocus() {
  if (_firstManageMoviesFocusNode != null) {
    // Pehle scroll करें first item को visible करने के लिए
    _scrollToFirstMovieItem();
    
    // Scroll के बाद focus request करें
    Future.delayed(const Duration(milliseconds: 150), () {
      _firstManageMoviesFocusNode!.requestFocus();
      print('🎯 Requested focus for first movie item');
      
      // Double ensure visibility
      Future.delayed(const Duration(milliseconds: 50), () {
        _scrollToFirstMovieItem();
      });
    });
  } else {
    print('⚠️ First movie focus node not available');
  }
}



// ScrollController? _moviesScrollController;

// void setMoviesScrollController(ScrollController controller) {
//   _moviesScrollController = controller;
// }

void requestManageMoviesFocusWithScroll() {
  // Pehle scroll करें
  if (_moviesScrollController?.hasClients == true) {
    _moviesScrollController!.animateTo(0.0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut);
  }
  
  // Phir focus request करें
  Future.delayed(Duration(milliseconds: 150), () {
    _firstManageMoviesFocusNode?.requestFocus();
  });
}

  


  FocusNode? _firstManageMoviesFocusNode;
  FocusNode? _firstManageWebseriesFocusNode;
  bool _webseriesFocusPrepared = false;

  // Movies focus management
  void setFirstManageMoviesFocusNode(FocusNode node) {
    _firstManageMoviesFocusNode = node;
     print('🎭 Set first webseries focus node: $node');
    notifyListeners();
  }

  void requestManageMoviesFocus() {
    if (_firstManageMoviesFocusNode != null) {
      _firstManageMoviesFocusNode!.requestFocus();
    }
  }

  // Webseries focus management
  void prepareWebseriesFocus() {
    _webseriesFocusPrepared = true;
    notifyListeners();
  }

  void setFirstManageWebseriesFocusNode(FocusNode node) {
    _firstManageWebseriesFocusNode = node;
    notifyListeners();
  }

    void requestFirstWebseriesFocus() {
    if (_firstManageWebseriesFocusNode != null) {
      print('🎭 Requesting focus on first webseries node');
      _firstManageWebseriesFocusNode!.requestFocus();
    } else {
      print('❌ First webseries focus node is null');
    }
  }

  // void requestFirstWebseriesFocus() {
  //   if (_firstManageWebseriesFocusNode != null) {
  //     _firstManageWebseriesFocusNode!.requestFocus();
  //   } 
  // }

  // Add this to clear focus nodes when not needed
  void clearWebseriesFocus() {
    _firstManageWebseriesFocusNode = null;
    _webseriesFocusPrepared = false;
  }







// // In FocusProvider:
// FocusNode? manageWebseriesFirstNode;
// void setFirstManageWebseriesFocusNode(FocusNode? node) {
//   manageWebseriesFirstNode = node;
// }
// void requestManageWebseriesFocus() {
//   // Try to request focus after a short delay so that widget is built
//   if (manageWebseriesFirstNode != null) {
//     Future.delayed(Duration(milliseconds: 30), () {
//       if (manageWebseriesFirstNode!.canRequestFocus) {
//         manageWebseriesFirstNode!.requestFocus();
//       }
//     });
//   }
// }



// // Add these to your existing FocusProvider class

// FocusNode? _firstManageWebseriesFocusNode;
// bool _isWebseriesReady = false;
// // final Map<String, GlobalKey> _elementKeys = {}; // This should already exist in your code

// // Set the first focus node for webseries
// void setFirstManageWebseriesFocusNode(FocusNode node) {
//   _firstManageWebseriesFocusNode?.dispose(); // Dispose old node if exists
//   _firstManageWebseriesFocusNode = node;
//   print("📺 setFirstManageWebseriesFocusNode: $node");

//   _isWebseriesReady = true;
//   print("✅ Webseries focus node registered: ${node.debugLabel}");
//   notifyListeners();
// }

// // Request focus on webseries with retry logic
// void requestManageWebseriesFocus() {
//   if (_firstManageWebseriesFocusNode != null && 
//       _firstManageWebseriesFocusNode!.context != null) {
//     print("🚀 Requesting focus on first webseries item");
//   print("📺 requestManageWebseriesFocus: $_firstManageWebseriesFocusNode");
//     _firstManageWebseriesFocusNode!.requestFocus();
    

//     scrollToElement('manageWebseries');
//   } else {
//     print("⚠️ First webseries focus node not available, scheduling retry");
//     _isWebseriesReady = false;
    
//     // Retry mechanism - removed 'mounted' check as it's not needed here
//     Future.delayed(Duration(milliseconds: 100), () {
//       if (!_isWebseriesReady) { // Removed 'mounted' check
//         print("🔄 Retrying webseries focus request");
//         requestManageWebseriesFocus();
//       }
//     });
//   }
// }



  FocusNode? _searchIconFocusNode;

  void setSearchIconFocusNode(FocusNode focusNode) {
    _searchIconFocusNode = focusNode;
  }

  void requestSearchIconFocus() {
    if (_searchIconFocusNode != null && _searchIconFocusNode!.canRequestFocus) {
      _searchIconFocusNode!.requestFocus();
    }
  }

  FocusNode? _youtubeSearchIconFocusNode;

  void setYoutubeSearchIconFocusNode(FocusNode focusNode) {
    _youtubeSearchIconFocusNode = focusNode;
  }

  void requestYoutubeSearchIconFocus() {
    if (_youtubeSearchIconFocusNode != null && _youtubeSearchIconFocusNode!.canRequestFocus) {
      _youtubeSearchIconFocusNode!.requestFocus();
    }
  }



    FocusNode? _searchNavigationFocusNode;

  void setSearchNavigationFocusNode(FocusNode node) {
    _searchNavigationFocusNode = node;
  }

  void requestSearchNavigationFocus() {
    _searchNavigationFocusNode?.requestFocus();
  }


  FocusNode? _youtubeSearchNavigationFocusNode;

  void setYoutubeSearchNavigationFocusNode(FocusNode node) {
    _youtubeSearchNavigationFocusNode = node;
  }

  void requestYoutubeSearchNavigationFocus() {
    _youtubeSearchNavigationFocusNode?.requestFocus();
  }


  // // In focus_provider.dart
  // void registerElementKey(String identifier, GlobalKey key) {
  //   _elementKeys[identifier] = key;
  //   notifyListeners();
  // }


  void registerElementKey(String identifier, GlobalKey key) {
    final bool isNewKey = _elementKeys[identifier] != key;
    _elementKeys[identifier] = key;
    if (isNewKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
}

  void unregisterElementKey(String identifier) {
    _elementKeys.remove(identifier);
    notifyListeners();
  }








void scrollToElement(String identifier) {
  // Fetch the key from _elementKeys
  final key = _elementKeys[identifier];

  if (key?.currentContext == null) {
    print('Key for $identifier has no currentContext or is not assigned!');
    return; // Exit early if key isn't valid
  }

  final BuildContext? context = key?.currentContext;
  if (context != null) {
    print('Scrolling to $identifier');
    Scrollable.ensureVisible(
      context,
      alignment: 0.15, // Align the element at the top
      duration: const Duration(milliseconds: 600), // Animation duration
      curve: Curves.linear, // Smooth scrolling
    );
  } else {
    print('Context not found for $identifier!');
  }
}



FocusNode? _homeCategoryFirstBannerFocusNode;

  void setHomeCategoryFirstBannerFocusNode(FocusNode focusNode) {
    _homeCategoryFirstBannerFocusNode = focusNode;
  }

  FocusNode? getHomeCategoryFirstBannerFocusNode() {
    return _homeCategoryFirstBannerFocusNode;
  }





 FocusNode? _firstMusicItemFocusNode;

  // Register focus node for the first music item
  // void setFirstMusicItemFocusNode(FocusNode focusNode) {
  //   _firstMusicItemFocusNode = focusNode;
  // }

  FocusNode? getFirstMusicItemFocusNode() {
    return _firstMusicItemFocusNode;
  }





    void setFirstMusicItemFocusNode(FocusNode node) {
      
    firstMusicItemFocusNode = node;
    print("🎯 FocusProvider: First music item focus node SET!");
    node.addListener(() {
      if (node.hasFocus) {
        scrollToElement('musicItem');
      }
    });
    notifyListeners();
  }



  // // Request focus for the first music item
  // void requestMusicItemFocuss(BuildContext context) {
  //   if (_firstMusicItemFocusNode != null) {
  //      print("Requesting focus for first music item.");
  //     FocusScope.of(context).requestFocus(_firstMusicItemFocusNode);
  //   }
  // }


  void requestMusicItemFocus(BuildContext context) {
  if (firstMusicItemFocusNode != null) {
    Future.delayed(Duration(milliseconds: 100), () {
      if (firstMusicItemFocusNode!.canRequestFocus) {
        print("🎯 Delayed Focus Request for First Music Item.");
        firstMusicItemFocusNode!.requestFocus();
              resetFocus();
      scrollToElement('musicItem');
      } else {
        print("⚠️ First Music Item FocusNode cannot request focus even after delay!");
      }
    });
  } else {
    print("⚠️ First Music Item FocusNode is NULL!");
  }
}


  
  // void requestMusicItemFocus(BuildContext context) {
  //   if (firstMusicItemFocusNode != null) {
  //      print("Requesting focus for first music item.");
       
  //     firstMusicItemFocusNode!.requestFocus();
  //     // FocusScope.of(context).requestFocus(_firstMusicItemFocusNode);
  //     resetFocus();
  //     scrollToElement('musicItem');
  //   }
  // }


  



 void requestNewsItemFocusNode(FocusNode focusNode) {
    if (focusNode.canRequestFocus) {
      
      focusNode.requestFocus();
    }
  }



   // News items ke focus nodes store karne ke liye map
  final Map<String, FocusNode> _newsItemFocusNodes = {};

  // Pehla focus node ka ID store karne ke liye variable
  String? _firstNewsItemId;

  // Register news item focus node
  void registerNewsItemFocusNode(String id, FocusNode node) {
    _newsItemFocusNodes[id] = node;
    _firstNewsItemId ??= id; // Pehla item ID store karein
    notifyListeners();
  }

  // Get news item focus node
  FocusNode? getNewsItemFocusNode(String id) {
    return _newsItemFocusNodes[id];
  }

  // Get first news item focus node
  FocusNode? getFirstNewsItemFocusNode() {
    if (_firstNewsItemId != null) {
      return _newsItemFocusNodes[_firstNewsItemId];
    }
    return null;
  }

  // Remove a focus node (optional)
  void unregisterNewsItemFocusNode(String id) {
    _newsItemFocusNodes.remove(id);
    notifyListeners();
  }
  







 FocusNode? _newsItemFocusNode;

  // void registerNewsItemFocusNode(FocusNode node) {
  //   _newsItemFocusNode = node;
  //   notifyListeners(); 
  // }

  void requestNewsItemFocus() {
    if (_newsItemFocusNode?.context != null) {
      _newsItemFocusNode?.requestFocus();
      print("Focus requested for news item.");
    } else {
      print("FocusNode is not ready.");
    }
  }

  

  FocusNode? firstItemFocusNode;

  // FocusProvider(FocusNode node) {
  //   liveScreenFocusNode = node;
  // }

  // void setLiveScreenFocusNode(FocusNode node) {
  //   liveScreenFocusNode = node;
  //   node.addListener(() {
  //     //   if (node.hasFocus) {
  //     //     scrollToElement('homeCategoryFirstBanner');
  //     //   }
  //   });
  // }

  // void requestLiveScreenFocus() {
  //   if (liveScreenFocusNode != null) {
  //     liveScreenFocusNode!.requestFocus();
  //     setLiveScreenFocusNode(liveScreenFocusNode!);
  //   }
  // }


  void setLiveScreenFocusNode(FocusNode node) {
    firstItemFocusNode = node;
}

void requestLiveScreenFocus() {
    if (firstItemFocusNode != null) {
        firstItemFocusNode!.requestFocus();
        if (firstItemFocusNode != null) {
            setLiveScreenFocusNode(firstItemFocusNode!);
        }

    }
}

  FocusNode? _liveTvFocusNode;

  void setLiveTvFocusNode(FocusNode node) {
    _liveTvFocusNode = node;
  }

  void requestLiveTvFocus() {
    _liveTvFocusNode?.requestFocus();
  }





  FocusNode? _VodMenuFocusNode;

  void setVodMenuFocusNode(FocusNode node) {
    _VodMenuFocusNode = node;
  }

  void requestVodMenuFocus() {
    _VodMenuFocusNode?.requestFocus();
  }


  // Focus node setters with scroll behavior
  void setWatchNowFocusNode(FocusNode node) {
    watchNowFocusNode = node;
    node.addListener(() {
      if (node.hasFocus) {
        scrollToElement('watchNow');
      }
    });
  }


    // Focus request methods with scroll behavior
  void requestWatchNowFocus() {
    if (watchNowFocusNode != null) {
      watchNowFocusNode!.requestFocus();
      setButtonFocus(true);
      scrollToElement('watchNow');
    }
  }

  // FocusNode? firstHomeCategoryFocusNode;

  // void setFirstHomeCategoryFocusNode(FocusNode node) {
  //   firstHomeCategoryFocusNode = node;
  //   node.addListener(() {
  //     if (node.hasFocus) {
  //       scrollToElement('homeCategoryFirstBanner');
  //     }
  //   });
  // }

  // void requestHomeCategoryFocus() {
  //   if (firstHomeCategoryFocusNode != null) {
  //     firstHomeCategoryFocusNode!.requestFocus();
  //     setFirstHomeCategoryFocusNode(firstHomeCategoryFocusNode!);

  //     scrollToElement('homeCategoryFirstBanner');
  //   } else {
  //     print("First HomeCategory FocusNode is not registered.");
  //   }
  // }


  

  FocusNode? firstVodBannerFocusNode;

  void setFirstVodBannerFocusNode(FocusNode node) {
    firstVodBannerFocusNode = node;
    node.addListener(() {
      // if (node.hasFocus) {
      //   scrollToElement('vodFirstBanner');
      // }
    });
  }

  void requestVodBannerFocus() {
    if (firstVodBannerFocusNode != null) {
      firstVodBannerFocusNode!.requestFocus();
      // scrollToElement('vodFirstBanner');
    } else {
      print("First Vod Banner FocusNode is not registered.");
    }
  }

  FocusNode? topNavigationFocusNode;

  void setTopNavigationFocusNode(FocusNode node) {
    topNavigationFocusNode = node;
  }

  void requestTopNavigationFocus() {
    if (topNavigationFocusNode != null) {
      topNavigationFocusNode!.requestFocus();
      setTopNavigationFocusNode(topNavigationFocusNode!);
      // scrollToElement('topNavigation'); // Optional, scroll if necessary

    } else {
      print("Top Navigation FocusNode is not registered.");
    }
  }



  void setFirstSubVodFocusNode(FocusNode node) {
    firstSubVodFocusNode = node;
    print("✅ FocusProvider: First SubVod focus node registered.");
    node.addListener(() {
      if (node.hasFocus) {
        // Only scroll if explicitly requested
        if (_isVodfirstbannerFocussed) {
          scrollToElement('subVod');
        }
      }
    });
  }

  void setVodFirstBannerFocus(bool focused) {
    _isVodfirstbannerFocussed = focused;
    notifyListeners();
  }





  void requestLastPlayedFocus() {
    if (firstLastPlayedFocusNode != null) {
      firstLastPlayedFocusNode!.requestFocus();
      setLastPlayedFocus(0);
      scrollToElement('lastPlayed');
    }
  }



  FocusNode? getFirstSubVodFocusNode() {
    return _firstSubVodFocusNode;
  }

  void requestSubVodFocus() {
    if (firstSubVodFocusNode != null) {
      setVodFirstBannerFocus(true); // Ensure scroll only happens when requested
      firstSubVodFocusNode!.requestFocus();
       print("✅ FocusProvider: First SubVod banner focus requested.");
      scrollToElement('subVod');
    } else {
      print("First SubVod FocusNode is not registered."); // Debug log
    }
  }

  // void requestSubVodFocus(BuildContext context) {
  //   if (firstSubVodFocusNode != null) {
  //     firstSubVodFocusNode!.requestFocus();
  //     setFirstSubVodFocusNode(firstSubVodFocusNode!);
  //     scrollToElement('subVod');

  //   } else {
  //     print("First SubVod FocusNode is not registered."); // Debug log
  //   }
  // }



  // Rest of the methods remain same
  void setButtonFocus(bool focused, {Color? color}) {
    _isButtonFocused = focused;
    if (focused) {
      _currentFocusColor = color;
      _isLastPlayedFocused = false;
      _focusedVideoIndex = -1;
    }
    notifyListeners();
  }

  void setLastPlayedFocus(int index) {
    _isLastPlayedFocused = true;
    _focusedVideoIndex = index;
    _isButtonFocused = false;
    notifyListeners();
  }

  void resetFocus() {
    _isButtonFocused = false;
    _isLastPlayedFocused = false;
    _focusedVideoIndex = -1;
    _currentFocusColor = null;
    notifyListeners();
  }

  // FocusNode? _subVodFocusNode;

  // FocusNode? get subVodFocusNode => _subVodFocusNode;

  void updateFocusColor(Color color) {
    _currentFocusColor = color;
    notifyListeners();
  }


  // Other existing properties and methods...
  
  // ScrollController for the main screen
  // final ScrollController scrollController = ScrollController();
  
  // Map to store element keys
  // final Map<String, GlobalKey> _elementKeys = {};
  
  // Focus nodes
  FocusNode? _watchNowFocusNode;
  // FocusNode? _firstMusicItemFocusNode;
  // FocusNode? _firstSubVodFocusNode;
  // FocusNode? _firstManageMoviesFocusNode;
  
  // Category count for ManageMovies
  int _categoryCountMovies = 0;
  
  // Height calculation for ManageMovies
  double _totalHeightMovies = 0.0;
  
  // Getters
  int get categoryCount => _categoryCountMovies;
  double get totalHeight => _totalHeightMovies;
  
  // Update category count from ManageMovies
  void updateCategoryCountMovies(int count) {
    _categoryCountMovies = count;
    
    // You might want to calculate total height here if needed
    // _totalHeight = count * someHeightPerCategory;
    
    notifyListeners();
  }

  // Category count for ManageMovies
  int _categoryCountWebseries = 0;
  
  // Height calculation for ManageMovies
  double _totalHeightWebseries = 0.0;
  
  // Getters
  int get categoryCountWebseries => _categoryCountWebseries;
  double get totalHeightWebseries => _totalHeightWebseries;
  
  // Update category count from ManageMovies
  void updateCategoryCountWebseries(int count) {
    _categoryCountWebseries = count;
    
    // You might want to calculate total height here if needed
    // _totalHeight = count * someHeightPerCategory;
    
    notifyListeners();
  }
  









  // FocusNode? firstManageMoviesFocusNode;

  // void setFirstManageMoviesFocusNode(FocusNode node) {
  //   firstManageMoviesFocusNode = node;
  //   notifyListeners();
  // }

  // void requestManageMoviesFocus() {
  //   firstManageMoviesFocusNode?.requestFocus();
  //     scrollToElement('manageMovies');
  // }



  // FocusNode? firstManageWebseriesFocusNode;

  // void setFirstManageWebseriesFocusNode(FocusNode node) {
  //   firstManageWebseriesFocusNode = node;
  //   notifyListeners();
  // }

  // void requestManageWebseriesFocus() {
  //   firstManageWebseriesFocusNode?.requestFocus();
  //     scrollToElement('manageWebseries');
  // }


  
  // Focus navigation methods and other functionality...


  @override
  void dispose() {
    scrollController.dispose();
    watchNowFocusNode?.dispose();
    firstLastPlayedFocusNode?.dispose();
    firstMusicItemFocusNode?.dispose();
    super.dispose();
  }
}