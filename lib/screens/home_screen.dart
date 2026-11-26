import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../game_engine/game_notifier.dart';
import '../localization/app_localizations.dart';
import '../settings/app_settings.dart';
import '../statistics/stats_models.dart';
import 'game_screen.dart';
import 'secondary_screens.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hasSavedGame = false;

  @override
  void initState() {
    super.initState();
    _checkSaved();
  }

  Future<void> _checkSaved() async {
    final has = await ref.read(gameProvider.notifier).hasSavedGame();
    if (mounted) setState(() => _hasSavedGame = has);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final stats = ref.watch(statsProvider);
    final loc = AppLocalizations(settings.language);
    final bg = AppThemes.backgroundGradients[settings.backgroundStyle] ??
        AppThemes.backgroundGradients['midnight']!;

    final menuItems = [
      (
        title: loc.t('new_game'),
        icon: Icons.play_circle_fill,
        color: const Color(0xFF10B981),
        onTap: () => _open(context, const AiSetupScreen()),
      ),
      (
        title: loc.t('play_ai'),
        icon: Icons.smart_toy,
        color: const Color(0xFF3B82F6),
        onTap: () => _open(context, const AiSetupScreen()),
      ),
      (
        title: loc.t('local_multiplayer'),
        icon: Icons.groups,
        color: const Color(0xFFF97316),
        onTap: () => _open(context, const LocalMultiplayerSetupScreen()),
      ),
      (
        title: loc.t('tournament'),
        icon: Icons.emoji_events,
        color: const Color(0xFFEAB308),
        onTap: () => _open(context, const TournamentScreen()),
      ),
      (
        title: loc.t('characters'),
        icon: Icons.face,
        color: const Color(0xFFEC4899),
        onTap: () => _open(context, const CharactersScreen()),
      ),
      (
        title: loc.t('card_collection'),
        icon: Icons.style,
        color: const Color(0xFF8B5CF6),
        onTap: () => _open(context, const CardCollectionScreen()),
      ),
      (
        title: loc.t('statistics'),
        icon: Icons.bar_chart,
        color: const Color(0xFF06B6D4),
        onTap: () => _open(context, const StatisticsScreen()),
      ),
      (
        title: loc.t('settings'),
        icon: Icons.settings,
        color: const Color(0xFF64748B),
        onTap: () => _open(context, const SettingsScreen()),
      ),
      (
        title: loc.t('rules'),
        icon: Icons.menu_book,
        color: const Color(0xFF14B8A6),
        onTap: () => _open(context, const RulesScreen()),
      ),
      (
        title: loc.t('about'),
        icon: Icons.info_outline,
        color: const Color(0xFF6366F1),
        onTap: () => _open(context, const AboutScreen()),
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: bg,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.t('app_title'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          loc.t('subtitle'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amberAccent),
                      ),
                      child: Text(
                        '🪙 ${stats.coins} ${loc.t('coins')}',
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasSavedGame)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await ref.read(gameProvider.notifier).resumeSavedGame();
                        if (context.mounted) {
                          await _open(context, const GameScreen());
                        }
                      },
                      icon: const Icon(Icons.restore),
                      label: Text(loc.t('resume_game')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE11D48),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.55,
                  ),
                  itemCount: menuItems.length,
                  itemBuilder: (context, idx) {
                    final item = menuItems[idx];
                    return _MenuButton(
                      title: item.title,
                      icon: item.icon,
                      color: item.color,
                      onTap: item.onTap,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    _checkSaved();
  }
}

class _MenuButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(color, Colors.white, 0.16)!,
                color,
                Color.lerp(color, Colors.black, 0.25)!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.45),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
