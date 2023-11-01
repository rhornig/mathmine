import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundpool/soundpool.dart';

import 'settings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MathMinerApp());
}

final mineCoinImage = Image.asset('assets/image/minecoin.webp');
final robuxImage = Image.asset('assets/image/robux.webp');
final happyImage = Image.asset('assets/image/happy.webp');
final sadImage = Image.asset('assets/image/sad.webp');
const kDefaultTextStyle = TextStyle(fontWeight: FontWeight.normal, fontFamily: 'Roboto', decoration: TextDecoration.none);
const kGridSize = 40.0; // the size of a single grid in on the helper area
const kNoOfSolutions = 100;

class MathMinerApp extends StatelessWidget {
  const MathMinerApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MathMine',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MathMinerWidget(),
    );
  }
}

class MathMinerWidget extends StatefulWidget {
  const MathMinerWidget({Key? key}) : super(key: key);

  @override
  State<MathMinerWidget> createState() => _MathMinerWidgetState();
}

class _MathMinerWidgetState extends State<MathMinerWidget> {
  // bool showSolution = false;
  bool showFailure = false;
  bool showSuccess = false;
  bool showSettings = false;

  int _coins = 0;
  int _reward = 1;

  final PuzzleConfig _puzzleConfig =
      PuzzleConfig(DigitSpec.digit_0, DigitSpec.all, Operation.mul, DigitSpec.digit_0, DigitSpec.all, Relation.eq, Currency.robux);
  Puzzle _puzzle = Puzzle(1, Operation.add, 1, Relation.eq, 2);

  @override
  initState() {
    super.initState();
    _showNewPuzzle();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _coins = prefs.getInt("coins") ?? 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CoinCounterWidget(coins: _coins, currency: _puzzleConfig.currency, onLongPress: _cashOut),
        actions: [
          GestureDetector(
            child: const Icon(Icons.settings, color: Color.fromRGBO(255, 255, 255, 0.0)),
            onLongPress: () {
              setState(() {
                showSettings = !showSettings;
              });
            },
          )
        ],
      ),
      body: showSettings
          ? SettingsWidget(_puzzleConfig)
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  _buildPuzzleGrid(),
                  AnswerGridWidget(),
                  /*
            HelperBackground(
              children: [
                HelperBar(size: _1st % 10),
                HelperBar(size: _2nd % 10),
                if (_1st >= 10) const HelperBar(size: 10),
                if (_2nd >= 10) const HelperBar(size: 10),
              ],
            ),
            */
                ],
              ),
            ),
    );
  }

  Widget _buildPuzzleGrid() {
    return Container(
      color: showFailure
          ? Colors.red.shade100
          : showSuccess
              ? Colors.green.shade100
              : Colors.blue.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Block(number: _puzzle.first),
          Block(operation: _puzzle.operation),
          Block(number: _puzzle.second),
          Block(relation: _puzzle.relation),
          showSuccess
              ? Block(number: _puzzle.third)
              : showFailure
                  ? const Block(showFailure: true)
                  : SolutionBlockWidget(_puzzle.third, reward: _reward, onSuccess: _success, onFailure: _failure),
        ],
      ),
    );
  }

  _showNewPuzzle() {
    setState(() {
      showFailure = false;
      showSuccess = false;

      _puzzle = generatePuzzle(_puzzleConfig);
      _reward = calculateReward(_puzzle);
    });
  }

  _success() {
    Sound.success.play();
    setState(() {
      showSuccess = true;
      _coins += _reward;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt("coins", _coins);
      });
    });

    Timer(const Duration(seconds: 2), () {
      setState(() {
        _showNewPuzzle();
      });
    });
  }

  _failure() {
    Sound.failure.play();
    setState(() {
      showFailure = true;
    });
    Timer(const Duration(seconds: 2), () {
      setState(() {
        _showNewPuzzle();
      });
    });
  }

  _cashOut() {
    if (_coins > _puzzleConfig.currency.cashoutUnit) {
      Sound.success.play();
      setState(() {
        _coins -= _puzzleConfig.currency.cashoutUnit;
        SharedPreferences.getInstance().then((prefs) {
          prefs.setInt("coins", _coins);
        });
      });
    }
  }
}

