//
//  AppDelegate.swift
//  DemoCallKit
//
//  Created by T.Minh on 7/5/21.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var skywayAPIKey: String = "d43ce8f6-820d-49e1-a7ac-bb2d850922a2"
    var skywayDomain: String = "localhost"

    var backgroundTaskID = UIBackgroundTaskIdentifier.invalid
    var timer: Timer?
    
    static let shared: AppDelegate = {
        guard let shared = UIApplication.shared.delegate as? AppDelegate else { fatalError()}
        return shared
    }()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(rootViewController: HomeViewController())
        window?.makeKeyAndVisible()
        return true
    }
}

extension AppDelegate {
    func startBackgroundTask() {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { timer in
            self.stopBackgroundTask()
        }
    }

    func stopBackgroundTask() {
        if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = UIBackgroundTaskIdentifier.invalid
        }
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
    }
}
