# Velvet Herald native shell

The initial page is https://gamedata.velvet-herald.online.
The supplied layered-character loader is bundled and displayed until the main
page finishes loading. HTTP/network failures and a 40-second timeout show a
retry screen. Retry creates a fresh WebView. All interface text is English.
The loader uses the system Georgia font, with no runtime font downloads.
Reduced Motion disables its animation ticker.

## Local assets for the remote website

The iOS WebView registers `velvet-asset://bundle/` and serves only explicit
bundled PNG paths. Before the site's JavaScript runs it sets:

```js
window.VELVET_ASSET_BASE = 'velvet-asset://bundle/images/';
// available keys: herald, salon, loadingHerald
window.VelvetNativeAssets.herald
```

The existing Velvet Herald HTML already uses VELVET_ASSET_BASE. Legacy
same-origin img src paths `/assets/images/herald.png` and `salon.png` are
also replaced automatically, including dynamically added images.
Loader layers are available at `velvet-asset://bundle/herald/`.
The website still requires internet; only its bundled imagery is local.
If the web server sets a Content-Security-Policy, its img-src directive must
allow `velvet-asset:`. No security headers are bypassed by the native shell.
Only the known image paths are mapped; new files must be added to
velvetAssetPaths and the JS mapping in lib/velvet_assets.dart.

External web/mail/phone links open through the operating system. The shell
keeps HTTPS verification enabled and does not add ATS exceptions.

## iOS

AppIcon.appiconset includes all sizes in its Contents.json, including the
opaque 1024px marketing icon. The native launch screen uses the same dark
background. Display name: Velvet Herald. Bundle ID and signing are preserved.
Camera/photo purpose strings describe optional profile and chronicle photos.

Run `flutter pub get`, `flutter analyze`, `flutter test`, then
`flutter build ios --no-codesign` or run on a selected simulator/device.
Before release verify photo selection, share/download behavior, CSP support,
and the custom image scheme in the remote page on a real iOS device.

Requested settings are enabled, including inspection and autoplay. MixedContentMode applies to Android; iOS ATS remains unchanged. Same-site popup URLs open in the current view; external URLs and HTTP(S) downloads open in the system browser. Blob/data downloads need a native export bridge. Blank popup windows are not supported. The app icon has no crown. Native build verification was blocked by Xcode Swift Package Manager sandbox-exec restrictions; build from Xcode before device testing.
