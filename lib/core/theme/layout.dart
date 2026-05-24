import 'package:flutter/material.dart';

/// Extra bottom inset so content clears the system navigation bar (~10px).
double screenBottomInset(BuildContext context) =>
    MediaQuery.viewPaddingOf(context).bottom + 10;
