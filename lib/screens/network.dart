import 'dart:convert';
import 'package:container_gradient_border/container_gradient_border.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: networks.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: networks.length,
              itemBuilder: (context, index) {
                final network = networks[index];
                return FocusableItem(
                  network: network,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NetworkCategory()),
                    );
                  },
                );
              },
            ),
    );
  }
}

class FocusableItem extends StatefulWidget {
  final Map network;
  final VoidCallback onTap;

  FocusableItem({required this.network, required this.onTap});

  @override
  _FocusableItemState createState() => _FocusableItemState();
}

class _FocusableItemState extends State<FocusableItem> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
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
          // decoration: BoxDecoration(
          //   border: Border.all(
          //     color: _focusNode.hasFocus ? AppColors.primaryColor : Colors.transparent,
          //     width: 1,
          //   ),
          // ),
           child: ContainerGradientBorder(
                  width: MediaQuery.of(context).size.width,
                  start: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  borderWidth: 1,
                  colorList: const [
                    AppColors.primaryColor,
                    AppColors.highlightColor
                  ],
          height: MediaQuery.of(context).size.height,
          padding: EdgeInsets.symmetric(vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Opacity(
                  opacity: _focusNode.hasFocus ? 0.8 : 1.0,
                  child: Image.network(
                    widget.network['logo'],
                    width: MediaQuery.of(context).size.width ,
                  ),
                ),
              ),
              SizedBox(height: 10.0),
              Text(
                widget.network['name'],
                style: TextStyle(
                  color: _focusNode.hasFocus ? AppColors.highlightColor : AppColors.hintColor,
                  fontSize: 40.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
           ),
        ),
      ),
    );
  }
}
