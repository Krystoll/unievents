import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../widgets/games_layout.dart';
import '../widgets/games_scaffold.dart';

const _simonMaxLives = 3;
const _simonMaxRounds = 10;
const _pointsPerRound = 10;
const _roundSuccessDelaySeconds = 3;

const _simonPadColors = [
  Color(0xFFFF6B6B),
  Color(0xFF4FC3F7),
  Color(0xFFFFF176),
  Color(0xFF81C784),
  Color(0xFFFF8A65),
  Color(0xFFBA68C8),
  Color(0xFF4DD0E1),
  Color(0xFFFFB74D),
  Color(0xFFA5D6A7),
  Color(0xFFEF5350),
  Color(0xFF42A5F5),
  Color(0xFFFFCA28),
  Color(0xFF66BB6A),
  Color(0xFFFF7043),
  Color(0xFFAB47BC),
  Color(0xFF26C6DA),
];

class SimonGameScreen extends StatefulWidget {
  const SimonGameScreen({super.key});

  @override
  State<SimonGameScreen> createState() => _SimonGameScreenState();
}

class _SimonGameScreenState extends State<SimonGameScreen> with SingleTickerProviderStateMixin {
  final _random = Random();

  int _playbackId = 0;
  int _celebrationId = 0;
  int _tapHighlightToken = 0;
  List<int> _sequence = [];
  int _lives = _simonMaxLives;
  int _round = 1;
  int _score = 0;
  int _playerIndex = 0;
  int? _highlightPad;
  bool _isShowing = false;
  bool _showRoundSuccess = false;
  int _lastRoundPoints = 0;
  int _countdownSeconds = 0;
  String _infoMessage = 'Слушайте последовательность';
  _SimonResult? _result;
  late final AnimationController _successPulse;

  int _sequenceLengthForRound(int round) => round + 1;

  @override
  void initState() {
    super.initState();
    _successPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _resetGame();
  }

  @override
  void dispose() {
    _successPulse.dispose();
    super.dispose();
  }

  void _resetGame() {
    _celebrationId++;
    _tapHighlightToken++;
    setState(() {
      _lives = _simonMaxLives;
      _round = 1;
      _score = 0;
      _result = null;
      _showRoundSuccess = false;
      _lastRoundPoints = 0;
      _countdownSeconds = 0;
      _sequence = List.generate(_sequenceLengthForRound(1), (_) => _random.nextInt(16));
      _playerIndex = 0;
      _isShowing = true;
      _highlightPad = null;
      _infoMessage = 'Слушайте последовательность';
    });
    _playSequence();
  }

