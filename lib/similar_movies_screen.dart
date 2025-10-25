import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'config.dart';

/// Similar Movies Screen: Infinite scroll, random refresh, favorite toggle with SnackBar
class SimilarMoviesScreen extends StatefulWidget {
  final String favoriteGenre;
  const SimilarMoviesScreen({super.key, required this.favoriteGenre});

  @override
  State<SimilarMoviesScreen> createState() => _SimilarMoviesScreenState();
}

class _SimilarMoviesScreenState extends State<SimilarMoviesScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> movies = [];
  List<String> favoriteIds = [];
  bool _loading = false;
  final ScrollController _scrollController = ScrollController();
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
    _loadFavorites();
    _fetchRandomPage();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_loading) {
        _fetchRandomPage();
      }
    });
  }

  /// Load favorite movie IDs
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('favorites') ?? [];
    favoriteIds = list.map((e) => jsonDecode(e)['id'].toString()).toList();
    setState(() {});
  }

  /// Fetch random page from TMDB
  Future<void> _fetchRandomPage({bool refresh = false}) async {
    if (_loading) return;
    setState(() => _loading = true);
    if (refresh) {
      movies.clear();
    }

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

    final randomPage = Random().nextInt(50) + 1;
    final url =
        'https://api.themoviedb.org/3/discover/movie?api_key=${Config.tmdbApiKey}&with_genres=$genreId&page=$randomPage';

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final newMovies = json.decode(res.body)['results'] as List;
        setState(() => movies.addAll(newMovies));
      }
    } catch (e) {
      debugPrint('Error fetching movies: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Toggle favorite and show SnackBar
  Future<void> _toggleFavorite(Map movie) async {
    final id = movie['id'].toString();
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('favorites') ?? [];

    if (favoriteIds.contains(id)) {
      list.removeWhere((e) => jsonDecode(e)['id'].toString() == id);
      favoriteIds.remove(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${movie['title']} removed from favorites')),
      );
    } else {
      list.add(jsonEncode(movie));
      favoriteIds.add(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${movie['title']} added to favorites')),
      );
    }
    await prefs.setStringList('favorites', list);
    setState(() {});
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        RefreshIndicator(
          onRefresh: () => _fetchRandomPage(refresh: true),
          child: ListView.builder(
            controller: _scrollController,
            itemCount: movies.length + 1,
            itemBuilder: (ctx, i) {
              if (i >= movies.length) {
                return _loading
                    ? const Center(child: CircularProgressIndicator())
                    : const SizedBox();
              }
              final m = movies[i];
              final isFav = favoriteIds.contains(m['id'].toString());
              return ListTile(
                leading: CachedNetworkImage(
                  imageUrl:
                      'https://image.tmdb.org/t/p/w200${m['poster_path'] ?? ''}',
                  width: 50,
                  height: 75,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const CircularProgressIndicator(),
                ),
                title: Text(
                  m['title'] ?? '',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Runtime: ${m['runtime'] ?? 'N/A'} min',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: Colors.white,
                  ),
                  onPressed: () => _toggleFavorite(m),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
