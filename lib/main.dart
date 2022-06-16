import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundpool/soundpool.dart';

final mineCoinImage = Image.asset('assets/image/minecoin.webp');
final happyImage = Image.asset('assets/image/happy.webp');
final sadImage = Image.asset('assets/image/sad.webp');
const kDefaultTextStyle = TextStyle(fontWeight: FontWeight.normal, fontFamily: 'Roboto', decoration: TextDecoration.none);
const kBlockSize = 100.0;

enum Operation {
  add("+"),
  sub("-"),
  mul("*"),
  div("/");

  final String opChar;
  const Operation(this.opChar);

  @override
  String toString() => opChar;
}

enum Relation {
  eq("="),
  less("<"),
  more(">"),
  lessOrEq("<="),
  moreOrEq(">=");

  final String relChar;
  const Relation(this.relChar);

  @override
  String toString() => relChar;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MathMinerApp());
}

class MathMinerApp extends StatelessWidget {
  const MathMinerApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MathMine',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MathMiner(),
    );
  }
}

class MathMiner extends StatefulWidget {
  const MathMiner({Key? key}) : super(key: key);

  @override
  State<MathMiner> createState() => _MathMinerState();
}

class _MathMinerState extends State<MathMiner> {
  int _coins = 0;
  int _reward = 1;
  int _solution = 2;
  int _1st = 1;
  int _2nd = 1;
  // bool showSolution = false;
  bool showFailure = false;
  bool showSuccess = false;
  Operation op = Operation.add;
  Relation rel = Relation.eq;

  @override
  initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _coins = prefs.getInt("coins") ?? 0;
      });
    });
  }

  _generatePuzzle() {
    setState(() {
      showFailure = false;
      showSuccess = false;
      var r = Random();
      // addition
      rel = Relation.eq;
      op = Operation.add;
      _solution = 1 + r.nextInt(30);
      _1st = r.nextInt(_solution);
      _2nd = _solution - _1st;

      // reward calculation
      if (_1st == 0 || _1st == 1 || _2nd == 0 || _2nd == 1) {
        _reward = 1;
      } else if (_1st < 10 && _2nd < 10 && _solution >= 10) {
        _reward = 3;
      } else if ((_1st < 20 && _2nd < 20) && _solution >= 20) {
        _reward = 3;
      } else if (_solution >= 10) {
        _reward = 2;
      } else {
        _reward = 1;
      }
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
        _generatePuzzle();
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
        _generatePuzzle();
      });
    });
  }

  _cashOut() {
    if (_coins > 320) {
      Sound.success.play();
      setState(() {
        _coins -= 320;
        SharedPreferences.getInstance().then((prefs) {
          prefs.setInt("coins", _coins);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // floatingActionButton: FloatingActionButton(onPressed: _generatePuzzle),
      appBar: AppBar(title: CoinCounter(coins: _coins, onLongPress: _cashOut)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              color: showFailure
                  ? Colors.red.shade100
                  : showSuccess
                      ? Colors.green.shade100
                      : Colors.blue.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Block(number: _1st),
                  Block(operation: op),
                  Block(number: _2nd),
                  Block(relation: rel),
                  showSuccess
                      ? Block(number: _solution)
                      : showFailure
                          ? const Block(showFailure: true)
                          : SolutionBlock(_solution, reward: _reward, onSuccess: _success, onFailure: _failure),
                ],
              ),
            ),
            Container(),
            AnswerGrid(),
          ],
        ),
      ),
    );
  }
}

class CoinCounter extends StatelessWidget {
  final VoidCallback onLongPress;
  final int coins;
  const CoinCounter({super.key, required this.coins, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      GestureDetector(onLongPress: onLongPress, child: SizedBox.square(dimension: 48, child: mineCoinImage)),
      Container(
        padding: const EdgeInsets.only(left: 10),
        child: Text('$coins', style: kDefaultTextStyle.copyWith(fontSize: 32)),
      ),
    ]);
  }
}

class Block extends StatelessWidget {
  static final colorMap = [
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

  final int? number;
  final int? reward;
  final Operation? operation;
  final Relation? relation;
  final bool hidden;
  final bool showFailure;
  final bool showSuccess;
  const Block({
    super.key,
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
      width: kBlockSize,
      height: kBlockSize,
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
                        padding: const EdgeInsets.all(2.0),
                        child: Wrap(
                          spacing: 2,
                          alignment: WrapAlignment.center,
                          runSpacing: 2,
                          runAlignment: WrapAlignment.spaceEvenly,
                          children: List.filled(reward!, SizedBox.square(dimension: 28, child: mineCoinImage)),
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
                        style: kDefaultTextStyle.copyWith(color: foregroundColor, fontSize: 72),
                      )),
      ),
    );
  }
}

/// A block that can accept an other block dropped on it and shows the possible rewards
/// for a successful guess.
class SolutionBlock extends StatelessWidget {
  final int solution;
  final int reward;
  final VoidCallback onSuccess;
  final VoidCallback onFailure;
  const SolutionBlock(
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

class AnswerGrid extends StatelessWidget {
  static const kSpacing = 20.0;

  AnswerGrid({super.key});

  final answerBlocks = List.generate(30, (index) {
    final value = index + 1;
    final tile = Block(number: value);
    return Draggable<int>(data: value, feedback: tile, childWhenDragging: tile, child: tile);
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SizedBox(
        width: kBlockSize * 5 + kSpacing * 4,
        child: Wrap(spacing: kSpacing, runSpacing: kSpacing, children: answerBlocks),
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
