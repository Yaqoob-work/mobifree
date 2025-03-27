import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobi_tv_entertainment/menu_screens/home_screen.dart';
import 'package:mobi_tv_entertainment/menu_screens/home_sub_screen/music_screen.dart';
import 'package:mobi_tv_entertainment/menu_screens/youtube_search_screen.dart';
import 'package:mobi_tv_entertainment/menu_screens/search_screen.dart';
import 'package:mobi_tv_entertainment/menu_screens/live_screen.dart';
import 'package:mobi_tv_entertainment/menu_screens/home_sub_screen/sub_vod.dart';
import 'package:provider/provider.dart';
import 'package:mobi_tv_entertainment/provider/color_provider.dart';
import 'package:mobi_tv_entertainment/provider/focus_provider.dart';
import 'package:mobi_tv_entertainment/provider/shared_data_provider.dart';

import 'main.dart';

// Router configuration
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

// Define your router
final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // Shell route for persistent navigation bar
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return TvScaffold(child: child);
      },
      routes: [
        // Home route
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => HomeScreen(),
        ),
        // VOD route
        GoRoute(
          path: '/vod',
          name: 'vod',
          builder: (context, state) => VOD(),
        ),
        // Live route
        GoRoute(
          path: '/live',
          name: 'live',
          builder: (context, state) => LiveScreen(),
        ),
        // Search route
        GoRoute(
          path: '/search',
          name: 'search',
          builder: (context, state) => SearchScreen(),
        ),
        // YouTube Search route
                GoRoute(
          path: '/music',
          name: 'music',
          builder: (context, state) => MusicScreen(focusNode: FocusNode()),
        ),
        GoRoute(
          path: '/youtube-search',
          name: 'youtube_search',
          builder: (context, state) => YoutubeSearchScreen(),
        ),
      ],
    ),
    
    // Detail routes that should be full-screen (outside of the shell)
    GoRoute(
      path: '/video/:id',
      name: 'video_detail',
      builder: (context, state) {
        final videoId = state.pathParameters['id'] ?? '';
        // Replace this with your actual video player screen
        return Scaffold(
          body: Center(
            child: Text('Video Player for ID: $videoId'),
          ),
        );
      },
    ),
  ],
);

// Scaffold with TV navigation
class TvScaffold extends StatefulWidget {
  final Widget child;
  
  const TvScaffold({Key? key, required this.child}) : super(key: key);
  
  @override
  _TvScaffoldState createState() => _TvScaffoldState();
}

class _TvScaffoldState extends State<TvScaffold> {
  int _selectedIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    // Get the current route location
    final location = GoRouterState.of(context).matchedLocation;
    
    // Set the selected index based on the current route
    if (location == '/') _selectedIndex = 0;
    else if (location == '/vod') _selectedIndex = 1;
    else if (location == '/live') _selectedIndex = 2;
    else if (location == '/search') _selectedIndex = 3;
    else if (location == '/youtube-search') _selectedIndex = 4;
    
    return Consumer<ColorProvider>(
      builder: (context, colorProvider, child) {
        // Get background color based on provider state
        Color backgroundColor = colorProvider.isItemFocused
          ? colorProvider.dominantColor.withOpacity(0.5)
          : cardColor;
          
        return SafeArea(
          child: Scaffold(
            body: Container(
              color: backgroundColor,
              child: Column(
                children: [
                  // TV Navigation bar with focus handling
                  TVNavigationBar(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                      
                      // Navigate based on the selected index
                      switch (index) {
                        case 0:
                          context.go('/');
                          break;
                        case 1:
                          context.go('/vod');
                          break;
                        case 2:
                          context.go('/live');
                          break;
                        case 3:
                          context.go('/search');
                          break;
                        case 4:
                          context.go('/youtube-search');
                          break;
                      }
                    },
                  ),
                  
                  // Content area
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Simplified TV Navigation Bar
class TVNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  
  const TVNavigationBar({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(context, 0, 'Home', Icons.home),
          _buildNavItem(context, 1, 'VOD', Icons.video_library),
          _buildNavItem(context, 2, 'Live', Icons.live_tv),
          _buildNavItem(context, 3, 'Search', Icons.search),
          _buildNavItem(context, 4, 'YouTube', Icons.youtube_searched_for),
        ],
      ),
    );
  }
  
  Widget _buildNavItem(BuildContext context, int index, String label, IconData icon) {
    final isFocused = index == selectedIndex;
    
    return Consumer<FocusProvider>(
      builder: (context, focusProvider, child) {
        return Focus(
          onFocusChange: (hasFocus) {
            if (hasFocus) {
              // focusProvider.setCurrentFocusIndex(index);
            }
          },
          child: GestureDetector(
            onTap: () => onDestinationSelected(index),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isFocused ? highlightColor : Colors.transparent,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isFocused ? Colors.white : Colors.grey,
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: isFocused ? Colors.white : Colors.grey,
                      fontSize: menutextsz,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}