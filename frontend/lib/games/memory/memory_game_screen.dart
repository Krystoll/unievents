import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/api/games_service.dart';
import '../../models/game_stats.dart';
import '../game_scoring.dart';
import '../game_session.dart';
import '../widgets/games_layout.dart';
import '../widgets/games_scaffold.dart';
import 'memory_game_logic.dart';

const _levelCompleteDelay = Duration(seconds: 2);
const _maxLives = 3;

class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> with SingleTickerProviderStateMixin {
  final _random = Random();
  final _submitter = GameSessionSubmitter(GamesService());

  int _levelIndex = 0;
  int _sessionId = 0;
  int _levelToken = 0;
  int _celebrationToken = 0;
  int _lives = _maxLives;
  int _pairPoints = 0;
  int _finalScore = 0;
  int _elapsedMs = 0;
  int _activeElapsedMs = 0;
  List<MemoryCard> _cards = [];
  List<int> _opened = [];
  bool _boardLocked = true;
  bool _isPreview = true;
  bool _sessionEnded = false;
  bool _showLevelComplete = false;
  bool _allLevelsCompleted = false;
  bool _scoreSubmitted = false;
  String? _infoMessage;
  DateTime? _startedAt;
  DateTime? _timerSegmentStart;
  bool _timerPaused = true;
  Timer? _elapsedTimer;
  late final AnimationController _levelPulse;

  MemoryLevel get _level => memoryLevels[_levelIndex];
  bool get _gameInProgress => _startedAt != null && !_sessionEnded && !_scoreSubmitted;

  @override
  void initState() {
    super.initState();
    _levelPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _startLevel();
  }

