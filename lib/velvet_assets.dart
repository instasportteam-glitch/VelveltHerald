import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

const velvetOrigin = 'https://gamedata.velvet-herald.online';
const velvetAssetPaths = <String, String>{
  '/images/herald.png': 'assets/images/herald.png',
  '/images/salon.png': 'assets/images/salon.png',
  '/herald/herald.png': 'assets/herald/herald.png',
  '/herald/herald_body.png': 'assets/herald/herald_body.png',
  '/herald/herald_head.png': 'assets/herald/herald_head.png',
};

String? bundledAssetFor(Uri uri) {
  if (uri.scheme != 'velvet-asset' || uri.host != 'bundle') return null;
  return velvetAssetPaths[uri.path];
}

Future<CustomSchemeResponse?> loadVelvetAsset(WebUri uri) async {
  final path = bundledAssetFor(Uri.parse(uri.toString()));
  if (path == null) return null;
  final bytes = await rootBundle.load(path);
  return CustomSchemeResponse(
    data: bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    contentType: 'image/png',
  );
}

// Installed before site scripts. The existing HTML respects VELVET_ASSET_BASE.
// The observer also handles legacy img paths and later SPA tab updates.
const velvetAssetScript = r'''
(() => {
  if (location.origin !== 'https://gamedata.velvet-herald.online') return;
  window.VELVET_ASSET_BASE = 'velvet-asset://bundle/images/';
  window.VelvetNativeAssets = Object.freeze({
    herald: 'velvet-asset://bundle/images/herald.png',
    salon: 'velvet-asset://bundle/images/salon.png',
    loadingHerald: 'velvet-asset://bundle/herald/herald.png'
  });
  const known = {
    '/assets/images/herald.png':'velvet-asset://bundle/images/herald.png',
    '/assets/images/salon.png':'velvet-asset://bundle/images/salon.png',
    '/assets/herald/herald.png':'velvet-asset://bundle/herald/herald.png',
    '/assets/herald/herald_body.png':'velvet-asset://bundle/herald/herald_body.png',
    '/assets/herald/herald_head.png':'velvet-asset://bundle/herald/herald_head.png'
  };
  function replace(img) {
    const raw = img.getAttribute('src');
    if (!raw || raw.startsWith('velvet-asset:')) return;
    let url;
    try { url = new URL(raw, location.href); } catch (_) { return; }
    if (url.origin !== location.origin) return;
    const target = known[url.pathname];
    if (target) { img.removeAttribute('srcset'); img.setAttribute('src', target); }
  }
  function scan(node) {
    if (node.nodeType !== 1) return;
    if (node.tagName === 'IMG') replace(node);
    node.querySelectorAll('img').forEach(replace);
  }
  new MutationObserver(records => {
    for (const r of records) {
      if (r.type === 'attributes') replace(r.target);
      else r.addedNodes.forEach(scan);
    }
  }).observe(document, {subtree:true, childList:true, attributes:true, attributeFilter:['src']});
  document.addEventListener('DOMContentLoaded', () => scan(document.documentElement), {once:true});
})();
''';
