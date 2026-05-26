import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/api/games_service.dart';
import '../../models/game_stats.dart';
import '../game_scoring.dart';
import '../game_session.dart';
import '../widgets/games_layout.dart';
import '../widgets/games_scaffold.dart';
import 'pattern_game_logic.dart';

class PatternGameScreen extends StatefulWidget {
  const PatternGameScreen({super.key});

  @override
  State<PatternGameScreen> createState() => _PatternGameScreenState();
}

class _PatternGameScreenState extends State<PatternGameScreen> {
  final _random = Random();
  final _gridKey = GlobalKey();
  final _stackKey = GlobalKey();
  final _submitter = GameSessionSubmitter(GamesService());

  GameGrid _grid = createEmptyGrid();
  List<BlockShape> _availableBlocks = [];
  int? _draggingBlockIndex;
  Offset? _dragPosition;
  int? _previewRow;
  int? _previewCol;
  int _lineScore = 0;
  int _placements = 0;
  int _linesCleared = 0;
  int _remainingMoves = GameScoring.patternStartingMoves;
  int _finalScore = 0;
  bool _gameOver = false;
  bool _scoreSubmitted = false;
  bool _outOfMoves = false;
  bool _isAnimatingClear = false;
  LinesToClear _clearingLines = const LinesToClear(rows: [], cols: []);
  int _clearAnimationToken = 0;
  DateTime? _startedAt;

  bool get _gameInProgress => _startedAt != null && !_gameOver && !_scoreSubmitted;

