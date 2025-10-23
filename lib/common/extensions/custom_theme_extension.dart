import 'package:flutter/material.dart';

import './common_colors.dart';

extension ExtendedTheme on BuildContext {
  CustomThemeExtension get theme =>
      Theme.of(this).extension<CustomThemeExtension>()!;
}

class CustomThemeExtension extends ThemeExtension<CustomThemeExtension> {
  final Color? primaryColor;
  final Color? whiteBgColor;
  final Color? grayBgColor;
  final Color? black;
  final Color? green;
  final Color? red;
  final Color? red500;
  final Color? red300;
  final Color? blue;
  final Color? blue500;

  static const lightMode = CustomThemeExtension(
    primaryColor: CommonColors.primaryColor,
    whiteBgColor: CommonColors.whiteBgColor,
    grayBgColor: CommonColors.grayBgColor,
    black: CommonColors.blackColor,
    green: CommonColors.greenColor,
    red: CommonColors.redColor,
    red500: CommonColors.red500,
    red300: CommonColors.red300,
    blue: CommonColors.blueColor,
    blue500: CommonColors.blue500,
  );

  static const darkMode = CustomThemeExtension(
    primaryColor: CommonColors.primaryColor,
    whiteBgColor: CommonColors.whiteBgColor,
    grayBgColor: CommonColors.grayBgColor,
    black: CommonColors.blackColor,
    green: CommonColors.greenColor,
    red: CommonColors.redColor,
    red500: CommonColors.red500,
    red300: CommonColors.red300,
    blue: CommonColors.blueColor,
    blue500: CommonColors.blue500,
  );

  const CustomThemeExtension({
    this.primaryColor,
    this.whiteBgColor,
    this.grayBgColor,
    this.black,
    this.green,
    this.red,
    this.red500,
    this.red300,
    this.blue,
    this.blue500,
  });

  @override
  ThemeExtension<CustomThemeExtension> copyWith({
    Color? primaryColor,
    Color? whiteBgColor,
    Color? grayBgColor,
    Color? black,
    Color? green,
    Color? red,
    Color? red500,
    Color? red300,
    Color? blue,
    Color? blue500,
  }) {
    return CustomThemeExtension(
      primaryColor: primaryColor ?? this.primaryColor,
      whiteBgColor: whiteBgColor ?? this.whiteBgColor,
      grayBgColor: grayBgColor ?? this.grayBgColor,
      black: black ?? this.black,
      green: green ?? this.green,
      red: red ?? this.red,
      red500: red500 ?? this.red500,
      red300: red300 ?? this.red300,
      blue: blue ?? this.blue,
      blue500: blue500 ?? this.blue500,
    );
  }

  @override
  ThemeExtension<CustomThemeExtension> lerp(
    covariant ThemeExtension<CustomThemeExtension>? other,
    double t,
  ) {
    if (other is! CustomThemeExtension) {
      return this;
    }
    return CustomThemeExtension(
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t),
      whiteBgColor: Color.lerp(whiteBgColor, other.whiteBgColor, t),
      grayBgColor: Color.lerp(grayBgColor, other.grayBgColor, t),
      black: Color.lerp(black, other.black, t),
      green: Color.lerp(green, other.green, t),
      red: Color.lerp(red, other.red, t),
      red500: Color.lerp(red500, other.red500, t),
      red300: Color.lerp(red300, other.red300, t),
      blue: Color.lerp(blue, other.blue, t),
      blue500: Color.lerp(blue500, other.blue500, t),
    );
  }
}