  void _flashPad(int padId) {
    final token = ++_tapHighlightToken;
    setState(() => _highlightPad = padId);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted && token == _tapHighlightToken && !_showRoundSuccess) {
        setState(() => _highlightPad = null);
      }
    });
  }

  void _clearPadHighlight() {
    _tapHighlightToken++;
    setState(() => _highlightPad = null);
  }

  Future<void> _playSequence() async {
    final playbackId = ++_playbackId;
    if (!mounted || _result != null) return;

    _clearPadHighlight();

    await Future<void>.delayed(const Duration(milliseconds: 500));
    for (final padId in _sequence) {
      if (!mounted || playbackId != _playbackId || _result != null) return;
      setState(() => _highlightPad = padId);
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted || playbackId != _playbackId) return;
      setState(() => _highlightPad = null);
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    if (!mounted || playbackId != _playbackId || _result != null) return;
    setState(() {
      _isShowing = false;
      _infoMessage = 'Повторите последовательность';
      _playerIndex = 0;
      _highlightPad = null;
    });
  }

  Future<void> _celebrateRoundSuccess() async {
    final celebrationId = ++_celebrationId;
    final points = _pointsPerRound;

    _clearPadHighlight();

    setState(() {
      _score += points;
      _lastRoundPoints = points;
      _showRoundSuccess = true;
      _isShowing = true;
      _countdownSeconds = _roundSuccessDelaySeconds;
      _infoMessage = 'Отлично! +$points очков';
    });

    _successPulse.repeat(reverse: true);

    for (var sec = _roundSuccessDelaySeconds; sec > 0; sec--) {
      if (!mounted || celebrationId != _celebrationId || _result != null) return;
      setState(() => _countdownSeconds = sec);
      await Future<void>.delayed(const Duration(seconds: 1));
    }

    _successPulse.stop();
    _successPulse.reset();

    if (!mounted || celebrationId != _celebrationId || _result != null) return;

    if (_round >= _simonMaxRounds) {
      setState(() {
        _result = _SimonResult(round: _round, score: _score);
        _showRoundSuccess = false;
        _isShowing = false;
        _countdownSeconds = 0;
        _highlightPad = null;
      });
      return;
    }

    setState(() {
      _showRoundSuccess = false;
      _countdownSeconds = 0;
      _round++;
      _sequence = List.generate(_sequenceLengthForRound(_round), (_) => _random.nextInt(16));
      _playerIndex = 0;
      _isShowing = true;
      _highlightPad = null;
      _infoMessage = 'Раунд $_round — слушайте';
    });
    _playSequence();
  }

  void _handlePadTap(int padId) {
    if (_isShowing || _result != null || _showRoundSuccess) return;

    _flashPad(padId);

    final expected = _sequence.elementAtOrNull(_playerIndex);
    if (padId == expected) {
      _playerIndex++;
      if (_playerIndex == _sequence.length) {
        _clearPadHighlight();
        _celebrateRoundSuccess();
      }
      return;
    }

    _clearPadHighlight();

    final newLives = _lives - 1;
    if (newLives > 0) {
      setState(() {
        _lives = newLives;
        _infoMessage = 'Ошибка! Жизней: $newLives';
        _playerIndex = 0;
        _isShowing = true;
      });
      _playSequence();
    } else {
      setState(() {
        _lives = 0;
        _infoMessage = 'Все жизни потрачены';
        _result = _SimonResult(round: _round, score: _score);
        _isShowing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = isCompactGameScreen(context);

    return GamesScaffold(
      title: 'Запомни и повтори',
      child: GamePageLayout(
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Раунд $_round/$_simonMaxRounds • длина ${_sequence.length}',
              style: compact
                  ? Theme.of(context).textTheme.labelLarge
                  : Theme.of(context).textTheme.titleSmall,
            ),
            Text('Счёт: $_score', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Жизни:', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 6),
                ...List.generate(_simonMaxLives, (index) {
                  final active = index < _lives;
                  return Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHigh,
                    ),
                  );
                }),
              ],
            ),
            Text(_infoMessage, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        board: GameBoardContainer(
          overlay: Stack(
            fit: StackFit.expand,
            children: [
              if (_showRoundSuccess)
                _RoundSuccessOverlay(
                  lastPoints: _lastRoundPoints,
                  countdownSeconds: _countdownSeconds,
                  pulse: _successPulse,
                ),
              if (_result != null)
                _SimonResultOverlay(
                  result: _result!,
                  onRestart: _resetGame,
                ),
            ],
          ),
          child: AdaptiveFixedGrid(
            columns: 4,
            rows: 4,
            itemCount: 16,
            spacing: compact ? 4 : 6,
            itemBuilder: (context, index, cellWidth, cellHeight) {
              final active = !_showRoundSuccess && _highlightPad == index;
              final successGlow = _showRoundSuccess;
              final color = successGlow
                  ? const Color(0xFF66BB6A).withValues(alpha: 0.85)
                  : _simonPadColors[index].withValues(alpha: active ? 1 : 0.65);
              final fontSize = compactFontSize(min(cellWidth, cellHeight), factor: 0.35, max: 16);

              return AnimatedScale(
                scale: active ? 1.12 : (successGlow ? 1.05 : 1),
                duration: const Duration(milliseconds: 120),
                child: Material(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: (_isShowing || _result != null || _showRoundSuccess)
                        ? null
                        : () => _handlePadTap(index),
                    borderRadius: BorderRadius.circular(8),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RoundSuccessOverlay extends StatelessWidget {
  const _RoundSuccessOverlay({
    required this.lastPoints,
    required this.countdownSeconds,
    required this.pulse,
  });

  final int lastPoints;
  final int countdownSeconds;
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        return Container(
          color: Colors.green.withValues(alpha: 0.12 + pulse.value * 0.08),
          alignment: Alignment.center,
          child: Transform.scale(
            scale: 1 + pulse.value * 0.08,
            child: child,
          ),
        );
      },
      child: Card(
        elevation: 8,
        color: const Color(0xFF43A047),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 48),
              const SizedBox(height: 8),
              Text(
                'Верно!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '+$lastPoints очков',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                countdownSeconds > 0
                    ? 'Следующий раунд через $countdownSeconds сек'
                    : 'Готовим следующий раунд...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimonResult {
  _SimonResult({required this.round, required this.score});

  final int round;
  final int score;
}

class _SimonResultOverlay extends StatelessWidget {
  const _SimonResultOverlay({required this.result, required this.onRestart});

  final _SimonResult result;
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
              Text('Результат', style: Theme.of(context).textTheme.titleLarge),
              Text('Раунд: ${result.round}'),
              Text('Очки: ${result.score}'),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRestart, child: const Text('Играть снова')),
            ],
          ),
        ),
      ),
    );
  }
}

extension _ListExt<T> on List<T> {
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}
