import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_plugin_openwhatsapp/flutter_plugin_openwhatsapp.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MyWebView extends StatefulWidget {
  @override
  _MyWebViewState createState() => _MyWebViewState();
}

class _MyWebViewState extends State<MyWebView> {
  bool? _isLoadingPage;
  @override
  void initState() {
    super.initState();
    _isLoadingPage = true;
  }

  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  String convertWhatsAppLink(String originalLink) {
    Uri originalUri = Uri.parse(originalLink);

    Uri convertedUri = Uri(
      scheme: 'https',
      host: 'api.whatsapp.com',
      path: '/send/',
      queryParameters: originalUri.queryParameters,
    );

    return convertedUri.toString();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        WebViewController webViewController = await _controller.future;
        if (await webViewController.canGoBack()) {
          webViewController.goBack();
          return false;
        } else {
          bool exitApp = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Confirmation'),
              content: Text('Do you want to exit the App?'),
              actions: <Widget>[
                InkWell(
                  onTap: () => Navigator.of(context).pop(false),
                  child: Text('No'),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(true),
                  child: Text('Yes'),
                ),
              ],
            ),
          );

          return exitApp ?? false;
        }
      },
      child: SafeArea(
        child: Stack(
          children: <Widget>[
            WebView(
              initialUrl: 'https://m.billingprobe.com/',
              javascriptMode: JavascriptMode.unrestricted,
              onWebViewCreated: (WebViewController webViewController) {
                _controller.complete(webViewController);
              },
              navigationDelegate: (NavigationRequest request) async {
                if (request.url.startsWith("whatsapp://send/")) {
                  Uri uri = Uri.parse(request.url);

                  String phoneNumber = uri.queryParameters['phone'] ?? "";
                  String text = uri.queryParameters['text'] ?? "";

                  String decodedText = Uri.decodeComponent(text);

                  final flutterPlugin = FlutterPluginOpenwhatsapp();
                  var platform = defaultTargetPlatform;
                  if (platform == TargetPlatform.android) {
                    String? result = await flutterPlugin.openWhatsApp(
                      phoneNumber: '$phoneNumber',
                      text: '$decodedText',
                    );
                    debugPrint('>>>: $result');
                  }
                  return NavigationDecision.prevent;
                } else if (request.url.startsWith("tel:")) {
                  Uri telUri = Uri.parse(request.url);
                  log('Tel URL detected: ${telUri.toString()}');
                  if (await canLaunchUrl(telUri)) {
                    log('Launching Tel URL: ${telUri.toString()}');
                    await launchUrl(telUri);
                    return NavigationDecision.prevent;
                  }
                }
                return NavigationDecision.navigate;
              },
              onPageStarted: (String url) {
                print('Page started loading: $url');
              },
              onPageFinished: (String url) {
                setState(() {
                  _isLoadingPage = false;
                });
                print('Page finished loading: $url');
              },
              gestureNavigationEnabled: true,
            ),
            _isLoadingPage!
                ? Center(child: CircularProgressIndicator())
                : Container(),
          ],
        ),
      ),
    );
  }
}
