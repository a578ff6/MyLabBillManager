//
//  Database.swift
//  MyLabBillManager
//
//  Created by 曹家瑋 on 2023/11/26.
//

import Foundation
import UIKit

class Database {
    
    /// 通知名稱，當賬單更新時會使用此通知。
    static let billUpdatedNotification = NSNotification.Name("com.apple.BillManager.billUpdated")
    
    /// 單例模式，全局只有一個 Database 實例。
    static let shared = Database()
    
    /// 從文件中讀取賬單數據
    private func loadBills() -> [UUID:Bill]? {
        var bills = [UUID:Bill]()
        
        do {
            let storageDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let storageURL = storageDirectory.appendingPathComponent("bills").appendingPathExtension("json")
            let fileData = try Data(contentsOf: storageURL)
            let billsArray = try JSONDecoder().decode([Bill].self, from: fileData)
            bills = billsArray.reduce(into: bills, { partial, bill in
                partial[bill.id] = bill
            })
        } catch {
            return nil
        }
        
        return bills
    }
    
    /// 將賬單數據保存到文件中
    private func saveBills(_ bills: [UUID:Bill]) {
        do {
            let storageDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let storageURL = storageDirectory.appendingPathComponent("bills").appendingPathExtension("json")
            let fileDate = try JSONEncoder().encode(Array(bills.values))
            try fileDate.write(to: storageURL)
        } catch {
            fatalError("There was a problem saving bills. Error: \(error)")
        }
    }
    
    /// 用於內部存儲賬單的可選字典。
    private var _billsOptional: [UUID:Bill]?
    
    /// 確保在訪問賬單時讀取或更新內部賬單字典。
    private var _billsLookup: [UUID:Bill] {
        get {
            // 需要時讀取賬單。
            if _billsOptional == nil {
                _billsOptional = loadBills() ?? [:]
            }
            
            return _billsOptional!
        }
        
        set {
            _billsOptional = newValue
        }
    }
    
    /// 提供外部訪問賬單的方法，返回一個賬單陣列。
    var bills: [Bill] {
        get {
            return Array(_billsLookup.values.sorted(by: <))
        }
    }
    
    /// 創建新的賬單並加入到賬單列表中。
    func addBill() -> Bill {
        let bill = Bill()
        _billsLookup[bill.id] = bill
        return bill
    }
    
    /// 更新並保存賬單，並發送更新通知。
    func updateAndSave(_ bill: Bill) {
        _billsLookup[bill.id] = bill
        save()
        NotificationCenter.default.post(name: Self.billUpdatedNotification, object: nil)
    }
    
    /// 保存所有賬單。
    func save() {
        saveBills(_billsLookup)
    }
    
    /// 刪除指定的賬單。
    func delete(bill: Bill) {
        _billsLookup[bill.id] = nil
    }
    
    /// 根據ID獲取特定賬單。
    func getBill(withID id: UUID) -> Bill? {
        return _billsLookup[id]
    }
    
    /// 根據通知ID獲取相應的賬單。
    /// - Parameter notificationID: 用於查找賬單的通知ID。
    /// - Returns: 如果找到對應的賬單則返回該賬單，否則返回nil。
    func getBill(notificationID: String) -> Bill? {
        
        // 使用 first(where:) 在 `_billsLookup` 字典中查找第一個匹配指定通知ID的鍵值對。
        // $0.value.notificationID == notificationID 檢查每個賬單的通知ID是否與給定的ID匹配。
        guard let keyValue = _billsLookup.first(where: { $0.value.notificationID == notificationID }) else { return nil }
        
        return keyValue.value 
    }
}

// MARK: - 擴展 Bill 結構，使其可以比較。
extension Bill: Comparable {
    
    // 定義比較規則，首先比較到期日，然後比較金額。
    static func < (lhs: Bill, rhs: Bill) -> Bool {
        
        // 用於比較金額。
        func compareAmounts(_ l: Bill, _ r: Bill) -> Bool {
            switch (l.amount, r.amount) {
            case (let l?, let r?):
                return l > r
            case (nil, .some(_)):
                return false
            case (.some(_), nil):
                return true
            case (nil, nil):
                return lhs.id.uuidString < rhs.id.uuidString
            }
        }
        
        // 比較到期日。
        switch (lhs.dueDate, rhs.dueDate) {
        case (let l? , let r?):
            let result = Calendar.current.compare(l, to: r, toGranularity: .day)
            if result == .orderedSame {
                return compareAmounts(lhs, rhs)
            } else {
                return result == .orderedAscending
            }
        case (nil, .some(_)):
            return false
        case (.some(_), nil):
            return true
        case (nil, nil):
            return compareAmounts(lhs, rhs)
        }
    }
}
