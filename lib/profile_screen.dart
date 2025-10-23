import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';

class ProfileScreen extends StatefulWidget {
  final String favoriteGenre;

  const ProfileScreen({super.key, required this.favoriteGenre});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  String? userName;
  int intervalDays = 1;
  TimeOfDay notificationTime = const TimeOfDay(
    hour: 21,
    minute: 0,
  ); // Default 21:00
  List<dynamic> favorites = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    _fadeAnimation = Tween<double>(
      begin: 0.2,
      end: 1.0,
    ).animate(_animationController);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName');
      intervalDays = prefs.getInt('intervalDays') ?? 1;
      int savedHour = prefs.getInt('notificationHour') ?? 21;
      int savedMinute = prefs.getInt('notificationMinute') ?? 0;
      notificationTime = TimeOfDay(hour: savedHour, minute: savedMinute);
      List<String>? favoritesJson = prefs.getStringList('favorites');
      favorites =
          favoritesJson?.map((jsonStr) => jsonDecode(jsonStr)).toList() ?? [];
    });
  }

  Future<void> _setNotificationSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('intervalDays', intervalDays);
    prefs.setInt('notificationHour', notificationTime.hour);
    prefs.setInt('notificationMinute', notificationTime.minute);
    await _scheduleNotification(widget.favoriteGenre);
  }

  Future<void> _scheduleNotification(String genre) async {
    final FlutterLocalNotificationsPlugin notifications =
        FlutterLocalNotificationsPlugin();
    var movie = await _getMovieRecommendation(genre);
    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + intervalDays,
      notificationTime.hour,
      notificationTime.minute,
    );
    await notifications.zonedSchedule(
      0,
      'Suggested Movie: ${movie['title'] ?? 'Movie'}',
      'Genre: ${movie['genres'] ?? genre}, Runtime: ${movie['runtime'] ?? 'N/A'} min, Language: ${movie['original_language'] ?? 'N/A'}',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'channel_id',
          'Movie Suggestions',
          importance: Importance.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('lastMovie', jsonEncode(movie));
  }

  Future<Map<String, dynamic>> _getMovieRecommendation(String genre) async {
    Map<String, String> genreIds = {
      'Action': '28',
      'Drama': '18',
      'Comedy': '35',
      'Horror': '27',
      'Sci-Fi': '878',
      'Romance': '10749',
      'Thriller': '53',
      'Adventure': '12',
      'Fantasy': '14',
      'Animation': '16',
    };
    String genreId = genreIds[genre] ?? '28';
    String url =
        'https://api.themoviedb.org/3/discover/movie?api_key=${Config.tmdbApiKey}&with_genres=$genreId';
    final response = await http.get(Uri.parse(url));
    var results = jsonDecode(response.body)['results'] as List<dynamic>;
    return results.isNotEmpty ? results[0] as Map<String, dynamic> : {};
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.transparent,
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          'Favorite Genre: ${widget.favoriteGenre}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                          setState(() => intervalDays = value!),
                      dropdownColor: Colors.black.withOpacity(0.8),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 20),
                    _glassButton(
                      'Set Time: ${notificationTime.format(context)}',
                      () async {
                        if (!mounted) return;
                        TimeOfDay? newTime = await showTimePicker(
                          context: context,
                          initialTime: notificationTime,
                        );
                        if (newTime != null && mounted) {
                          setState(() => notificationTime = newTime);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: _glassButton('Save Settings', _setNotificationSettings),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Favorites:',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: favorites.length,
                  itemBuilder: (context, index) => ListTile(
                    title: Text(
                      favorites[index]['title'],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