  @override
  void dispose() {
    _levelPulse.dispose();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  void _syncElapsed() {
    if (_timerPaused || _timerSegmentStart == null) {
      _elapsedMs = _activeElapsedMs;
      return;
    }
    _elapsedMs = _activeElapsedMs + DateTime.now().difference(_timerSegmentStart!).inMilliseconds;
  }

  void _pauseTimer() {
    if (!_timerPaused && _timerSegmentStart != null) {
      _activeElapsedMs += DateTime.now().difference(_timerSegmentStart!).inMilliseconds;
    }
    _timerSegmentStart = null;
    _timerPaused = true;
    _elapsedTimer?.cancel();
    _syncElapsed();
  }

  void _resumeTimer() {
    if (_sessionEnded || !_timerPaused) return;
    _timerPaused = false;
    _timerSegmentStart = DateTime.now();
    _startedAt ??= DateTime.now();
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _sessionEnded || _timerPaused) return;
      setState(_syncElapsed);
    });
  }

  Future<void> _startLevel() async {
    final token = ++_levelToken;
    _pauseTimer();
    setState(() {
      _cards = generateMemoryCards(_level, _random).map((c) => c.copyWith(isFaceUp: true)).toList();
      _opened = [];
      _boardLocked = true;
      _isPreview = true;
      _showLevelComplete = false;
      _infoMessage = 'Запоминайте пары (${_level.previewMillis / 1000}s)';
    });

    await Future<void>.delayed(Duration(milliseconds: _level.previewMillis));
    if (!mounted || token != _levelToken) return;

    setState(() {
      _cards = _cards.map((c) => c.copyWith(isFaceUp: false)).toList();
      _boardLocked = false;
      _isPreview = false;
      _infoMessage = null;
    });
    _resumeTimer();
  }

  void _restartRun() {
    _levelToken++;
    _celebrationToken++;
    _elapsedTimer?.cancel();
    _submitter.submitted = false;
    _levelPulse.stop();
    _levelPulse.reset();
    setState(() {
      _lives = _maxLives;
      _pairPoints = 0;
      _finalScore = 0;
      _elapsedMs = 0;
      _activeElapsedMs = 0;
      _levelIndex = 0;
      _sessionId++;
      _sessionEnded = false;
      _showLevelComplete = false;
      _allLevelsCompleted = false;
      _scoreSubmitted = false;
      _startedAt = null;
      _timerSegmentStart = null;
      _timerPaused = true;
    });
    _startLevel();
  }

  Future<void> _loseLife(String reason) async {
    final newLives = _lives - 1;
    setState(() {
      _lives = newLives;
      _infoMessage = '$reason Жизней: $newLives';
    });
    if (newLives <= 0) {
      await _finishSession(allLevelsCompleted: false);
    }
  }

  Future<void> _finishSession({required bool allLevelsCompleted}) async {
    if (_sessionEnded) return;
    _pauseTimer();
    _allLevelsCompleted = allLevelsCompleted;
    final levelsDone = allLevelsCompleted ? memoryLevels.length : _levelIndex + 1;
    final score = GameScoring.memoryFinal(
      levelsCompleted: levelsDone,
      pairPoints: _pairPoints,
      elapsedMs: _elapsedMs,
      allLevelsCompleted: allLevelsCompleted,
    );

    setState(() {
      _sessionEnded = true;
      _finalScore = score;
      _boardLocked = true;
      _showLevelComplete = false;
    });

    final saved = await _submitter.submit(
      SubmitGameScorePayload(
        gameType: GameType.memory,
        score: score,
        durationMs: _elapsedMs,
        progress: levelsDone,
        completed: allLevelsCompleted,
      ),
    );
    if (mounted) {
      setState(() => _scoreSubmitted = true);
      await showScoreSavedSnackBar(context, saved: saved);
    }
  }

  Future<void> _celebrateLevelComplete() async {
    final token = ++_celebrationToken;
    final isLastLevel = _levelIndex >= memoryLevels.length - 1;

    _pauseTimer();
    setState(() {
      _showLevelComplete = true;
      _boardLocked = true;
      _infoMessage = isLastLevel ? 'Все уровни пройдены!' : 'Уровень ${_levelIndex + 1} пройден!';
    });
    _levelPulse.repeat(reverse: true);

    await Future<void>.delayed(_levelCompleteDelay);
    _levelPulse.stop();
    _levelPulse.reset();

    if (!mounted || token != _celebrationToken) return;

    if (isLastLevel) {
      await _finishSession(allLevelsCompleted: true);
      return;
    }

    setState(() {
      _showLevelComplete = false;
      _levelIndex++;
    });
    await _startLevel();
  }

  Future<void> _handleCardClick(int index) async {
    if (_boardLocked || _sessionEnded || _isPreview || _showLevelComplete) return;
    final card = _cards[index];
    if (card.isFaceUp || card.isMatched) return;

    if (card.isMine) {
      setState(() {
        _boardLocked = true;
        _pairPoints = max(0, _pairPoints - 2);
        _cards[index] = card.copyWith(isFaceUp: true);
      });
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() {
        _cards[index] = _cards[index].copyWith(isFaceUp: false);
        _boardLocked = false;
      });
      await _loseLife('Мина!');
      return;
    }

    setState(() {
      _cards[index] = card.copyWith(isFaceUp: true);
      _opened = [..._opened, index];
    });

    if (_opened.length < 2) return;

    setState(() => _boardLocked = true);
    final first = _opened[0];
    final second = _opened[1];
    final firstCard = _cards[first];
    final secondCard = _cards[second];

    if (firstCard.sticker == secondCard.sticker && !firstCard.isMine) {
      setState(() {
        _cards[first] = firstCard.copyWith(isMatched: true);
        _cards[second] = secondCard.copyWith(isMatched: true);
        _pairPoints += 8;
        _opened = [];
      });

      final totalPairs = _cards.where((c) => !c.isMine).length ~/ 2;
      final matchedPairs = _cards.where((c) => c.isMatched && !c.isMine).length ~/ 2;
      if (matchedPairs >= totalPairs) {
        await _celebrateLevelComplete();
      } else if (mounted) {
        setState(() => _boardLocked = false);
      }
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() {
        _cards[first] = _cards[first].copyWith(isFaceUp: false);
        _cards[second] = _cards[second].copyWith(isFaceUp: false);
        _opened = [];
        _boardLocked = false;
      });
      await _loseLife('Ошибка!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = isCompactGameScreen(context);
    final textStyle = compact
        ? Theme.of(context).textTheme.bodySmall
        : Theme.of(context).textTheme.bodyMedium;

    return GamesScaffold(
      title: 'Мини-memory',
      gameInProgress: _gameInProgress,
      scoreSubmitted: _scoreSubmitted,
      child: GamePageLayout(
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Уровень ${_levelIndex + 1}/${memoryLevels.length} • ${_level.rows}×${_level.cols}',
              style: compact
                  ? Theme.of(context).textTheme.labelLarge
                  : Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              'Жизни: $_lives • Пары: +$_pairPoints • Время: ${GameScoring.formatDuration(_elapsedMs)}',
              style: textStyle,
            ),
            if (_infoMessage != null)
              Text(
                _infoMessage!,
                style: textStyle?.copyWith(color: Theme.of(context).colorScheme.secondary),
              ),
          ],
        ),
        board: GameBoardContainer(
          overlay: Stack(
            fit: StackFit.expand,
            children: [
              if (_isPreview && !_sessionEnded && !_showLevelComplete)
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Запоминайте пары',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
              if (_showLevelComplete)
                _LevelCompleteOverlay(
                  levelNumber: _levelIndex + 1,
                  isLastLevel: _levelIndex >= memoryLevels.length - 1,
                  pulse: _levelPulse,
                ),
              if (_sessionEnded)
                _SessionResultOverlay(
                  title: _allLevelsCompleted ? 'Победа!' : 'Игра окончена',
                  score: _finalScore,
                  subtitle: gameResultSubtitle(
                    score: _finalScore,
                    durationMs: _elapsedMs,
                    progress: _allLevelsCompleted ? memoryLevels.length : _levelIndex + 1,
                    completed: _allLevelsCompleted,
                  ),
                  onRestart: _restartRun,
                ),
            ],
          ),
          child: AdaptiveFixedGrid(
            key: ValueKey('$_levelIndex-$_sessionId'),
            columns: _level.cols,
            rows: _level.rows,
            itemCount: _cards.length,
            spacing: compact ? 4 : 6,
            cellAspectRatio: 0.85,
            itemBuilder: (context, index, cellWidth, cellHeight) {
              final card = _cards[index];
              return _MemoryCardTile(
                card: card,
                enabled: !_boardLocked,
                isPreviewPhase: _isPreview,
                fontSize: compactFontSize(min(cellWidth, cellHeight), factor: _isPreview ? 0.58 : 0.5),
                onTap: () => _handleCardClick(index),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SessionResultOverlay extends StatelessWidget {
  const _SessionResultOverlay({
    required this.title,
    required this.score,
    required this.subtitle,
    required this.onRestart,
  });

  final String title;
  final int score;
  final String subtitle;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
      alignment: Alignment.center,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              Text('Итоговый счёт: $score', style: Theme.of(context).textTheme.titleMedium),
              Text(subtitle, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRestart, child: const Text('Играть снова')),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCompleteOverlay extends StatelessWidget {
  const _LevelCompleteOverlay({
    required this.levelNumber,
    required this.isLastLevel,
    required this.pulse,
  });

  final int levelNumber;
  final bool isLastLevel;
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        return Container(
          color: Colors.green.withValues(alpha: 0.1 + pulse.value * 0.06),
          alignment: Alignment.center,
          child: Transform.scale(scale: 1 + pulse.value * 0.05, child: child),
        );
      },
      child: Card(
        elevation: 8,
        color: const Color(0xFF43A047),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 48),
              const SizedBox(height: 8),
              Text(
                isLastLevel ? 'Все уровни пройдены!' : 'Уровень пройден!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              Text(
                isLastLevel ? 'Подсчитываем результат...' : 'Уровень $levelNumber завершён',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemoryCardTile extends StatelessWidget {
  const _MemoryCardTile({
    required this.card,
    required this.enabled,
    required this.isPreviewPhase,
    required this.fontSize,
    required this.onTap,
  });

  final MemoryCard card;
  final bool enabled;
  final bool isPreviewPhase;
  final double fontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final faceUp = card.isFaceUp || card.isMatched;
    Color bg;
    Color borderColor = Colors.transparent;
    var borderWidth = 0.0;

    if (isPreviewPhase && faceUp) {
      bg = card.isMine ? const Color(0xFFFFCDD2) : const Color(0xFFE8F5E9);
      borderColor = card.isMine ? const Color(0xFFE53935) : const Color(0xFF43A047);
      borderWidth = 2;
    } else if (card.isMatched) {
      bg = Theme.of(context).colorScheme.primaryContainer;
    } else if (card.isMine && card.isFaceUp) {
      bg = Theme.of(context).colorScheme.errorContainer;
    } else if (faceUp) {
      bg = Theme.of(context).colorScheme.secondaryContainer;
    } else {
      bg = Theme.of(context).colorScheme.surfaceContainerHigh;
    }

    return Material(
      color: bg,
      elevation: isPreviewPhase && faceUp ? 3 : 0,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: enabled && !card.isMatched && !card.isFaceUp ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Center(
            child: FittedBox(
              child: Text(faceUp ? card.sticker : '?', style: TextStyle(fontSize: fontSize)),
            ),
          ),
        ),
      ),
    );
  }
}
