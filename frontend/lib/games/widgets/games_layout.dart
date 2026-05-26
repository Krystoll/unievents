import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Ограничивает ширину игры на больших экранах и уменьшает отступы на телефонах.
class GamePageLayout extends StatelessWidget {
  const GamePageLayout({
    super.key,
    required this.header,
    required this.board,
    this.footer,
    this.maxWidth = 640,
  });

  final Widget header;
  final Widget board;
  final Widget? footer;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: min(maxWidth, constraints.maxWidth),
              maxHeight: constraints.maxHeight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: AppSpacing.sm),
                Expanded(child: board),
                if (footer != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  footer!,
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Сетка фиксированного размера, которая масштабируется под доступное пространство.
class AdaptiveFixedGrid extends StatelessWidget {
  const AdaptiveFixedGrid({
    super.key,
    required this.columns,
    required this.rows,
    required this.itemCount,
    required this.itemBuilder,
    this.spacing = 6,
    this.cellAspectRatio = 1,
  });

  final int columns;
  final int rows;
  final int itemCount;
  final double spacing;
  final double cellAspectRatio;
  final Widget Function(BuildContext context, int index, double cellWidth, double cellHeight)
      itemBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        if (maxW <= 0 || maxH <= 0) {
          return const SizedBox.shrink();
        }

        final cellW = (maxW - spacing * (columns - 1)) / columns;
        final cellH = (maxH - spacing * (rows - 1)) / rows;
        var width = min(cellW, cellH / cellAspectRatio);
        var height = width * cellAspectRatio;

        // Пересчёт, если по высоте не влезает.
        if (height * rows + spacing * (rows - 1) > maxH) {
          height = (maxH - spacing * (rows - 1)) / rows;
          width = height / cellAspectRatio;
        }

        final gridW = width * columns + spacing * (columns - 1);
        final gridH = height * rows + spacing * (rows - 1);

        return Center(
          child: SizedBox(
            width: gridW,
            height: gridH,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(rows, (row) {
                return Padding(
                  padding: EdgeInsets.only(bottom: row < rows - 1 ? spacing : 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(columns, (col) {
                      final index = row * columns + col;
                      if (index >= itemCount) {
                        return SizedBox(width: width, height: height);
                      }
                      return Padding(
                        padding: EdgeInsets.only(right: col < columns - 1 ? spacing : 0),
                        child: SizedBox(
                          width: width,
                          height: height,
                          child: itemBuilder(context, index, width, height),
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
    );
  }
}

/// Контейнер игрового поля с общим оформлением.
class GameBoardContainer extends StatelessWidget {
  const GameBoardContainer({
    super.key,
    required this.child,
    this.overlay,
  });

  final Widget child;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: child,
            ),
            if (overlay != null) overlay!,
          ],
        ),
      ),
    );
  }
}

double compactFontSize(double cellSize, {double factor = 0.42, double min = 12, double max = 28}) {
  return (cellSize * factor).clamp(min, max);
}

bool isCompactGameScreen(BuildContext context) {
  return MediaQuery.sizeOf(context).width < 400 ||
      MediaQuery.sizeOf(context).height < 640;
}
