import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' show dotenv;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hypebard/components/HideKeyboard.dart';
import 'package:hypebard/page/AppOpenPage.dart';
import 'package:hypebard/stores/AIChatStore.dart';
import 'package:hypebard/utils/Chatgpt.dart';
import 'package:provider/provider.dart';

/// 程序的入口点，执行初始化和应用启动
void main() async {
  // 设置状态栏样式为透明
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  // 加载环境变量
  await dotenv.load(fileName: ".env");

  // 初始化存储和ChatGPT服务
  await GetStorage.init();
  await ChatGPT.initChatGPT();

  // 启动应用并配置加载状态
  runApp(
    ChangeNotifierProvider(
      create: (context) => AIChatStore(),
      child: const MyApp(),
    ),
  );
  configLoading();
}

/// 设置全屏模式，保留底部Overlay
void enterFullScreenButKeepBottomOverlay() {
  // 设置系统UI模式为全屏边缘模式
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

/// MyApp Widget，应用的根组件
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 构建应用基础结构，隐藏键盘，设置主题和首页
    return HideKeyboard(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF6F1F1),
          brightness: Brightness.light,
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
          fontFamily: 'Poppins',
        ),
        home: const SplashPage(),
        builder: EasyLoading.init(),
      ),
    );
  }
}

/// 配置EasyLoading加载指示器的显示样式和行为
Future<void> configLoading() async {
  // 配置EasyLoading实例，设置其外观和行为
  EasyLoading.instance
    ..maskType = EasyLoadingMaskType.none
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..displayDuration = const Duration(milliseconds: 1000)
    ..userInteractions = false;
}
