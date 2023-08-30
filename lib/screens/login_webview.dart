import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotibuddy/screens/home_page.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import 'package:webview_flutter/webview_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'dart:async';

class LoginSpoti extends StatefulWidget {
  const LoginSpoti({Key? key}) : super(key: key);

  @override
  LoginSpotiState createState() => LoginSpotiState();
}

class LoginSpotiState extends State<LoginSpoti> {
  String spDcc = "";

  Future<String> getCookie() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final cookieManager = WebviewCookieManager();

    final gotCookies =
        await cookieManager.getCookies('https://open.spotify.com/');
    for (var item in gotCookies) {
      if (item.name.toString() == "sp_dc") {
        debugPrint("SP_DC: ${item.value}");
        setState(() {
          spDcc = item.value.toString();
          prefs.setString('sp_dc', item.value.toString());

          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (BuildContext context) => MyHomePage(
                  spDc: spDcc,
                ),
              ),
              ModalRoute.withName('/'));
        });

        return item.value.toString();
      }
    }

    return "";
  }

  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    const PlatformWebViewControllerCreationParams params =
        PlatformWebViewControllerCreationParams();

    WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;

    Timer.periodic(const Duration(seconds: 3), (timer) {
      getCookie();

      if (spDcc.toString().isNotEmpty) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  int pos = 0;
  @override
  Widget build(BuildContext context) {
    _controller.loadRequest(Uri.parse(
        'https://accounts.spotify.com/en/login?continue=https:%2F%2Fopen.spotify.com%2F'));

    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
          backgroundColor: const Color(0xff121212),
          elevation: 0,
          title: const Text("Login"),
          centerTitle: true,
          foregroundColor: Colors.white),
      body: WebViewWidget(
        controller: _controller,
      ),
    );
  }
}
