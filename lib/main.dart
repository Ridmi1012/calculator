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
  static const int MAX_EXPRESSION_LENGTH = 20;

  void _onButtonPressed(String value) {
    setState(() {
      if (value == '=') {
        // Calculate the result when '=' is pressed
        _onEnter();
        return;
      } else if (value == '√') {
        // **New handling for the square root button**
        _calculateSquareRootOfExpression();
        return;
      }

      if (_expression.length >= MAX_EXPRESSION_LENGTH) {
        return;
      }

      if (isOperator(value) &&
          _expression.isNotEmpty &&
          isOperator(_expression[_expression.length - 1])) {
        _expression = _expression.substring(0, _expression.length - 1) + value;
      } else {
        _displayValue = '';
        _expression += value;
      }
    });
  }

  bool isOperator(String value) {
    return value == '+' || value == '-' || value == 'x' || value == '/' || value == '%' || value == '.';
  }

  void _onClear() {
    setState(() {
      _displayValue = '0';
      _expression = '';
      _resultFontSize = 64;
      _isResultDisplayed = false;
    });
  }

  void _onClearEntry() {
    setState(() {
      if (_isResultDisplayed) {
        _displayValue = '0';
      } else if (_expression.isNotEmpty) {
        _expression = _expression.substring(0, _expression.length - 1);
      }
    });
  }

  // **New function to calculate the square root of the entire expression**
  void _calculateSquareRootOfExpression() {
    _onEnter(); // First, calculate the result of the expression
    setState(() {
      try {
        // Parse _displayValue as a double if it is a valid result
        double result = double.parse(_displayValue);

        if (result >= 0) {
          // Calculate the square root only if the result is non-negative
          double sqrtResult = sqrt(result);

          // Check if sqrtResult is an integer
          if (sqrtResult == sqrtResult.roundToDouble()) {
            _displayValue = sqrtResult.toStringAsFixed(0); // No decimal points
          } else {
            _displayValue = sqrtResult.toStringAsFixed(4); // Up to 4 decimal points
          }

          _isResultDisplayed = true;
          _expression = ''; // Clear the expression after displaying the result
        } else {
          // Display an error if trying to take the square root of a negative number
          _displayValue = 'Error';
        }
      } catch (e) {
        // Display an error if parsing fails or any other issue occurs
        _displayValue = 'Error';
      }
    });
  }

  void _onEnter() {
    try {
      if (_expression.isEmpty) return;

      Parser p = Parser();
      Expression exp = p.parse(_expression.replaceAll('x', '*'));
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      String formattedResult = eval.toStringAsFixed(8);
      if (formattedResult.contains('.')) {
        formattedResult = formattedResult.replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
      }
      if (formattedResult.length > 10) {
        formattedResult = eval.toStringAsExponential(6);
      }

      setState(() {
        _displayValue = formattedResult;
        _isResultDisplayed = true;
        _resultFontSize = 64;
        _expression = '';
      });
    } catch (e) {
      setState(() {
        _displayValue = 'Error';
        _expression = '';
        _resultFontSize = 48;
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
          style: const TextStyle(color: Colors.white), // Set title color to white
        ),
        backgroundColor: Colors.black,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _expression,
                      style: GoogleFonts.rubik(
                        textStyle: const TextStyle(fontSize: 48, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _displayValue.isEmpty ? ' ' : _displayValue, // Display 0 if no value
                      style: GoogleFonts.rubik(
                        textStyle: TextStyle(fontSize: _resultFontSize, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildButtonRow(['AC', 'C', '%', '/']),
                buildButtonRow(['7', '8', '9', 'x']),
                buildButtonRow(['4', '5', '6', '-']),
                buildButtonRow(['1', '2', '3', '+']),
                buildButtonRow(['0', '.', '√', '=']),
              ],
            ),
          ],
        ),
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

    if (label == 'AC' || label == '00') {
      buttonFontSize = 16; // Smaller font size for AC and 00
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
            overlayColor: WidgetStateProperty.all(overlayColor.withOpacity(0.3)),
          ),
          child: Text(
            label,
            style: GoogleFonts.rubik(
              textStyle: TextStyle(fontSize: buttonFontSize, color: textColor),
            ),
          ),
          onPressed: () {
            if (label == 'AC') {
              _onClear(); // Clear all entries
            } else if (label == 'C') {
              _onClearEntry(); // Clear the last entry
            } else if (label == '=') {
              _onEnter(); // Calculate the result
            } else if (label == '%') {
               // Calculate percentage
            } else if (label == '√') {
              _calculateSquareRootOfExpression();
            }else {
              // If result is displayed, start new calculation with previous result
              if (_isResultDisplayed) {
                _expression = _displayValue; // Start a new expression with the previous result
                _displayValue = ''; // Reset display for new input
                _isResultDisplayed = false; // Reset result display status
              }
              _onButtonPressed(label); // Process button press
            }
          },
        ),
      ),
    );
  }
}

//To Do
//can't find the square root of a continues calclation
//percentage is not working properly