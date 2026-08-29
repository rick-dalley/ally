import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let watchConnectivityBridge = WatchConnectivityBridge()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      watchConnectivityBridge.start(messenger: controller.binaryMessenger)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
