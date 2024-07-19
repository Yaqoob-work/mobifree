import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobi_tv_entertainment/home_sub_screen/network_category.dart';
import 'package:mobi_tv_entertainment/main.dart';

class Network extends StatefulWidget {
  @override
  _NetworkState createState() => _NetworkState();
}

class _NetworkState extends State<Network> {
  List networks = [];
  bool isLoading = true; // Add a loading flag
  FocusNode fabFocusNode = FocusNode(); // FocusNode for FAB
  List<FocusNode> bannerFocusNodes = []; // List of FocusNodes for banners

  @override
  void initState() {
    super.initState();
    fetchNetworks();
  }

  Future<void> fetchNetworks() async {
    try {
      final response = await http.get(
        Uri.parse('https://mobifreetv.com/android/getNetworks'),
        headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
      );

      if (response.statusCode == 200) {
        setState(() {
          networks = json.decode(response.body);
          bannerFocusNodes = List<FocusNode>.generate(networks.length, (index) => FocusNode());
          isLoading = false; // Set loading to false when data is fetched
        });
      } else {
        throw Exception('Failed to load networks');
      }
    } catch (error) {
      print('Error fetching networks: $error');
      setState(() {
        isLoading = false; // Set loading to false even if there is an error
      });
    }
  }

  @override
  void dispose() {
    fabFocusNode.dispose(); // Dispose the focus node
    bannerFocusNodes.forEach((node) => node.dispose()); // Dispose banner focus nodes
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : networks.isEmpty
              ? Center(child: Text('No networks available'))
              : Stack(
                  children: [
                    ListView.builder(
                      itemCount: networks.length,
                      itemBuilder: (context, index) {
                        final network = networks[index];
                        return Focus(
                          focusNode: bannerFocusNodes[index],
                          onFocusChange: (hasFocus) {
                            setState(() {}); // Rebuild to update the focused state
                          },
                          onKey: (node, event) {
                            if (event is RawKeyDownEvent) {
                              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                                if (index == networks.length - 1) {
                                  fabFocusNode.requestFocus();
                                  return KeyEventResult.handled;
                                }
                              }
                              if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                                if (index == 0) {
                                  fabFocusNode.requestFocus();
                                  return KeyEventResult.handled;
                                }
                              }
                            }
                            return KeyEventResult.ignored;
                          },
                          child: GestureDetector(
                            onTap: () {
                              // Handle tap on network banner
                            },
                            child: Container(
                              height: MediaQuery.of(context).size.height,
                              padding: EdgeInsets.symmetric(vertical: 10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      network['name'] ?? '',
                                      style: TextStyle(
                                        color: AppColors.hintColor,
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Image.network(
                                      network['logo'] ?? '',
                                      fit: BoxFit.contain,
                                      width: MediaQuery.of(context).size.width * 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      left: 16.0,
                      bottom: 16.0,
                      child: Focus(
                        focusNode: fabFocusNode,
                        onFocusChange: (hasFocus) {
                          setState(() {}); // Rebuild to update the focused state
                        },
                        onKey: (node, event) {
                          if (event is RawKeyDownEvent) {
                            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                              if (bannerFocusNodes.isNotEmpty) {
                                bannerFocusNodes[0].requestFocus();
                                return KeyEventResult.handled;
                              }
                            }
                            if (event.logicalKey == LogicalKeyboardKey.select) {
                              // Handle select action when FAB is focused
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => NetworkCategory()), // Navigate to NetworkCategory
                              );
                              return KeyEventResult.handled;
                            }
                          }
                          return KeyEventResult.ignored;
                        },
                        child: FocusableActionDetector(
                          onFocusChange: (hasFocus) {
                            setState(() {}); // Rebuild to update the focused state
                          },
                          child: FloatingActionButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => NetworkCategory()), // Replace with your target page
                              );
                            },
                            child: Icon(Icons.navigate_next, color: Colors.black),
                            backgroundColor: fabFocusNode.hasFocus ? AppColors.primaryColor : AppColors.hintColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class OtherPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Other Page')),
      body: Center(child: Text('Welcome to the Other Page')),
    );
  }
}
