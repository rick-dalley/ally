import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let watchConnectivityBridge = WatchConnectivityBridge()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Under the UIScene lifecycle (required from iOS 27) the window belongs to the scene
  // and doesn't exist yet at launch, so plugins and the watch channel are wired up here,
  // once the engine is ready, rather than through window?.rootViewController.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    watchConnectivityBridge.start(messenger: engineBridge.applicationRegistrar.messenger())
  }
}
