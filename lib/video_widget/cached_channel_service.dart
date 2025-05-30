// import 'dart:convert';
// import 'package:mobi_tv_entertainment/menu_screens/home_sub_screen/banner_slider_screen.dart';
// import 'package:mobi_tv_entertainment/menu_screens/home_sub_screen/home_category.dart';
// import 'package:mobi_tv_entertainment/menu_screens/home_sub_screen/sub_vod.dart';
// import 'package:mobi_tv_entertainment/video_widget/socket_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class CachedChannelService {
//   static final CachedChannelService _instance = CachedChannelService._internal();
//   final SocketService _socketService = SocketService();
//   Map<String, dynamic> _channelCache = {};

//   factory CachedChannelService() {
//     return _instance;
//   }

//   CachedChannelService._internal();

//   Future<void> initializeCache() async {
//     await _loadChannelCache();
//   }

//   Future<void> _loadChannelCache() async {
//     final prefs = await SharedPreferences.getInstance();
//     final cachedData = prefs.getString('channel_cache');
//     if (cachedData != null) {
//       _channelCache = json.decode(cachedData);
//     }
//   }

//   Future<void> _saveChannelCache() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('channel_cache', json.encode(_channelCache));
//   }

//   Future<List<dynamic>> getCachedChannelList(List<dynamic> originalChannelList, {
//     required bool isBannerSlider,
//     required bool isVOD,
//     required String source,
//   }) async {
//     List<dynamic> updatedChannelList = List.from(originalChannelList);
//     bool hasChanges = false;

//     for (int i = 0; i < updatedChannelList.length; i++) {
//       var channel = updatedChannelList[i];
//       String cacheKey = '${channel.id}_${channel.url}';

//       // Check if we have a valid cached version
//       if (_channelCache.containsKey(cacheKey)) {
//         updatedChannelList[i] = _channelCache[cacheKey];
//         continue;
//       }

//       try {
//         var updatedChannel = await _updateChannelUrl(
//           channel,
//           isBannerSlider: isBannerSlider,
//           isVOD: isVOD,
//           source: source,
//         );

//         if (updatedChannel != null) {
//           updatedChannelList[i] = updatedChannel;
//           _channelCache[cacheKey] = updatedChannel;
//           hasChanges = true;
//         }
//       } catch (e) {
//         print('Error updating channel $cacheKey: $e');
//         // Keep original channel on error
//         continue;
//       }
//     }

//     if (hasChanges) {
//       await _saveChannelCache();
//     }

//     return updatedChannelList;
//   }

//   Future<dynamic> _updateChannelUrl(dynamic channel, {
//     required bool isBannerSlider,
//     required bool isVOD,
//     required String source,
//   }) async {
//     String updatedUrl = channel.url;
//     bool needsUpdate = false;

//     try {
//       if (isBannerSlider) {
//         final playLink = await fetchLiveFeaturedTVById(channel.contentId);
//         if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
//           updatedUrl = playLink['url']!;
//           if (playLink['stream_type'] == 'YoutubeLive') {
//             updatedUrl = await _socketService.getUpdatedUrl(playLink['url']!);
//           }
//           needsUpdate = true;
//         }
//       } else if (channel.streamType == 'YoutubeLive' || channel.streamType == 'Youtube') {
//         updatedUrl = await _socketService.getUpdatedUrl(channel.url);
//         if (updatedUrl.isNotEmpty) {
//           needsUpdate = true;
//         }
//       }

//       if (channel.contentType == '1' || (channel.contentType == 1 && source == 'isSearchScreen')) {
//         final contentId = int.tryParse(channel.id) ?? 0;
//         final playLink = await fetchMoviePlayLink(contentId);
//         if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
//           updatedUrl = playLink['url']!;
//           if (playLink['type'] == 'Youtube' || 
//               playLink['type'] == 'YoutubeLive' || 
//               playLink['content_type'] == '1' || 
//               playLink['content_type'] == 1) {
//             updatedUrl = await _socketService.getUpdatedUrl(playLink['url']!);
//           }
//           needsUpdate = true;
//         }
//       }

//       if (isVOD || source == 'isSearchScreenViaDetailsPageChannelList') {
//         if (channel.contentType == '1' || channel.contentType == 1) {
//           final contentId = int.tryParse(channel.id) ?? 0;
//           final playLink = await fetchMoviePlayLink(contentId);
//           if (playLink['url'] != null && playLink['url']!.isNotEmpty) {
//             updatedUrl = playLink['url']!;
//             if (playLink['type'] == 'Youtube' || 
//                 playLink['type'] == 'YoutubeLive' || 
//                 playLink['content_type'] == '1' || 
//                 playLink['content_type'] == 1) {
//               updatedUrl = await _socketService.getUpdatedUrl(playLink['url']!);
//             }
//             needsUpdate = true;
//           }
//         }
//       }

//       if (needsUpdate) {
//         // Create a copy of the channel with the updated URL
//         return _updateChannelObject(channel, updatedUrl);
//       }
      
//       return channel;
//     } catch (e) {
//       print('Error updating channel URL: $e');
//       return null;
//     }
//   }

//   dynamic _updateChannelObject(dynamic originalChannel, String newUrl) {
//     // Create a deep copy of the channel object and update its URL
//     var channelCopy = Map<String, dynamic>.from(originalChannel.toJson());
//     channelCopy['url'] = newUrl;
//     return Channel.fromJson(channelCopy); // Assuming you have a Channel class
//   }

//   void clearCache() async {
//     _channelCache.clear();
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove('channel_cache');
//   }
// }