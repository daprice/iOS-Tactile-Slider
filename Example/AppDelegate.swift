//
//  AppDelegate.swift
//  TactileSlider
//
//  Created by daprice on 01/22/2019.
//  Copyright (c) 2019 daprice. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

      let storyboard = UIStoryboard(name: "Main", bundle: nil)
      self.window = UIWindow(frame: UIScreen.main.bounds)
      self.window?.rootViewController = storyboard.instantiateViewController(withIdentifier: "MainViewController")
      self.window?.makeKeyAndVisible()
      return true
   }
}