  BlockShape? get _activeBlock {
    if (_draggingBlockIndex == null) return null;
    return _availableBlocks[_draggingBlockIndex!];
  }

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    _submitter.submitted = false;
    setState(() {
      _grid = createEmptyGrid();
      _availableBlocks = generateRandomBlocks(_random);
      _draggingBlockIndex = null;
      _dragPosition = null;
      _previewRow = null;
      _previewCol = null;
      _lineScore = 0;
      _placements = 0;
      _linesCleared = 0;
      _remainingMoves = GameScoring.patternStartingMoves;
      _finalScore = 0;
      _gameOver = false;
      _scoreSubmitted = false;
      _outOfMoves = false;
      _isAnimatingClear = false;
      _clearingLines = const LinesToClear(rows: [], cols: []);
      _startedAt = DateTime.now();
    });
  }

  Future<void> _finishSession({required bool outOfMoves}) async {
    if (_gameOver) return;
    final score = GameScoring.patternFinal(
      lineScore: _lineScore,
      placements: _placements,
    );
    setState(() {
      _gameOver = true;
      _outOfMoves = outOfMoves;
      _finalScore = score;
    });
    final durationMs = _startedAt == null ? 0 : DateTime.now().difference(_startedAt!).inMilliseconds;
    final saved = await _submitter.submit(
      SubmitGameScorePayload(
        gameType: GameType.pattern,
        score: score,
        durationMs: durationMs,
        progress: _placements,
        completed: _linesCleared >= 5,
      ),
    );
    if (mounted) {
      setState(() => _scoreSubmitted = true);
      await showScoreSavedSnackBar(context, saved: saved);
    }
  }

  (int?, int?) _globalToGridCell(Offset global) {
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return (null, null);

    final local = box.globalToLocal(global);
    if (local.dx < 0 || local.dy < 0 || local.dx > box.size.width || local.dy > box.size.height) {
      return (null, null);
    }

    final cellW = box.size.width / gridSize;
    final cellH = box.size.height / gridSize;
    final col = (local.dx / cellW).floor().clamp(0, gridSize - 1);
    final row = (local.dy / cellH).floor().clamp(0, gridSize - 1);
    return (row, col);
  }

  void _startDrag(int index, Offset globalPosition) {
    if (_gameOver || _isAnimatingClear || _remainingMoves <= 0) return;
    setState(() {
      _draggingBlockIndex = index;
      _dragPosition = globalPosition;
      final (row, col) = _globalToGridCell(globalPosition);
      _previewRow = row;
      _previewCol = col;
    });
  }

  void _updateDrag(Offset globalPosition) {
    if (_draggingBlockIndex == null) return;
    final (row, col) = _globalToGridCell(globalPosition);
    setState(() {
      _dragPosition = globalPosition;
      _previewRow = row;
      _previewCol = col;
    });
  }

  void _cancelDrag() {
    setState(() {
      _draggingBlockIndex = null;
      _dragPosition = null;
      _previewRow = null;
      _previewCol = null;
    });
  }

  Future<void> _checkGameOver() async {
    if (_remainingMoves <= 0) {
      await _finishSession(outOfMoves: true);
      return;
    }
    if (!hasPossiblePlacement(_grid, _availableBlocks)) {
      await _finishSession(outOfMoves: false);
    }
  }

  Future<void> _tryPlaceBlock(int row, int col) async {
    if (_draggingBlockIndex == null || _gameOver || _isAnimatingClear || _remainingMoves <= 0) return;

    final blockIndex = _draggingBlockIndex!;
    final block = _availableBlocks[blockIndex];
    if (!canPlaceBlock(_grid, block, row, col)) {
      _cancelDrag();
      return;
    }

    final placedGrid = placeBlock(_grid, block, row, col);
    final lines = findLinesToClear(placedGrid);

    _cancelDrag();

    if (lines.count > 0) {
      final token = ++_clearAnimationToken;
      setState(() {
        _grid = placedGrid;
        _isAnimatingClear = true;
        _clearingLines = lines;
      });

      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted || token != _clearAnimationToken) return;

      applyLineClear(_grid, lines);
      setState(() {
        _linesCleared += lines.count;
        _lineScore += calculateScore(lines.count);
        _remainingMoves += GameScoring.patternMovesForLines(lines.count);
        _isAnimatingClear = false;
        _clearingLines = const LinesToClear(rows: [], cols: []);
      });
    } else {
      setState(() => _grid = placedGrid);
    }

    final newBlocks = List<BlockShape>.from(_availableBlocks)..removeAt(blockIndex);
    newBlocks.add(generateRandomBlocks(_random, count: 1).first);

    setState(() {
      _placements++;
      _remainingMoves--;
      _availableBlocks = newBlocks;
    });

    await _checkGameOver();
  }

  void _endDrag(Offset globalPosition) {
    if (_draggingBlockIndex == null) return;
    final (row, col) = _globalToGridCell(globalPosition);
    if (row != null && col != null) {
      _tryPlaceBlock(row, col);
    } else {
      _cancelDrag();
    }
  }

  bool _cellInPreview(int row, int col) {
    final block = _activeBlock;
    if (block == null || _previewRow == null || _previewCol == null) return false;
    return isPreviewCell(
      block: block,
      centerRow: _previewRow,
      centerCol: _previewCol,
      row: row,
      col: col,
    );
  }

  bool _previewValid() {
    final block = _activeBlock;
    if (block == null || _previewRow == null || _previewCol == null) return false;
    return canPlaceBlock(_grid, block, _previewRow!, _previewCol!);
  }

  Color _cellColor(BuildContext context, int row, int col, bool filled) {
    if (_isAnimatingClear && _clearingLines.affectsCell(row, col)) {
      return const Color(0xFFFFD54F);
    }
    if (filled) {
      return Theme.of(context).colorScheme.primary;
    }
    if (_cellInPreview(row, col)) {
      return _previewValid()
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.45)
          : Theme.of(context).colorScheme.error.withValues(alpha: 0.45);
    }
    return Theme.of(context).colorScheme.surface;
  }

  Offset? _dragGhostLocalPosition() {
    if (_dragPosition == null) return null;
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null) return null;
    return stackBox.globalToLocal(_dragPosition!);
  }

  @override
  Widget build(BuildContext context) {
    final compact = isCompactGameScreen(context);
    final ghostLocal = _dragGhostLocalPosition();
    final displayScore = _gameOver ? _finalScore : _lineScore + _placements * 10;

    return GamesScaffold(
      title: 'Блочный пазл',
      gameInProgress: _gameInProgress,
      scoreSubmitted: _scoreSubmitted,
      child: Listener(
        onPointerMove: (event) {
          if (_draggingBlockIndex != null) _updateDrag(event.position);
        },
        onPointerUp: (event) {
          if (_draggingBlockIndex != null) _endDrag(event.position);
        },
        onPointerCancel: (_) => _cancelDrag(),
        child: Stack(
          key: _stackKey,
          clipBehavior: Clip.none,
          children: [
            GamePageLayout(
              header: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Очки: $displayScore', style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        'Ходы: $_remainingMoves',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: _remainingMoves <= 3
                                  ? Theme.of(context).colorScheme.error
                                  : null,
                            ),
                      ),
                    ],
                  ),
                  Text('Линий: $_linesCleared • Размещено: $_placements', style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    _draggingBlockIndex != null
                        ? 'Перетащите фигуру на поле'
                        : 'Линия = +${GameScoring.patternMovesPerLine} хода. Ходы закончились — игра окончена.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              board: GameBoardContainer(
                overlay: _gameOver
                    ? _PatternResultOverlay(
                        finalScore: _finalScore,
                        lineScore: _lineScore,
                        placements: _placements,
                        linesCleared: _linesCleared,
                        outOfMoves: _outOfMoves,
                        onRestart: _startNewGame,
                      )
                    : null,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final side = min(constraints.maxWidth, constraints.maxHeight);
                    return Center(
                      child: SizedBox(
                        key: _gridKey,
                        width: side,
                        height: side,
                        child: Column(
                          children: List.generate(gridSize, (row) {
                            return Expanded(
                              child: Row(
                                children: List.generate(gridSize, (col) {
                                  final filled = _grid[row][col];
                                  return Expanded(
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 120),
                                      margin: const EdgeInsets.all(0.5),
                                      decoration: BoxDecoration(
                                        color: _cellColor(context, row, col, filled),
                                        borderRadius: BorderRadius.circular(2),
                                        boxShadow: _isAnimatingClear && _clearingLines.affectsCell(row, col)
                                            ? [
                                                BoxShadow(
                                                  color: Colors.amber.withValues(alpha: 0.8),
                                                  blurRadius: 6,
                                                ),
                                              ]
                                            : null,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            );
                          }),
                        ),
                      ),
                    );
                  },
                ),
              ),
              footer: Row(
                children: List.generate(_availableBlocks.length, (index) {
                  final block = _availableBlocks[index];
                  final isDragging = _draggingBlockIndex == index;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index < _availableBlocks.length - 1 ? 6 : 0),
                      child: Listener(
                        onPointerDown: (event) => _startDrag(index, event.position),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: isDragging ? 0.35 : 1,
                          child: Material(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              height: compact ? 56 : 64,
                              child: Center(
                                child: BlockShapeWidget(
                                  block: block,
                                  cellSize: compact ? 8 : 10,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            if (_draggingBlockIndex != null && ghostLocal != null)
              Positioned(
                left: ghostLocal.dx - 40,
                top: ghostLocal.dy - 40,
                child: IgnorePointer(
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.95),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: BlockShapeWidget(
                        block: _availableBlocks[_draggingBlockIndex!],
                        cellSize: compact ? 10 : 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BlockShapeWidget extends StatelessWidget {
  const BlockShapeWidget({
    super.key,
    required this.block,
    required this.cellSize,
    required this.color,
  });

  final BlockShape block;
  final double cellSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final minRow = block.cells.map((c) => c.$1).reduce(min);
    final maxRow = block.cells.map((c) => c.$1).reduce(max);
    final minCol = block.cells.map((c) => c.$2).reduce(min);
    final maxCol = block.cells.map((c) => c.$2).reduce(max);
    final rows = maxRow - minRow + 1;
    final cols = maxCol - minCol + 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(rows, (r) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(cols, (c) {
            final occupied = block.cells.any(
              (cell) => cell.$1 - minRow == r && cell.$2 - minCol == c,
            );
            return Container(
              width: cellSize,
              height: cellSize,
              margin: const EdgeInsets.all(0.5),
              decoration: BoxDecoration(
                color: occupied ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      }),
    );
  }
}

class _PatternResultOverlay extends StatelessWidget {
  const _PatternResultOverlay({
    required this.finalScore,
    required this.lineScore,
    required this.placements,
    required this.linesCleared,
    required this.outOfMoves,
    required this.onRestart,
  });

  final int finalScore;
  final int lineScore;
  final int placements;
  final int linesCleared;
  final bool outOfMoves;
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
              Text('Игра окончена', style: Theme.of(context).textTheme.titleLarge),
              Text('Итоговый счёт: $finalScore'),
              Text('Линии: $lineScore • Размещено: $placements'),
              Text('Линий очищено: $linesCleared'),
              Text(outOfMoves ? 'Ходы закончились' : 'Нет доступных ходов на поле'),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRestart, child: const Text('Играть снова')),
            ],
          ),
        ),
      ),
    );
  }
}