class CoinCounterWidget extends StatelessWidget {
  final VoidCallback onLongPress;
  final int coins;
  final Currency currency;
  const CoinCounterWidget({super.key, required this.currency, required this.coins, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      GestureDetector(onLongPress: onLongPress, child: SizedBox.square(dimension: 48, child: Image.asset(currency.imagePath))),
      Container(
        padding: const EdgeInsets.only(left: 10),
        child: Text('$coins', style: kDefaultTextStyle.copyWith(fontSize: 32)),
      ),
    ]);
  }
}

final colorMap = [
  Colors.orange.shade500,
  Colors.grey.shade50,
  Colors.red.shade200,
  Colors.blue.shade300,
  Colors.red.shade500,
  Colors.yellow.shade400,
  Colors.purple.shade600,
  Colors.grey.shade900,
  Colors.brown.shade600,
  Colors.blue.shade800,
];

class Block extends StatelessWidget {
  final int? number;
  final int? reward;
  final double size;
  final Operation? operation;
  final Relation? relation;
  final bool hidden;
  final bool showFailure;
  final bool showSuccess;
  const Block({
    super.key,
    this.size = 70,
    this.number,
    this.operation,
    this.relation,
    this.hidden = false,
    this.reward,
    this.showFailure = false,
    this.showSuccess = false,
  });

  @override
  Widget build(BuildContext context) {
    var backgroundColor = number != null ? colorMap[number! % 10] : Colors.grey.shade300;
    var foregroundColor = backgroundColor.computeLuminance() > 0.1 ? Colors.black : Colors.white;
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(width: 4, color: Colors.grey.shade500),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
        child: Center(
            child: showFailure
                ? Padding(padding: const EdgeInsets.all(8.0), child: sadImage) // failure display
                : reward != null
                    ? Padding(
                        // reward display
                        padding: const EdgeInsets.all(0),
                        child: Wrap(
                          spacing: 1,
                          alignment: WrapAlignment.center,
                          runSpacing: 1,
                          runAlignment: WrapAlignment.spaceEvenly,
                          children: List.filled(reward!, SizedBox.square(dimension: 14, child: mineCoinImage)),
                        ))
                    : Text(
                        // content display (number or operation or relation)
                        number != null
                            ? "$number"
                            : operation != null
                                ? operation!.opChar
                                : relation != null
                                    ? relation!.relChar
                                    : "",
                        style: kDefaultTextStyle.copyWith(color: foregroundColor, fontSize: size * 0.65),
                      )),
      ),
    );
  }
}

/// A block that can accept an other block dropped on it and shows the possible rewards
/// for a successful guess.
class SolutionBlockWidget extends StatelessWidget {
  final int solution;
  final int reward;
  final VoidCallback onSuccess;
  final VoidCallback onFailure;
  const SolutionBlockWidget(
    this.solution, {
    required this.reward,
    required this.onSuccess,
    required this.onFailure,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      builder: (BuildContext context, List<dynamic> accepted, List<dynamic> rejected) {
        return Block(reward: reward);
      },
      onAccept: (int data) {
        if (data == solution) {
          onSuccess();
        } else {
          onFailure();
        }
      },
    );
  }
}

class AnswerGridWidget extends StatelessWidget {
  static const kSpacing = 10.0;
  static const kBlockSize = 60.0;

  AnswerGridWidget({super.key});

  final answerBlocks = List.generate(kNoOfSolutions, (index) {
    final value = index;
    final tile = Block(number: value, size: kBlockSize);
    return Draggable<int>(data: value, feedback: tile, childWhenDragging: tile, child: tile);
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SizedBox(
        width: kBlockSize * 10 + kSpacing * 9,
        child: Wrap(spacing: kSpacing, runSpacing: kSpacing, children: answerBlocks),
      ),
    );
  }
}

class HelperBackgroundPainter extends CustomPainter {
  final thick = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.black
    ..strokeWidth = 3;

