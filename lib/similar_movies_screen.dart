import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'config.dart';

/// Screen that shows movies similar to the user's favorite genre.
/// Features:
/// - Infinite scroll (loads next page when reaching bottom)
/// - Pull-to-refresh
/// - Favorite button (heart) that toggles and prevents duplicates
/// - Cached image loading for posters
class SimilarMoviesScreen extends StatefulWidget {
  final String favoriteGenre;

  const SimilarMoviesScreen({super.key, required this.favoriteGenre});

  @override
  SimilarMoviesScreenState createState() => SimilarMoviesScreenState();
}

class SimilarMoviesScreenState extends State<SimilarMoviesScreen>
    with SingleTickerProviderStateMixin {
  // List of movie objects from TMDB
  List<dynamic> movies = [];

  // List of movie IDs that are already favorited (used to avoid duplicates & show filled heart)
  List<String> favoritesIds = [];

  // Pagination
  int _currentPage = 1;
  bool _isLoading = false;

  // Scroll controller to detect when user reaches bottom
  final ScrollController _scrollController = ScrollController();

  // Background animation (fading GIF)
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize fade animation for background GIF
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    _fadeAnimation = Tween<double>(
      begin: 0.2,
      end: 1.0,
    ).animate(_animationController);

    // Load saved favorite IDs and fetch first page of movies
    _loadFavorites();
    _fetchMovies(initialLoad: true);

    // Listen for scroll to load more movies
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading) {
        _fetchMovies();
      }
    });
  }

  /// Load favorite movie IDs from SharedPreferences
  Future<void> _loadFavorites() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? favoritesJson = prefs.getStringList('favorites');

    // FIX: Convert Iterable to List<String> explicitly
    favoritesIds =
        favoritesJson
            ?.map((jsonStr) => jsonDecode(jsonStr)['id'].toString())
            .toList() ??
        [];

    setState(() {});
  }

  /// Fetch movies from TMDB for the selected genre and page
  Future<void> _fetchMovies({bool initialLoad = false}) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    if (initialLoad) {
      movies.clear();
      _currentPage = 1;
    }

    // Map genre name to TMDB genre ID
    final Map<String, String> genreIds = {
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

    final String genreId = genreIds[widget.favoriteGenre] ?? '28';
    final String url =
        'https://api.themoviedb.org/3/discover/movie?api_key=${Config.tmdbApiKey}&with_genres=$genreId&page=$_currentPage';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> newMovies = json.decode(response.body)['results'];
        setState(() {
          movies.addAll(newMovies);
          _currentPage++;
        });
      } else {
        debugPrint('Failed to load movies: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching movies: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Pull-to-refresh: reload from page 1
  Future<void> _refreshMovies() async {
    await _fetchMovies(initialLoad: true);
  }

  /// Add movie to favorites if not already added
  Future<void> _addToFavorites(Map<dynamic, dynamic> movie) async {
    final String movieId = movie['id'].toString();

    // Prevent duplicates
    if (favoritesIds.contains(movieId)) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> favorites = prefs.getStringList('favorites') ?? [];
    favorites.add(json.encode(movie));
    await prefs.setStringList('favorites', favorites);

    setState(() {
      favoritesIds.add(movieId);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background animated GIF with fade effect
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

        // Pull-to-refresh + Infinite scroll list
        RefreshIndicator(
          onRefresh: _refreshMovies,
          child: ListView.builder(
            controller: _scrollController,
            itemCount: movies.length + 1, // +1 for loading indicator
            itemBuilder: (context, index) {
              // Show loading spinner at the end
              if (index >= movies.length) {
                return _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : const SizedBox.shrink();
              }

              final movie = movies[index];
              final String movieId = movie['id'].toString();
              final bool isFavorite = favoritesIds.contains(movieId);

              return ListTile(
                // Poster with cache
                leading: CachedNetworkImage(
                  imageUrl:
                      'https://image.tmdb.org/t/p/w200${movie['poster_path'] ?? ''}',
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                  fit: BoxFit.cover,
                  width: 50,
                  height: 75,
                ),
                title: Text(
                  movie['title'] ?? 'No Title',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Genre: ${widget.favoriteGenre}',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.white,
                  ),
                  onPressed: () => _addToFavorites(movie),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
