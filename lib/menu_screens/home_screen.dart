// import 'package:flutter/material.dart';
// import 'package:mobi_tv_entertainment/main.dart';
// import 'package:mobi_tv_entertainment/menu_screens/home_sub_screen/movies_screen.dart';
// import 'package:mobi_tv_entertainment/provider/color_provider.dart';
// import 'package:mobi_tv_entertainment/provider/focus_provider.dart';
// import 'package:mobi_tv_entertainment/video_widget/socket_service.dart';
// import 'package:mobi_tv_entertainment/widgets/small_widgets/loading_indicator.dart';
// import 'package:provider/provider.dart';
// import 'home_sub_screen/banner_slider_screen.dart';
// import 'home_sub_screen/manage_movies.dart';
// import 'home_sub_screen/music_screen.dart';
// import 'home_sub_screen/sub_vod.dart';
// import 'home_sub_screen/home_category.dart';

// void main() {
//   runApp(const HomeScreen());
// }

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({Key? key}) : super(key: key);

//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final SocketService _socketService = SocketService();
//   final GlobalKey watchNowKey = GlobalKey();
//   final GlobalKey musicItemKey = GlobalKey();
//   final GlobalKey subVodKey = GlobalKey();
//   final GlobalKey manageMoviesKey = GlobalKey();
//   final GlobalKey homeCategoryFirstBannerKey = GlobalKey();

//   late FocusNode watchNowFocusNode;
//   late FocusNode musicItemFocusNode;
//   late FocusNode firstSubVodFocusNode;
//   late FocusNode manageMoviesFocusNode;
//   late FocusNode firstHomeCategoryFocusNode;

//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();

//     // Initialize focus nodes
//     watchNowFocusNode = FocusNode();
//     musicItemFocusNode = FocusNode();
//     firstSubVodFocusNode = FocusNode();
//     manageMoviesFocusNode = FocusNode();
//     firstHomeCategoryFocusNode = FocusNode();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final focusProvider = context.read<FocusProvider>();

//       // Set focus nodes
//       focusProvider.setWatchNowFocusNode(watchNowFocusNode);
//       focusProvider.setFirstMusicItemFocusNode(musicItemFocusNode);
//       focusProvider.setFirstSubVodFocusNode(firstSubVodFocusNode);
//       focusProvider.setFirstSubVodFocusNode(manageMoviesFocusNode);

//       context.read<FocusProvider>().registerElementKey('watchNow', watchNowKey);
//       focusProvider.registerElementKey('musicItem', musicItemKey);
//       focusProvider.registerElementKey('subVod', subVodKey);
//       focusProvider.registerElementKey('manageMovies', manageMoviesKey);
//       focusProvider.registerElementKey(
//           'homeCategoryFirstBanner', homeCategoryFirstBannerKey);
//     });
//   }

//   // @override
//   // void dispose() {
//   //   watchNowFocusNode.dispose();
//   //   musicItemFocusNode.dispose();
//   //   _socketService.dispose();
//   //   super.dispose();
//   // }

//   @override
//   void dispose() {
//     final focusProvider = context.read<FocusProvider>();
//     focusProvider.unregisterElementKey('watchNow');
//     focusProvider.unregisterElementKey('musicItem');
//     focusProvider.unregisterElementKey('subVod');
//     focusProvider.unregisterElementKey('manageMovies');
//     context
//         .read<FocusProvider>()
//         .unregisterElementKey('homeCategoryFirstBanner');
//     // Clean up focus nodes
//     watchNowFocusNode.dispose();
//     musicItemFocusNode.dispose();
//     firstSubVodFocusNode.dispose();
//     firstHomeCategoryFocusNode.dispose();
//     _socketService.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<ColorProvider>(builder: (context, colorProvider, child) {
//       Color backgroundColor = colorProvider.isItemFocused
//           ? colorProvider.dominantColor.withOpacity(0.5)
//           : cardColor;

