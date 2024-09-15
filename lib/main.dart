import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:intl/intl_standalone.dart';
import 'package:mood_diary/router/app_pages.dart';
import 'package:mood_diary/router/app_routes.dart';
import 'package:mood_diary/utils/channel.dart';
import 'package:mood_diary/utils/utils.dart';
import 'package:window_manager/window_manager.dart';

Future<void> initSystem() async {
  //获取系统语言
  await findSystemLocale();
  //锁定屏幕方向
  await SystemChrome.setPreferredOrientations(Utils().layoutUtil.getOrientation());
  //初始化pref
  await Utils().prefUtil.initPref();
  //初始化所需目录
  await Utils().fileUtil.initCreateDir();
  //初始化Isar
  await Utils().isarUtil.initIsar();
  //supabase初始化
  //await Utils().supabaseUtil.initSupabase();
  if (Platform.isAndroid) {
    //shiply初始化
    await Utils().updateUtil.initShiply();
    //设置高刷
    await FlutterDisplayMode.setHighRefreshRate();
    //设置状态栏沉浸
    await ViewChannel.setSystemUIVisibility();
  }

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1024, 768),
      minimumSize: Size(512, 768),
      center: true,
      windowButtonVisibility: true,
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
}

String getInitialRoute() {
  var initialRoute = AppRoutes.homePage;
  if (Utils().prefUtil.getValue<bool>('firstStart')!) {
    initialRoute = AppRoutes.startPage;
  }
  if (Utils().prefUtil.getValue<bool>('lock')!) {
    initialRoute = AppRoutes.lockPage;
  }
  return initialRoute;
}

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      Utils().logUtil.printError('Flutter error', error: details.exception, stackTrace: details.stack);
      Utils().noticeUtil.showBug('Flutter error', error: details.exception, stackTrace: details.stack);
    };
    //初始化系统
    await initSystem();
    runApp(GetMaterialApp(
      initialRoute: getInitialRoute(),
      builder: (context, widget) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(Utils().prefUtil.getValue<double>('fontScale')!),
        ),
        child: Platform.isWindows ? DragToMoveArea(child: widget!) : widget!,
      ),
      theme: await Utils().themeUtil.buildTheme(Brightness.light),
      darkTheme: await Utils().themeUtil.buildTheme(Brightness.dark),
      themeMode: ThemeMode.values[Utils().prefUtil.getValue<int>('themeMode')!],
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.cupertino,
      getPages: AppPages.routes,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ));
  }, (error, stack) {
    Utils().logUtil.printWTF('Error', error: error, stackTrace: stack);
    Utils().noticeUtil.showBug('Error', error: error, stackTrace: stack);
  });
}
