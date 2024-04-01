import 'dart:async';

import 'package:billing_probe_webview/webview.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MySplashScreen extends StatefulWidget {
  @override
  _MySplashScreenState createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen> {
  String splashLogo = '';
  String currentAddress = '';
  Position? currentPosition;

  @override
  void initState() {
    super.initState();
    getCurrentPosition();
  }

  Future<bool> handleLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return false;
      }
    }
    if (permission == LocationPermission.denied) {
      return false;
    }
    return true;
  }

  Future<void> getCurrentPosition() async {
    final hasPermission = await handleLocationPermission();
    if (!hasPermission) {
      print("Permission Denied");
      return;
    }

    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) async {
      currentPosition = position;
      print(currentPosition!.latitude);
      await _getAddressFromLatLng(position);
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(
            currentPosition!.latitude, currentPosition!.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];

      if (place.country == 'India' ||
          place.country == 'IN' ||
          place.country == 'in') {
        setState(() {
          splashLogo =
              'https://billingprobe.com/assets/image/logo/MunshiJi-Billing-Software-Light.png';
        });
      } else {
        setState(() {
          splashLogo =
              'https://billingprobe.com/assets/image/logo/BillingProbe-Billing-Software-Light.png';
        });
      }

      Timer(Duration(seconds: 15), () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MyWebView()),
        );
      });
    }).catchError((e) {
      print(e);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: splashLogo != null && splashLogo!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: splashLogo!,
                  progressIndicatorBuilder: (context, url, downloadProgress) =>
                      CircularProgressIndicator(
                          value: downloadProgress.progress),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                )
              : CircularProgressIndicator(),
        ));
  }
}
