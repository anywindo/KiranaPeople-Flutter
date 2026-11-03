import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/core/theme/app_theme.dart';
import 'package:kirana_people/core/widgets/shimmer_loading.dart';

void main() {
  group('ShimmerLoading & Skeleton Widgets Tests', () {
    testWidgets('ShimmerLoading renders child correctly in light mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: ShimmerLoading(
              child: SkeletonBox(width: 100, height: 20),
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerLoading), findsOneWidget);
      expect(find.byType(SkeletonBox), findsOneWidget);
    });

    testWidgets('ShimmerLoading renders child correctly in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: ShimmerLoading(
              child: SkeletonBox.circle(size: 40),
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerLoading), findsOneWidget);
      expect(find.byType(SkeletonBox), findsOneWidget);
    });

    testWidgets('HistoryListSkeleton renders designated item count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: HistoryListSkeleton(itemCount: 3),
          ),
        ),
      );

      expect(find.byType(HistoryCardSkeleton), findsNWidgets(3));
    });

    testWidgets('AttendanceScreenSkeleton renders all structural skeleton sections', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AttendanceScreenSkeleton(),
          ),
        ),
      );

      expect(find.byType(AttendanceScreenSkeleton), findsOneWidget);
      expect(find.byType(ShiftInfoCardSkeleton), findsOneWidget);
    });

    testWidgets('ProfileHeaderSkeleton renders without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: ProfileHeaderSkeleton(),
          ),
        ),
      );

      expect(find.byType(ProfileHeaderSkeleton), findsOneWidget);
    });
  });
}

