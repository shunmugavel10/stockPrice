import 'package:flutter/cupertino.dart';
import '../constants/app_colors.dart';

/// Cupertino theme configuration for iOS devices
class AppCupertinoTheme {
  AppCupertinoTheme._();

  static CupertinoThemeData get light => const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.lightBackground,
        barBackgroundColor: AppColors.lightSurface,
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.primary,
          textStyle: TextStyle(
            color: AppColors.lightTextPrimary,
            fontSize: 16,
            fontFamily: '.SF Pro Text',
          ),
          navTitleTextStyle: TextStyle(
            color: AppColors.lightTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: '.SF Pro Text',
          ),
          navLargeTitleTextStyle: TextStyle(
            color: AppColors.lightTextPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w700,
            fontFamily: '.SF Pro Display',
          ),
          tabLabelTextStyle: TextStyle(
            fontSize: 10,
            fontFamily: '.SF Pro Text',
          ),
        ),
      );

  static CupertinoThemeData get dark => const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.darkBackground,
        barBackgroundColor: AppColors.darkSurface,
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.primary,
          textStyle: TextStyle(
            color: AppColors.darkTextPrimary,
            fontSize: 16,
            fontFamily: '.SF Pro Text',
          ),
          navTitleTextStyle: TextStyle(
            color: AppColors.darkTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: '.SF Pro Text',
          ),
          navLargeTitleTextStyle: TextStyle(
            color: AppColors.darkTextPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w700,
            fontFamily: '.SF Pro Display',
          ),
          tabLabelTextStyle: TextStyle(
            fontSize: 10,
            fontFamily: '.SF Pro Text',
          ),
        ),
      );
}
