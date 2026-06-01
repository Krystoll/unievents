import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/api/games_service.dart';
import '../../models/game_stats.dart';
import '../game_scoring.dart';
import '../game_session.dart';
import '../widgets/games_layout.dart';
import '../widgets/games_scaffold.dart';
import 'tap_game_logic.dart';
import 'tap_shape_painter.dart';

class TapGameScreen extends StatefulWidget {
  const TapGameScreen({super.key, this.eventId});

  final String? eventId;

  @override
  State<TapGameScreen> createState() => _TapGameScreenState();
}

class _TapGameScreenState extends State<TapGameScreen> {
  final _random = Random();
  final _submitter = GameSessionSubmitter(GamesService());
  Timer? _timer;
  Timer? _clusterTimer;

  int _timeLeft = tapGameDurationSec;
  int _score = 0;
  int _misses = 0;
  int _combo = 0;
  int? _bestReactionMs;
  int _clusterId = 0;
  int _sessionId = 0;
  int _layoutGeneration = 0;
  bool _gameFinished = false;
  bool _scoreSubmitted = false;
  DateTime? _startedAt;
  TapInstruction _instruction = TapInstruction(
    shape: TargetShape.circle,
    color: targetPalette.first,
    shouldAvoid: false,
  );
  String? _feedback;
  Color? _feedbackColor;
  int _lastSpawnMs = 0;
  double _boardWidth = 0;
  double _boardHeight = 0;
  double _targetSizeScale = 1;
  List<GlyphDescriptor> _glyphs = [];

  bool get _gameInProgress => _startedAt != null && !_gameFinished && !_scoreSubmitted;

  @override
  void initState() {
    super.initState();
    _instruction = generateInstruction(_random);
    _startSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clusterTimer?.cancel();
    super.dispose();
  }

