import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Registering here (not in didFinishLaunchingWithOptions) is what the
    // implicit-engine template's own docs call for — at
    // didFinishLaunchingWithOptions time, window?.rootViewController isn't
    // reliably a FlutterViewController yet, so LiveActivityChannel's method
    // channel handler never got attached and every call from the Dart side
    // failed with MissingPluginException.
    if #available(iOS 16.2, *) {
      LiveActivityChannel.register(with: engineBridge.applicationRegistrar.messenger())
    }
  }
}
