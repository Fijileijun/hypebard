import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sp_util/sp_util.dart';
import 'package:url_launcher/url_launcher.dart';

class Utils {
  static Future<SharedPreferences> prefs = SharedPreferences.getInstance();

  static Utils get instance => _getInstance();
  static Utils? _instance;

  static Utils _getInstance() {
    _instance ??= Utils();
    return _instance!;
  }

  /// 页面跳转工具函数，使用 MaterialPageRoute 实现页面跳转效果。
  ///
  /// @param context BuildContext 对象，用于访问当前 Widget 的构建上下文。
  /// @param widget 需要跳转到的目标页面 Widget。
  static jumpPage(BuildContext context, Widget widget) {
    // 创建 MaterialPageRoute，用于实现页面跳转的动画效果。
    PageRoute builder = MaterialPageRoute(builder: (context) {
      // 返回目标页面 Widget，跳转后将显示此 Widget。
      return widget;
    });

    // 使用 Navigator 推送新页面，实现页面跳转。
    Navigator.push(context, builder);
  }


  /// 在导航栈中以替换的方式推送新页面。
  ///
  /// 此方法使用PageRouteBuilder构建一个PageRoute，并通过Navigator.pushReplacement方法
  /// 将当前页面替换为新页面。transitionDuration设置为0毫秒，意味着没有动画效果，
  /// 直接进行页面替换操作。
  ///
  /// @param context BuildContext，用于获取当前Widget的上下文。
  /// @param widget 需要推送展示的Widget。
  static pushReplacement(BuildContext context, Widget widget) {
    // 创建PageRouteBuilder，配置页面替换的路由。
    PageRoute builder = PageRouteBuilder(
      // 设置页面切换的持续时间为0毫秒，即无动画效果。
      transitionDuration: const Duration(milliseconds: 0),
      // 定义页面构建器，无论动画状态如何，都返回widget。
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation secondaryAnimation) {
        return widget;
      },
    );
    // 执行页面替换操作。
    Navigator.pushReplacement(context, builder);
  }


  /// Save whether to install for the first time
  static void saveInstall() async {
    await SpUtil.getInstance();
    SpUtil.putBool("install_key", true);
  }

  /// Is it the first time to install
  static Future<bool> getInstall() async {
    await SpUtil.getInstance();
    bool? isInstall = SpUtil.getBool("install_key");
    if (isInstall == null) {
      return false;
    }
    return isInstall;
  }

  static launchURL(
    Uri url, {
    LaunchMode mode = LaunchMode.externalNonBrowserApplication,
    Function? onLaunchFail,
  }) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: mode,
      );
    } else {
      if (onLaunchFail != null) {
        onLaunchFail();
      }
      throw 'Could not launch $url';
    }
  }
}
