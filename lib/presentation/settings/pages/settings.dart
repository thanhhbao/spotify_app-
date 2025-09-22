import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

/// SettingsPage - đồng bộ Firebase Auth + Firestore
/// - Cập nhật email (reauthenticate)
/// - Cập nhật mật khẩu
/// - Lưu các toggle/settings xuống Firestore: users/{uid}/meta/settings
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Settings states (UI)
  String _themeMode = 'System';
  bool _shareActivity = true;
  bool _autoplay = true;
  bool _crossfade = false;
  bool _normalizeVolume = true;
  bool _wifiOnly = false;
  bool _systemNotifications = true;
  bool _newReleases = true;
  bool _playlistUpdates = true;
  bool _marketing = false;
  String _streamQuality = 'High';
  String _downloadQuality = 'High';
  String _language = 'English';
  bool _publicPlaylists = true;

  // Firebase shortcut
  fb.FirebaseAuth get _auth => fb.FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    _loadSettingsFromFirestore();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Load settings ban đầu từ Firestore: users/{uid}/meta/settings
  Future<void> _loadSettingsFromFirestore() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('meta')
        .doc('settings')
        .get();
    if (!doc.exists) return;

    final d = doc.data()!;
    setState(() {
      _themeMode = (d['themeMode'] as String?) ?? _themeMode;
      _shareActivity = (d['shareActivity'] as bool?) ?? _shareActivity;
      _autoplay = (d['autoplay'] as bool?) ?? _autoplay;
      _crossfade = (d['crossfade'] as bool?) ?? _crossfade;
      _normalizeVolume = (d['normalizeVolume'] as bool?) ?? _normalizeVolume;
      _wifiOnly = (d['wifiOnly'] as bool?) ?? _wifiOnly;
      _systemNotifications =
          (d['systemNotifications'] as bool?) ?? _systemNotifications;
      _newReleases = (d['newReleases'] as bool?) ?? _newReleases;
      _playlistUpdates = (d['playlistUpdates'] as bool?) ?? _playlistUpdates;
      _marketing = (d['marketing'] as bool?) ?? _marketing;
      _streamQuality = (d['streamQuality'] as String?) ?? _streamQuality;
      _downloadQuality = (d['downloadQuality'] as String?) ?? _downloadQuality;
      _language = (d['language'] as String?) ?? _language;
      _publicPlaylists = (d['publicPlaylists'] as bool?) ?? _publicPlaylists;
    });
  }

  /// Lưu 1 key xuống Firestore
  Future<void> _saveSetting(String key, dynamic value) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('meta')
        .doc('settings')
        .set({key: value}, SetOptions(merge: true));
  }

  Future<void> _updateEmail({
    required String newEmail,
    required String currentPasswordIfAny,
  }) async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('No user signed in');
      return;
    }

    try {
      // Nếu đăng nhập bằng email/password -> reauth bằng mật khẩu
      final usesPasswordProvider =
          user.providerData.any((p) => p.providerId == 'password');

      if (usesPasswordProvider &&
          user.email != null &&
          currentPasswordIfAny.isNotEmpty) {
        final cred = fb.EmailAuthProvider.credential(
          email: user.email!,
          password: currentPasswordIfAny,
        );
        await user.reauthenticateWithCredential(cred);
      }

      // Gửi email xác minh trước khi cập nhật email
      await user.verifyBeforeUpdateEmail(newEmail);

      // (không cần user.updateEmail nữa)
      // Có thể lưu nháp vào Firestore nếu muốn hiển thị pending email:
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'pendingEmail': newEmail}, SetOptions(merge: true));

      _showSnackBar(
          'Verification email sent. Please confirm to finish change.');
      setState(() {});
    } on fb.FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? 'Failed to update email');
    }
  }

  /// Đổi mật khẩu (cần reauthenticate)
  Future<void> _updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      _showSnackBar('No user signed in');
      return;
    }
    try {
      final cred = fb.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      _showSnackBar('Password updated');
    } on fb.FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? 'Failed to update password');
    }
  }

  /// Đổi displayName
  Future<void> _updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.updateDisplayName(name);
      await _db.collection('users').doc(user.uid).set(
        {'displayName': name},
        SetOptions(merge: true),
      );
      _showSnackBar('Profile updated');
      setState(() {});
    } on fb.FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? 'Failed to update profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentUser = _auth.currentUser;

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
                        const Color(0xFF1DB954).withOpacity(0.1),
                        const Color(0xFF121212),
                        const Color(0xFF000000)
                      ]
                    : [
                        const Color(0xFF1DB954).withOpacity(0.05),
                        const Color(0xFFF8F9FA),
                        Colors.white
                      ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(isDarkMode),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildSection('Account',
                            _buildAccountSection(currentUser), isDarkMode),
                        _buildSection('Profile & Privacy',
                            _buildPrivacySection(), isDarkMode),
                        _buildSection(
                            'Playback', _buildPlaybackSection(), isDarkMode),
                        _buildSection('Audio & Downloads', _buildAudioSection(),
                            isDarkMode),
                        _buildSection('Notifications',
                            _buildNotificationSection(), isDarkMode),
                        _buildSection('Appearance', _buildAppearanceSection(),
                            isDarkMode),
                        _buildSection('Connected Devices',
                            _buildDevicesSection(), isDarkMode),
                        _buildSection(
                            'Help & About', _buildHelpSection(), isDarkMode),
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
    );
  }

  // ===================== UI helpers =====================

  Widget _buildHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          _glassBtn(Icons.arrow_back_ios_new, () => Navigator.pop(context),
              isDarkMode),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassBtn(IconData icon, VoidCallback onTap, bool isDarkMode) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Center(
                child: Icon(icon,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    size: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveDisplayName(String newName) async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final trimmed = newName.trim();
    // 1) Cập nhật displayName trên Firebase Auth
    await user.updateDisplayName(trimmed);

    // 2) Lưu vào Firestore: users/{uid}.displayName
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({'displayName': trimmed}, SetOptions(merge: true));

    // 3) Reload để UI đọc lại tên mới từ Auth (nếu bạn không dùng stream Firestore)
    await user.reload();

    _showSnackBar('Đã cập nhật tên');
  }

  Widget _buildSection(String title, Widget content, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1DB954),
                    ),
                  ),
                ),
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========== Sections ===========

  Widget _buildAccountSection(fb.User? currentUser) {
    final email = currentUser?.email ?? 'Unknown';
    final providers =
        currentUser?.providerData.map((e) => e.providerId).join(', ') ?? '-';

    return Column(
      children: [
        _menuItem(Icons.email_outlined, 'Email', email, _showEmailDialog),
        _menuItem(
            Icons.lock_outline, 'Change Password', null, _showPasswordDialog),
        _menuItem(Icons.login_outlined, 'Social Login', providers,
            _showSocialLoginDialog),
        _menuItem(Icons.credit_card_outlined, 'Subscription & Billing',
            'Premium - \$9.99/month', _showSubscriptionDialog),
      ],
    );
  }

  Widget _buildPrivacySection() {
    return Column(
      children: [
        _menuItem(
            Icons.edit_outlined, 'Edit Profile', null, _showEditProfileDialog),
        _switchItem(Icons.public_outlined, 'Public Playlists by Default',
            _publicPlaylists, (v) {
          setState(() => _publicPlaylists = v);
          _saveSetting('publicPlaylists', v);
        }),
        _switchItem(
            Icons.share_outlined, 'Share Listening Activity', _shareActivity,
            (v) {
          setState(() => _shareActivity = v);
          _saveSetting('shareActivity', v);
        }),
        _menuItem(Icons.block_outlined, 'Blocked Users', null,
            () => _showSnackBar('Blocked users management')),
      ],
    );
  }

  Widget _buildPlaybackSection() {
    return Column(
      children: [
        _switchItem(
            Icons.auto_awesome_outlined, 'Autoplay Similar Tracks', _autoplay,
            (v) {
          setState(() => _autoplay = v);
          _saveSetting('autoplay', v);
        }),
        _switchItem(Icons.merge_outlined, 'Crossfade', _crossfade, (v) {
          setState(() => _crossfade = v);
          _saveSetting('crossfade', v);
        }),
        _switchItem(
            Icons.volume_up_outlined, 'Normalize Volume', _normalizeVolume,
            (v) {
          setState(() => _normalizeVolume = v);
          _saveSetting('normalizeVolume', v);
        }),
        _menuItem(
            Icons.bedtime_outlined, 'Sleep Timer', null, _showSleepTimerDialog),
        _switchItem(Icons.wifi_outlined, 'Stream Only on Wi-Fi', _wifiOnly,
            (v) {
          setState(() => _wifiOnly = v);
          _saveSetting('wifiOnly', v);
        }),
      ],
    );
  }

  Widget _buildAudioSection() {
    return Column(
      children: [
        _dropdownItem(Icons.high_quality_outlined, 'Stream Quality',
            _streamQuality, ['Low', 'Normal', 'High', 'Very High'], (v) {
          setState(() => _streamQuality = v);
          _saveSetting('streamQuality', v);
        }),
        _dropdownItem(Icons.download_outlined, 'Download Quality',
            _downloadQuality, ['Normal', 'High', 'Very High'], (v) {
          setState(() => _downloadQuality = v);
          _saveSetting('downloadQuality', v);
        }),
        _menuItem(Icons.storage_outlined, 'Storage & Cache', 'Used: 2.4GB',
            _showStorageDialog),
        _menuItem(Icons.folder_outlined, 'Download Location',
            'Internal Storage', _showLocationDialog),
      ],
    );
  }

  Widget _buildNotificationSection() {
    return Column(
      children: [
        _switchItem(Icons.notifications_outlined, 'System Notifications',
            _systemNotifications, (v) {
          setState(() => _systemNotifications = v);
          _saveSetting('systemNotifications', v);
        }),
        _switchItem(Icons.new_releases_outlined, 'New Releases', _newReleases,
            (v) {
          setState(() => _newReleases = v);
          _saveSetting('newReleases', v);
        }),
        _switchItem(
            Icons.playlist_play_outlined, 'Playlist Updates', _playlistUpdates,
            (v) {
          setState(() => _playlistUpdates = v);
          _saveSetting('playlistUpdates', v);
        }),
        _switchItem(
            Icons.campaign_outlined, 'Marketing & Promotions', _marketing, (v) {
          setState(() => _marketing = v);
          _saveSetting('marketing', v);
        }),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    return Column(
      children: [
        _dropdownItem(Icons.palette_outlined, 'Theme', _themeMode,
            ['Light', 'Dark', 'System'], (v) {
          setState(() => _themeMode = v);
          _saveSetting('themeMode', v);
        }),
        _dropdownItem(Icons.language_outlined, 'Language', _language,
            ['English', 'Vietnamese', 'Spanish', 'French'], (v) {
          setState(() => _language = v);
          _saveSetting('language', v);
        }),
      ],
    );
  }

  Widget _buildDevicesSection() {
    return Column(
      children: [
        _menuItem(Icons.bluetooth_outlined, 'Bluetooth Devices', null,
            () => _showSnackBar('Bluetooth devices')),
        _menuItem(Icons.cast_outlined, 'Cast Devices', null,
            () => _showSnackBar('Chromecast/AirPlay devices')),
        _menuItem(Icons.mic_outlined, 'Voice Assistant', null,
            () => _showSnackBar('Voice assistant settings')),
        _menuItem(Icons.directions_car_outlined, 'Car Mode', null,
            () => _showSnackBar('Car mode settings')),
      ],
    );
  }

  Widget _buildHelpSection() {
    return Column(
      children: [
        _menuItem(Icons.help_outline, 'FAQ & Support', null,
            () => _showSnackBar('Opening help center')),
        _menuItem(Icons.info_outline, 'App Version', '1.0.0',
            () => _showSnackBar('App version: 1.0.0')),
        _menuItem(Icons.privacy_tip_outlined, 'Privacy Policy', null,
            () => _showSnackBar('Opening privacy policy')),
        _menuItem(Icons.gavel_outlined, 'Terms of Service', null,
            () => _showSnackBar('Opening terms of service')),
      ],
    );
  }

  // =========== Item builders ===========

  Widget _menuItem(
      IconData icon, String title, String? subtitle, VoidCallback onTap) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF1DB954), size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        )),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.6)
                                : Colors.black.withOpacity(0.5),
                          )),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Colors.grey.withOpacity(0.6), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switchItem(
      IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1DB954), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black87,
                )),
          ),
          Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF1DB954)),
        ],
      ),
    );
  }

  Widget _dropdownItem(IconData icon, String title, String value,
      List<String> options, ValueChanged<String> onChanged) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1DB954), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black87,
                )),
          ),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            items: options
                .map((option) => DropdownMenuItem<String>(
                      value: option,
                      child: Text(option,
                          style: TextStyle(
                              color:
                                  isDarkMode ? Colors.white : Colors.black87)),
                    ))
                .toList(),
            onChanged: (v) => onChanged(v!),
          ),
        ],
      ),
    );
  }

  // =========== Dialogs ===========

  void _showEmailDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emailCtrl =
        TextEditingController(text: _auth.currentUser?.email ?? '');
    final pwdCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Change Email',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                  labelText: 'New Email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pwdCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password (if email/password)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateEmail(
                  newEmail: emailCtrl.text.trim(),
                  currentPasswordIfAny: pwdCtrl.text);
            },
            child:
                const Text('Save', style: TextStyle(color: Color(0xFF1DB954))),
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Change Password',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Current Password', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'New Password', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updatePassword(
                  currentPassword: currentCtrl.text, newPassword: newCtrl.text);
            },
            child:
                const Text('Save', style: TextStyle(color: Color(0xFF1DB954))),
          ),
        ],
      ),
    );
  }

  void _showSocialLoginDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Social Login',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _socialBtn(Icons.g_mobiledata, 'Google', Colors.red,
                () => _showSnackBar('Connect Google')),
            const SizedBox(height: 12),
            _socialBtn(Icons.apple, 'Apple', Colors.black,
                () => _showSnackBar('Connect Apple')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _socialBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(context);
          onTap();
        },
        icon: Icon(icon, color: color),
        label: Text('Connect $label'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.withOpacity(0.1),
          foregroundColor: color,
        ),
      ),
    );
  }

  void _showSubscriptionDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Subscription',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Premium Plan',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF1DB954))),
            SizedBox(height: 8),
            Text('\$9.99/month'),
            SizedBox(height: 8),
            Text('Next billing: Mar 15, 2025'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl =
        TextEditingController(text: _auth.currentUser?.displayName ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Profile',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFF1DB954),
                child: Icon(Icons.person, color: Colors.white, size: 40)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Display Name', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateDisplayName(nameCtrl.text.trim());
            },
            child:
                const Text('Save', style: TextStyle(color: Color(0xFF1DB954))),
          ),
        ],
      ),
    );
  }

  void _showSleepTimerDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sleep Timer',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children:
              ['15 min', '30 min', '45 min', '1 hour', 'End of track'].map((o) {
            return ListTile(
              title: Text(o),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Sleep timer set to $o');
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  void _showStorageDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Storage & Cache',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Total used: 2.4GB'),
            const SizedBox(height: 8),
            const Text('Downloaded music: 1.8GB'),
            const Text('Cache: 600MB'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showSnackBar('Cache cleared');
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text('Clear Cache'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  void _showLocationDialog() => _showSnackBar('Download location settings');

  // =========== Utils ===========

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1DB954),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
