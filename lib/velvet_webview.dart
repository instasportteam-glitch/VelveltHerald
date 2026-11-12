import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import 'velvet_assets.dart';
import 'velvet_loading_screen.dart';

class VelvetWebView extends StatefulWidget {
  const VelvetWebView({super.key});
  @override
  State<VelvetWebView> createState() => _VelvetWebViewState();
}

class _VelvetWebViewState extends State<VelvetWebView> {
  Timer? _timeout;
  bool _loading = true;
  String? _error;
  int _progress = 0;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _armTimeout();
  }

  void _armTimeout() {
    _timeout?.cancel();
    _timeout = Timer(const Duration(seconds: 40), () {
      _fail(
        'This is taking longer than expected. Check your connection and try again.',
      );
    });
  }

  void _fail(String message) {
    if (!mounted) return;
    _timeout?.cancel();
    setState(() {
      _error = message;
      _loading = false;
    });
  }

  void _retry() {
    // Recreate the platform view, so late events from an old load cannot
    // dismiss the new loader or replace its error state.
    setState(() {
      _generation++;
      _loading = true;
      _error = null;
      _progress = 0;
    });
    _armTimeout();
  }

  Future<void> _openExternal(Uri uri) async {
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
          mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open this link.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open this link.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final generation = _generation;
    bool current() => mounted && generation == _generation;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            InAppWebView(
              key: ValueKey(_generation),
              initialUrlRequest: URLRequest(url: WebUri(velvetOrigin)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                transparentBackground: true,
                resourceCustomSchemes: ['velvet-asset'],
                useShouldOverrideUrlLoading: true,
                allowsBackForwardNavigationGestures: true,
                mediaPlaybackRequiresUserGesture: false,
                disableDefaultErrorPage: true,
                allowsInlineMediaPlayback: true,
                allowsPictureInPictureMediaPlayback: true,
                useOnDownloadStart: true,
                javaScriptCanOpenWindowsAutomatically: true,
                supportMultipleWindows: true,
                thirdPartyCookiesEnabled: true,
                sharedCookiesEnabled: true,
                domStorageEnabled: true,
                databaseEnabled: true,
                cacheEnabled: true,
                mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                isInspectable: true,
              ),
              initialUserScripts: UnmodifiableListView([
                UserScript(
                  source: velvetAssetScript,
                  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                  forMainFrameOnly: true,
                ),
              ]),
              onCreateWindow: (controller, action) async {
                final uri = Uri.tryParse(action.request.url?.toString() ?? '');
                if (uri == null) return false;
                if (uri.scheme == 'https' &&
                    uri.host == 'gamedata.velvet-herald.online') {
                  await controller.loadUrl(
                    urlRequest: URLRequest(url: WebUri(uri.toString())),
                  );
                } else if ([
                  'https',
                  'http',
                  'mailto',
                  'tel',
                ].contains(uri.scheme)) {
                  await _openExternal(uri);
                }
                return false;
              },
              onDownloadStartRequest: (controller, request) async {
                final uri = Uri.tryParse(request.url.toString());
                if (uri != null && ['https', 'http'].contains(uri.scheme)) {
                  await _openExternal(uri);
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'This download needs a direct HTTPS file link.',
                      ),
                    ),
                  );
                }
              },
              onLoadResourceWithCustomScheme: (controller, request) async {
                try {
                  return await loadVelvetAsset(request.url);
                } catch (_) {
                  return null;
                }
              },
              shouldOverrideUrlLoading: (controller, action) async {
                final uri = Uri.tryParse(action.request.url?.toString() ?? '');
                if (uri == null) return NavigationActionPolicy.CANCEL;
                if (uri.scheme == 'https' &&
                    uri.host == 'gamedata.velvet-herald.online') {
                  return NavigationActionPolicy.ALLOW;
                }
                if (uri.scheme == 'about' || uri.scheme == 'velvet-asset') {
                  return NavigationActionPolicy.ALLOW;
                }
                if (action.isForMainFrame &&
                    ['https', 'http', 'mailto', 'tel'].contains(uri.scheme)) {
                  await _openExternal(uri);
                }
                return NavigationActionPolicy.CANCEL;
              },
              onLoadStart: (controller, url) {
                if (!current()) return;
                setState(() {
                  _loading = true;
                  _progress = 0;
                });
                _armTimeout();
              },
              onProgressChanged: (controller, progress) {
                if (current()) setState(() => _progress = progress);
              },
              onLoadStop: (controller, url) {
                if (!current() || _error != null) return;
                _timeout?.cancel();
                setState(() => _loading = false);
              },
              onReceivedError: (controller, request, error) {
                if (current() && request.isForMainFrame == true) {
                  _fail(
                    'Your residence could not be reached. Check your internet connection and try again.',
                  );
                }
              },
              onReceivedHttpError: (controller, request, response) {
                if (current() && request.isForMainFrame == true) {
                  _fail(
                    'The residence is temporarily unavailable (HTTP ${response.statusCode}). Please try again.',
                  );
                }
              },
              onWebContentProcessDidTerminate: (controller) {
                if (current()) {
                  _fail(
                    'The page was interrupted. Please reload your residence.',
                  );
                }
              },
            ),
            if (_loading && _error == null)
              Positioned.fill(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const VelvetLoadingScreen(),
                    Positioned(
                      left: 24,
                      right: 24,
                      top: 18,
                      child: Semantics(
                        label: 'Page loading: $_progress percent',
                        child: LinearProgressIndicator(
                          value: _progress / 100,
                          color: const Color(0xFFE9C37A),
                          backgroundColor: const Color(0x335B3543),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_error != null)
              ColoredBox(
                color: const Color(0xFF1B0D14),
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/branding/app_icon.png',
                            width: 100,
                            height: 100,
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Your residence awaits',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 28,
                              color: Color(0xFFE9C37A),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
