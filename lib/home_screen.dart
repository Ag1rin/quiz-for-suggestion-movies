import 'package:flutter/material.dart';
import 'today_movie_screen.dart'; // New file
import 'similar_movies_screen.dart'; // New file
import 'profile_screen.dart'; // New file

class HomeScreen extends StatefulWidget {
  final String favoriteGenre;

  const HomeScreen({super.key, required this.favoriteGenre});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      TodayMovieScreen(favoriteGenre: widget.favoriteGenre),
      SimilarMoviesScreen(favoriteGenre: widget.favoriteGenre),
      ProfileScreen(favoriteGenre: widget.favoriteGenre),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.movie),
            label: 'Today\'s Movie',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Similar Movies',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.black.withAlpha(
          204,
        ), // Replaced withOpacity for precision
        onTap: _onItemTapped,
      ),
    );
  }
}
