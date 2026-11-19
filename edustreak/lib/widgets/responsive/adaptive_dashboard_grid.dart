import 'package:flutter/material.dart';

/// An adaptive dashboard grid that automatically computes the optimal number of
/// columns, item heights, and spacing based on actual constraints rather than fixed breakpoints.
class AdaptiveDashboardGrid extends StatelessWidget {
  final List<Widget> children;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double? mainAxisExtent;
  final double childAspectRatio;
  final int mobileCols;
  final int largeMobileCols;
  final int tabletCols;
  final int laptopCols;
  final int desktopCols;
  final int tvCols;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const AdaptiveDashboardGrid({
    super.key,
    required this.children,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
    this.mainAxisExtent,
    this.childAspectRatio = 1.0,
    this.mobileCols = 1,
    this.largeMobileCols = 2,
    this.tabletCols = 2,
    this.laptopCols = 4,
    this.desktopCols = 4,
    this.tvCols = 4,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  });

  /// Factory helper for metric / KPI cards (compact 100-115px height)
  factory AdaptiveDashboardGrid.metrics({
    Key? key,
    required List<Widget> children,
    double mainAxisExtent = 110,
    double crossAxisSpacing = 16,
    double mainAxisSpacing = 16,
    int mobileCols = 1,
    int largeMobileCols = 2,
    int tabletCols = 2,
    int laptopCols = 4,
    int desktopCols = 4,
    int tvCols = 4,
  }) {
    return AdaptiveDashboardGrid(
      key: key,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      mainAxisExtent: mainAxisExtent,
      mobileCols: mobileCols,
      largeMobileCols: largeMobileCols,
      tabletCols: tabletCols,
      laptopCols: laptopCols,
      desktopCols: desktopCols,
      tvCols: tvCols,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int cols;

        if (width < 600) {
          cols = mobileCols;
        } else if (width < 768) {
          cols = largeMobileCols;
        } else if (width < 1024) {
          cols = tabletCols;
        } else if (width < 1440) {
          cols = laptopCols;
        } else if (width < 1920) {
          cols = desktopCols;
        } else {
          cols = tvCols;
        }

        // Clamp cols to at least 1 and at most children length
        if (cols < 1) cols = 1;

        if (mainAxisExtent != null) {
          return GridView.builder(
            shrinkWrap: shrinkWrap,
            physics: physics,
            itemCount: children.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: crossAxisSpacing,
              mainAxisSpacing: mainAxisSpacing,
              mainAxisExtent: mainAxisExtent,
            ),
            itemBuilder: (context, index) => children[index],
          );
        }

        return GridView.builder(
          shrinkWrap: shrinkWrap,
          physics: physics,
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}