//       return Scaffold(
//         backgroundColor: backgroundColor,
//         body: Container(
//           width: screenwdt,
//           height: screenhgt,
//           color: cardColor,
//           child: SingleChildScrollView(
//             controller: context.read<FocusProvider>().scrollController,
//             child: Container(
//               margin: EdgeInsets.symmetric(horizontal: screenwdt * 0.03),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Container(
//                     height: screenhgt * 0.8,
//                     width: screenwdt,
//                     key: watchNowKey,
//                     child: BannerSlider(
//                       focusNode: watchNowFocusNode,
//                     ),
//                   ),
//                   Container(
//                     height: screenhgt * 0.5,
//                     key: musicItemKey,
//                     child: MusicScreen(
//                       focusNode: musicItemFocusNode,
//                     ),
//                   ),
//                   SizedBox(
//                     height: screenhgt * 0.5,
//                     key: subVodKey,
//                     child: SubVod(
//                       focusNode: firstSubVodFocusNode,
//                     ),
//                   ),
//                   SizedBox(
//                     // height: screenhgt * 0.5,
//                     // height: CategoryHeightCalculator.getHeight(),
//                     height: context.read<FocusProvider>().totalHeight,
//                     key: manageMoviesKey,
//                     child: ManageMovies(
//                       focusNode: manageMoviesFocusNode,
//                     ),
//                   ),
//                   // SizedBox(
//                   //   height: screenhgt * 0.5,
//                   //   key: GlobalKey(),
//                   //   child: MoviesScreen(
//                   //     focusNode: firstHomeCategoryFocusNode,
//                   //   ),
//                   // ),
//                   SizedBox(
//                     height: screenhgt * 4,
//                     key: homeCategoryFirstBannerKey,
//                     child: HomeCategory(
//                         // focusNode: firstHomeCategoryFocusNode,
//                         ),
//                   ),
//                   if (_isLoading) Center(child: LoadingIndicator()),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );
//     });
//   }
// }
import 'package:flutter/material.dart';
import 'package:mobi_tv_entertainment/main.dart';
import 'package:mobi_tv_entertainment/menu_screens/home_sub_screen/manage_webseries.dart';
import 'package:mobi_tv_entertainment/menu_screens/home_sub_screen/movies_screen.dart';
import 'package:mobi_tv_entertainment/provider/color_provider.dart';
import 'package:mobi_tv_entertainment/provider/focus_provider.dart';
import 'package:mobi_tv_entertainment/video_widget/socket_service.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'home_sub_screen/banner_slider_screen.dart';
import 'home_sub_screen/manage_movies.dart';
import 'home_sub_screen/music_screen.dart';
import 'home_sub_screen/sub_vod.dart';
import 'home_sub_screen/home_category.dart';

