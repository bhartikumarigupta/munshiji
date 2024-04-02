import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
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
                log('URL: ${request.url}');
                if (request.url.startsWith("whatsapp://send/")) {
                  log('WhatsApp URL detected: ${request.url}');
                  if (await canLaunchUrl(
                      convertWhatsAppLink(request.url) as Uri)) {
                    log('Launching WhatsApp URL: ${convertWhatsAppLink(request.url)}');
                    await launchUrl(convertWhatsAppLink(request.url) as Uri);
                    return NavigationDecision.prevent;
                  }
                }
                if (request.url.startsWith("tel:")) {
                  log('Tel URL detected: ${request.url}');
                  if (await canLaunchUrl(Uri.parse(request.url))) {
                    log('Launching Tel URL: ${request.url}');
                    await launchUrl(request.url as Uri);
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
