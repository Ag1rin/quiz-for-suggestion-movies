import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart'; // Import config

class ProfileScreen extends StatefulWidget {
  final String favoriteGenre;

  const ProfileScreen({super.key, required this.favoriteGenre});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  String? userName;
  int intervalDays = 1;
  TimeOfDay notificationTime = const TimeOfDay(hour: 20, minute: 0);
  List<dynamic> favorites = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName');
      intervalDays = prefs.getInt('intervalDays') ?? 1;
      int savedHour = prefs.getInt('notificationHour') ?? 20;
      int savedMinute = prefs.getInt('notificationMinute') ?? 0;
      notificationTime = TimeOfDay(hour: savedHour, minute: savedMinute);
      List<String>? favoritesJson = prefs.getStringList('favorites');
      favorites =
          favoritesJson?.map((jsonStr) => jsonDecode(jsonStr)).toList() ?? [];
    });
    if (userName == null) {
      await _askForName();
    }
  }

  Future<void> _askForName() async {
    TextEditingController controller = TextEditingController();
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter your name'),
        content: TextField(controller: controller),
        actions: [
          ElevatedButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              if (mounted) {
                setState(() => userName = controller.text);
              }
              prefs.setString('userName', controller.text);
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person, size: 100, color: Colors.white),
          Text(
            userName ?? 'User',
            style: const TextStyle(color: Colors.white, fontSize: 24),
          ),
          Text(
            'Favorite Genre: ${widget.favoriteGenre}',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 20),
          DropdownButton<int>(
            value: intervalDays,
            items: [1, 3, 7]
                .map(
                  (days) =>
                      DropdownMenuItem(value: days, child: Text('$days days')),
                )
                .toList(),
            onChanged: (value) => setState(() => intervalDays = value!),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!mounted) return;
              TimeOfDay? newTime = await showTimePicker(
                context: context,
                initialTime: notificationTime,
              );
              if (newTime != null && mounted) {
                setState(() => notificationTime = newTime);
              }
            },
            child: Text('Set Time: ${notificationTime.format(context)}'),
          ),
          ElevatedButton(
            onPressed: _setNotificationSettings,
            child: const Text('Save Settings'),
          ),
          const SizedBox(height: 20),
          const Text('Favorites:', style: TextStyle(color: Colors.white)),
          ListView.builder(
            shrinkWrap: true,
            itemCount: favorites.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(
                favorites[index]['title'],
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
