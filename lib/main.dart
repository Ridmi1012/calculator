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
  String _displayValue = '0 '; // Display value shown on the screen
  String _expression = ''; // Expression input by the user
  double _resultFontSize = 48; // Default font size for the result
  bool _isResultDisplayed = false; // Track if result is displayed

  void _onButtonPressed(String value) {
    setState(() {
      if (value == '=') {
        // If equals is pressed, calculate the result
        _onEnter();
        return; // Don't add to the expression
      }

      if (isOperator(value) &&
          _expression.isNotEmpty &&
          isOperator(_expression[_expression.length - 1])) {
        // Replace the last operator if the current input is also an operator
        _expression = _expression.substring(0 , _expression.length - 1) + value;
      } else {
        // Update the expression with the new input
        _displayValue = ' ';
        _expression += value;
      }

    });
  }

  bool isOperator(String value) {
    return value == '+' || value == '-' || value == 'x' || value == '/' || value == '%' || value == '.' || value == '√';
  }

  void _onClear() {
    setState(() {
      _displayValue = '0'; // Reset display value
      _expression = ''; // Clear expression
      _resultFontSize = 64; // Reset font size on clear
      _isResultDisplayed = false; // Reset result display status
    });
  }

  void _onClearEntry() {
    setState(() {
      if (_isResultDisplayed) {
        // If result is displayed, remove the last digit from the displayed value
        if (_displayValue.length > 1) {
          // Keep at least one character to avoid showing empty
          _displayValue = _displayValue.substring(0, _displayValue.length - 1);
        } else {
          // If only one digit is left, reset the display
          _displayValue = '0';
        }
      } else {
        // If expression is not empty, remove the last character from the expression
        if (_expression.isNotEmpty || _expression.length > 1) {
          _expression = _expression.substring(0, _expression.length - 1);
        }else {
          _expression = ' ';
          _displayValue = '0';
        }
      }
    });
  }

  void _onEnter() {
    try {
      if (_expression.isEmpty) return;

      // Check for division by zero
      if (_expression.contains('/0')) {
        throw Exception('Division by zero');
      }

      Parser p = Parser();
      Expression exp = p.parse(_expression.replaceAll('x', '*'));
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      String formattedResult = eval % 1 == 0 ? eval.toInt().toString() : eval.toString();

      // Set the result to the display
      setState(() {
        _displayValue = formattedResult; // Update display with result
        _isResultDisplayed = true; // Set result display status
        _resultFontSize = 64; // Increase font size for the result

        // Clear expression when result is displayed
        _expression = '';
      });
    } catch (e) {
      setState(() {
        _displayValue = 'Error'; // Display error on invalid expression
        _expression = ''; // Clear expression on error
        _resultFontSize = 48; // Reset font size on error
        _isResultDisplayed = false; // Reset result display status
      });
    }
  }

  void _calculatePercentage() {
    setState(() {
      if (_expression.isNotEmpty) {
        // Assume the last number in the expression is the base
        final parts = _expression.split(RegExp(r'[\+\-\*/]'));
        if (parts.length >= 2) {
          double percentage = double.tryParse(parts[parts.length - 2]) ?? 0; // Get the percentage part
          double baseNumber = double.tryParse(parts.last) ?? 0; // Get the base number
          double result = (percentage / 100) * baseNumber; // Calculate the percentage
          // Update the expression with the new percentage calculation
          _expression = _expression.replaceRange(_expression.length - parts.last.length, _expression.length, result.toString()); // Replace last number with percentage result
        }
      }
    });
  }

  void _calculateSquareRoot() {
    setState(() {
      if (_expression.isNotEmpty) {
        double number = double.tryParse(_expression) ?? 0;
        if (number >= 0) {
          _expression = (sqrt(number)).toString(); // Calculate square root
        } else {
          _expression = 'Error'; // Handle negative input
        }
        _onEnter(); // Automatically calculate after square root
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
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
            overlayColor: MaterialStateProperty.all(overlayColor.withOpacity(0.3)),
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
              _calculatePercentage(); // Calculate percentage
            } else if (label == '√') {
              _calculateSquareRoot(); // Calculate square root
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