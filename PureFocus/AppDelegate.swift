//
//  AppDelegate.swift
//  PureFocus
//
//  Created by Ryan Dines on 8/18/17.
//  Copyright © 2017 Ryan Dines. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var appState: AppState!
    
    // TO DO:  ADD SAVE/LOAD CODE FROMM PERSITENT STORE
    
    // Eventually move location manager here.  First piece of code that relaunches for faster recovery

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Initialize if nil after application launch.
        if appState == nil{
            // foreground
            appState = AppState(internalAppState: .foreground, singleAppModeState: .unlocked)
        }else{
            appState.internalAppState = .foreground
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        if appState == nil{
            // foreground
            appState.internalAppState = .background
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        appState.internalAppState = .background
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        appState.internalAppState = .foreground
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        // returns from phone call
        appState.internalAppState = .foreground
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        appState.internalAppState = .terminated
    }
}

