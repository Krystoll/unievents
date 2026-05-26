import 'dart:math';

class MemoryLevel {
  MemoryLevel({
    required this.rows,
    required this.cols,
    required this.previewMillis,
    required this.baseMines,
  })  : capacity = rows * cols,
        mines = _adjustedMines(rows * cols, baseMines),
        pairCount = (rows * cols - _adjustedMines(rows * cols, baseMines)) ~/ 2;

  final int rows;
  final int cols;
  final int previewMillis;
  final int baseMines;
  final int capacity;
  final int mines;
  final int pairCount;

  static int _adjustedMines(int capacity, int baseMines) {
    var adjusted = baseMines;
    while ((capacity - adjusted) % 2 != 0 && adjusted < capacity) {
      adjusted++;
    }
    return adjusted;
  }
}

final memoryLevels = [
  MemoryLevel(rows: 2, cols: 2, previewMillis: 2000, baseMines: 0),
  MemoryLevel(rows: 3, cols: 2, previewMillis: 2600, baseMines: 0),
  MemoryLevel(rows: 3, cols: 3, previewMillis: 3200, baseMines: 1),
  MemoryLevel(rows: 3, cols: 4, previewMillis: 3800, baseMines: 1),
  MemoryLevel(rows: 4, cols: 4, previewMillis: 4500, baseMines: 2),
  MemoryLevel(rows: 4, cols: 5, previewMillis: 5200, baseMines: 2),
  MemoryLevel(rows: 5, cols: 5, previewMillis: 6000, baseMines: 3),
  MemoryLevel(rows: 5, cols: 6, previewMillis: 6800, baseMines: 3),
  MemoryLevel(rows: 6, cols: 6, previewMillis: 7600, baseMines: 4),
  MemoryLevel(rows: 6, cols: 7, previewMillis: 8600, baseMines: 4),
  MemoryLevel(rows: 7, cols: 7, previewMillis: 9800, baseMines: 5),
];

const stickerSet = ['🧠', '⚡', '🎯', '🚀', '🧩', '🎲', '🔮', '🦊', '🌟', '🎵', '🐙', '🍀'];

class MemoryCard {
  MemoryCard({
    required this.uid,
    required this.sticker,
    required this.isMine,
    this.isFaceUp = false,
    this.isMatched = false,
  });

  final int uid;
  final String sticker;
  final bool isMine;
  final bool isFaceUp;
  final bool isMatched;

  MemoryCard copyWith({bool? isFaceUp, bool? isMatched}) {
    return MemoryCard(
      uid: uid,
      sticker: sticker,
      isMine: isMine,
      isFaceUp: isFaceUp ?? this.isFaceUp,
      isMatched: isMatched ?? this.isMatched,
    );
  }
}

List<MemoryCard> generateMemoryCards(MemoryLevel level, Random random) {
  final stickers = List<String>.from(stickerSet)..shuffle(random);
  final selected = stickers.take(level.pairCount).toList();
  var uid = 0;
  final pairs = selected.expand(
    (sticker) => [
      MemoryCard(uid: uid++, sticker: sticker, isMine: false),
      MemoryCard(uid: uid++, sticker: sticker, isMine: false),
    ],
  );

  final mines = <MemoryCard>[];
  for (var i = 0; i < level.mines; i++) {
    mines.add(MemoryCard(uid: uid++, sticker: '💣', isMine: true));
  }
  while (pairs.length + mines.length < level.capacity) {
    mines.add(MemoryCard(uid: uid++, sticker: '💣', isMine: true));
  }

  final all = [...pairs, ...mines]..shuffle(random);
  return all;
}
