import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spotify_app/presentation/settings/pages/settings.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _menuAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _menuAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _menuAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _headerAnimationController.forward();
    _menuAnimationController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _menuAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDarkMode
                    ? [
                        const Color(0xFF1DB954).withValues(alpha: 0.2),
                        const Color(0xFF121212),
                        const Color(0xFF000000),
                      ]
                    : [
                        const Color(0xFF1DB954).withValues(alpha: 0.08),
                        const Color(0xFFF8F9FA),
                        Colors.white,
                      ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(isDarkMode),
                _buildProfileInfo(isDarkMode),
                const SizedBox(height: 30),
                // Menu
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildMenuItems(isDarkMode),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== Header =====================

  Widget _buildHeader(bool isDarkMode) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildGlassButton(
                Icons.arrow_back_ios_new,
                () => Navigator.pop(context),
                isDarkMode,
              ),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
                ).createShader(bounds),
                child: const Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              _buildGlassButton(
                Icons.settings_outlined,
                _openSettings,
                isDarkMode,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton(IconData icon, VoidCallback onTap, bool isDarkMode) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Center(
                child: Icon(
                  icon,
                  color: isDarkMode ? Colors.white : Colors.black87,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===================== Profile Info (Firebase) =====================

  Widget _buildProfileInfo(bool isDarkMode) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data ?? FirebaseAuth.instance.currentUser;

        final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
            ? user!.displayName!
            : 'Guest';
        final email = user?.email ?? '';
        final photoURL = user?.photoURL;

        return ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            children: [
              // Avatar (ưu tiên photoURL)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1DB954).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: photoURL != null
                      ? Image.network(photoURL, fit: BoxFit.cover)
                      : const Icon(Icons.person, color: Colors.white, size: 50),
                ),
              ),
              const SizedBox(height: 16),

              // Name
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),

              // Email
              if (email.isNotEmpty)
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.5),
                  ),
                ),

              const SizedBox(height: 16),

              // Stats row (demo)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatItem('Playlists', '12', isDarkMode),
                  const SizedBox(width: 28),
                  _buildStatItem('Liked', '134', isDarkMode),
                  const SizedBox(width: 28),
                  _buildStatItem('Followers', '56', isDarkMode),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String count, bool isDarkMode) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1DB954),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.6)
                : Colors.black.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  // ===================== Menu =====================

  Widget _buildMenuItems(bool isDarkMode) {
    final menuItems = [
      {
        'icon': Icons.library_music_outlined,
        'title': 'Your Library',
        'onTap': () => _showSnackBar('Your Library opened'),
      },
      {
        'icon': Icons.download_outlined,
        'title': 'Downloaded Music',
        'onTap': () => _showSnackBar('Downloaded music section'),
      },
      {
        'icon': Icons.favorite_outline,
        'title': 'Liked Songs',
        'onTap': () => _showSnackBar('Liked songs playlist'),
      },
      {
        'icon': Icons.history_outlined,
        'title': 'Recently Played',
        'onTap': () => _showSnackBar('Recently played tracks'),
      },
      {
        'icon': Icons.share_outlined,
        'title': 'Share Profile',
        'onTap': _shareProfile,
      },
      {
        'icon': Icons.logout_outlined,
        'title': 'Log Out',
        'onTap': _showLogoutDialog,
        'isDestructive': true,
      },
    ];

    return Column(
      children: menuItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;

        return AnimatedBuilder(
          animation: _menuAnimationController,
          builder: (context, child) {
            final anim = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _menuAnimationController,
                curve: Interval(
                  (index * 0.1).clamp(0.0, 1.0),
                  ((index * 0.1) + 0.3).clamp(0.0, 1.0),
                  curve: Curves.easeOutBack,
                ),
              ),
            );
            final clampedOpacity = anim.value.clamp(0.0, 1.0);

            return Transform.scale(
              scale: anim.value,
              child: Opacity(
                opacity: clampedOpacity,
                child: _buildMenuItem(
                  item['icon'] as IconData,
                  item['title'] as String,
                  item['onTap'] as VoidCallback,
                  isDarkMode,
                  isDestructive: item['isDestructive'] as bool? ?? false,
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap,
    bool isDarkMode, {
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: (isDestructive
                                  ? Colors.red
                                  : const Color(0xFF1DB954))
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            icon,
                            color: isDestructive
                                ? Colors.red
                                : const Color(0xFF1DB954),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDestructive
                                ? Colors.red
                                : (isDarkMode ? Colors.white : Colors.black87),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.4)
                            : Colors.black.withValues(alpha: 0.3),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===================== Helpers / Actions =====================

  void _openSettings() {
    // Điều hướng sang SettingsPage với hiệu ứng slide
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const SettingsPage(),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  void _shareProfile() {
    // TODO: dùng share_plus để share thực tế
    _showSnackBar('Share profile link copied!');
  }

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseAuth.instance.signOut();
                _showSnackBar('Logged out');
                // TODO: Điều hướng về SignIn nếu cần
                // Navigator.of(context).pushAndRemoveUntil(
                //   MaterialPageRoute(builder: (_) => const SigninPage()),
                //   (_) => false,
                // );
              } catch (e) {
                _showSnackBar('Log out failed: $e');
              }
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}
