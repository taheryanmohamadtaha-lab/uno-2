import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game_engine/game_notifier.dart';
import '../localization/app_localizations.dart';
import '../models/character.dart';
import '../models/player.dart';
import '../settings/app_settings.dart';
import '../statistics/stats_models.dart';
import '../tournament/tournament_notifier.dart';
import 'game_screen.dart';

class AiSetupScreen extends ConsumerStatefulWidget {
  const AiSetupScreen({super.key});

  @override
  ConsumerState<AiSetupScreen> createState() => _AiSetupScreenState();
}

class _AiSetupScreenState extends ConsumerState<AiSetupScreen> {
  int _opponents = 2;
  AiDifficulty _difficulty = AiDifficulty.medium;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final loc = AppLocalizations(settings.language);

    return Scaffold(
      appBar: AppBar(title: Text(loc.t('play_ai'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            loc.isFa ? 'تعداد رقبای هوش مصنوعی' : 'AI Opponents',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _opponents.toDouble(),
            min: 1,
            max: 3,
            divisions: 2,
            label: '$_opponents',
            onChanged: (v) => setState(() => _opponents = v.round()),
          ),
          const SizedBox(height: 16),
          Text(
            loc.isFa ? 'سطح دشواری' : 'Difficulty',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SegmentedButton<AiDifficulty>(
            segments: [
              ButtonSegment(
                value: AiDifficulty.easy,
                label: Text(loc.t('easy')),
              ),
              ButtonSegment(
                value: AiDifficulty.medium,
                label: Text(loc.t('medium')),
              ),
              ButtonSegment(
                value: AiDifficulty.hard,
                label: Text(loc.t('hard')),
              ),
            ],
            selected: {_difficulty},
            onSelectionChanged: (s) => setState(() => _difficulty = s.first),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () {
              ref.read(gameProvider.notifier).startAiGame(
                    opponentCount: _opponents,
                    difficulty: _difficulty,
                    rules: settings.rulesConfig,
                    playerCharacterId: settings.selectedCharacterId,
                  );
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const GameScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: Text(loc.t('new_game')),
          ),
        ],
      ),
    );
  }
}

class LocalMultiplayerSetupScreen extends ConsumerStatefulWidget {
  const LocalMultiplayerSetupScreen({super.key});

  @override
  ConsumerState<LocalMultiplayerSetupScreen> createState() =>
      _LocalMultiplayerSetupScreenState();
}

class _LocalMultiplayerSetupScreenState
    extends ConsumerState<LocalMultiplayerSetupScreen> {
  int _count = 2;
  final List<TextEditingController> _controllers = List.generate(
    4,
    (i) => TextEditingController(text: 'بازیکن ${i + 1}'),
  );

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final loc = AppLocalizations(settings.language);

    return Scaffold(
      appBar: AppBar(title: Text(loc.t('local_multiplayer'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            loc.isFa ? 'تعداد بازیکنان (۲ تا ۴ نفر)' : 'Players (2-4)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _count.toDouble(),
            min: 2,
            max: 4,
            divisions: 2,
            label: '$_count',
            onChanged: (v) => setState(() => _count = v.round()),
          ),
          for (int i = 0; i < _count; i++) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _controllers[i],
              decoration: InputDecoration(
                labelText: '${loc.isFa ? 'نام بازیکن' : 'Player'} ${i + 1}',
                prefixText: '${kGameCharacters[i].emoji} ',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final list = [
                for (int i = 0; i < _count; i++)
                  (
                    name: _controllers[i].text.trim().isEmpty
                        ? 'Player ${i + 1}'
                        : _controllers[i].text.trim(),
                    characterId: kGameCharacters[i].id,
                  ),
              ];
              ref.read(gameProvider.notifier).startLocalMultiplayer(
                    humanPlayers: list,
                    rules: settings.rulesConfig,
                  );
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const GameScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFFF97316),
              foregroundColor: Colors.white,
            ),
            child: Text(loc.t('new_game')),
          ),
        ],
      ),
    );
  }
}

class TournamentScreen extends ConsumerWidget {
  const TournamentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tState = ref.watch(tournamentProvider);
    final settings = ref.watch(settingsProvider);
    final loc = AppLocalizations(settings.language);

