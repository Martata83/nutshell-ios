/*
* Copyright (c) 2015, Tidepool Project
*
* This program is free software; you can redistribute it and/or modify it under
* the terms of the associated License, which is identical to the BSD 2-Clause
* License as published by the Open Source Initiative at opensource.org.
*
* This program is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE. See the License for more details.
*
* You should have received a copy of the License along with this program; if
* not, you can obtain one from Tidepool Project at tidepool.org.
*/

import UIKit
import CoreData
import CocoaLumberjack
import HealthKit

var fileLogger: DDFileLogger!

/// Set up health kit configuration singleton, specialized version of HealthKitConfiguration
let appHealthKitConfiguration = NutshellHealthKitConfiguration()

/// AppDelegate deals with app startup, restart, termination:
/// - Switches UI between login and event controllers.
/// - Initializes the UI appearance defaults.
/// - Initializes data model and api connector.

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    static var healthKitUIEnabled = true
    // one shot, true until we go to foreground...
    private var freshLaunch = true
    // one shot, UI should put up dialog letting user know we are in test mode!
    static var testModeNotification = false
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        DDLogVerbose("trace")

        // Default HealthKit UI enable UI to on unless iPad
        // TODO: remove, for v0.8.6.0 release only!
        AppDelegate.healthKitUIEnabled = HKHealthStore.isHealthDataAvailable()
        
        // Override point for customization after application launch.
        UINavigationBar.appearance().barTintColor = Styles.darkPurpleColor
        UINavigationBar.appearance().translucent = false
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: Styles.navTitleBoldFont]
        
        // Initialize database by referencing username. This must be done before using the APIConnector!
        let name = NutDataController.controller().currentUserName
        if !name.isEmpty {
            NSLog("Initializing NutshellDataController, found and set user \(name)")
        }

        // Set up the API connection
        APIConnector.connector().configure()
        
        NSLog("did finish launching")
        return true
        
        // Note: for non-background launches, this will continue in applicationDidBecomeActive...
    }
    
    static var testMode: Bool {
        set(newValue) {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: kTestModeSettingKey)
            NSUserDefaults.standardUserDefaults().synchronize()
            _testMode = nil
        }
        get {
            if _testMode == nil {
                _testMode = NSUserDefaults.standardUserDefaults().boolForKey(kTestModeSettingKey)
            }
            return _testMode!
        }
    }
    static let kTestModeSettingKey = "kTestModeSettingKey"
    static var _testMode: Bool?

    func setupUIForLogin() {
        let sb = UIStoryboard(name: "Login", bundle: nil)
        if let vc = sb.instantiateInitialViewController() {
            self.window?.rootViewController = vc
        }
    }
    
    func logout() {
        APIConnector.connector().logout() {
            self.setupUIForLogin()
        }
    }
    
    func setupUIForLoginSuccess() {
        // Upon login success, switch over to the EventView storyboard flow. This starts with a nav controller, and all other controllers are pushed/popped from that.
        let sb = UIStoryboard(name: "EventView", bundle: nil)
        if let vc = sb.instantiateInitialViewController() {
            self.window?.rootViewController = vc
        }
    }
    
    private var deviceIsLocked = false
    func applicationProtectedDataDidBecomeAvailable(application: UIApplication) {
        DDLogVerbose("Device unlocked!")
        deviceIsLocked = false
    }
    
    func applicationProtectedDataWillBecomeUnavailable(application: UIApplication) {
        DDLogVerbose("Device locked!")
        deviceIsLocked = true
    }
    
    // Support for background fetch
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        NSLog("performFetchWithCompletionHandler")
        
        // if device is locked, bail now because we can't read HealthKit data
        if deviceIsLocked {
            if AppDelegate.testMode {
                self.localNotifyMessage("Nutshell skipping background fetch: device is locked!")
            }
            completionHandler(.Failed)
            return
        }
        
        // next make sure we are logged in and have connectivity
        let api = APIConnector.connector()
        if api.sessionToken == nil {
            NSLog("No token available, user will need to log in!")
            // Use local notifications to test background activity...
            if AppDelegate.testMode {
                self.localNotifyMessage("Nutshell was unable to download items from Tidepool: log in required!")
            }
            completionHandler(.Failed)
            return
        }
        
        if !api.isConnectedToNetwork() {
            NSLog("No network available!")
            // Use local notifications to test background activity...
            if AppDelegate.testMode {
                self.localNotifyMessage("Nutshell was unable to download items from Tidepool: no network available!")
            }
            completionHandler(.Failed)
            return
        }
        // make sure HK interface is configured...
        // TODO: this can kick off a lot of activity! Review...
        // Note: configureHealthKitInterface is somewhat background-aware...
        NutDataController.controller().configureHealthKitInterface()
        // then call it...
        HealthKitDataPusher.sharedInstance.backgroundFetch { (fetchResult) -> Void in
            completionHandler(fetchResult)
        }
    }

    private func localNotifyMessage(msg: String) {
        NSLog("localNotifyMessage: \(msg)")
        let debugMsg = UILocalNotification()
        debugMsg.alertBody = msg
        UIApplication.sharedApplication().presentLocalNotificationNow(debugMsg)
    }
    
    
    func applicationWillResignActive(application: UIApplication) {
        NSLog("Nutshell applicationWillResignActive")
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        NSLog("Nutshell applicationDidEnterBackground")
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        NSLog("Nutshell applicationWillEnterForeground")
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        NSLog("Nutshell applicationDidBecomeActive")
        if freshLaunch {
            freshLaunch = false
            let api = APIConnector.connector()
            if api.sessionToken == nil {
                NSLog("No token available, clear any data in case user did not log out normally")
                api.logout() {
                    self.setupUIForLogin()
                }
                return
            }
            
            if !api.isConnectedToNetwork() {
                setupUIForLogin()
                return
            }
            
            NSLog("AppDelegate: attempting to refresh token...")
            api.refreshToken() { succeeded -> (Void) in
                if succeeded {
                    NutDataController.controller().configureHealthKitInterface()
                    // TODO: only if app is in the foreground?
                    self.setupUIForLoginSuccess()
                } else {
                    NSLog("Refresh token failed, need to log in normally")
                    api.logout() {
                        self.setupUIForLogin()
                    }
                }
            }
        }
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        NutDataController.controller().appWillTerminate()
        NSLog("Nutshell applicationWillTerminate")
    }


}

