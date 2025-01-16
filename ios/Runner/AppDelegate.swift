import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let viewController = window?.rootViewController {
            let swipeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
            swipeGesture.edges = .left
            viewController.view.addGestureRecognizer(swipeGesture)
        }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  @objc func handleSwipe(_ gesture: UIScreenEdgePanGestureRecognizer) {
        // Non fare nulla, questo blocca il gesto
  }
}
