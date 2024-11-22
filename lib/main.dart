import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:math_expressions/math_expressions.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(title: 'Calculator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _displayValue = '0';
  String _expression = '';
  double _resultFontSize = 48;
  bool _isResultDisplayed = false;
  static const int MAX_EXPRESSION_LENGTH = 15;

  // History storage
  List<String> _history = [];
  bool _isHistoryVisible = false; // Flag for toggling history visibility

  // Handles button press events
  void _onButtonPressed(String value) {
    setState(() {
      if (value == '=') {
        _onEnter();
        return;
      }

      if (_expression.length >= MAX_EXPRESSION_LENGTH) return;

      if (value == '.' &&
          (_expression.isEmpty ||
              _expression.endsWith('.') ||
              isOperator(_expression[_expression.length - 1]))) {
        return;
      }

      if (value == '.' &&
          _expression.split(RegExp(r'[^0-9.]')).last.contains('.')) {
        return;
      }

      if (value == '( )') {
        _handleBrackets();
      } else if (value == '√') {
        _expression += 'sqrt(';
      } else if (isOperator(value) &&
          _expression.isNotEmpty &&
          isOperator(_expression[_expression.length - 1])) {
        _expression =
            _expression.substring(0, _expression.length - 1) + value;
      } else {
        _displayValue = '';
        _expression += value;
      }
    });
  }

  void _handleBrackets() {
    setState(() {
      int openBrackets = _expression.split('(').length - 1;
      int closeBrackets = _expression.split(')').length - 1;

      if (openBrackets > closeBrackets) {
        _expression += ')';
      } else {
        _expression += '(';
      }
    });
  }

  bool isOperator(String value) {
    return value == '+' ||
        value == '-' ||
        value == 'x' ||
        value == '/' ||
        value == '.' ||
        value == '√';
  }

  void _onClear() {
    setState(() {
      _displayValue = ' ';
      _expression = '';
      _resultFontSize = 64;
      _isResultDisplayed = false;
    });
  }

  void _onClearEntry() {
    setState(() {
      if (_isResultDisplayed) {
        _displayValue = ' ';
      } else if (_expression.isNotEmpty) {
        _expression = _expression.substring(0, _expression.length - 1);
      }
    });
  }
  void _onEnter() {
    try {
      if (_expression.isEmpty) return;

      if (_expression.contains('/0')) {
        setState(() {
          _displayValue = 'Error';
          _expression = '';
          _isResultDisplayed = false;
        });
        return;
      }

      // Replace 'sqrt(' with the actual MathExpression parser-friendly syntax
      String parsedExpression = _expression.replaceAll('sqrt', 'sqrt');

      Parser parser = Parser();
      Expression exp = parser.parse(parsedExpression.replaceAll('x', '*'));
      ContextModel contextModel = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, contextModel);

      String formatResult(num eval) {
        String formattedResult;
        if (eval.abs() < 1e4 && eval.abs() > 1e-4) {
          formattedResult = eval
              .toStringAsFixed(7)
              .replaceAll(RegExp(r'0+$'), '')
              .replaceAll(RegExp(r'\.$'), '');
        } else {
          formattedResult = eval.toStringAsExponential(4);
        }
        return formattedResult;
      }

      setState(() {
        if (eval.isInfinite || eval.isNaN) {
          _displayValue = 'Error';
        } else {
          _displayValue = formatResult(eval);
          _history.add('$_expression = $_displayValue');
        }
        _isResultDisplayed = true;
        _resultFontSize = 64;
        _expression = '';
      });
    } catch (e) {
      setState(() {
        _displayValue = 'Error';
        _expression = '';
        _resultFontSize = 46;
        _isResultDisplayed = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              setState(() {
                _isHistoryVisible = !_isHistoryVisible;
              });
            },
          ),
        ],
      ),
      body: _isHistoryVisible
          ? buildHistoryView()
          : buildCalculatorView(),
    );
  }

  Widget buildHistoryView() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _history.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(
                  _history[index],
                  style: GoogleFonts.rubik(
                    textStyle: const TextStyle(
                        fontSize: 18, color: Colors.white),
                  ),
                ),
                onTap: () {
                  setState(() {
                    _expression = _history[index].split(' = ')[1];
                    _isHistoryVisible = false;
                  });
                },
              );
            },
          ),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _history.clear();
            });
          },
          child: const Text('Clear History'),
        ),
      ],
    );
  }

  Widget buildCalculatorView() {
    return Container(
      alignment: Alignment.bottomRight,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _expression,
                      style: GoogleFonts.rubik(
                        textStyle: const TextStyle(fontSize: 48, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _displayValue.isEmpty ? ' ' : _displayValue,
                      style: GoogleFonts.rubik(
                        textStyle: TextStyle(fontSize: _resultFontSize, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildButtonRow(['AC', 'C', '( )', '/']),
              buildButtonRow(['7', '8', '9', 'x']),
              buildButtonRow(['4', '5', '6', '-']),
              buildButtonRow(['1', '2', '3', '+']),
              buildButtonRow(['0', '.', '√', '=']),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildButtonRow(List<String> labels) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: labels.map((label) {
        return Expanded(
          child: buildCalculatorButton(label),
        );
      }).toList(),
    );
  }

  Widget buildCalculatorButton(String label, {double fontSize = 24}) {
    Color textColor;
    Color overlayColor;
    double buttonFontSize = fontSize;

    if (label == 'AC' || label == '( )') {
      buttonFontSize = 16;
    }

    if (label == 'AC' || label == 'C') {
      textColor = Colors.blue;
      overlayColor = Colors.blue.shade200;
    } else if (isOperator(label)) {
      textColor = Colors.purple;
      overlayColor = Colors.purple.shade100;
    } else if (label == '=') {
      textColor = Colors.white;
      overlayColor = Colors.purple.shade100;
    } else {
      textColor = Colors.white;
      overlayColor = Colors.grey.shade300;
    }

    return Container(
      margin: const EdgeInsets.all(5.0),
      child: AspectRatio(
        aspectRatio: 1,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: label == '=' ? Colors.transparent : Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
              side: label == '=' ? const BorderSide(color: Colors.purple, width: 3.0) : BorderSide.none,
            ),
          ).copyWith(
            overlayColor: WidgetStatePropertyAll(overlayColor.withOpacity(0.3)),
          ),
          child: Text(
            label,
            style: GoogleFonts.rubik(
              textStyle: TextStyle(fontSize: buttonFontSize, color: textColor),
            ),
          ),
          onPressed: () {
            if (label == 'AC') {
              _onClear();
            } else if (label == 'C') {
              _onClearEntry();
            } else if (label == '=') {
              _onEnter();
            } else {
              if (_isResultDisplayed) {
                _expression = _displayValue;
                _displayValue = '';
                _isResultDisplayed = false;
              }
              _onButtonPressed(label);
            }
          },
        ),
      ),
    );
  }
}
