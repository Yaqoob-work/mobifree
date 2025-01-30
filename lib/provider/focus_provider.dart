
import 'package:flutter/material.dart';

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





  FocusNode? _searchIconFocusNode;

  void setSearchIconFocusNode(FocusNode focusNode) {
    _searchIconFocusNode = focusNode;
  }

  void requestSearchIconFocus() {
    if (_searchIconFocusNode != null && _searchIconFocusNode!.canRequestFocus) {
      _searchIconFocusNode!.requestFocus();
    }
  }


  // In focus_provider.dart
  void registerElementKey(String identifier, GlobalKey key) {
    _elementKeys[identifier] = key;
    notifyListeners();
  }

  void unregisterElementKey(String identifier) {
    _elementKeys.remove(identifier);
    notifyListeners();
  }

//   // In focus_provider.dart
//   void scrollToElement(String identifier) {
//     final key = _elementKeys[identifier];
//     if (key?.currentContext == null) {
//       print('Key for $identifier has no currentContext or is not assigned!');
//       return; // Exit early if key isn't valid
//     }
// print('Scrolling to $identifier');
//     Scrollable.ensureVisible(
//       key!.currentContext!,
//       alignment: 0.0,
//       duration: const Duration(milliseconds: 300),
//     );
//   }






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
      alignment: 0.0, // Align the element at the top
      duration: const Duration(milliseconds: 300), // Animation duration
      curve: Curves.easeInOut, // Smooth scrolling
    );
  } else {
    print('Context not found for $identifier!');
  }
}











 FocusNode? _firstMusicItemFocusNode;

  // Register focus node for the first music item
  // void setFirstMusicItemFocusNode(FocusNode focusNode) {
  //   _firstMusicItemFocusNode = focusNode;
  // }


    void setFirstMusicItemFocusNode(FocusNode node) {
    firstMusicItemFocusNode = node;
    node.addListener(() {
      if (node.hasFocus) {
        scrollToElement('musicItem');
      }
    });
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
       print("Requesting focus for first music item.");
       
      firstMusicItemFocusNode!.requestFocus();
      // FocusScope.of(context).requestFocus(_firstMusicItemFocusNode);
      resetFocus();
      scrollToElement('musicItem');
    }
  }


  



 void requestNewsItemFocusNode(FocusNode focusNode) {
    if (focusNode.canRequestFocus) {
      
      focusNode.requestFocus();
    }
  }
  



 FocusNode? _newsItemFocusNode;

  void registerNewsItemFocusNode(FocusNode node) {
    _newsItemFocusNode = node;
  }

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

  

  void requestSubVodFocus() {
    if (firstSubVodFocusNode != null) {
      setVodFirstBannerFocus(true); // Ensure scroll only happens when requested
      firstSubVodFocusNode!.requestFocus();
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

  @override
  void dispose() {
    scrollController.dispose();
    watchNowFocusNode?.dispose();
    firstLastPlayedFocusNode?.dispose();
    firstMusicItemFocusNode?.dispose();
    super.dispose();
  }
}