import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:chewie/chewie.dart';
import 'config.dart';

class TodayMovieScreen extends StatefulWidget {
  final String favoriteGenre;

  const TodayMovieScreen({super.key, required this.favoriteGenre});

  @override
  TodayMovieScreenState createState() => TodayMovieScreenState();
}

class TodayMovieScreenState extends State<TodayMovieScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? lastMovie;
  String? _youtubeVideoId;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoadingTrailer = true;

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

    _loadLastMovie();
  }

  Future<void> _loadLastMovie() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastMovieJson = prefs.getString('lastMovie');
    if (lastMovieJson != null) {
      lastMovie = json.decode(lastMovieJson) as Map<String, dynamic>;
      _loadTrailer(lastMovie!['id'].toString());
    } else {
      lastMovie = await _getMovieRecommendation(widget.favoriteGenre);
      if (lastMovie!.isNotEmpty) {
        prefs.setString('lastMovie', json.encode(lastMovie));
        _loadTrailer(lastMovie!['id'].toString());
      }
    }
    setState(() {});
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
        'https://api.themoviedb.org/3/discover/movie?api_key=${Config.tmdbApiKey}&with_genres=$genreId&sort_by=popularity.desc';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var results = json.decode(response.body)['results'] as List<dynamic>;
        return results.isNotEmpty ? results[0] as Map<String, dynamic> : {};
      } else {
        throw Exception('Failed to load movie: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching movie: $e');
      return {};
    }
  }

  Future<void> _loadTrailer(String movieId) async {
    final trailerUrl =
        'https://api.themoviedb.org/3/movie/$movieId/videos?api_key=${Config.tmdbApiKey}';
    try {
      final response = await http.get(Uri.parse(trailerUrl));
      if (response.statusCode == 200) {
        final videos = json.decode(response.body)['results'] as List<dynamic>;
        final trailer = videos.firstWhere(
          (v) => v['site'] == 'YouTube' && v['type'] == 'Trailer',
          orElse: () => null,
        );
        if (trailer != null) {
          _youtubeVideoId = trailer['key'] as String;
          await _initializePlayer(_youtubeVideoId!);
        }
      }
    } catch (e) {
      print('Error loading trailer: $e');
    } finally {
      setState(() => _isLoadingTrailer = false);
    }
  }

  Future<void> _initializePlayer(String youtubeId) async {
    final yt = YoutubeExplode();
    try {
      final manifest = await yt.videos.streamsClient.getManifest(youtubeId);
      final streamInfo = manifest.muxed.withHighestBitrate();
      final streamUrl = streamInfo.url.toString();

      _videoPlayerController = VideoPlayerController.network(streamUrl);
      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        aspectRatio: 16 / 9,
        allowFullScreen: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.red,
          handleColor: Colors.red,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.white30,
        ),
      );
    } catch (e) {
      print('Error initializing player: $e');
    } finally {
      yt.close();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _animationController.dispose();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
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

        Center(
          child: lastMovie == null || lastMovie!.isEmpty
              ? const CircularProgressIndicator()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        lastMovie!['title'] ?? 'No Title',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      CachedNetworkImage(
                        imageUrl:
                            'https://image.tmdb.org/t/p/w500${lastMovie!['poster_path'] ?? ''}',
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(
                              color: Colors.white,
                            ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 60,
                        ),
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height: 20),

                      _isLoadingTrailer
                          ? const CircularProgressIndicator()
                          : _chewieController != null &&
                                _videoPlayerController!.value.isInitialized
                          ? SizedBox(
                              height: 220,
                              child: Chewie(controller: _chewieController!),
                            )
                          : const Text(
                              'Trailer not available',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                      const SizedBox(height: 20),

                      _buildInfoRow(
                        'Genre',
                        _getGenreNames(lastMovie!['genre_ids'] ?? []),
                      ),
                      _buildInfoRow(
                        'Language',
                        _getLanguageName(
                          lastMovie!['original_language'] ?? 'en',
                        ),
                      ),
                      _buildInfoRow(
                        'Release Date',
                        lastMovie!['release_date'] ?? 'Unknown',
                      ),
                      _buildInfoRow(
                        'Rating',
                        '${lastMovie!['vote_average']?.toStringAsFixed(1) ?? '0'} ⭐',
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white70, fontSize: 18),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getGenreNames(List<dynamic> genreIds) {
    Map<int, String> genreMap = {
      28: 'Action',
      12: 'Adventure',
      16: 'Animation',
      35: 'Comedy',
      80: 'Crime',
      99: 'Documentary',
      18: 'Drama',
      10751: 'Family',
      14: 'Fantasy',
      36: 'History',
      27: 'Horror',
      10402: 'Music',
      9648: 'Mystery',
      10749: 'Romance',
      878: 'Sci-Fi',
      10770: 'TV Movie',
      53: 'Thriller',
      10752: 'War',
      37: 'Western',
    };
    return genreIds.map((id) => genreMap[id] ?? 'Unknown').join(', ');
  }

  String _getLanguageName(String code) {
    Map<String, String> langMap = {
      'en': 'English',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'ja': 'Japanese',
      'ko': 'Korean',
      'zh': 'Chinese',
      'hi': 'Hindi',
      'ar': 'Arabic',
      'pt': 'Portuguese',
    };
    return langMap[code] ?? code.toUpperCase();
  }
}
