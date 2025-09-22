import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spotify_app/core/configs/assets/app_images.dart';
import 'package:spotify_app/core/configs/constants/app_urls.dart';
import 'package:spotify_app/domain/entities/song/song.dart';
import 'package:spotify_app/presentation/song_player/bloc/song_player_cubit.dart';

import 'package:spotify_app/presentation/song_player/bloc/song_player_state.dart';

class SongPlayerPage extends StatefulWidget {
  final SongEntity songEntity;

  const SongPlayerPage({required this.songEntity, super.key});

  @override
  State<SongPlayerPage> createState() => _SongPlayerPageState();
}

class _SongPlayerPageState extends State<SongPlayerPage>
    with TickerProviderStateMixin {
  bool _isFavorited = false;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationAnimation =
        Tween<double>(begin: 0, end: 1).animate(_rotationController);

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final audioUrl =
        '${AppURLs.songFirestorage}${widget.songEntity.artist} - ${widget.songEntity.title}.mp3?${AppURLs.mediaAlt}';

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      body: BlocProvider(
        create: (_) => SongPlayerCubit()..loadSong(audioUrl),
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDarkMode
                      ? [
                          const Color(0xFF1DB954).withOpacity(0.3),
                          const Color(0xFF121212),
                          const Color(0xFF000000),
                        ]
                      : [
                          const Color(0xFF1DB954).withOpacity(0.1),
                          Colors.white,
                          const Color(0xFFF5F5F5),
                        ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(context, isDarkMode),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildSongCover(context, isDarkMode),
                          const SizedBox(height: 40),
                          _buildSongDetail(isDarkMode),
                          const SizedBox(height: 40),
                          _buildSongPlayer(context, isDarkMode),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          Container(
            decoration: BoxDecoration(
              color:
                  isDarkMode ? Colors.black26 : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: isDarkMode ? Colors.white : Colors.black87,
                size: 28,
              ),
            ),
          ),

          // Title
          Text(
            'Now Playing',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),

          // More button
          Container(
            decoration: BoxDecoration(
              color:
                  isDarkMode ? Colors.black26 : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.more_vert_rounded,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongCover(BuildContext context, bool isDarkMode) {
    final imageAsset = _getImageAsset(
      widget.songEntity.title.trim(),
      widget.songEntity.artist.trim(),
    );

    return BlocBuilder<SongPlayerCubit, SongPlayerState>(
      builder: (context, state) {
        final isPlaying = state is SongPlayerLoaded &&
            context.read<SongPlayerCubit>().audioPlayer.playing;

        if (isPlaying && !_rotationController.isAnimating) {
          _rotationController.repeat();
        } else if (!isPlaying) {
          _rotationController.stop();
        }

        return Center(
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isPlaying ? _pulseAnimation.value : 1.0,
                child: Container(
                  height: MediaQuery.of(context).size.width * 0.8,
                  width: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(200),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1DB954).withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 5,
                        offset: const Offset(0, 15),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: isPlaying ? _rotationAnimation.value * 6.283 : 0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(200),
                          child: Stack(
                            children: [
                              Image.asset(
                                imageAsset,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[300],
                                      borderRadius: BorderRadius.circular(200),
                                    ),
                                    child: Icon(
                                      Icons.music_note,
                                      size: 80,
                                      color: isDarkMode
                                          ? Colors.grey[600]
                                          : Colors.grey[500],
                                    ),
                                  );
                                },
                              ),
                              // Vinyl effect
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(200),
                                  gradient: RadialGradient(
                                    center: Alignment.center,
                                    colors: [
                                      Colors.transparent,
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.1),
                                    ],
                                    stops: const [0.0, 0.7, 1.0],
                                  ),
                                ),
                              ),
                              // Center dot
                              Center(
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? Colors.black54
                                        : Colors.black26,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _getImageAsset(String title, String artist) {
    final normalizedTitle = title.trim().toUpperCase();
    final normalizedArtist = artist.trim().toUpperCase();
    final key = '$normalizedTitle - $normalizedArtist';

    switch (key) {
      case 'HOST - COLOR OUT':
        return AppImages.host;
      case 'LEONA - DO I':
        return AppImages.leeonaDoI;
      case 'IN MY MIND - LAMINAR':
        return AppImages.laminarInMyMind;
      case 'MOLOTOV HEART - RADIO NOWHERE':
        return AppImages.monlotov;
      case 'ALONE - COLOR OUT':
        return AppImages.alone;
      case 'NO REST OR ENDLESS REST - LISOFV':
        return AppImages.norestorendlessrest;
      case 'FIND A WAY - THE DLX':
        return AppImages.findaway;
      default:
        return AppImages.error;
    }
  }

  Widget _buildSongDetail(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.songEntity.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.songEntity.artist,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.7)
                        : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              setState(() {
                _isFavorited = !_isFavorited;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isFavorited
                    ? const Color(0xFF1DB954).withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                _isFavorited ? Icons.favorite : Icons.favorite_outline,
                size: 30,
                color: _isFavorited
                    ? const Color(0xFF1DB954)
                    : (isDarkMode ? Colors.white70 : Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongPlayer(BuildContext context, bool isDarkMode) {
    return BlocBuilder<SongPlayerCubit, SongPlayerState>(
      builder: (context, state) {
        if (state is SongPlayerLoading) {
          return SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(
                color: const Color(0xFF1DB954),
                strokeWidth: 3,
              ),
            ),
          );
        }

        if (state is SongPlayerFailure) {
          return Column(
            children: [
              const Icon(Icons.error_outline,
                  size: 40, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                'Không tải được bài hát. Hãy kiểm tra URL audio.',
                style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54),
              ),
            ],
          );
        }

        // Loaded
        final cubit = context.read<SongPlayerCubit>();
        final total = cubit.songDuration.inSeconds.toDouble();
        final safeMax = total <= 0 ? 1.0 : total;
        final safeValue =
            cubit.songPosition.inSeconds.toDouble().clamp(0.0, safeMax);

        return Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF1DB954),
                      inactiveTrackColor: isDarkMode
                          ? Colors.white.withOpacity(0.3)
                          : Colors.black.withOpacity(0.1),
                      thumbColor: const Color(0xFF1DB954),
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                      trackHeight: 4,
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      value: safeValue,
                      min: 0.0,
                      max: safeMax,
                      onChanged: (v) =>
                          cubit.seek(Duration(seconds: v.toInt())),
                    ),
                  ),

                  // Time labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatDuration(cubit.songPosition),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        formatDuration(cubit.songDuration),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(Icons.shuffle, () {}, isDarkMode, size: 24),
                _buildControlButton(Icons.skip_previous, () {}, isDarkMode,
                    size: 32),

                // Play/Pause
                GestureDetector(
                  onTap: () => cubit.playOrPauseSong(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 70,
                    width: 70,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(
                      cubit.audioPlayer.playing
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),

                _buildControlButton(Icons.skip_next, () {}, isDarkMode,
                    size: 32),
                _buildControlButton(Icons.repeat, () {}, isDarkMode, size: 24),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildControlButton(
    IconData icon,
    VoidCallback onTap,
    bool isDarkMode, {
    double size = 24,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Icon(
          icon,
          size: size,
          color: isDarkMode
              ? Colors.white.withOpacity(0.8)
              : Colors.black.withOpacity(0.7),
        ),
      ),
    );
  }

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
