// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:mathmine/main.dart';

void main() {
  test("random single digit with min, max and constraints", () {
    for (DigitSpec ds in DigitSpec.values) {
      for (int max = 0; max < 10; max++) {
        for (int min = 0; min <= max; min++) {
          int result = drawDigit(ds, min: min, max: max);
          if (result == -1) continue;

          expect(result, greaterThanOrEqualTo(min));
          expect(result, lessThanOrEqualTo(max));
          expect(ds.digits, contains(result), reason: "min: $min max: $max result: $result in ${ds.digits}");
        }
      }
    }
  });

  test("random double digit numbers with min, max and constrains", () {
    for (DigitSpec ds1 in DigitSpec.values) {
      for (DigitSpec ds2 in DigitSpec.values) {
        for (int max = 0; max < 100; max += 1) {
          for (int min = 0; min <= max; min += 1) {
            int result = drawTwoDigitNumber(ds1, ds2, min: min, max: max);
            if (result == -1) continue;

            expect(result, greaterThanOrEqualTo(min));
            expect(result, lessThanOrEqualTo(max));
            expect(ds1.digits, contains(result ~/ 10));
            expect(ds2.digits, contains(result % 10));
          }
        }
      }
    }
  });

  test("generate possible puzzles with random rules", () {
    for (int i = 0; i < 100; i++) {
      PuzzleConfig pc = PuzzleConfig(
        DigitSpec.values[r.nextInt(DigitSpec.values.length)],
        DigitSpec.values[r.nextInt(DigitSpec.values.length)],
        Operation.values[r.nextInt(Operation.values.length)],
        DigitSpec.values[r.nextInt(DigitSpec.values.length)],
        DigitSpec.values[r.nextInt(DigitSpec.values.length)],
        Relation.eq,
      );
      Puzzle puzzle = generatePuzzle(pc);
      print("Config: $pc  Puzzle: $puzzle");
      expect(puzzle, isNotNull);
      expect(puzzle.third, lessThanOrEqualTo(99));
      expect(puzzle.third, greaterThanOrEqualTo(0));
    }
  });
}
