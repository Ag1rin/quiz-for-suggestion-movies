import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'today_movie_screen.dart';
import 'similar_movies_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String favoriteGenre;

  const HomeScreen({super.key, required this.favoriteGenre});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pages = [
      TodayMovieScreen(favoriteGenre: widget.favoriteGenre),
      SimilarMoviesScreen(favoriteGenre: widget.favoriteGenre),
      ProfileScreen(favoriteGenre: widget.favoriteGenre),
    ];
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    _fadeAnimation = Tween<double>(
      begin: 0.2,
      end: 1.0,
    ).animate(_animationController);
    _checkUserData();
  }

  Future<void> _checkUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userName = prefs.getString('userName');
    if (userName == null && mounted) {
      await _showUserDataDialog();
    }
  }

  Future<void> _showUserDataDialog() async {
    TextEditingController nameController = TextEditingController();
    int intervalDays = 1;
    TimeOfDay notificationTime = const TimeOfDay(hour: 21, minute: 0);

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Welcome!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Enter your name',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  StatefulBuilder(
                    builder: (context, setDialogState) => Column(
                      children: [
                        DropdownButton<int>(
                          value: intervalDays,
                          items: [1, 3, 7]
                              .map(
                                (days) => DropdownMenuItem(
                                  value: days,
                                  child: Text(
                                    '$days days',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setDialogState(() => intervalDays = value!),
                          dropdownColor: Colors.black.withOpacity(0.8),
                          style: const TextStyle(color: Colors.white),
                        ),
                        _glassButton(
                          'Set Time: ${notificationTime.format(context)}',
                          () async {
                            TimeOfDay? newTime = await showTimePicker(
                              context: context,
                              initialTime: notificationTime,
                            );
                            if (newTime != null)
                              setDialogState(() => notificationTime = newTime);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _glassButton('Save', () async {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    if (mounted) {
                      setState(() {
                        prefs.setString('userName', nameController.text);
                        prefs.setInt('intervalDays', intervalDays);
                        prefs.setInt('notificationHour', notificationTime.hour);
                        prefs.setInt(
                          'notificationMinute',
                          notificationTime.minute,
                        );
                      });
                      Navigator.pop(context);
                    }
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Image.asset('assets/main.gif', fit: BoxFit.cover),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withAlpha(76)),
            ),
          ),
          _pages[_selectedIndex],
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20), // Moved up slightly
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.movie),
                    label: 'Today\'s Movie',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.list),
                    label: 'Similar Movies',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: Colors.white, // Stay white, no purple
                unselectedItemColor: Colors.grey,
                backgroundColor: Colors.transparent,
                onTap: _onItemTapped,
                enableFeedback: false, // Disable long press feedback
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassButton(String text, VoidCallback? onPressed) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              side: BorderSide(color: Colors.white.withOpacity(0.3)),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: Text(text, style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
