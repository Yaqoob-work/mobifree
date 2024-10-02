import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(child: Center(child: Text('Notification'),),);
  }
}




// import 'package:flutter/material.dart';
// import 'package:mobi_tv_entertainment/main.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../video_widget/video_screen.dart';

// class LastPlayedVideoScreen extends StatefulWidget {
//   @override
//   _LastPlayedVideoScreenState createState() => _LastPlayedVideoScreenState();
// }

// class _LastPlayedVideoScreenState extends State<LastPlayedVideoScreen> {
//   List<Map<String, dynamic>> lastPlayedVideos = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadLastPlayedVideos();
//   }

//   Future<void> _loadLastPlayedVideos() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     List<String>? storedVideos = prefs.getStringList('last_played_videos');

//     if (storedVideos != null && storedVideos.isNotEmpty) {
//       setState(() {
//         lastPlayedVideos = storedVideos.map((videoEntry) {
//           List<String> details = videoEntry.split('|');
//           print("Banner URL: ${details[2]}");

//           return {
//             'videoUrl': details[0], // Video URL
//             'position': Duration(milliseconds: int.parse(details[1])), // Playback position
//             'bannerImageUrl': details[2],  // Banner image URL
            
//           };
          
//         }).toList();
//       });
      
//     }
//   }

//   void _playVideo(String videoUrl, Duration position) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => VideoScreen(
//           videoUrl: videoUrl,
//           videoTitle: 'Last Played Video',
//           channelList: [],  
//           bannerImageUrl: '',  
//           startAtPosition: position, 
//           genres: '', 
//           channels: [], 
//           initialIndex: 1,  
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(

//       body: lastPlayedVideos.isEmpty
//           ? Center(child: Text('No last played videos available'))
//           : GridView.builder(
//   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//     crossAxisCount: 3,  // 3 videos per row
//     crossAxisSpacing: 10,
//     mainAxisSpacing: 10,
//     childAspectRatio: 16 / 9,
//   ),
//   itemCount: lastPlayedVideos.length,
//   itemBuilder: (context, index) {
//     Map<String, dynamic> videoData = lastPlayedVideos[index];
//     String bannerUrl = videoData['bannerImageUrl']??localImage;

//     return GestureDetector(
//       onTap: () => _playVideo(videoData['videoUrl'], videoData['position']),
//       child: GridTile(
//         child: Stack(
//           children: [
//             // Display the image using the banner URL
//             Image.network(
//               bannerUrl,
//               fit: BoxFit.cover,
//               width: double.infinity,
//               height: double.infinity,
//               errorBuilder: (context, error, stackTrace) {
//                 // Fallback image if the banner URL is invalid
//                 return Image.asset(
//                   'assets/logo.png',  // Use a valid path to your default image
//                   fit: BoxFit.cover,
//                   width: double.infinity,
//                   height: double.infinity,
//                 );
//               },
//             ),
//             Align(
//               alignment: Alignment.bottomCenter,
//               child: Container(
//                 color: Colors.black.withOpacity(0.5),
//                 padding: EdgeInsets.all(4),
//                 child: Text(
//                   'Last Played: ${videoData['position'].inMinutes} min',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   },
// )

//     );
//   }
// }
