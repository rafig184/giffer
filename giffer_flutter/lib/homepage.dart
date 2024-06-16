import 'package:flutter/material.dart';
import 'dart:core';
import 'package:flutter/widgets.dart';
import 'package:giffer_flutter/gifs.dart';
import 'package:giffer_flutter/images.dart';
import 'package:giffer_flutter/colors.dart';
import 'package:giffer_flutter/memes.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage();

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum GifsProvider { Giphy, Tenor, Trending }

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 1;

  static List<Widget> _widgetOptions = <Widget>[
    ImagesPage(),
    GifsPage(),
    MemesPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: primaryColor,
        title: Center(
          child: Image.asset(
            'assets/logo.png',
            height: 40,
          ),
        ),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.image),
            label: "Images",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gif_box_rounded),
            label: "Gifs",
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.image_rounded), label: "Memes"),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: secondaryColor,
        unselectedItemColor: Colors.grey,
        // selectedItemColor: secondaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}