  final normal = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.black26
    ..strokeWidth = 3;

  final thin = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.black12
    ..strokeWidth = 1;

  final filled = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.black12;

  @override
  void paint(Canvas canvas, Size size) {
    for (int x = 0; x <= size.width / (kGridSize * 5); x++) {
      canvas.drawLine(Offset(x * kGridSize * 5, 0), Offset(x * kGridSize * 5, size.height), normal);
    }

    for (int x = 0; x <= size.width / (kGridSize * 10); x++) {
      canvas.drawLine(Offset(x * kGridSize * 10, 0), Offset(x * kGridSize * 10, size.height), thick);
    }

    for (int x = 0; x <= size.width / kGridSize; x++) {
      canvas.drawLine(Offset(x * kGridSize, 0), Offset(x * kGridSize, size.height), thin);
    }

    for (int y = 0; y <= size.height / kGridSize; y++) {
      canvas.drawLine(Offset(0, y * kGridSize), Offset(size.width, y * kGridSize), thick);
    }

    for (int y = 0; y <= size.height / kGridSize - 1; y++) {
      for (int x = 0; x <= size.width / kGridSize - 1; x++) {
        canvas.drawCircle(Offset((x + 0.5) * kGridSize, (y + 0.5) * kGridSize), 5, filled);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HelperBackgroundWidget extends StatelessWidget {
  final List<Widget> children;
  const HelperBackgroundWidget({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    var background = CustomPaint(
      painter: HelperBackgroundPainter(),
      child: SizedBox(
        width: 800,
        height: 200,
        child: Stack(children: children),
      ),
    );
    return DragTarget<_HelperBarWidgetState>(
      builder: (BuildContext context, List<dynamic> accepted, List<dynamic> rejected) {
        return background;
      },
      onAcceptWithDetails: (details) {
        // change the position of the bar at the end of dragging to the new position
        RenderBox rBox = context.findRenderObject() as RenderBox;
        var localOffset = rBox.globalToLocal(details.offset);
        details.data.updatePosition(localOffset);
      },
    );
  }
}

class HelperBarWidget extends StatefulWidget {
  final int size;
  const HelperBarWidget({super.key, required this.size});

  @override
  State<HelperBarWidget> createState() => _HelperBarWidgetState();
}

class _HelperBarWidgetState extends State<HelperBarWidget> {
  Offset _position = Offset.zero;

  @override
  void initState() {
    super.initState();
    var r = Random();
    _position = Offset(r.nextDouble() * 400, r.nextDouble() * 150);
  }

  void updatePosition(Offset position) {
    setState(() {
      _position = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    var bar = SizedBox(
      width: widget.size * kGridSize,
      height: kGridSize,
      child: ClipRect(
        child: CustomPaint(
          foregroundPainter: HelperBackgroundPainter(),
          child: Container(
            color: colorMap[widget.size % 10],
          ),
        ),
      ),
    );

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: Draggable<_HelperBarWidgetState>(
        data: this,
        feedback: bar,
        childWhenDragging: Container(),
        child: bar,
      ),
    );
  }
}

/// low latency sound engine
final _soundPool = Soundpool.fromOptions(options: const SoundpoolOptions(streamType: StreamType.notification));
final _soundToId = <Sound, int>{};

enum Sound {
  success("success.mp3"),
  failure("failure.mp3");

  final String filename;
  const Sound(this.filename);

  Future<int> play() async {
    if (!kIsWeb) return Future<int>(() => -1);
    int soundId = _soundToId[this] ?? await _soundPool.load(await rootBundle.load("assets/sound/$filename"));
    if (soundId >= 0) _soundToId[this] = soundId;
    return await _soundPool.play(soundId);
  }

  static Future<void> init() async {
    if (!kIsWeb) return;
    for (var s in Sound.values) {
      _soundToId[s] = await _soundPool.load(await rootBundle.load("assets/sound/${s.filename}"));
    }
  }
}

enum DigitSpec {
  digit_0({0}, "0"),
  digit_1({1}, "1"),
  digit_2({2}, "2"),
  digit_3({3}, "3"),
  digit_4({4}, "4"),
  digit_5({5}, "5"),
  digit_6({6}, "6"),
  digit_7({7}, "7"),
  digit_8({8}, "8"),
  digit_9({9}, "9"),

  non_0({1, 2, 3, 4, 5, 6, 7, 8, 9}, "nem nulla"),
  div_by_5({0, 5}, "osztható 5-el"),
  lt_5({0, 1, 2, 3, 4}, "< 5"),
  mt_5({5, 6, 7, 8, 9}, ">= 5"),
  even({0, 2, 4, 6, 8}, "páros"),
  odd({1, 3, 5, 7, 9}, "páratlan"),
  all({0, 1, 2, 3, 4, 5, 6, 7, 8, 9}, "minden");

  final Set<int> digits;
  final String label;
  const DigitSpec(this.digits, this.label);
}

/// Draw a digit randomly from a set of digits with uniform distribution taking into account the min, max value
/// With an empty set after the min,max filtering, it will return -1
/// If the set contains a single element, it returns that element
int drawDigit(DigitSpec digitSet, {int min = 0, int max = 9}) {
  if (max < min) max = min;
  var s = Set<int>.of(digitSet.digits)..retainWhere((d) => d >= min && d <= max);
  if (s.isEmpty) return -1;
  if (s.length == 1) return s.first;
  return s.elementAt(Random().nextInt(s.length));
}

/// Draws a two digit number from two sets of digits
/// The first digit is drawn from the first set, the second digit is drawn from the second set
/// Allows specification of a minimum and maximum value. If the constraints cannot be met, -1 is returned
int drawTwoDigitNumber(DigitSpec firstDigits, DigitSpec secondDigits, {int min = 0, int max = 99}) {
  final int minFirst = min ~/ 10;
  final int maxFirst = max ~/ 10;
  final int minSecond = min % 10;
  final int maxSecond = max % 10;
  final int first = drawDigit(firstDigits, min: minFirst, max: maxFirst);
  if (first == -1) return -1;

  final int second = drawDigit(
    secondDigits,
    min: first == minFirst ? minSecond : 0,
    max: first == maxFirst ? maxSecond : 9,
  );
  if (second == -1) return -1;

  return first * 10 + second;
}

enum Currency {
  minecoin('assets/image/minecoin.webp', 320),
  robux('assets/image/robux.webp', 400);

  final String imagePath;
  final int cashoutUnit;
  const Currency(this.imagePath, this.cashoutUnit);

  @override
  String toString() => imagePath;
}

enum Operation {
  add("+"),
  sub("-"),
  mul("×"),
  div("÷");

  final String opChar;
  const Operation(this.opChar);

  @override
  String toString() => opChar;
}

enum Relation {
  eq("="),
  less("<"),
  greater(">"),
  lessOrEq("<="),
  greaterOrEq(">=");

  final String relChar;
  const Relation(this.relChar);

  @override
  String toString() => relChar;
}

class Puzzle {
  final int first;
  final Operation operation;
  final int second;
  final Relation relation;
  final int third;

  Puzzle(this.first, this.operation, this.second, this.relation, this.third);

  @override
  String toString() {
    return "$first $operation $second $relation $third";
  }
}

class PuzzleConfig {
  Currency currency;
  DigitSpec msd1;
  DigitSpec lsd1;
  Operation operation;
  DigitSpec msd2;
  DigitSpec lsd2;
  Relation relation;

  PuzzleConfig(this.msd1, this.lsd1, this.operation, this.msd2, this.lsd2, this.relation, this.currency);

  @override
  String toString() {
    return "${currency.name} [${msd1.label}, ${lsd1.label}] ${operation.opChar} [${msd2.label}, ${lsd2.label}] ${relation.relChar} ???";
  }
}

final r = Random(DateTime.now().millisecondsSinceEpoch);

Puzzle generatePuzzle(PuzzleConfig pc) {
  var op = Operation.add;
  var rel = Relation.eq;
  int first = 0, second = 0, third = 0;

  if (pc.operation == Operation.add) {
    // addition
    rel = Relation.eq;
    op = Operation.add;
    for (int i = 0; i < 30; ++i) {
      // try at least 30 times if the constraints cannot be met (digit set vs max/min)
      first = drawTwoDigitNumber(pc.msd1, pc.lsd1);
      if (first == -1) continue;

      second = drawTwoDigitNumber(pc.msd2, pc.lsd2, max: 99 - first);
      if (second == -1) continue;

      break;
    }
    // if a constraints cannot be met, use 0 which always works
    if (first == -1) first = 0;
    if (second == -1) second = 0;

    third = first + second;
  } else if (pc.operation == Operation.sub) {
    // subtraction
    rel = Relation.eq;
    op = Operation.sub;
    for (int i = 0; i < 30; ++i) {
      // try at least 30 times if the constraints cannot be met (digit set vs max/min)
      first = drawTwoDigitNumber(pc.msd1, pc.lsd1);
      if (first == -1) continue;

      second = drawTwoDigitNumber(pc.msd2, pc.lsd2, max: first);
      if (second == -1) continue;

      break;
    }
    // if a constraints cannot be met, use 0 which always works
    if (first == -1) first = 0;
    if (second == -1) second = 0;

    third = first - second;
  } else if (pc.operation == Operation.mul) {
    // multiplication
    rel = Relation.eq;
    op = Operation.mul;
    first = drawDigit(pc.lsd1);
    second = drawDigit(pc.lsd2);
    third = first * second;
  } else if (pc.operation == Operation.div) {
    // division
    rel = Relation.eq;
    op = Operation.div;
    third = drawDigit(DigitSpec.non_0);
    second = drawDigit(DigitSpec.non_0);
    first = second * third;
  }

  return Puzzle(first, op, second, rel, third);
}

int calculateReward(Puzzle puzzle) {
  if (puzzle.first == 0 || puzzle.second == 0) return 1;

  int reward = 0;
  if (puzzle.first >= 20) reward++;
  if (puzzle.first >= 50) reward++;
  if (puzzle.second >= 20) reward++;
  if (puzzle.second >= 50) reward++;
  switch (puzzle.operation) {
    case Operation.add:
      if (puzzle.first % 10 != 0 && puzzle.first >= 10) reward += 2;
      if (puzzle.second % 10 != 0 && puzzle.second >= 10) reward += 2;
      if (puzzle.third % 10 != 0) reward += 2;
      if (puzzle.first % 10 + puzzle.second % 10 >= 10) reward += 7; // more rewards for carrying over
      break;
    case Operation.sub:
      if (puzzle.first % 10 != 0 && puzzle.first >= 10) reward += 2;
      if (puzzle.second % 10 != 0 && puzzle.second >= 10) reward += 2;
      if (puzzle.third % 10 != 0) reward += 2;
      if (puzzle.first % 10 - puzzle.second % 10 < 0) reward += 7; // more rewards for carrying over
      break;
    case Operation.mul:
      if (puzzle.first <= 1 || puzzle.second <= 1) return 1;
      reward += 1;

      if ({5}.contains(puzzle.first)) reward += 1;
      if ({9}.contains(puzzle.first)) reward += 2;
      if ({3, 4, 6}.contains(puzzle.first)) reward += 3;
      if ({7, 8}.contains(puzzle.first)) reward += 4;

      if ({5}.contains(puzzle.second)) reward += 1;
      if ({9}.contains(puzzle.second)) reward += 2;
      if ({3, 4, 6}.contains(puzzle.second)) reward += 3;
      if ({7, 8}.contains(puzzle.second)) reward += 4;
      break;
    case Operation.div:
      if (puzzle.second <= 1 || puzzle.third <= 1) return 1;
      reward += 1;
      if (puzzle.first >= 10) reward += 2;
      if (puzzle.first >= 30) reward += 2;
      if (puzzle.first >= 60) reward += 2;
      if (puzzle.second > 4) reward += 2;
      if (puzzle.second > 6) reward += 2;
      break;
  }
  return reward;
}

/// Settings screen ============================================================
///
