//
//  Bill+Extras.swift
//  MyLabBillManager
//
//  Created by 曹家瑋 on 2023/11/26.
//

import Foundation
import UserNotifications

extension Bill {
    
    /// 設定通知類別的ID。
    static let notificationCategoryID = "ReminderNotifications"
    
    /// 表示賬單是否設定了提醒。如果 `remindDate` 不為 nil，則表示設定了提醒。
    var hasReminder: Bool {
        return (remindDate != nil)
    }
    
    /// 表示賬單是否已支付。如果 `paidDate` 不為 nil，則表示賬單已支付。
    var isPaid: Bool {
        return (paidDate != nil)
    }
    
    /// 返回格式化的到期日期字符串。如果 `dueDate` 為 nil，則返回空字符串。
    var formattedDueDate: String {
        let dateString: String
        
        if let dueDate = self.dueDate {
            dateString = dueDate.formatted(date: .numeric, time: .omitted)
        } else {
            dateString = ""
        }
        
        return dateString
    }
    
    /// 移除現有的提醒。
    mutating func removeReminder() {
        if let id = notificationID {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
            // 清除相關的提醒資訊。
            notificationID = nil
            remindDate = nil
        }
    }
    
    /// 檢查並請求通知授權，如果需要的話。
    private func authorizeIfNeeded(completion: @escaping (Bool) -> ()) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { (settings) in
            switch settings.authorizationStatus {
            case .notDetermined:
                // 尚未確定，請求授權。
                notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    completion(granted)
                }
            case .denied:
                completion(false)                   // 已被拒絕，不再請求。
            case .authorized, .provisional:
                completion(true)                    // 已授權。
            case .ephemeral:
                completion(false)                   // App Clip 專用，暫時不授權。
            @unknown default:
                completion(false)                   // 未知狀態，預設不授權。
            }
        }
    }
    
    /// 排程一個新的提醒。
    mutating func scheduleReminder(on date: Date, completion: @escaping (Bill) -> ()) {
        var updatedBill = self
        
        // 移除現有提醒，避免重複。
        updatedBill.removeReminder()
        
        // 確認是否有發送通知的授權。
        authorizeIfNeeded { granted in
            // 如果沒有授權，立即完成並返回。
            guard granted else {
                DispatchQueue.main.async {
                    completion(updatedBill)
                }
                
                return
            }
            
            /// 創建新的通知內容。
            let content = UNMutableNotificationContent()
            content.title = "Bill Reminder"
            // 格式化通知內容，包括帳單金額、收款人和到期日。
            content.body = String(format:  "%@ due to %@ on %@", arguments: [(updatedBill.amount ?? 0).formatted(.currency(code: "usd")), (updatedBill.payee ?? ""), updatedBill.formattedDueDate])
            content.categoryIdentifier = Bill.notificationCategoryID
            content.sound = UNNotificationSound.default
            
            /// 設定提醒的時間。以觸發通知。
            let triggerDateComponents = Calendar.current.dateComponents([.second, .minute, .hour, .day, .month, .year], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: false)
            
            /// 生成唯一的通知識別碼。
            let notificationID = UUID().uuidString
            /// 創建並設定通知請求。
            let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
            
            // 添加通知到通知中心。
            UNUserNotificationCenter.current().add(request) { (error) in
                DispatchQueue.main.async {
                    // 處理可能的錯誤，並更新帳單資訊。
                    if let error = error {
                        print(error.localizedDescription)
                    } else {
                        // 更新帳單的通知ID和提醒日期。
                        updatedBill.notificationID = notificationID
                        updatedBill.remindDate = date
                    }
                    
                    // 完成並回傳更新過的帳單。
                    DispatchQueue.main.async {
                        completion(updatedBill)
                    }
                }
            }
        }
    }
}

