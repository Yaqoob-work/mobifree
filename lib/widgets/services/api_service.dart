import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_item_model.dart';

class ApiService {
  List<NewsItemModel> allChannelList = [];
  List<NewsItemModel> newsList = [];
  List<NewsItemModel> movieList = [];
  List<NewsItemModel> musicList = [];
  List<NewsItemModel> entertainmentList = [];
  List<NewsItemModel> religiousList = [];
  List<NewsItemModel> sportsList = [];
  List<int> allowedChannelIds = [];
  bool tvenableAll = false;

  Future<void> fetchSettings() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.ekomflix.com/android/getSettings'),
        headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
      );

      if (response.statusCode == 200) {
        final settingsData = json.decode(response.body);
        allowedChannelIds = List<int>.from(settingsData['channels']);
        tvenableAll = settingsData['tvenableAll'] == 1;
      } else {
        throw Exception('Failed to load settings');
      }
    } catch (e) {
      throw Exception('Error fetching settings: $e');
    }
  }

  Future<void> fetchEntertainment() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.ekomflix.com/android/getFeaturedLiveTV'),
        headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        allChannelList = responseData.where((channel) {
          int channelId = int.tryParse(channel['id'].toString()) ?? 0;
          String channelGenres = channel['status'].toString();
          String channelStatus = channel['status'].toString();

          return channelGenres.contains('1') &&
              channelStatus == "1" &&
              (tvenableAll || allowedChannelIds.contains(channelId));
        }).map((channel) => NewsItemModel.fromJson(channel)).toList();


        newsList = responseData.where((channel) {
          int channelId = int.tryParse(channel['id'].toString()) ?? 0;
          String channelGenres = channel['genres'].toString();
          String channelStatus = channel['status'].toString();

          return channelGenres.contains('News') &&
              channelStatus == "1" &&
              (tvenableAll || allowedChannelIds.contains(channelId));
        }).map((channel) => NewsItemModel.fromJson(channel)).toList();


        movieList = responseData.where((channel) {
          int channelId = int.tryParse(channel['id'].toString()) ?? 0;
          String channelGenres = channel['genres'].toString();
          String channelStatus = channel['status'].toString();

          return channelGenres.contains('Movie') &&
              channelStatus == "1" &&
              (tvenableAll || allowedChannelIds.contains(channelId));
        }).map((channel) => NewsItemModel.fromJson(channel)).toList();
        
        musicList = responseData.where((channel) {
          int channelId = int.tryParse(channel['id'].toString()) ?? 0;
          String channelGenres = channel['genres'].toString();
          String channelStatus = channel['status'].toString();

          return channelGenres.contains('Music') &&
              channelStatus == "1" &&
              (tvenableAll || allowedChannelIds.contains(channelId));
        }).map((channel) => NewsItemModel.fromJson(channel)).toList();
        
        
        entertainmentList = responseData.where((channel) {
          int channelId = int.tryParse(channel['id'].toString()) ?? 0;
          String channelGenres = channel['genres'].toString();
          String channelStatus = channel['status'].toString();

          return channelGenres.contains('Entertainment') &&
              channelStatus == "1" &&
              (tvenableAll || allowedChannelIds.contains(channelId));
        }).map((channel) => NewsItemModel.fromJson(channel)).toList();
        
        
        religiousList = responseData.where((channel) {
          int channelId = int.tryParse(channel['id'].toString()) ?? 0;
          String channelGenres = channel['genres'].toString();
          String channelStatus = channel['status'].toString();

          return channelGenres.contains('Religious') &&
              channelStatus == "1" &&
              (tvenableAll || allowedChannelIds.contains(channelId));
        }).map((channel) => NewsItemModel.fromJson(channel)).toList();
        
        
        sportsList = responseData.where((channel) {
          int channelId = int.tryParse(channel['id'].toString()) ?? 0;
          String channelGenres = channel['genres'].toString();
          String channelStatus = channel['status'].toString();

          return channelGenres.contains('Sports') &&
              channelStatus == "1" &&
              (tvenableAll || allowedChannelIds.contains(channelId));
        }).map((channel) => NewsItemModel.fromJson(channel)).toList();



      } else {
        throw Exception('Failed to load entertainment data');
      }
    } catch (e) {
      throw Exception('Error fetching entertainment data: $e');
    }
  }
}