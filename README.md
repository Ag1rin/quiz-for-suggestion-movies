# Quiz for Movie Suggestion 🎬

A fun Flutter app that discovers your cinematic taste through a **15-question quiz** and suggests movies tailored just for you!

On top of personalized recommendations, the app sends you **a new movie suggestion every day** via notification—so you'll never run out of things to watch. 🍿

### Key Features ✨
- **Personalized Quiz**: 15 carefully designed questions to understand your preferences (genres, moods, actors, and more)
- **Smart Movie Suggestions**: Recommendations powered by the **TMDB API** based on your quiz scores
- **Daily Notifications**: Get a fresh movie suggestion every day (using `flutter_local_notifications` + `workmanager`)
- **Beautiful Visuals**: Animated background (GIF) with blur effects, YouTube trailer playback, and cached images
- **State Management**: First-time user detection and preference saving with `shared_preferences`

### Technologies Used 💻
- **Flutter** (Dart)
- **TMDB API** for movie data
- **Video & Trailers**: `chewie` + `video_player` + `youtube_explode_dart`
- **Notifications & Background Tasks**: `flutter_local_notifications` + `workmanager` + `timezone`
- **Images**: `cached_network_image` + `flutter_blurhash`
- **Assets**: Animated GIF backgrounds

### Screenshots 📸
<!-- Add screenshots here when available -->
<!-- Example: -->
<!-- ![Splash Screen](screenshots/splash.png) -->
<!-- ![Quiz Screen](screenshots/quiz.png) -->
<!-- ![Suggestion Screen](screenshots/suggestion.png) -->

(Screenshots coming soon!)

### Setup & Run 🚀
1. Clone the repository:
   ```bash
   git clone https://github.com/Ag1rin/quiz-for-suggestion-movies.git
   ```
2. Navigate to the project folder:
   ```bash
   cd quiz-for-suggestion-movies
   ```
3. Get dependencies:
   ```bash
   flutter pub get
   ```
4. **TMDB API Key required**: Get your free API key from [TMDB](https://www.themoviedb.org/settings/api) and add it to the API service file.
5. Run the app:
   ```bash
   flutter run
   ```

### In Development 👨‍💻
This project is still in early stages (v0.1.0). Planned features:
- More questions and smarter recommendation logic
- Enhanced movie detail pages
- Multi-language support

Contributions, ideas, and pull requests are very welcome! 😊

**Built with ❤️ by [Ag1rin](https://github.com/Ag1rin)**

Let’s discover great movies together! 🚀
