import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../video_widget/video_screen.dart';

class PopularNetworkListScreen extends StatefulWidget {
  @override
  _PopularNetworkListScreenState createState() =>
      _PopularNetworkListScreenState();
}

class _PopularNetworkListScreenState extends State<PopularNetworkListScreen> {
  List networks = [];

  @override
  void initState() {
    super.initState();
    fetchNetworks();
  }

  Future<void> fetchNetworks() async {
    final response = await http.get(
      Uri.parse('https://mobifreetv.com/android/getNetworks'),
      headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
    );

    if (response.statusCode == 200) {
      setState(() {
        networks = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load networks');
    }
  }

  void playVideo(String? videoUrl) {
    if (videoUrl != null && videoUrl.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoScreen(
            videoUrl: videoUrl,
            videoTitle: '',
            channelList: [],
            onFabFocusChanged: (bool) {},
            genres: '',url: '',
            playUrl: '',playVideo: (String id) {  },
          ),
        ),
      );
    } else {
      print('No video URL available');
      // Handle case where no video URL is available
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: networks.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: networks.length,
              itemBuilder: (context, index) {
                final network = networks[index];
                return GestureDetector(
                  onTap: () {
                    playVideo(network[
                        'url']); // Replace with your video URL field name
                  },
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.5,
                    color: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.network(
                          network['logo'],
                          width: MediaQuery.of(context).size.width * 0.2,
                        ),
                        SizedBox(
                            height:
                                1.0), // Add some space between image and text
                        Text(
                          network['name'],
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
