import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hypebard/page/HomePage.dart';
import 'package:hypebard/utils/Utils.dart';
import 'package:lottie/lottie.dart';

import '../utils/Config.dart';
// The SplashPage class, extends StatefulWidget, used to display the splash screen animation when the app starts.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  _SplashPageState createState() => _SplashPageState();
}

// _SplashPageState class, the state class of SplashPage, manages the state of the splash screen.
class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  // The LottieBuilder object for playing the splash screen animation.
  late LottieBuilder _splashLottie;
  // The animation controller, used to control the playback of the Lottie animation.
  late AnimationController _lottieController;

  // Indicates whether the app opening animation should be displayed.
  bool _showAppOpenAnimate = true;
  // Indicates whether the Lottie animation file (JSON) has been loaded.
  bool _isAnimateFileLoaded = false;

  // A timer object used to handle delayed tasks.
  Timer? _timer;

  // The initialization method, called after the widget is first inserted into the tree.
  @override
  void initState() {
    super.initState();

    // Initialize the Lottie animation.
    _lottieInit();
  }

  // The initialization logic for the Lottie animation.
  void _lottieInit() {
    // Create an AnimationController with a duration of 3 seconds.
    _lottieController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    // Add a status listener to the animation controller to handle actions after the animation completes.
    _lottieController.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        // When the animation completes, stop the animation controller, update the state to hide the animation, and navigate to the HomePage.
        _lottieController.stop();
        _showAppOpenAnimate = false;
        Utils.pushReplacement(context, const HomePage());
      }
    });
    // Initialize the LottieBuilder with the animation file path, set the animation to play once, and specify the animation controller.
    _splashLottie = Lottie.asset(
      'images/splash.json',
      repeat: false,
      animate: true,
      width: double.maxFinite,
      height: double.maxFinite,
      controller: _lottieController,
      onLoaded: (composition) {
        // When the animation file is loaded, update the state to indicate that the file is loaded, start the animation, and set its duration.
        _isAnimateFileLoaded = true;
        _lottieController.forward(from: 0);
        _lottieController.duration = composition.duration;
        // Update the widget tree to reflect the changes in state.
        setState(() {});
      },
    );
  }

  // Build method, returns the widget tree for the current state.
  @override
  Widget build(BuildContext context) {
    // Call the renderContent method to determine the content to display.
    return Scaffold(body: renderContent());
  }

  // Method to determine the content to display on the screen.
  Widget renderContent() {
    // If the animation should not be displayed, return an empty Container.
    if (!_showAppOpenAnimate) {
      return Container();
    }
    // Otherwise, return a Stack widget containing the background color and the splash animation.
    return Stack(
      children: [
        Container(
          color: const Color(0xFFF6F1F1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Display the splash animation, taking up a certain proportion of the screen height.
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.3,
                child: _splashLottie,
              ),
              // If the animation file is loaded, display the app name.
              if (_isAnimateFileLoaded)
                Text(
                  Config.appName,
                  softWrap: true,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 50,
                    height: 28 / 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              // If the animation file is not loaded, add some spacing to maintain layout consistency.
              if (!_isAnimateFileLoaded) const SizedBox(height: 28),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ],
    );
  }

  // Cleanup method, called when the widget is removed from the tree and will never be inserted again.
  @override
  void dispose() {
    // Dispose of the animation controller to release resources.
    _lottieController.dispose();

    // If a timer exists, cancel it to avoid memory leaks.
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
    }

    super.dispose();
  }
}
