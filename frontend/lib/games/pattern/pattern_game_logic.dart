import 'dart:math';

enum BlockType { i, j, l, o, s, t, z, dot, smallL, smallT }

class BlockShape {
  const BlockShape(this.type, this.cells);

  final BlockType type;
  final List<(int, int)> cells;
}

const gridSize = 9;
const blocksCount = 3;

final blockShapes = {
  BlockType.i: const BlockShape(BlockType.i, [(0, -1), (0, 0), (0, 1), (0, 2)]),
  BlockType.j: const BlockShape(BlockType.j, [(-1, -1), (0, -1), (0, 0), (0, 1)]),
  BlockType.l: const BlockShape(BlockType.l, [(-1, 1), (0, -1), (0, 0), (0, 1)]),
  BlockType.o: const BlockShape(BlockType.o, [(0, 0), (0, 1), (1, 0), (1, 1)]),
  BlockType.s: const BlockShape(BlockType.s, [(0, 0), (0, 1), (1, -1), (1, 0)]),
  BlockType.t: const BlockShape(BlockType.t, [(-1, 0), (0, -1), (0, 0), (0, 1)]),
  BlockType.z: const BlockShape(BlockType.z, [(0, -1), (0, 0), (1, 0), (1, 1)]),
  BlockType.dot: const BlockShape(BlockType.dot, [(0, 0)]),
  BlockType.smallL: const BlockShape(BlockType.smallL, [(0, 0), (0, 1), (1, 0)]),
  BlockType.smallT: const BlockShape(BlockType.smallT, [(0, -1), (0, 0), (0, 1)]),
};

typedef GameGrid = List<List<bool>>;

GameGrid createEmptyGrid() {
  return List.generate(gridSize, (_) => List.filled(gridSize, false));
}

List<(int, int)> rotateCells90(List<(int, int)> cells) {
  return cells.map((c) => (c.$2, -c.$1)).toList();
}

BlockShape randomOrientedBlock(Random random) {
  final types = BlockType.values;
  final base = blockShapes[types[random.nextInt(types.length)]]!;
  var cells = base.cells;
  final rotations = random.nextInt(4);
  for (var i = 0; i < rotations; i++) {
    cells = rotateCells90(cells);
  }
  return BlockShape(base.type, cells);
}

List<BlockShape> generateRandomBlocks(Random random, {int count = blocksCount}) {
  return List.generate(count, (_) => randomOrientedBlock(random));
}

bool canPlaceBlock(GameGrid grid, BlockShape shape, int centerRow, int centerCol) {
  for (final (dr, dc) in shape.cells) {
    final row = centerRow + dr;
    final col = centerCol + dc;
    if (row < 0 || row >= gridSize || col < 0 || col >= gridSize) return false;
    if (grid[row][col]) return false;
  }
  return true;
}

GameGrid placeBlock(GameGrid grid, BlockShape shape, int centerRow, int centerCol) {
  final copy = grid.map((row) => List<bool>.from(row)).toList();
  for (final (dr, dc) in shape.cells) {
    copy[centerRow + dr][centerCol + dc] = true;
  }
  return copy;
}

LinesToClear findLinesToClear(GameGrid grid) {
  final rowsToClear = <int>[];
  final colsToClear = <int>[];

  for (var row = 0; row < gridSize; row++) {
    if (grid[row].every((cell) => cell)) rowsToClear.add(row);
  }
  for (var col = 0; col < gridSize; col++) {
    var filled = true;
    for (var row = 0; row < gridSize; row++) {
      if (!grid[row][col]) {
        filled = false;
        break;
      }
    }
    if (filled) colsToClear.add(col);
  }

  return LinesToClear(rows: rowsToClear, cols: colsToClear);
}

class LinesToClear {
  const LinesToClear({required this.rows, required this.cols});

  final List<int> rows;
  final List<int> cols;

  int get count => rows.length + cols.length;

  bool affectsCell(int row, int col) {
    return rows.contains(row) || cols.contains(col);
  }
}

void applyLineClear(GameGrid grid, LinesToClear lines) {
  for (final row in lines.rows) {
    for (var col = 0; col < gridSize; col++) {
      grid[row][col] = false;
    }
  }
  for (final col in lines.cols) {
    for (var row = 0; row < gridSize; row++) {
      grid[row][col] = false;
    }
  }
}

int clearLines(GameGrid grid) {
  final lines = findLinesToClear(grid);
  applyLineClear(grid, lines);
  return lines.count;
}

bool hasPossiblePlacement(GameGrid grid, List<BlockShape> blocks) {
  for (final block in blocks) {
    for (var row = 0; row < gridSize; row++) {
      for (var col = 0; col < gridSize; col++) {
        if (canPlaceBlock(grid, block, row, col)) return true;
      }
    }
  }
  return false;
}

int calculateScore(int linesCleared) {
  return switch (linesCleared) {
    1 => 10,
    2 => 50,
    3 => 150,
    4 => 400,
    _ => linesCleared * 10,
  };
}

bool isBlockCell(BlockShape block, int centerRow, int centerCol, int row, int col) {
  return block.cells.any((c) => centerRow + c.$1 == row && centerCol + c.$2 == col);
}

bool isPreviewCell({
  required BlockShape? block,
  required int? centerRow,
  required int? centerCol,
  required int row,
  required int col,
}) {
  if (block == null || centerRow == null || centerCol == null) return false;
  return isBlockCell(block, centerRow, centerCol, row, col);
}