  void _startSession() {
    _timer?.cancel();
    _clusterTimer?.cancel();
    _submitter.submitted = false;
    setState(() {
      _timeLeft = tapGameDurationSec;
      _score = 0;
      _misses = 0;
      _combo = 0;
      _bestReactionMs = null;
      _clusterId = 0;
      _gameFinished = false;
      _scoreSubmitted = false;
      _startedAt = DateTime.now();
      _instruction = generateInstruction(_random);
      _feedback = null;
      _glyphs = [];
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          _gameFinished = true;
          _timer?.cancel();
          _clusterTimer?.cancel();
          _submitResult();
        }
      });
    });
    if (_boardWidth > 0 && _boardHeight > 0) {
      _spawnCluster();
    }
  }

  TapGameStage get _currentStage {
    final elapsed = tapGameDurationSec - _timeLeft;
    return tapStages.lastWhere((s) => elapsed >= s.startAtSec);
  }

  void _updateBoardSize(double width, double height) {
    if (width <= 0 || height <= 0) return;
    final ref = min(width, height);
    final scale = (ref / 280).clamp(0.35, 0.85);
    if (_boardWidth == width && _boardHeight == height && _targetSizeScale == scale) {
      return;
    }
    setState(() {
      _boardWidth = width;
      _boardHeight = height;
      _targetSizeScale = scale;
      _layoutGeneration++;
    });
    _spawnCluster();
  }

  Future<void> _submitResult() async {
    final durationMs = GameScoring.tapDurationSec * 1000;
    final saved = await _submitter.submit(
      SubmitGameScorePayload(
        gameType: GameType.tap,
        score: _score,
        durationMs: durationMs,
        progress: _score,
        completed: true,
        eventId: widget.eventId,
      ),
    );
    if (mounted) {
      setState(() => _scoreSubmitted = true);
      await showScoreSavedSnackBar(context, saved: saved);
    }
  }

  void _spawnCluster() {
    if (_gameFinished || _boardWidth <= 0 || _boardHeight <= 0) return;

    _clusterTimer?.cancel();
    _lastSpawnMs = DateTime.now().millisecondsSinceEpoch;
    final glyphs = generateGlyphs(
      random: _random,
      stage: _currentStage,
      instruction: _instruction,
      containerWidth: _boardWidth,
      containerHeight: _boardHeight,
      targetSizeScale: _targetSizeScale,
    );

    setState(() => _glyphs = glyphs);

    _clusterTimer = Timer(Duration(milliseconds: _currentStage.lifetimeMs), () {
      if (!mounted || _gameFinished) return;
      setState(() {
        _misses++;
        _combo = 0;
        _clusterId++;
        _instruction = generateInstruction(_random);
      });
      _spawnCluster();
    });
  }

  void _onHit(TapHitResult result) {
    if (_gameFinished) return;
    _clusterTimer?.cancel();

    final reaction = DateTime.now().millisecondsSinceEpoch - _lastSpawnMs;
    final theme = Theme.of(context);

    setState(() {
      switch (result) {
        case TapHitResult.correct:
          _combo++;
          final points = GameScoring.tapPointsForReaction(reaction, _combo);
          _score += points;
          _bestReactionMs =
              _bestReactionMs == null ? reaction : min(_bestReactionMs!, reaction);
          _feedback = '+$points';
          _feedbackColor = theme.colorScheme.primary;
        case TapHitResult.wrong:
          _combo = 0;
          _score = max(0, _score - 1);
          _misses++;
          _feedback = '-1';
          _feedbackColor = theme.colorScheme.error;
        case TapHitResult.bonus:
          _score += tapBonusScoreReward;
          _timeLeft += tapBonusTimeReward;
          _feedback = '+$tapBonusScoreReward +${tapBonusTimeReward}s';
          _feedbackColor = const Color(0xFFFFD54F);
      }
      _clusterId++;
      _instruction = generateInstruction(_random);
    });
    _spawnCluster();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _feedback = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final compact = isCompactGameScreen(context);
    final layoutGen = _layoutGeneration;

    return GamesScaffold(
      title: 'Tap-the-Target',
      gameInProgress: _gameInProgress,
      scoreSubmitted: _scoreSubmitted,
      child: GamePageLayout(
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Счёт: $_score', style: Theme.of(context).textTheme.titleSmall),
                Text('${_timeLeft}s • ${_currentStage.label}', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MiniStat(label: 'Комбо', value: '$_combo'),
                _MiniStat(label: 'Промахи', value: '$_misses'),
                _MiniStat(label: 'мс', value: _bestReactionMs?.toString() ?? '—'),
              ],
            ),
            const SizedBox(height: 6),
            _InstructionCard(instruction: _instruction, compact: compact),
          ],
        ),
        board: GameBoardContainer(
          overlay: _gameFinished
              ? _ResultOverlay(
                  score: _score,
                  bestReactionMs: _bestReactionMs,
                  onRestart: () {
                    setState(() => _sessionId++);
                    _startSession();
                  },
                )
              : _feedback != null
                  ? Container(
                      color: _feedbackColor!.withValues(alpha: 0.15),
                      alignment: Alignment.center,
                      child: Text(
                        _feedback!,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: _feedbackColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    )
                  : null,
          child: LayoutBuilder(
            builder: (context, constraints) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _updateBoardSize(constraints.maxWidth, constraints.maxHeight);
              });

              return Stack(
                key: ValueKey('$_sessionId-$_clusterId-$layoutGen'),
                clipBehavior: Clip.none,
                children: _glyphs.map((glyph) {
                  final size = _currentStage.targetSize * _targetSizeScale * glyph.sizeMultiplier;
                  return Positioned(
                    left: glyph.x.clamp(0, max(0, _boardWidth - size)),
                    top: glyph.y.clamp(0, max(0, _boardHeight - size)),
                    width: size,
                    height: size,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _onHit(evaluateTap(glyph, _instruction)),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: Size(size, size),
                            painter: TapShapePainter(shape: glyph.shape, color: glyph.color),
                          ),
                          if (glyph.isBonus)
                            Text('⚡', style: TextStyle(fontSize: max(12, size * 0.28))),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.labelLarge),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({required this.instruction, required this.compact});

  final TapInstruction instruction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instruction.shouldAvoid ? 'Не нажимайте' : 'Найдите: ${shapeTitle(instruction.shape)}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  if (!instruction.shouldAvoid)
                    Text(
                      instruction.color.title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: instruction.color.color,
                          ),
                    )
                  else
                    Text('Любую другую фигуру', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            SizedBox(
              width: compact ? 36 : 44,
              height: compact ? 36 : 44,
              child: CustomPaint(
                painter: TapShapePainter(
                  shape: instruction.shape,
                  color: instruction.color.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.score,
    required this.bestReactionMs,
    required this.onRestart,
  });

  final int score;
  final int? bestReactionMs;
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
              Text('Очки: $score'),
              Text('Лучшее: ${bestReactionMs ?? '—'} мс'),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRestart, child: const Text('Играть снова')),
            ],
          ),
        ),
      ),
    );
  }
}
