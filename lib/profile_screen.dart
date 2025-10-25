import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'dart:ui';
import 'config.dart';

/// Profile screen – shows user info, notification settings and favorite movies
/// with full scroll, glass-morphism UI and background GIF animation.
class ProfileScreen extends StatefulWidget {
  final String favoriteGenre;

  const ProfileScreen({super.key, required this.favoriteGenre});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  // User data
  String? userName;
  int intervalDays = 1;
  TimeOfDay notificationTime = const TimeOfDay(hour: 21, minute: 0);

  // Favorites list (full movie objects)
  List<dynamic> favorites = [];

  // Background fade animation
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialise fade animation for background GIF
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

  /// Load saved user data and favorites
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      userName = prefs.getString('userName');
      intervalDays = prefs.getInt('intervalDays') ?? 1;
      final savedHour = prefs.getInt('notificationHour') ?? 21;
      final savedMinute = prefs.getInt('notificationMinute') ?? 0;
      notificationTime = TimeOfDay(hour: savedHour, minute: savedMinute);

      final favoritesJson = prefs.getStringList('favorites');
      favorites =
          favoritesJson
              ?.map((jsonStr) => jsonDecode(jsonStr) as Map<String, dynamic>)
              .toList() ??
          [];
    });

    // Ask for name if not set
    if (userName == null || userName!.isEmpty) {
      await _askForName();
    }
  }

  /// Show dialog to enter user name
  Future<void> _askForName() async {
    final controller = TextEditingController();
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter your name'),
        content: TextField(controller: controller),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final name = controller.text.trim();
              if (name.isNotEmpty && mounted) {
                setState(() => userName = name);
                await prefs.setString('userName', name);
              }
              // ignore: use_build_context_synchronously
              if (mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Save notification settings and schedule a notification
  Future<void> _setNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('intervalDays', intervalDays);
    await prefs.setInt('notificationHour', notificationTime.hour);
    await prefs.setInt('notificationMinute', notificationTime.minute);
    await _scheduleNotification(widget.favoriteGenre);
  }

  /// Schedule a daily movie suggestion notification
  Future<void> _scheduleNotification(String genre) async {
    final notifications = FlutterLocalNotificationsPlugin();
    final movie = await _getMovieRecommendation(genre);

    final now = tz.TZDateTime.now(tz.local);
    final scheduled = tz.TZDateTime(
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
      'Genre: ${movie['genres']?.join(', ') ?? genre} | '
          'Runtime: ${movie['runtime'] ?? 'N/A'} min | '
          'Language: ${movie['original_language'] ?? 'N/A'}',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'channel_id',
          'Movie Suggestions',
          importance: Importance.high,
        ),
      ),
      androidScheduleMode:
          AndroidScheduleMode.exactAllowWhileIdle, // Fixed deprecated
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastMovie', jsonEncode(movie));
  }

  /// Get one random movie from the favorite genre
  Future<Map<String, dynamic>> _getMovieRecommendation(String genre) async {
    const genreIds = {
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

    final genreId = genreIds[genre] ?? '28';
    final url =
        'https://api.themoviedb.org/3/discover/movie?api_key=${Config.tmdbApiKey}&with_genres=$genreId';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return {};

    final results = json.decode(response.body)['results'] as List<dynamic>;
    return results.isNotEmpty ? results.first as Map<String, dynamic> : {};
  }

  /// Fetch extra movie details (director, runtime, rating) – used when saving favorites
  // ignore: unused_element
  Future<Map<String, dynamic>> _getMovieDetails(int movieId) async {
    final url =
        'https://api.themoviedb.org/3/movie/$movieId?api_key=${Config.tmdbApiKey}&append_to_response=credits';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return {};

    final data = json.decode(response.body);
    final director = data['credits']['crew'].firstWhere(
      (p) => p['job'] == 'Director',
      orElse: () => {'name': 'N/A'},
    )['name'];
    data['director'] = director;
    return data;
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
          // Animated background GIF
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Image.asset('assets/main.gif', fit: BoxFit.cover),
            ),
          ),

          // Blur overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withAlpha(76)),
            ),
          ),

          // Full-page scrollable content
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // User avatar + name + genre
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: 0.3,
                        ), // Fixed deprecated
                        width: 2,
                      ),
                    ),
                    child: const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.transparent,
                      child: Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName ?? 'User',
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

              const SizedBox(height: 30),

              // Notification interval dropdown
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DropdownButton<int>(
                      value: intervalDays,
                      dropdownColor: Colors.black.withValues(
                        alpha: 0.8,
                      ), // Fixed
                      style: const TextStyle(color: Colors.white),
                      items: [1, 3, 7]
                          .map(
                            (d) => DropdownMenuItem(
                              value: d,
                              child: Text(
                                '$d days',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => intervalDays = v!),
                    ),
                    const SizedBox(width: 20),
                    _glassButton(
                      'Set Time: ${notificationTime.format(context)}',
                      () async {
                        final newTime = await showTimePicker(
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
              const SizedBox(height: 30),

              // Favorites header
              const Center(
                child: Text(
                  'Favorites:',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              const SizedBox(height: 10),

              // Favorites list – each item shows poster, title, director, genres, runtime, rating
              ...favorites.map((movie) {
                // Some fields may be missing – provide fallbacks
                final director = movie['director']?.toString() ?? 'N/A';
                final genres =
                    (movie['genres'] as List<dynamic>?)
                        ?.map((g) => g['name']?.toString() ?? '')
                        .where((s) => s.isNotEmpty)
                        .join(', ') ??
                    widget.favoriteGenre;
                final runtime = movie['runtime']?.toString() ?? 'N/A';
                final rating = movie['vote_average']?.toString() ?? 'N/A';

                return Card(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl:
                            'https://image.tmdb.org/t/p/w200${movie['poster_path'] ?? ''}',
                        placeholder: (_, __) => const SizedBox(
                          width: 50,
                          height: 75,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.error, color: Colors.white),
                        width: 50,
                        height: 75,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      movie['title'] ?? 'No Title',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Director: $director',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        Text(
                          'Genre: $genres',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        Text(
                          'Runtime: $runtime min',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        Text(
                          'Rating: $rating / 10',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              // ignore: unnecessary_to_list_in_spreads
              }).toList(),

              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }

  /// Glass-morphism button widget
  Widget _glassButton(String text, VoidCallback? onPressed) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.2), // Fixed deprecated
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
              backgroundColor: Colors.white.withValues(alpha: 0.2), // Fixed
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
              ), // Fixed
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: Text(text, style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
