import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotibuddy/screens/home_page.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';

class LoginSpoti extends StatefulWidget {
  const LoginSpoti({Key? key}) : super(key: key);

  @override
  _LoginSpotiState createState() => _LoginSpotiState();
}

class _LoginSpotiState extends State<LoginSpoti> {
  String spDcc = "";

  Future<String> getCookie() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final cookieManager = WebviewCookieManager();

    final gotCookies =
        await cookieManager.getCookies('https://open.spotify.com/');
    for (var item in gotCookies) {
      if (item.name.toString() == "sp_dc") {
        debugPrint("SP_DC: " + item.value.toString());
        setState(() {
          spDcc = item.value.toString();
          prefs.setString('sp_dc', item.value.toString());

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (BuildContext context) => MyHomePage(
                spDc: spDcc,
              ),
            ),
          );
        });

        return item.value.toString();
      }
    }

    return "";
  }

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();

    Timer timer = Timer.periodic(const Duration(seconds: 3), (timer) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
          backgroundColor: const Color(0xff121212),
          elevation: 0,
          title: const Text("Login"),
          centerTitle: true,
          foregroundColor: Colors.white),
      body: const WebView(
        initialUrl:
            "https://accounts.spotify.com/en/login?continue=https:%2F%2Fopen.spotify.com%2F",
        javascriptMode: JavascriptMode.unrestricted,
        allowsInlineMediaPlayback: true,
        initialMediaPlaybackPolicy: AutoMediaPlaybackPolicy.always_allow,
        userAgent: "random",
      ),
    );
  }
}
