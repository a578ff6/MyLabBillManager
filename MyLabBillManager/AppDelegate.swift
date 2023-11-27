//
//  AppDelegate.swift
//  MyLabBillManager
//
//  Created by 曹家瑋 on 2023/11/25.
//

import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // 用於通知動作的ID。
    private let remindActionID = "RemindAction"
    private let markAsPaidActionID = "MarkAsPaidAction"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        ///「稍後提醒」動作，無特殊選項。
        let remindAction = UNNotificationAction(identifier: remindActionID, title: "Remind me later", options: [])
        ///「標記為已付款」動作，需要認證。
        let markAsPaidAction = UNNotificationAction(identifier: markAsPaidActionID, title: "Mark as paid", options: [.authenticationRequired])
        
        /// 創建通知類別，結合上述動作。
        let category = UNNotificationCategory(identifier: Bill.notificationCategoryID, actions: [remindAction, markAsPaidAction], intentIdentifiers: [], options: [])
        
        UNUserNotificationCenter.current().setNotificationCategories([category])                // 設置通知中心使用的通知類別。
        UNUserNotificationCenter.current().delegate = self                                      // 設定當前對象為通知中心的代理。
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    /// 當收到通知回應時被呼叫的函數
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        /// 從回應中獲取通知的唯一id
        let id = response.notification.request.identifier
        
        /// 使用 id 從資料庫中找到相應的賬單，如果找不到，就直接返回
        guard var bill = Database.shared.getBill(notificationID: id) else { completionHandler(); return }
        
        // 根據用戶的操作（如「稍後提醒」或「標記為已付」）處理通知
        switch response.actionIdentifier {
        case remindActionID:
            // 設置一個新的提醒時間，為當前時間後一小時
            let newRemindDate = Date().addingTimeInterval(60 * 60)
            
            // 計劃新的提醒，並在提醒設定後更新賬單
            bill.scheduleReminder(on: newRemindDate) { (updatedBill) in
                Database.shared.updateAndSave(updatedBill)
            }
            
        case markAsPaidActionID:
            // 將賬單的付款日期設為當前時間
            bill.paidDate = Date()
            Database.shared.updateAndSave(bill)
            
        default:
            break
        }
        
        // 呼叫完成處理程序
        completionHandler()
    }
    
    // 當通知在app前台展示時被呼叫的函數
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 設置通知展示的方式（列表、橫幅和聲音）
        completionHandler([.list, .banner, .sound])
    }
}

