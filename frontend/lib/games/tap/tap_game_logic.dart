import 'dart:math';

import 'package:flutter/material.dart';

enum TargetShape { circle, triangle, star, house, square }

class TargetColor {
  const TargetColor(this.title, this.color);

  final String title;
  final Color color;
}

const targetPalette = [
  TargetColor('Красный', Color(0xFFE53935)),
  TargetColor('Синий', Color(0xFF1E88E5)),
  TargetColor('Зелёный', Color(0xFF43A047)),
  TargetColor('Жёлтый', Color(0xFFFDD835)),
  TargetColor('Фиолетовый', Color(0xFF8E24AA)),
  TargetColor('Оранжевый', Color(0xFFFB8C00)),
];

class TapGameStage {
  const TapGameStage({
    required this.startAtSec,
    required this.label,
    required this.targetSize,
    required this.lifetimeMs,
    required this.distractors,
  });

  final int startAtSec;
  final String label;
  final double targetSize;
  final int lifetimeMs;
  final int distractors;
}

const tapStages = [
  TapGameStage(startAtSec: 0, label: 'Разминка', targetSize: 72, lifetimeMs: 2200, distractors: 1),
  TapGameStage(startAtSec: 15, label: 'Темп растёт', targetSize: 60, lifetimeMs: 1600, distractors: 2),
  TapGameStage(startAtSec: 35, label: 'Фокус', targetSize: 48, lifetimeMs: 1100, distractors: 3),
  TapGameStage(startAtSec: 50, label: 'Максимальная концентрация', targetSize: 40, lifetimeMs: 800, distractors: 4),
];

const tapGameDurationSec = 60;
const tapBonusTimeReward = 3;
const tapBonusScoreReward = 2;

class TapInstruction {
  TapInstruction({
    required this.shape,
    required this.color,
    required this.shouldAvoid,
  });

  final TargetShape shape;
  final TargetColor color;
  final bool shouldAvoid;
}

TapInstruction generateInstruction(Random random) {
  final shapes = TargetShape.values;
  final shape = shapes[random.nextInt(shapes.length)];
  final color = targetPalette[random.nextInt(targetPalette.length)];
  final avoid = random.nextDouble() < 0.2;
  return TapInstruction(shape: shape, color: color, shouldAvoid: avoid);
}

enum TapHitResult { correct, wrong, bonus }

class GlyphDescriptor {
  GlyphDescriptor({
    required this.shape,
    required this.color,
    required this.isTarget,
    required this.isBonus,
    required this.x,
    required this.y,
    required this.sizeMultiplier,
  });

  final TargetShape shape;
  final Color color;
  final bool isTarget;
  final bool isBonus;
  final double x;
  final double y;
  final double sizeMultiplier;
}

List<GlyphDescriptor> generateGlyphs({
  required Random random,
  required TapGameStage stage,
  required TapInstruction instruction,
  required double containerWidth,
  required double containerHeight,
  double targetSizeScale = 1,
}) {
  if (containerWidth <= 0 || containerHeight <= 0) return [];

  final targetSize = stage.targetSize * targetSizeScale;
  final bonusChance = 0.1 + stage.distractors * 0.05;
  final includeBonus = random.nextDouble() < bonusChance;

  final seeds = <_GlyphSeed>[
    _GlyphSeed(
      shape: instruction.shape,
      color: instruction.color.color,
      isTarget: true,
      isBonus: false,
      sizeMultiplier: 1,
    ),
  ];

  final shapesPool = TargetShape.values.where((s) => s != instruction.shape).toList();
  for (var i = 0; i < stage.distractors; i++) {
    final shape = shapesPool[random.nextInt(shapesPool.length)];
    seeds.add(
      _GlyphSeed(
        shape: shape,
        color: targetPalette[random.nextInt(targetPalette.length)].color,
        isTarget: false,
        isBonus: false,
        sizeMultiplier: 0.9,
      ),
    );
  }

  if (includeBonus) {
    seeds.add(
      const _GlyphSeed(
        shape: TargetShape.star,
        color: Color(0xFFFFD54F),
        isTarget: false,
        isBonus: true,
        sizeMultiplier: 1.05,
      ),
    );
  }

  seeds.shuffle(random);
  final occupied = <Rect>[];
  final glyphs = <GlyphDescriptor>[];

  for (final seed in seeds) {
    final size = targetSize * seed.sizeMultiplier;
    final rect = _placeGlyphRect(
      random: random,
      occupied: occupied,
      width: size,
      height: size,
      maxX: max(0, containerWidth - size),
      maxY: max(0, containerHeight - size),
    );
    occupied.add(rect);
    glyphs.add(
      GlyphDescriptor(
        shape: seed.shape,
        color: seed.color,
        isTarget: seed.isTarget,
        isBonus: seed.isBonus,
        x: rect.left,
        y: rect.top,
        sizeMultiplier: seed.sizeMultiplier,
      ),
    );
  }

  return glyphs;
}

class _GlyphSeed {
  const _GlyphSeed({
    required this.shape,
    required this.color,
    required this.isTarget,
    required this.isBonus,
    required this.sizeMultiplier,
  });

  final TargetShape shape;
  final Color color;
  final bool isTarget;
  final bool isBonus;
  final double sizeMultiplier;
}

Rect _placeGlyphRect({
  required Random random,
  required List<Rect> occupied,
  required double width,
  required double height,
  required double maxX,
  required double maxY,
  double gap = 6,
}) {
  for (var i = 0; i < 40; i++) {
    final x = maxX == 0 ? 0.0 : random.nextDouble() * maxX;
    final y = maxY == 0 ? 0.0 : random.nextDouble() * maxY;
    final rect = Rect.fromLTWH(x, y, width, height);
    if (!occupied.any((other) => _overlaps(rect, other, gap))) {
      return rect;
    }
  }
  return Rect.fromLTWH(0, 0, width, height);
}

bool _overlaps(Rect a, Rect b, double gap) {
  return a.left < b.right + gap &&
      a.right + gap > b.left &&
      a.top < b.bottom + gap &&
      a.bottom + gap > b.top;
}

String shapeTitle(TargetShape shape) {
  return switch (shape) {
    TargetShape.circle => 'Круг',
    TargetShape.triangle => 'Треугольник',
    TargetShape.star => 'Звезда',
    TargetShape.house => 'Домик',
    TargetShape.square => 'Квадрат',
  };
}

TapHitResult evaluateTap(GlyphDescriptor glyph, TapInstruction instruction) {
  if (glyph.isBonus) return TapHitResult.bonus;
  if (instruction.shouldAvoid) {
    return glyph.shape == instruction.shape ? TapHitResult.wrong : TapHitResult.correct;
  }
  return glyph.shape == instruction.shape ? TapHitResult.correct : TapHitResult.wrong;
}