void main() {
  runApp(const HomeScreen());
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SocketService _socketService = SocketService();
  final GlobalKey watchNowKey = GlobalKey();
  final GlobalKey musicItemKey = GlobalKey();
  final GlobalKey subVodKey = GlobalKey();
  final GlobalKey manageMoviesKey = GlobalKey();
  final GlobalKey manageWebseriesKey = GlobalKey();
  final GlobalKey homeCategoryFirstBannerKey = GlobalKey();

  late FocusNode watchNowFocusNode;
  late FocusNode musicItemFocusNode;
  late FocusNode firstSubVodFocusNode;
  late FocusNode manageMoviesFocusNode;
  late FocusNode manageWebseriesFocusNode;
  late FocusNode firstHomeCategoryFocusNode;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize focus nodes
    watchNowFocusNode = FocusNode();
    musicItemFocusNode = FocusNode();
    firstSubVodFocusNode = FocusNode();
    manageMoviesFocusNode = FocusNode();
    manageWebseriesFocusNode = FocusNode();
    firstHomeCategoryFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final focusProvider = context.read<FocusProvider>();

      // Set focus nodes
      focusProvider.setWatchNowFocusNode(watchNowFocusNode);
      focusProvider.setFirstMusicItemFocusNode(musicItemFocusNode);
      focusProvider.setFirstSubVodFocusNode(firstSubVodFocusNode);
      focusProvider.setFirstSubVodFocusNode(manageMoviesFocusNode);
      focusProvider.setFirstSubVodFocusNode(manageWebseriesFocusNode);

      context.read<FocusProvider>().registerElementKey('watchNow', watchNowKey);
      focusProvider.registerElementKey('musicItem', musicItemKey);
      focusProvider.registerElementKey('subVod', subVodKey);
      focusProvider.registerElementKey('manageMovies', manageMoviesKey);
      focusProvider.registerElementKey('manageWebseries', manageMoviesKey);
      focusProvider.registerElementKey(
          'homeCategoryFirstBanner', homeCategoryFirstBannerKey);
    });
  }

  @override
  void dispose() {
    final focusProvider = context.read<FocusProvider>();
    focusProvider.unregisterElementKey('watchNow');
    focusProvider.unregisterElementKey('musicItem');
    focusProvider.unregisterElementKey('subVod');
    focusProvider.unregisterElementKey('manageMovies');
    focusProvider.unregisterElementKey('manageWebseries');
    context
        .read<FocusProvider>()
        .unregisterElementKey('homeCategoryFirstBanner');
    // Clean up focus nodes
    watchNowFocusNode.dispose();
    musicItemFocusNode.dispose();
    firstSubVodFocusNode.dispose();
    firstHomeCategoryFocusNode.dispose();
    _socketService.dispose();
    super.dispose();
  }

  // Calculate ManageMovies height based on category count
  double _calculateManageMoviesHeight(BuildContext context) {
    final focusProvider = context.watch<FocusProvider>();
    final int categoryCount = focusProvider.categoryCount;
    
    // Base height per category (adjust this value as needed)
    final double heightPerCategory = screenhgt * 0.45;
    
    // Calculate total height based on number of categories
    // Using a minimum of 1 category to avoid zero height
    final int effectiveCategoryCount = categoryCount > 0 ? categoryCount : 1;
    
    return heightPerCategory * effectiveCategoryCount;
  }
  // Calculate ManageMovies height based on category count
  double _calculateManageWebseriesHeight(BuildContext context) {
    final focusProvider = context.watch<FocusProvider>();
    final int categoryCount = focusProvider.categoryCount;
    
    // Base height per category (adjust this value as needed)
    final double heightPerCategory = screenhgt * 0.45;
    
    // Calculate total height based on number of categories
    // Using a minimum of 1 category to avoid zero height
    final int effectiveCategoryCount = categoryCount > 0 ? categoryCount : 1;
    
    return heightPerCategory * effectiveCategoryCount;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ColorProvider>(builder: (context, colorProvider, child) {
      Color backgroundColor = colorProvider.isItemFocused
          ? colorProvider.dominantColor.withOpacity(0.5)
          : cardColor;

      // Get the calculated height for ManageMovies
      final double manageMoviesHeight = _calculateManageMoviesHeight(context);
      final double manageWebseriesHeight = _calculateManageWebseriesHeight(context);

      return Scaffold(
        backgroundColor: backgroundColor,
        body: Container(
          width: screenwdt,
          height: screenhgt,
          color: cardColor,
          child: SingleChildScrollView(
            controller: context.read<FocusProvider>().scrollController,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: screenwdt * 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: screenhgt * 0.8,
                    width: screenwdt,
                    key: watchNowKey,
                    child: BannerSlider(
                      focusNode: watchNowFocusNode,
                    ),
                  ),
                  Container(
                    height: screenhgt * 0.5,
                    key: musicItemKey,
                    child: MusicScreen(
                      focusNode: musicItemFocusNode,
                    ),
                  ),
                  SizedBox(
                    height: screenhgt * 0.5,
                    key: subVodKey,
                    child: SubVod(
                      focusNode: firstSubVodFocusNode,
                    ),
                  ),
                  SizedBox(
                    // Use the dynamically calculated height based on category count
                    height: manageMoviesHeight,
                    key: manageMoviesKey,
                    child: ManageMovies(
                      focusNode: manageMoviesFocusNode,
                    ),
                  ),
                  SizedBox(
                    // Use the dynamically calculated height based on category count
                    height: manageWebseriesHeight,
                    key: manageWebseriesKey,
                    child: ManageWebseries(
                      focusNode: manageWebseriesFocusNode,
                    ),
                  ),
                  SizedBox(
                    height: screenhgt * 4,
                    key: homeCategoryFirstBannerKey,
                    child: HomeCategory(),
                  ),
                  if (_isLoading) Center(child: LoadingIndicator()),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}