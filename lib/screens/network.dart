import 'dart:convert';
import 'package:container_gradient_border/container_gradient_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobi_tv_entertainment/home_sub_screen/network_category.dart';
import 'package:mobi_tv_entertainment/main.dart';
import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}


class Network extends StatefulWidget {
  @override
  _NetworkState createState() => _NetworkState();
}

class _NetworkState extends State<Network> {
  List networks = [];
  List<FocusNode> _focusNodes = [];

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
        // Create focus nodes for each network item
        _focusNodes = List.generate(networks.length, (_) => FocusNode());
        // Request focus for the first item
        // if (_focusNodes.isNotEmpty) {
        //   WidgetsBinding.instance.addPostFrameCallback((_) {
        //     FocusScope.of(context).requestFocus(_focusNodes[0]);
        //   });
        // }
      });
    } else {
      throw Exception('Failed to load networks');
    }
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardColor,
      body: networks.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(10.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // Number of columns in the grid
                  // childAspectRatio: 0.8, // Aspect ratio of each grid item
                  // crossAxisSpacing: 10,
                  // mainAxisSpacing: 10,
                ),
                itemCount: networks.length,
                itemBuilder: (context, index) {
                  final network = networks[index]??'';
                  return FocusableItem(
                    network: network,
                    focusNode: _focusNodes[index],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NetworkCategory()),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

class FocusableItem extends StatefulWidget {
  final Map network;
  final FocusNode focusNode;
  final VoidCallback onTap;

  FocusableItem(
      {required this.network, required this.focusNode, required this.onTap});

  @override
  _FocusableItemState createState() => _FocusableItemState();
}

class _FocusableItemState extends State<FocusableItem> {
  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onKey: (node, event) {
        if (event.isKeyPressed(LogicalKeyboardKey.select) ||
            event.isKeyPressed(LogicalKeyboardKey.enter)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      onFocusChange: (isFocused) {
        setState(() {});
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                
                  width: widget.focusNode.hasFocus ? 190 : 110,
                  height: widget.focusNode.hasFocus ? 140 : 110,
                  //       decoration: BoxDecoration(
                  //   border: Border.all(
                  //     color: widget.focusNode.hasFocus ? AppColors.primaryColor : AppColors.cardColor,
                  //     width: 5,
                  //   ),
                  // ),
                  // width:widget.focusNode.hasFocus ?200:150,
                  child: ContainerGradientBorder(
                    width: widget.focusNode.hasFocus ? 190 : 110,
                    height: widget.focusNode.hasFocus ? 140 : 110,
                    start: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    borderWidth: 7,
                    colorList: widget.focusNode.hasFocus
                        ? [
                            AppColors.primaryColor,
                            AppColors.highlightColor,
                            AppColors.primaryColor,
                            AppColors.highlightColor,
                            AppColors.primaryColor,
                            AppColors.highlightColor,
                            AppColors.primaryColor,
                            AppColors.highlightColor,
                            AppColors.primaryColor,
                            AppColors.highlightColor,
                            AppColors.primaryColor,
                            AppColors.highlightColor,
                            AppColors.primaryColor,
                            AppColors.highlightColor,
                            AppColors.primaryColor,
                            AppColors.highlightColor,
                          ]
                        : [AppColors.primaryColor, AppColors.highlightColor],
                    borderRadius: 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        widget.network['banner'] ?? '',
                        fit: BoxFit.cover,
                        width: widget.focusNode.hasFocus ? 180 : 100,
                        height: widget.focusNode.hasFocus ? 130 : 100,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.0),
              Text(
                widget.network['name'] ?? '',
                style: TextStyle(
                  color: widget.focusNode.hasFocus
                      ? AppColors.highlightColor
                      : AppColors.hintColor,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
