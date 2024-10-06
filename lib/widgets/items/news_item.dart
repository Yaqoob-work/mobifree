import 'package:mobi_tv_entertainment/main.dart';
import 'package:mobi_tv_entertainment/widgets/utils/color_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/news_item_model.dart';

class NewsItem extends StatefulWidget {
  final NewsItemModel item;
  final VoidCallback onTap;
  final ValueChanged<String> onEnterPress;
  final bool hideDescription;

  NewsItem({
    Key? key,
    required this.item,
    required this.onTap,
    required this.onEnterPress,
    this.hideDescription = false,
  }) : super(key: key);

  @override
  _NewsItemState createState() => _NewsItemState();
}

class _NewsItemState extends State<NewsItem> {
  bool isFocused = false;
  Color dominantColor = Colors.white.withOpacity(0.5);
  final PaletteColorService _paletteColorService = PaletteColorService();

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: _handleFocusChange,
      onKey: (FocusNode node, RawKeyEvent event) {
        if (event is RawKeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.select) {
          widget.onEnterPress(widget.item.id);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildImage(),
            SizedBox(height: 8),
            _buildTextContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return AnimatedContainer(
      curve: Curves.ease,
      width: MediaQuery.of(context).size.width * 0.19,
      height: isFocused
          ? MediaQuery.of(context).size.height * 0.22
          : MediaQuery.of(context).size.height * 0.2,
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        border: Border.all(
          color: isFocused ? dominantColor : Colors.transparent,
          width: 3.0,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                    color: dominantColor, blurRadius: 25.0, spreadRadius: 10.0)
              ]
            : [],
      ),
      child: widget.item.id == 'view_all'
          ? Container(
              color: Colors.grey[800],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'VieW ALL',
                      style: TextStyle(
                        color: isFocused ? dominantColor : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.item.name,
                      style: TextStyle(
                        color: isFocused ? dominantColor : Colors.white,
                        fontSize: nametextsz,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Channel',
                      style: TextStyle(
                        color: isFocused ? dominantColor : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              ),
            )
          : CachedNetworkImage(
              imageUrl: widget.item.banner,
              placeholder: (context, url) => Container(color: Colors.grey),
              fit: BoxFit.cover,
            ),
    );
  }

  // String _formatViewAllText(String text) {
  //   List<String> words = text.split(' ');
  //   if (words.length > 1) {
  //     return words
  //         .map((word) => word.trim())
  //         .where((word) => word.isNotEmpty)
  //         .join('\n');
  //   }
  //   return text;
  // }

  // double _calculateFontSize(String text) {
  //   if (text.length <= 5) return 20;
  //   if (text.length <= 10) return 18;
  //   if (text.length <= 15) return 16;
  //   return 14;
  // }

  Widget _buildTextContent() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.15,
      child: Column(
        children: [
          Text(
            widget.item.name.toUpperCase(),
            style: TextStyle(
              fontSize: nametextsz,
              fontWeight: FontWeight.bold,
              color: isFocused ? dominantColor : Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          // if (!widget.hideDescription)
          // Text(
          //   widget.item.description,
          //   style: TextStyle(
          //     fontSize: 12,
          //     color: isFocused
          //         ? dominantColor.withOpacity(0.8)
          //         : Colors.white.withOpacity(0.8),
          //   ),
          //   textAlign: TextAlign.center,
          //   maxLines: 3,
          //   overflow: TextOverflow.ellipsis,
          // ),
        ],
      ),
    );
  }

  void _handleFocusChange(bool hasFocus) async {
    setState(() {
      isFocused = hasFocus;
    });

    if (hasFocus) {
      if (widget.item.id == 'view_all') {
        // For "View All", use a predefined color
        dominantColor = Colors.blue
            // .withOpacity(0.5)
            ;
      } else {
        // For content items, extract color from the banner
                dominantColor = await _paletteColorService.getSecondaryColor(
          widget.item.banner,
          fallbackColor: Colors.grey,
        );
      }
      setState(() {});
    }
  }
}