    return Scaffold(
      appBar: AppBar(title: Text(loc.t('tournament'))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.emoji_events, color: Colors.amber),
                title: Text(loc.isFa
                    ? 'مرحله فعلی: ${tState.currentStage} از ۳'
                    : 'Current Stage: ${tState.currentStage} / 3'),
                subtitle: Text(loc.isFa
                    ? 'تورنمنت‌های برده: ${tState.tournamentsWon} | امتیاز کل: ${tState.totalPoints}'
                    : 'Won: ${tState.tournamentsWon} | Points: ${tState.totalPoints}'),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (!tState.inProgress) {
                  await ref.read(tournamentProvider.notifier).startTournament();
                }
                final diff = tState.currentStage == 1
                    ? AiDifficulty.easy
                    : (tState.currentStage == 2
                        ? AiDifficulty.medium
                        : AiDifficulty.hard);
                ref.read(gameProvider.notifier).startAiGame(
                      opponentCount: 3,
                      difficulty: diff,
                      rules: settings.rulesConfig,
                      playerCharacterId: settings.selectedCharacterId,
                      isTournament: true,
                    );
                if (context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GameScreen()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFFEAB308),
                foregroundColor: Colors.black,
              ),
              child: Text(
                loc.isFa ? 'شروع / ادامه مسابقه تورنمنت' : 'Play Tournament Match',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CharactersScreen extends ConsumerWidget {
  const CharactersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final settings = ref.watch(settingsProvider);
    final loc = AppLocalizations(settings.language);

    return Scaffold(
      appBar: AppBar(title: Text(loc.t('characters'))),
      body: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: kGameCharacters.length,
        itemBuilder: (context, idx) {
          final c = kGameCharacters[idx];
          final unlocked = stats.unlockedCharacters.contains(c.id);
          final selected = settings.selectedCharacterId == c.id;

          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: c.primaryColor,
                child: Text(c.emoji, style: const TextStyle(fontSize: 22)),
              ),
              title: Text(c.name(settings.language)),
              subtitle: Text('${c.style(settings.language)} • ${c.specialQuoteFa}'),
              trailing: unlocked
                  ? (selected
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : ElevatedButton(
                          onPressed: () => ref
                              .read(settingsProvider.notifier)
                              .update(settings.copyWith(selectedCharacterId: c.id)),
                          child: Text(loc.isFa ? 'انتخاب' : 'Select'),
                        ))
                  : ElevatedButton(
                      onPressed: () => ref
                          .read(statsProvider.notifier)
                          .unlockCharacter(c.id, c.unlockCost),
                      child: Text('🪙 ${c.unlockCost}'),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class CardCollectionScreen extends ConsumerWidget {
  const CardCollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final settings = ref.watch(settingsProvider);
    final loc = AppLocalizations(settings.language);

    final backs = [
      (id: 'classic_dark', nameFa: 'کلاسیک تیره', cost: 0),
      (id: 'royal_gold', nameFa: 'طلایی سلطنتی', cost: 0),
      (id: 'neon_cyber', nameFa: 'نئون سایبری', cost: 150),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(loc.t('card_collection'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: backs.map((b) {
          final unlocked = stats.unlockedCardBacks.contains(b.id);
          final selected = settings.cardBackStyle == b.id;
          return Card(
            child: ListTile(
              title: Text(b.nameFa),
              trailing: unlocked
                  ? (selected
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : ElevatedButton(
                          onPressed: () => ref
                              .read(settingsProvider.notifier)
                              .update(settings.copyWith(cardBackStyle: b.id)),
                          child: Text(loc.isFa ? 'فعال‌سازی' : 'Equip'),
                        ))
                  : ElevatedButton(
                      onPressed: () => ref
                          .read(statsProvider.notifier)
                          .unlockCardBack(b.id, b.cost),
                      child: Text('🪙 ${b.cost}'),
                    ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final settings = ref.watch(settingsProvider);
    final loc = AppLocalizations(settings.language);

    return Scaffold(
      appBar: AppBar(title: Text(loc.t('statistics'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text(loc.isFa ? 'کل بازی‌ها' : 'Games Played'),
              trailing: Text('${stats.gamesPlayed}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          Card(
            child: ListTile(
              title: Text(loc.isFa ? 'برد / باخت' : 'Wins / Losses'),
              trailing: Text('${stats.wins} / ${stats.losses}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          Card(
            child: ListTile(
              title: Text(loc.isFa ? 'بهترین امتیاز' : 'Best Score'),
              trailing: Text('${stats.bestScore}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          Card(
            child: ListTile(
              title: Text(loc.isFa ? 'دستاوردهای بازشده' : 'Achievements'),
              trailing: Text('${stats.unlockedAchievements.length} / 3',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final loc = AppLocalizations(s.language);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(loc.t('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          ListTile(
            title: Text(loc.t('language')),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'fa', label: Text('فارسی')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {s.language},
              onSelectionChanged: (v) =>
                  notifier.update(s.copyWith(language: v.first)),
            ),
          ),
          SwitchListTile(
            title: Text(loc.t('dark_mode')),
            value: s.darkMode,
            onChanged: (v) => notifier.update(s.copyWith(darkMode: v)),
          ),
          SwitchListTile(
            title: Text(loc.t('sound_fx')),
            value: s.soundEnabled,
            onChanged: (v) => notifier.update(s.copyWith(soundEnabled: v)),
          ),
          SwitchListTile(
            title: Text(loc.t('vibration')),
            value: s.vibrationEnabled,
            onChanged: (v) => notifier.update(s.copyWith(vibrationEnabled: v)),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(loc.t('stacking')),
            value: s.rulesConfig.allowStacking,
            onChanged: (v) => notifier.update(
              s.copyWith(rulesConfig: s.rulesConfig.copyWith(allowStacking: v)),
            ),
          ),
          SwitchListTile(
            title: Text(loc.t('seven_zero')),
            value: s.rulesConfig.sevenZeroRule,
            onChanged: (v) => notifier.update(
              s.copyWith(rulesConfig: s.rulesConfig.copyWith(sevenZeroRule: v)),
            ),
          ),
          SwitchListTile(
            title: Text(loc.t('jump_in')),
            value: s.rulesConfig.allowJumpIn,
            onChanged: (v) => notifier.update(
              s.copyWith(rulesConfig: s.rulesConfig.copyWith(allowJumpIn: v)),
            ),
          ),
          SwitchListTile(
            title: Text(loc.t('draw_until')),
            value: s.rulesConfig.drawUntilPlayable,
            onChanged: (v) => notifier.update(
              s.copyWith(
                  rulesConfig: s.rulesConfig.copyWith(drawUntilPlayable: v)),
            ),
          ),
        ],
      ),
    );
  }
}

class RulesScreen extends ConsumerWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations(ref.watch(settingsProvider).language);
    return Scaffold(
      appBar: AppBar(title: Text(loc.t('rules'))),
      body: const Padding(
        padding: EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Text(
            '• بازی با ۱۰۸ کارت استاندارد و ۷ کارت اولیه برای هر بازیکن آغاز می‌شود.\n'
            '• کارت انتخابی باید هم‌رنگ، هم‌عدد یا هم‌نماد با کارت روی زمین باشد.\n'
            '• با رسیدن به ۱ کارت حتماً دکمه UNO را بزنید؛ در غیر این صورت ۲ کارت جریمه می‌شوید.\n'
            '• کارت +4 فقط زمانی مجاز است که رنگ فعال را در دست نداشته باشید؛ در غیر این صورت حریف می‌تواند اعتراض کند (+4 یا +6 کارت جریمه).\n'
            '• در بازی دونفره، کارت Reverse همانند Skip عمل می‌کند.',
            style: TextStyle(fontSize: 15, height: 1.7),
          ),
        ),
      ),
    );
  }
}

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations(ref.watch(settingsProvider).language);
    return Scaffold(
      appBar: AppBar(title: Text(loc.t('about'))),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'UNO Party V1.0\nبازی کارتی سه‌بعدی آفلاین برای اندروید\nساخته‌شده با Flutter و Dart',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, height: 1.7),
          ),
        ),
      ),
    );
  }
}
