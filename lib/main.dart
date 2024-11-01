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
  static const int MAX_EXPRESSION_LENGTH = 20;

  void _onButtonPressed(String value) {
    setState(() {
      if (value == '=') {
        // If equals is pressed, calculate the result
        _onEnter();
        return; // Don't add to the expression
      }

      // Prevent further input if expression length exceeds MAX_EXPRESSION_LENGTH
      if (_expression.length >= MAX_EXPRESSION_LENGTH) {
        return; // Stop adding characters if max length reached
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

  void _calculateSquareRoot() {
    setState(() {
      // Extract the last number in the expression to apply the square root
      final match = RegExp(r'\d+(\.\d+)?$').firstMatch(_expression);
      if (match != null) {
        final lastNumberStr = match.group(0) ?? '0';
        final lastNumber = double.tryParse(lastNumberStr) ?? 0;

        if (lastNumber >= 0) {
          // Calculate square root and replace the last number with the result
          final sqrtResult = sqrt(lastNumber).toStringAsFixed(4);
          _expression = _expression.replaceFirst(RegExp(r'\d+(\.\d+)?$'), sqrtResult);
        } else {
          _displayValue = 'Error';
          _expression = '';
        }
        _onEnter(); // Calculate the new result
      }
    });
  }

  void _calculatePercentage() {
    setState(() {
      // Apply percentage to the last operand in the expression
      final match = RegExp(r'\d+(\.\d+)?$').firstMatch(_expression);
      if (match != null) {
        final lastNumberStr = match.group(0) ?? '0';
        final lastNumber = double.tryParse(lastNumberStr) ?? 0;

        // Calculate the percentage and replace last operand with result
        final percentResult = (lastNumber / 100).toStringAsFixed(4);
        _expression = _expression.replaceFirst(RegExp(r'\d+(\.\d+)?$'), percentResult);
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

      // Limit decimal places to prevent overflow
      String formattedResult = eval.toStringAsFixed(8);

      // Remove unnecessary trailing zeroes after decimal
      if (formattedResult.contains('.')) {
        formattedResult = formattedResult.replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
      }

      // Limit displayed digits to prevent overflow in UI
      if (formattedResult.length > 10) {
        formattedResult = eval.toStringAsExponential(6); // Switch to exponential if too long
      }

      setState(() {
        _displayValue = formattedResult; // Update display with result
        _isResultDisplayed = true; // Set result display status
        _resultFontSize = 64; // Increase font size for the result
        _expression = ''; // Clear expression when result is displayed
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