import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotibuddy/consumable_store.dart';
import 'package:spotibuddy/screens/ads.dart';
import 'package:spotibuddy/screens/splash.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class MyHomePage extends StatefulWidget {
  final String spDc;

  const MyHomePage({Key? key, required this.spDc}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

String convertToAgo(DateTime input) {
  Duration diff = DateTime.now().difference(input);

  if (diff.inDays >= 1) {
    return diff.inDays.toString() + ' days ago';
  } else if (diff.inHours >= 1) {
    return diff.inHours.toString() + ' hours ago';
  } else if (diff.inMinutes >= 1) {
    return diff.inMinutes.toString() + ' min ago';
  } else if (diff.inSeconds >= 1) {
    return diff.inSeconds.toString() + ' sec ago';
  } else {
    return 'just now';
  }
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController editingController = TextEditingController();
  String searchString = "";
  late BannerAd myBanner;
  BannerAd? _anchoredBanner;

  List<String> consumables = [];

  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;

  launchURLBrowser(String url) async {
    if (await canLaunch(url)) {
      await launch(url,
          forceWebView: true, enableDomStorage: true, enableJavaScript: true);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('sp_dc') ?? "";

    String spDcc = "";

    if (widget.spDc.isNotEmpty) {
      spDcc = widget.spDc;
    } else {
      spDcc = token;
    }

    if (spDcc.isEmpty) {
      _restartDialog();
    }
    debugPrint("Bome:" + spDcc.toString());
    final response = await http.get(
      Uri.parse('https://spotibuddy.metareverse.net/?cookie=' + spDcc),
      headers: {HttpHeaders.authorizationHeader: 'Lxw42HRYaQtgFXZF2'},
    );

    if (response.statusCode == 200) {
      return (jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to get data.');
    }
  }

  Future<void> _restartDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sorry for this notification.'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text(
                    "Spotify can sometimes refresh and reset entries. Therefore, your entry has been invalidated. We're restarting the app for you to log in again, thanks for your understanding."),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                restart();
              },
            ),
          ],
        );
      },
    );
  }

  restart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('sp_dc', "");

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (BuildContext context) => const SplashScreen(),
      ),
    );
  }

  @override
  initState() {
    super.initState();

    final BannerAd banner = BannerAd(
      size: AdSize.banner,
      request: const AdRequest(),
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3753684966275105/6352534282'
          : 'ca-app-pub-3753684966275105/9012194471',
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          setState(() {
            _anchoredBanner = ad as BannerAd?;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
        },
      ),
    );
    banner.load();

    if (consumables.isEmpty) {
      _createInterstitialAd();
    }
  }

  @override
  void dispose() {
    super.dispose();
    try {
      myBanner.dispose();
    } catch (e) {}
    _interstitialAd?.dispose();
  }

  void _createInterstitialAd() {
    InterstitialAd.load(
        adUnitId: Platform.isAndroid
            ? 'ca-app-pub-3753684966275105/3717813846'
            : 'ca-app-pub-3753684966275105/1708419522',
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitialAd = ad;
            _numInterstitialLoadAttempts = 0;
            _interstitialAd!.setImmersiveMode(true);
            //_showInterstitialAd();
            if (consumables.isEmpty) {
              _interstitialAd!.show();
            }
          },
          onAdFailedToLoad: (LoadAdError error) {
            _numInterstitialLoadAttempts += 1;
            _interstitialAd = null;
            if (_numInterstitialLoadAttempts <= 3) {
              _createInterstitialAd();
            }
          },
        ));
  }

  payforAds(BuildContext context, stack) {
    showModalBottomSheet<void>(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25), topRight: Radius.circular(25))),
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xff292929),
        builder: (BuildContext context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: 70,
                height: 5,
                child: Container(
                  decoration: BoxDecoration(
                      color: const Color(0xffcccccc),
                      borderRadius: BorderRadius.circular(50)),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(13),
                child: Center(
                  child: Column(
                    children: const [
                      Text(
                        "An ad-free experience?",
                        style: TextStyle(fontSize: 20),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "We know ads are annoying. You can get away with it for just one cup of coffee fee.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 150,
                child: stack,
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    ConsumableStore.load().then((value) {
      consumables = value;
    });

    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xff121212),
        actions: [
          Platform.isAndroid
              ? consumables.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        Fluttertoast.showToast(
                          msg: "Thanks for your purchase",
                        );
                      },
                      icon: const Icon(
                        Icons.upgrade_outlined,
                        color: Colors.green,
                        size: 32,
                      ))
                  : TextButton.icon(
                      onPressed: () {
                        payforAds(context, const AppPurchase());
                      },
                      icon: Image.asset(
                        "assets/images/no.png",
                        width: 28,
                      ),
                      label: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Text(
                            "Remove Ads",
                            style: TextStyle(color: Colors.white),
                          )))
              : Container()
        ],
      ),
      bottomNavigationBar: consumables.isEmpty
          ? SizedBox(
              height: 60.0,
              child: Column(
                children: [
                  if (_anchoredBanner != null && consumables.isEmpty) ...[
                    Container(
                      color: Colors.green,
                      width: _anchoredBanner!.size.width.toDouble(),
                      height: _anchoredBanner!.size.height.toDouble(),
                      child: AdWidget(ad: _anchoredBanner!),
                    ),
                  ]
                ],
              ),
            )
          : const SizedBox(height: 0, width: 0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 40),
              const Text(
                "Friends Activity",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              /*Text(
                "SPDC:" + widget.spDc.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 20),*/
              SizedBox(
                height: 45,
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchString = value;
                    });
                  },
                  controller: editingController,
                  decoration: InputDecoration(
                    hintText: "Find Friends",
                    hintStyle: const TextStyle(
                      color: Color(0xff8f8f8f),
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    labelStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          width: 2,
                          color: Theme.of(context).colorScheme.secondary),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    filled: true,
                    fillColor: const Color(0xff282828),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xff8f8f8f),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                        onPressed: () async {
                          await launchApp("spotify:home");
                        },
                        child: const Text(
                          "Spotify",
                          maxLines: 1,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5)),
                            onPrimary: Colors.white,
                            primary: const Color(0xff282828))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                        onPressed: () async {
                          await launchApp("spotify:search");
                        },
                        child: const Text(
                          "Add Friend",
                          maxLines: 1,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5)),
                            onPrimary: Colors.white,
                            primary: const Color(0xff282828))),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FutureBuilder(
                  future: fetchData(),
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    var data = [];

                    if (snapshot.hasData) {
                      data = List.from(snapshot.data["friends"].reversed);
                      try {
                        if ((data.length - 1) == -1) {
                          return const Center(
                            child: Text("You don't have any friends. :("),
                          );
                        }
                        return ListView.builder(
                            shrinkWrap: true,
                            primary: false,
                            itemCount: data.length,
                            itemBuilder: (context, index) {
                              if (data[index]['user']['name']
                                  .toString()
                                  .toLowerCase()
                                  .contains(searchString.toLowerCase())) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 0),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 72,
                                        height: 72,
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(100),
                                          child: Image.network(data[index]
                                                  ['track']['imageUrl']
                                              .toString()),
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                if (data[index]['user']
                                                        ['imageUrl'] !=
                                                    null) ...[
                                                  InkWell(
                                                    onTap: () async {
                                                      final url = data[index]
                                                          ['user']['uri'];
                                                      await launchApp(url);
                                                    },
                                                    child: SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(100),
                                                        child: Image.network(
                                                            data[index]['user']
                                                                    ['imageUrl']
                                                                .toString()),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 5),
                                                ],
                                                InkWell(
                                                  onTap: () async {
                                                    final url = data[index]
                                                        ['user']['uri'];
                                                    await launchApp(url);
                                                  },
                                                  child: Text(
                                                    data[index]['user']['name']
                                                        .toString(),
                                                    style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            Color(0xff7e7e7e)),
                                                  ),
                                                ),
                                                Text(
                                                  " • " +
                                                      convertToAgo(DateTime
                                                          .fromMillisecondsSinceEpoch(
                                                              data[index][
                                                                  'timestamp'])),
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Color(0xff7e7e7e)),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Marquee(
                                              pauseDuration: const Duration(
                                                  milliseconds: 1),
                                              backDuration: const Duration(
                                                  milliseconds: 1),
                                              directionMarguee:
                                                  DirectionMarguee.TwoDirection,
                                              autoRepeat: true,
                                              direction: Axis.horizontal,
                                              child: Text(
                                                data[index]['track']['name']
                                                    .toString(),
                                                style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xffeaeaea)),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            InkWell(
                                              onTap: () async {
                                                final url = data[index]['track']
                                                    ['album']['uri'];
                                                await launchApp(url);
                                              },
                                              child: Marquee(
                                                pauseDuration: const Duration(
                                                    milliseconds: 1),
                                                backDuration: const Duration(
                                                    milliseconds: 1),
                                                directionMarguee:
                                                    DirectionMarguee
                                                        .TwoDirection,
                                                autoRepeat: true,
                                                direction: Axis.horizontal,
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.album,
                                                      size: 16,
                                                      color: Color(0xff7e7e7e),
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      data[index]['track']
                                                              ['album']['name']
                                                          .toString(),
                                                      style: const TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Color(
                                                              0xff7e7e7e)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                          onPressed: () async {
                                            final url =
                                                data[index]['track']['uri'];
                                            await launchApp(url);
                                          },
                                          icon: Container(
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                width: 1,
                                                color: Colors.white,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.play_arrow_rounded,
                                              size: 20,
                                              color: Colors.white,
                                              semanticLabel: "Play",
                                            ),
                                          ))
                                    ],
                                  ),
                                );
                              } else {
                                return Container();
                              }
                            });
                      } catch (e) {
                        _restartDialog();
                      }
                    }
                    return const CircularProgressIndicator();
                  }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> launchApp(url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      Fluttertoast.showToast(
        msg: "Spotify is not installed.",
      );
    }
  }
}
