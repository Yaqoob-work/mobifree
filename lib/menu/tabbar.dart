import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focusable Menu with Dynamic Pages',
      home: Tabbar(),
    );
  }
}

class Tabbar extends StatefulWidget {
  @override
  _TabbarState createState() => _TabbarState();
}

class _TabbarState extends State<Tabbar> {
  final List<String> categories = [
    'Live', 'Entertainment', 'Music', 'Movie', 'News', 'Sports', 'Religious'
  ];

  String _selectedCategory = 'Live';
  late List<FocusNode> focusNodes;
  int focusedIndex = 0; // Track the index of the currently focused category

  @override
  void initState() {
    super.initState();
    focusNodes = List.generate(categories.length, (index) => FocusNode());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (focusNodes.isNotEmpty) {
        FocusScope.of(context).requestFocus(focusNodes[0]);
      }
    });
  }

  @override
  void dispose() {
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          _buildCategoryButtons(),
          Expanded(child: _renderPageBasedOnCategory()),
        ],
      ),
    );
  }

  Widget _buildCategoryButtons() {
    return RawKeyboardListener(
      focusNode: FocusNode(), // FocusNode to listen to keyboard events
      autofocus: true, // Ensure this listener always has focus
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight && focusedIndex < categories.length - 1) {
            setState(() {
              focusedIndex++;
              FocusScope.of(context).requestFocus(focusNodes[focusedIndex]);
            });
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft && focusedIndex > 0) {
            setState(() {
              focusedIndex--;
              FocusScope.of(context).requestFocus(focusNodes[focusedIndex]);
            });
          } else if (event.logicalKey == LogicalKeyboardKey.enter) {
            _selectCategory(categories[focusedIndex]);
          }
        }
      },
      child: Container(
        height: 50, // Fixed height for better control
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              onTap: () {
                _selectCategory(categories[index]);
              },
              child: Focus(
                focusNode: focusNodes[index],
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _selectedCategory == categories[index]
                        ? Colors.blue
                        : focusNodes[index].hasFocus ? Colors.lightBlueAccent : Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (index == 0) // Reintegrated image for the first category
                          Padding(
                            padding: EdgeInsets.only(right: 10),
                            child: Image.asset('assets/logo.png', width: 24, height: 24),
                          ),
                        Text(
                          categories[index],
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _renderPageBasedOnCategory() {
    switch (_selectedCategory) {
      case 'Live':
        return Center(child: Text('Live Content'));
      case 'Entertainment':
        return Center(child: Text('Entertainment Content'));
      case 'Music':
        return Center(child: Text('Music Content'));
      case 'Movie':
        return Center(child: Text('Movie Content'));
      case 'News':
        return Center(child: Text('News Content'));
      case 'Sports':
        return Center(child: Text('Sports Content'));
      case 'Religious':
        return Center(child: Text('Religious Content'));
      default:
        return Center(child: Text('Select a Category'));
    }
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }
}
