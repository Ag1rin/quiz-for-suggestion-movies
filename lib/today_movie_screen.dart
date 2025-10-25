import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'config.dart';

/// Today's Movie Screen: Full scroll, title above poster, details, trailer in glass card
class TodayMovieScreen extends StatefulWidget {
  final String favoriteGenre;
  const TodayMovieScreen({super.key, required this.favoriteGenre});

  @override
  State<TodayMovieScreen> createState() => _TodayMovieScreenState();
}

class _TodayMovieScreenState extends State<TodayMovieScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? movie;
  List<dynamic> reviews = [];
  String? trailerKey;
  bool loading = true;
  late YoutubePlayerController _youtubeController;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    _fadeAnim = Tween<double>(begin: 0.2, end: 1.0).animate(_animCtrl);
    _loadOrFetchMovie();
  }

  /// Load from cache or fetch new
  Future<void> _loadOrFetchMovie() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('todayMovie');
    if (saved != null) {
      final data = jsonDecode(saved);
      movie = data['details'];
      reviews = data['reviews'];
      trailerKey = data['trailer'];
    } else {
      await _fetchTodayMovie();
    }

    if (trailerKey != null) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: trailerKey!,
        flags: const YoutubePlayerFlags(
          autoPlay: false, // خودکار پلی نمی‌شه
          mute: false,
          showLiveFullscreenButton: false,
        ),
      );
    }

    setState(() => loading = false);
  }

  /// Fetch random movie + details + trailer + reviews
  Future<void> _fetchTodayMovie() async {
    final genreId =
        {
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
        }[widget.favoriteGenre] ??
        '28';

    final discoverUrl =
        'https://api.themoviedb.org/3/discover/movie?api_key=${Config.tmdbApiKey}&with_genres=$genreId';
    final res = await http.get(Uri.parse(discoverUrl));
    final results = jsonDecode(res.body)['results'] as List;
    final randomMovie = results[Random().nextInt(results.length)];

    final detailsUrl =
        'https://api.themoviedb.org/3/movie/${randomMovie['id']}?api_key=${Config.tmdbApiKey}&append_to_response=videos,reviews';
    final detRes = await http.get(Uri.parse(detailsUrl));
    final details = jsonDecode(detRes.body);

    final videos = details['videos']['results'] as List;
    trailerKey = videos.isNotEmpty
        ? videos.firstWhere(
            (v) => v['type'] == 'Trailer',
            orElse: () => videos.first,
          )['key']
        : null;

    reviews = (details['reviews']['results'] as List).take(3).toList();

    movie = details;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'todayMovie',
      jsonEncode({
        'details': details,
        'reviews': reviews,
        'trailer': trailerKey,
      }),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        Positioned.fill(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Image.asset('assets/main.gif', fit: BoxFit.cover),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),
        ),
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title Card Above Poster
            Card(
              color: Colors.white.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  movie?['title'] ?? 'No Title',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Poster
            Center(
              child: CachedNetworkImage(
                imageUrl:
                    'https://image.tmdb.org/t/p/w500${movie?['poster_path'] ?? ''}',
                width: 200,
                height: 300,
                fit: BoxFit.cover,
                placeholder: (_, __) => const CircularProgressIndicator(),
              ),
            ),
            const SizedBox(height: 20),

            // Details
            _infoTile(
              'Genre',
              (movie?['genres'] as List?)?.map((g) => g['name']).join(', ') ??
                  'N/A',
            ),
            _infoTile('Runtime', '${movie?['runtime'] ?? 'N/A'} min'),
            _infoTile(
              'Language',
              movie?['original_language']?.toUpperCase() ?? 'N/A',
            ),

            // Trailer in Glass Card
            if (trailerKey != null) ...[
              const SizedBox(height: 20),
              const Text(
                'Trailer:',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              _glassYoutubeCard(),
            ],

            // Reviews
            const SizedBox(height: 20),
            const Text(
              'Reviews:',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            ...reviews.map(
              (r) => Card(
                color: Colors.white.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    r['content'] ?? '',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ],
    );
  }

  /// Glass-morphism YouTube Player Card
  Widget _glassYoutubeCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.2),
            blurRadius: 12,
            spreadRadius: 3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: Colors.white.withValues(alpha: 0.15),
            padding: const EdgeInsets.all(8),
            child: YoutubePlayer(
              controller: _youtubeController,
              showVideoProgressIndicator: true,
              progressIndicatorColor: Colors.white,
              progressColors: const ProgressBarColors(
                playedColor: Colors.red,
                handleColor: Colors.redAccent,
              ),
              onReady: () {
                // فقط وقتی کاربر دکمه Play رو زد، پلی می‌شه
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return ListTile(
      title: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _youtubeController.dispose();
    super.dispose();
  }
}
