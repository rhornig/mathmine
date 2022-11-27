import 'package:flutter/material.dart';

import 'main.dart';

class SettingsWidget extends StatelessWidget {
  final PuzzleConfig puzzleConfig;

  const SettingsWidget(this.puzzleConfig, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            DropdownButtonFormField<DigitSpec>(
              decoration: const InputDecoration(labelText: "MSD1"),
              elevation: 8,
              isExpanded: true,
              borderRadius: BorderRadius.circular(8),
              focusColor: Colors.grey.withAlpha(0),
              items: DigitSpec.values.map((e) => DropdownMenuItem<DigitSpec>(value: e, child: Text(e.label))).toList(),
              value: puzzleConfig.msd1,
              onChanged: (DigitSpec? newValue) {
                puzzleConfig.msd1 = newValue!;
              },
            ),
            DropdownButtonFormField<DigitSpec>(
              decoration: const InputDecoration(labelText: "LSD1"),
              elevation: 8,
              isExpanded: true,
              borderRadius: BorderRadius.circular(8),
              focusColor: Colors.grey.withAlpha(0),
              items: DigitSpec.values.map((e) => DropdownMenuItem<DigitSpec>(value: e, child: Text(e.label))).toList(),
              value: puzzleConfig.lsd1,
              onChanged: (DigitSpec? newValue) {
                puzzleConfig.lsd1 = newValue!;
              },
            ),
            DropdownButtonFormField<Operation>(
              decoration: const InputDecoration(labelText: "Operation"),
              elevation: 8,
              isExpanded: true,
              borderRadius: BorderRadius.circular(8),
              focusColor: Colors.grey.withAlpha(0),
              items: Operation.values.map((e) => DropdownMenuItem<Operation>(value: e, child: Text(e.opChar))).toList(),
              value: puzzleConfig.operation,
              onChanged: (Operation? newValue) {
                puzzleConfig.operation = newValue!;
              },
            ),
            DropdownButtonFormField<DigitSpec>(
              decoration: const InputDecoration(labelText: "MSD2"),
              elevation: 8,
              isExpanded: true,
              borderRadius: BorderRadius.circular(8),
              focusColor: Colors.grey.withAlpha(0),
              items: DigitSpec.values.map((e) => DropdownMenuItem<DigitSpec>(value: e, child: Text(e.label))).toList(),
              value: puzzleConfig.msd2,
              onChanged: (DigitSpec? newValue) {
                puzzleConfig.msd2 = newValue!;
              },
            ),
            DropdownButtonFormField<DigitSpec>(
              decoration: const InputDecoration(labelText: "LSD2"),
              elevation: 8,
              isExpanded: true,
              borderRadius: BorderRadius.circular(8),
              focusColor: Colors.grey.withAlpha(0),
              items: DigitSpec.values.map((e) => DropdownMenuItem<DigitSpec>(value: e, child: Text(e.label))).toList(),
              value: puzzleConfig.lsd2,
              onChanged: (DigitSpec? newValue) {
                puzzleConfig.lsd2 = newValue!;
              },
            ),
          ],
        ),
      ),
    );
  }
}
