import 'dart:convert';
import 'package:container_gradient_border/container_gradient_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobi_tv_entertainment/home_sub_screen/network_category.dart';
import 'package:mobi_tv_entertainment/main.dart';

class SubNetwork extends StatefulWidget {
  @override
  _SubNetworkState createState() => _SubNetworkState();
}

class _SubNetworkState extends State<SubNetwork> {
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
        if (_focusNodes.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FocusScope.of(context).requestFocus(_focusNodes[0]);
          });
        }
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
          : Column(
              children: [
                SizedBox(height: 20.0), // Add some spacing at the top
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: networks.length,
                    itemBuilder: (context, index) {
                      final network = networks[index];
                      return FocusableItem(
                        network: network,
                        focusNode: _focusNodes[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => NetworkCategory()),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class FocusableItem extends StatefulWidget {
  final Map network;
  final FocusNode focusNode;
  final VoidCallback onTap;

  FocusableItem({required this.network, required this.focusNode, required this.onTap});

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
          margin: const EdgeInsets.all(8.0),
          
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: widget.focusNode.hasFocus ? 200 : 120,
                height: widget.focusNode.hasFocus ? 150 : 120,
          //       decoration: BoxDecoration(
          //   border: Border.all(
          //     color: widget.focusNode.hasFocus ? AppColors.primaryColor : AppColors.cardColor,
          //     width: 5,
          //   ),
          // ),
          child: ContainerGradientBorder(
                  width: widget.focusNode.hasFocus ? 190 : 110,
                  height: widget.focusNode.hasFocus ? 140 : 110,
                  start: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  borderWidth: 7,
                  colorList:  widget.focusNode.hasFocus ? [
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
                  :
                  [
                    AppColors.primaryColor,
                    AppColors.highlightColor
                  ],
                  borderRadius: 10,
                child: 
                   ClipRRect(
                     child: Image.network(
                      widget.network['logo'],
                      fit: BoxFit.cover,
                      width:widget.focusNode.hasFocus ? MediaQuery.of(context).size.width * 0.25: MediaQuery.of(context).size.width * 0.2,
                      height: 150 ,
                                       ),
                   ),
          ),
              ),
              SizedBox(height: 10.0),
              Text(
                widget.network['name'],
                style: TextStyle(
                  color: widget.focusNode.hasFocus ? AppColors.highlightColor : AppColors.hintColor,
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
