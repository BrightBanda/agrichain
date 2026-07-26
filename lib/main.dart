import 'package:agri/src/core/theme/app_colors.dart';
import 'package:agri/src/presentation/view/analytics_page.dart';
import 'package:agri/src/presentation/view/auth_gate.dart';
import 'package:agri/src/presentation/view/AccountSelectionPage.dart';
import 'package:agri/src/presentation/view/SecurityPasswordPage.dart';
import 'package:agri/src/presentation/view/farm_harvest_page.dart';
import 'package:agri/src/presentation/view/landing_page.dart';
import 'package:agri/src/presentation/view/lending_score_page.dart';
import 'package:agri/src/presentation/view/login_page.dart';
import 'package:agri/src/presentation/view/product_form_page.dart';
import 'package:agri/src/presentation/view/sign_in_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  // ProviderScope hosts every view model, repository and the Dio client.
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgriChain',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: FarmHarvestPage(),
    );
  }
}
