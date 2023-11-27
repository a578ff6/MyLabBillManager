//
//  Bill.swift
//  MyLabBillManager
//
//  Created by 曹家瑋 on 2023/11/25.
//

import Foundation

/// 賬單
struct Bill: Codable {
    /// 賬單的唯一識別碼。
    let id: UUID
    /// 賬單的金額。
    var amount: Double?
    /// 賬單的到期日期。
    var dueDate: Date?
    /// 通知（區分每個帳單的提醒）
    var notificationID: String?
    /// 賬單的支付日期。
    var paidDate: Date?
    /// 收款人。
    var payee: String?
    /// 用戶設定的提醒日期。可選，用於提醒用戶支付賬單。
    var remindDate: Date?
    
    /// 初始化一個新的賬單實例。
    /// - Parameter id: 賬單的唯一識別碼。如果未提供，將自動生成。
    init(id: UUID = UUID()) {
        self.id = id
    }
}


extension Bill: Hashable {
//    static func ==(_ lhs: Bill, _ rhs: Bill) -> Bool {
//        return lhs.id == rhs.id
//    }
//
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//    }
}
