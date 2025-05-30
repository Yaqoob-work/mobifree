



// import 'dart:async';
// import 'dart:convert';
// import 'package:mobi_tv_entertainment/menu_screens/home_sub_screen/banner_slider_screen.dart';
// import 'package:mobi_tv_entertainment/menu_screens/home_sub_screen/sub_vod.dart';
// import 'package:mobi_tv_entertainment/video_widget/socket_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';


// import 'dart:async';
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';

// class ChannelUrlManager {
//   static final ChannelUrlManager _instance = ChannelUrlManager._internal();
//   final SocketService _socketService = SocketService();
//   Timer? _updateTimer;
//   static const String CACHE_KEY = 'channel_url_cache';
//   static const int CACHE_DURATION_HOURS = 5;
//   bool _isUpdating = false;
//   SharedPreferences? _prefs;
  
//   factory ChannelUrlManager() {
//     return _instance;
//   }
  
//   ChannelUrlManager._internal();

//   Future<void> initialize() async {
//     _prefs = await SharedPreferences.getInstance();
//     _startPeriodicUpdate();
//   }

//   void _startPeriodicUpdate() {
//     _updateTimer?.cancel();
//     _updateTimer = Timer.periodic(
//       Duration(hours: CACHE_DURATION_HOURS),
//       (_) => _updateAllChannels()
//     );
//   }

//   bool _needsUrlUpdate(dynamic channel, bool isBannerSlider, bool isVOD, String source) {
//     // For banner slider
//     if (isBannerSlider) {
//       return true; // Banner slider channels always need processing
//     }

//     // For YouTube content
//     if (channel.streamType == 'YoutubeLive' || 
//         channel.streamType == 'Youtube') {
//       return true;
//     }

//     // For content type 1 in search screen
//     if ((channel.contentType == '1' || channel.contentType == 1) && 
//         (source == 'isSearchScreen')) {
//       return true;
//     }

//     // For VOD content
//     if ((channel.contentType == '1' || channel.contentType == 1) && 
//         (isVOD || source == 'isSearchScreenViaDetailsPageChannelList')) {
//       return true;
//     }

//     return false; // Don't update URLs for other channel types
//   }

//   Future<void> updateChannelList({
//     required List<dynamic> channelList,
//     required bool isBannerSlider,
//     required bool isVOD,
//     required String source,
//   }) async {
//     if (_isUpdating) return;
//     _isUpdating = true;

//     try {
//       for (var channel in channelList) {
//         // Check if channel needs URL update
//         if (_needsUrlUpdate(channel, isBannerSlider, isVOD, source)) {
//           String? cachedUrl = await getUrlFromCache(channel.url);
//           if (cachedUrl == null) {
//             String updatedUrl = await _processChannel(
//               channel: channel,
//               isBannerSlider: isBannerSlider,
//               isVOD: isVOD,
//               source: source
//             );
//             if (updatedUrl.isNotEmpty && updatedUrl != channel.url) {
//               await saveUrlToCache(channel.url, updatedUrl);
//             }
//           }
//         }
//       }
//     } catch (e) {
//       print('Error updating channel list: $e');
//     } finally {
//       _isUpdating = false;
//     }
//   }

//   Future<String> _processChannel({
//     required dynamic channel,
//     required bool isBannerSlider,
//     required bool isVOD,
//     required String source,
//   }) async {
//     try {
//       String updatedUrl = channel.url;
//       final int contentId = int.tryParse(channel.id) ?? 0;

//       if (isBannerSlider) {
//         final playLink = await fetchLiveFeaturedTVById(channel.contentId);
//         if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
//           updatedUrl = playLink['url']!;
//           if (playLink['stream_type'] == 'YoutubeLive') {
//             updatedUrl = await _socketService.getUpdatedUrl(playLink['url']!);
//           }
//         }
//       } 
//       else if (channel.streamType == 'YoutubeLive' ||
//           channel.streamType == 'Youtube') {
//         String tempUrl = await _socketService.getUpdatedUrl(channel.url);
//         if (tempUrl.isNotEmpty) {
//           updatedUrl = tempUrl;
//         }
//       }

//       if (channel.contentType == '1' ||
//           (channel.contentType == 1 && source == 'isSearchScreen')) {
//         final playLink = await fetchMoviePlayLink(contentId);
//         if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
//           updatedUrl = playLink['url']!;
//           if (playLink['type'] == 'Youtube' ||
//               playLink['type'] == 'YoutubeLive' ||
//               playLink['content_type'] == '1' ||
//               playLink['content_type'] == 1) {
//             updatedUrl = await _socketService.getUpdatedUrl(playLink['url']!);
//           }
//         }
//       }

//       if (isVOD || source == 'isSearchScreenViaDetailsPageChannelList') {
//         if (channel.contentType == '1' || channel.contentType == 1) {
//           final playLink = await fetchMoviePlayLink(contentId);
//           if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
//             updatedUrl = playLink['url']!;
//             if (playLink['type'] == 'Youtube' ||
//                 playLink['type'] == 'YoutubeLive' ||
//                 playLink['content_type'] == '1' ||
//                 playLink['content_type'] == 1) {
//               updatedUrl = await _socketService.getUpdatedUrl(playLink['url']!);
//             }
//           }
//         }
//       }

//       return updatedUrl;
//     } catch (e) {
//       print('Error processing channel: ${channel.name} - $e');
//       return channel.url;
//     }
//   }

//   Future<void> saveUrlToCache(String originalUrl, String updatedUrl) async {
//     try {
//       final cache = await _loadCache();
//       cache[originalUrl] = {
//         'url': updatedUrl,
//         'timestamp': DateTime.now().toIso8601String()
//       };
//       await _prefs?.setString(CACHE_KEY, jsonEncode(cache));
//     } catch (e) {
//       print('Error saving to cache: $e');
//     }
//   }

//   Future<Map<String, dynamic>> _loadCache() async {
//     try {
//       final String? data = _prefs?.getString(CACHE_KEY);
//       if (data != null) {
//         return jsonDecode(data);
//       }
//     } catch (e) {
//       print('Error loading cache: $e');
//     }
//     return {};
//   }

//   Future<String?> getUrlFromCache(String originalUrl) async {
//     try {
//       final cache = await _loadCache();
//       if (cache.containsKey(originalUrl)) {
//         final entry = cache[originalUrl];
//         final timestamp = DateTime.parse(entry['timestamp']);
//         if (DateTime.now().difference(timestamp).inHours < CACHE_DURATION_HOURS) {
//           return entry['url'];
//         }
//       }
//     } catch (e) {
//       print('Error getting URL from cache: $e');
//     }
//     return null;
//   }

//   Future<void> _updateAllChannels() async {
//     if (_isUpdating) return;
//     _isUpdating = true;
    
//     try {
//       final cache = await _loadCache();
//       List<String> expiredKeys = [];
      
//       for (var key in cache.keys) {
//         final entry = cache[key];
//         final timestamp = DateTime.parse(entry['timestamp']);
//         if (DateTime.now().difference(timestamp).inHours >= CACHE_DURATION_HOURS) {
//           expiredKeys.add(key);
//         }
//       }
      
//       for (String key in expiredKeys) {
//         cache.remove(key);
//       }
      
//       await _prefs?.setString(CACHE_KEY, jsonEncode(cache));
//     } catch (e) {
//       print('Error in update all channels: $e');
//     } finally {
//       _isUpdating = false;
//     }
//   }
// }