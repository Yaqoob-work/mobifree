import 'package:flutter/material.dart';
import 'package:mobi_tv_entertainment/main.dart';
import 'package:mobi_tv_entertainment/provider/color_provider.dart';
import 'package:mobi_tv_entertainment/provider/focus_provider.dart';
import 'package:mobi_tv_entertainment/video_widget/socket_service.dart';
import 'package:mobi_tv_entertainment/widgets/small_widgets/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'home_sub_screen/banner_slider_screen.dart';
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
  final GlobalKey homeCategoryFirstBannerKey = GlobalKey();

  late FocusNode watchNowFocusNode;
  late FocusNode musicItemFocusNode;
  late FocusNode firstSubVodFocusNode;
  late FocusNode firstHomeCategoryFocusNode;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize focus nodes
    watchNowFocusNode = FocusNode();
    musicItemFocusNode = FocusNode();
    firstSubVodFocusNode = FocusNode();
    firstHomeCategoryFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final focusProvider = context.read<FocusProvider>();

      // Set focus nodes
      focusProvider.setWatchNowFocusNode(watchNowFocusNode);
      focusProvider.setFirstMusicItemFocusNode(musicItemFocusNode);
      focusProvider.setFirstSubVodFocusNode(firstSubVodFocusNode);

      context.read<FocusProvider>().registerElementKey('watchNow', watchNowKey);
      focusProvider.registerElementKey('musicItem', musicItemKey);
      focusProvider.registerElementKey('subVod', subVodKey);
      focusProvider.registerElementKey(
          'homeCategoryFirstBanner', homeCategoryFirstBannerKey);
    });
  }

  // @override
  // void dispose() {
  //   watchNowFocusNode.dispose();
  //   musicItemFocusNode.dispose();
  //   _socketService.dispose();
  //   super.dispose();
  // }

  @override
  void dispose() {
    final focusProvider = context.read<FocusProvider>();
    focusProvider.unregisterElementKey('watchNow');
    focusProvider.unregisterElementKey('musicItem');
    focusProvider.unregisterElementKey('subVod');
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ColorProvider>(builder: (context, colorProvider, child) {
      Color backgroundColor = colorProvider.isItemFocused
          ? colorProvider.dominantColor.withOpacity(0.5)
          : cardColor;

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
                    height: screenhgt * 4,
                    key: homeCategoryFirstBannerKey,
                    child: HomeCategory(
                        // focusNode: firstHomeCategoryFocusNode,
                        ),
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
