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
      theme: ThemeData( // Set the app title
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(title: 'Calculator'), // Set home widget
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
  String _expression = ''; // Expression entered by the user
  double _resultFontSize = 48;
  bool _isResultDisplayed = false; // Flag to check if the result is displayed
  static const int MAX_EXPRESSION_LENGTH = 15;

  // Handles button press events
  void _onButtonPressed(String value) {
    setState(() {
      if (value == '=') {
        _onEnter(); // If '=' is pressed, evaluate the expression
        return;
      } else if (value == '√') {
        _calculateSquareRootOfExpression(); // If '√' is pressed, calculate square root
        return;
      }

      // Prevent adding more characters if the expression length exceeds the limit
      if (_expression.length >= MAX_EXPRESSION_LENGTH) {
        return;
      }

      // Handle opening and closing brackets
      if (value == '( )') {
        _handleBrackets(); // Toggle brackets
      } else if (isOperator(value) &&
          _expression.isNotEmpty &&
          isOperator(_expression[_expression.length - 1])) {
        // If the last character is an operator, replace it with the new one
        _expression = _expression.substring(0, _expression.length - 1) + value;
      } else {
        // Add the button value to the expression
        _displayValue = '';
        _expression += value;
      }
    });
  }

  // Toggles between opening and closing brackets based on the current expression
  void _handleBrackets() {
    setState(() {
      int openBrackets = _expression.split('(').length - 1;
      int closeBrackets = _expression.split(')').length - 1;

      if (openBrackets > closeBrackets) {
        // Add a closing bracket if there's an unmatched opening bracket
        _expression += ')';
      } else {
        // Add an opening bracket if the counts are equal
        _expression += '(';
      }
    });
  }

  // Check if a string is an operator (e.g. +, -, x, /, .)
  bool isOperator(String value) {
    return value == '+' || value == '-' || value == 'x' || value == '/'  || value == '.' || value == '√';
  }

  // Clear all expressions and results
  void _onClear() {
    setState(() {
      _displayValue = ' ';
      _expression = '';
      _resultFontSize = 64;
      _isResultDisplayed = false; // Reset result display flag
    });
  }

  void _onClearEntry() {
    setState(() {
      if (_isResultDisplayed) {
        _displayValue = ' ';
      } else if (_expression.isNotEmpty) {
        // Remove the last character of the expression
        _expression = _expression.substring(0, _expression.length - 1);
      }
    });
  }

  // Calculate the square root of the entire expression's result
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
          _expression = '';
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

  // Evaluate the entered expression and display the result
  void _onEnter() {
    try {
      // No expression to evaluate
      if (_expression.isEmpty) return;

      // Prevent division by zero
      if (_expression.contains('/0')) {
        setState(() {
          _displayValue = 'Error'; // Show error for division by zero
          _expression = '';
          _isResultDisplayed = false;
        });
        return;
      }

      // Parse and evaluate the expression
      Parser parser = Parser();
      Expression exp = parser.parse(_expression.replaceAll('x', '*'));
      ContextModel contextModel = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, contextModel);

      // Format the result
      String formatResult(num eval) {
        String formattedResult;

        if (eval.abs() < 1e4 && eval.abs() > 1e-4) {
          // Use fixed-point notation for numbers in a reasonable range
          formattedResult = eval.toStringAsFixed(7);

          // Remove trailing zeros and unnecessary decimal points
          formattedResult = formattedResult
              .replaceAll(RegExp(r'0+$'), '') // Remove trailing zeros after the decimal
              .replaceAll(RegExp(r'\.$'), ''); // Remove decimal point if no fractional part
        } else {
          // Use exponential notation for very large or small numbers
          formattedResult = eval.toStringAsExponential(4);
        }

        return formattedResult;
      }

      // Display the formatted result
      setState(() {
        if (eval.isInfinite || eval.isNaN) {
          _displayValue = 'Error'; // Handle cases like 1/0 or invalid numbers
        } else {
          _displayValue = formatResult(eval);
        }
        _isResultDisplayed = true;
        _resultFontSize = 64;
        _expression = '';
      });
    } catch (e) {
      // Handle errors (e.g., invalid input or parsing issues)
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
          style: const TextStyle(color: Colors.white), // Set title color to white
        ),
        backgroundColor: Colors.black,
      ),
      body: Container(
        alignment: Alignment.bottomRight, // Ensure the entire content aligns to bottom-right
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
                  // Horizontal scroll for the expression aligned to the right corner
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Align(
                      alignment: Alignment.centerRight,  // Correct alignment to right corner
                      child: Text(
                        _expression,
                        style: GoogleFonts.rubik(
                          textStyle: const TextStyle(fontSize: 48, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Horizontal scroll for the result aligned to the right corner
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Align(
                      alignment: Alignment.centerRight,  // Correct alignment to right corner
                      child: Text(
                        _displayValue.isEmpty ? ' ' : _displayValue, // Display 0 if no value
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
      ),
    );
  }

  // Build a row of calculator buttons
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

  // Create a button with specific styling
  Widget buildCalculatorButton(String label, {double fontSize = 24}) {
    Color textColor;
    Color overlayColor;
    double buttonFontSize = fontSize;

    if (label == 'AC' || label == '( )') {
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