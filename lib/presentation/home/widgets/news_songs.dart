import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spotify_app/common/helpers/is_dark_mode.dart';
import 'package:spotify_app/core/configs/assets/app_images.dart';
import 'package:spotify_app/domain/entities/song/song.dart';
import 'package:spotify_app/presentation/home/bloc/news_songs_cubit.dart';
import 'package:spotify_app/presentation/song_player/pages/song_player.dart';
import '../bloc/news_songs_state.dart';

class NewsSongs extends StatefulWidget {
  const NewsSongs({super.key});
  @override
  State<NewsSongs> createState() => _NewsSongsState();
}

class _NewsSongsState extends State<NewsSongs> with TickerProviderStateMixin {
  late AnimationController _staggerController;

  // Kích thước item
  static const double _cover =
      180; // tăng chiều cao ảnh để “điền” khoảng trống dưới
  static const double _textBlock = 40; // title + artist + spacing nhỏ
  static const double _cardBottom = 10; // space giữa ảnh và text

  // Khoảng cách section
  static const double _topGap = 12; // giữ khoảng dưới header/tab
  static const double _bottomGap = 0; // gần sát Playlist

  // Tổng chiều cao
  static const double _sectionHeight =
      _cover + _cardBottom + _textBlock + _topGap + _bottomGap;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NewsSongsCubit()..getNewsSongs(),
      child: SizedBox(
        height: _sectionHeight,
        child: BlocBuilder<NewsSongsCubit, NewsSongsState>(
          builder: (context, state) {
            if (state is NewsSongsLoading) {
              return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF1DB954), strokeWidth: 3),
              );
            }
            if (state is NewsSongsLoaded) {
              return _songs(state.songs);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _songs(List<SongEntity> songs) {
    final isDarkMode = context.isDarkMode;

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, _topGap, 20, _bottomGap),
      itemCount: songs.length,
      separatorBuilder: (_, __) => const SizedBox(width: 16),
      itemBuilder: (context, index) {
        final s = songs[index];
        final imageAsset = _getImageAsset(s.title.trim(), s.artist.trim());

        final anim = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(
              (index * 0.1).clamp(0.0, 1.0),
              ((index * 0.1) + 0.3).clamp(0.0, 1.0),
              curve: Curves.easeOutBack, // có overshoot → sẽ clamp opacity
            ),
          ),
        );

        return AnimatedBuilder(
          animation: anim,
          builder: (_, __) {
            // tránh lỗi assert của Opacity khi overshoot > 1
            final double safeOpacity = anim.value.clamp(0.0, 1.0);
            return Transform.scale(
              scale: anim.value, // scale > 1 không sao
              child: Opacity(
                opacity: safeOpacity,
                child: _buildSongCard(s, imageAsset, isDarkMode),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSongCard(SongEntity song, String imageAsset, bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, a, __) => SongPlayerPage(songEntity: song),
            transitionsBuilder: (_, a, __, child) => SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0, 1), end: Offset.zero)
                  .animate(
                      CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
        );
      },
      child: SizedBox(
        width: _cover,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            Container(
              height: _cover,
              width: _cover,
              margin: const EdgeInsets.only(bottom: _cardBottom),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withValues(alpha: isDarkMode ? 0.4 : 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Image.asset(
                      imageAsset,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF1DB954).withValues(alpha: 0.3),
                              isDarkMode
                                  ? Colors.grey[800]!
                                  : Colors.grey[300]!,
                            ],
                          ),
                        ),
                        child: const Icon(Icons.music_note,
                            size: 50, color: Color(0xFF1DB954)),
                      ),
                    ),
                    // Play button overlay
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1DB954),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF1DB954).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.black.withValues(alpha: 0.5),
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

  String _getImageAsset(String title, String artist) {
    final t = title.trim().toUpperCase();
    final a = artist.trim().toUpperCase();
    final key = '$t - $a';
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
}
