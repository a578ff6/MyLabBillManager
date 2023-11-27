//
//  BillDetailTableViewController.swift
//  MyLabBillManager
//
//  Created by 曹家瑋 on 2023/11/25.
//

import UIKit

class BillDetailTableViewController: UITableViewController {

    // 設置界面元素：收款人、金額、到期日、到期日選擇器
    @IBOutlet weak var payeeTextField: UITextField!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var dueDatePicker: UIDatePicker!
    
    // 設置提醒狀態、開關和提醒選擇器
    @IBOutlet weak var remindStatusLabel: UILabel!
    @IBOutlet weak var remindSwitch: UISwitch!
    @IBOutlet weak var remindDatePicker: UIDatePicker!
    
    // 設置支付狀態、開關和支付日期標籤
    @IBOutlet weak var paidStatusLabel: UILabel!
    @IBOutlet weak var paidSwitch: UISwitch!
    @IBOutlet weak var paidDateLabel: UILabel!
    
    //選擇器高度和對應的索引路徑
    private let datePickerHeight = CGFloat(216)
    private let dueDateCellIndexPath = IndexPath(row: 2, section: 0)
    private let remindDateCellIndexPath = IndexPath(row: 0, section: 1)

    // 日期選擇器顯示狀態
    var isDueDatePickerShown: Bool = false {
        didSet {
            dueDatePicker.isHidden = !isDueDatePickerShown
        }
    }
    
    var isRemindDatePickerShown: Bool = false {
        didSet {
            remindDatePicker.isHidden = !isRemindDatePickerShown
        }
    }
    
    /// 單據資訊
    var bill: Bill?
    /// 支付日期
    var paidDate: Date?

    override func viewDidLoad() {
        super.viewDidLoad()
        // 設定點擊背景隱藏鍵盤
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGestureRecognizer.numberOfTouchesRequired = 1
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGestureRecognizer)
        // 設定金額輸入欄位為小數鍵盤
        amountTextField.keyboardType = .decimalPad
        // 初始化支付日期標籤
        paidDateLabel.text = ""
        
        // 設定默認的到期日期和更新UI
        dueDatePicker.date = Calendar.current.startOfDay(for: Date()).addingTimeInterval(86399)
        updateDueDateUI()
        
        // 若已有帳單資訊，則進行編輯，否則為新增帳單
        if let bill = bill {
            payeeTextField.text = bill.payee
            
            amountTextField.text = String(format: "%@", arguments: [(bill.amount ?? 0).formatted(.number.precision(.fractionLength(2)))])
            // 設定到期日期
            if let dueDate = bill.dueDate {
                dueDatePicker.date = dueDate
            }
            
            updateDueDateUI()
            
            // 設定提醒開關和日期
            remindSwitch.isOn = bill.hasReminder
            remindDatePicker.date = bill.remindDate ?? Date()
            updateRemindUI()
            
            // 設定支付開關和日期
            paidSwitch.isOn = bill.isPaid
            paidDate = bill.paidDate
            updatePaymentUI()
            // 隱藏左上角的取消按鈕
            navigationItem.leftBarButtonItem = nil
        } else {
            title = "Add Bill"
            // 顯示左上角的取消按鈕
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
        }
    }
    
    // MARK: - Table View Delegate
    
    // 處理表格視圖的行點擊事件
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch (indexPath.section, indexPath.row) {
        // 點擊到期日期行時的操作
        case (dueDateCellIndexPath.section, dueDateCellIndexPath.row):
            updateDueDateUI()
            
            if isDueDatePickerShown {
                isDueDatePickerShown = false
            } else if isRemindDatePickerShown {
                isRemindDatePickerShown = false
                isDueDatePickerShown = true
            } else {
                isDueDatePickerShown = true
            }
            // 更新視圖的高度
            tableView.beginUpdates()
            tableView.endUpdates()
            
        // 點擊提醒日期行時的操作
        case (remindDateCellIndexPath.section, remindDateCellIndexPath.row):
            if isRemindDatePickerShown {
                isRemindDatePickerShown = false
            } else if isDueDatePickerShown {
                isDueDatePickerShown = false
                isRemindDatePickerShown = true
            } else {
                isRemindDatePickerShown = true
            }
            // 更新視圖的高度
            tableView.beginUpdates()
            tableView.endUpdates()
            
        default:
            break
        }
    }
    
    // 設定表格行的高度
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch (indexPath.section, indexPath.row) {
        case (dueDateCellIndexPath.section, dueDateCellIndexPath.row + 1):
            if isDueDatePickerShown {
                return datePickerHeight
            } else {
                return 0
            }
            
        case (remindDateCellIndexPath.section, remindDateCellIndexPath.row + 1):
            if isRemindDatePickerShown {
                return datePickerHeight
            } else {
                return 0
            }
            
        default:
            return 44
        }
    }
    
    // MARK: - Navigation
    // 在轉換到另一個視圖控制器之前準備資料的過程。
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        /// 從現有的bill實例獲取資料，如果不存在則創建一個新的。
        var bill = self.bill ?? Database.shared.addBill()
        
        // 將表單中的數據賦值給bill實例。
        bill.payee = payeeTextField.text
        bill.amount =  Double(amountTextField.text ?? "0") ?? 0.00
        bill.dueDate = dueDatePicker.date
        bill.paidDate = paidDate
        
        // 檢查提醒開關是否開啟。
        if remindSwitch.isOn {
            // 如果開啟，則安排一個提醒。
            bill.scheduleReminder(on: remindDatePicker.date) { (updatedBill) in
                if updatedBill.notificationID == nil {
                    // 如果未成功，顯示一個授權提醒。
                    self.presentNeedAuthorizationAlert()
                }
                // 更新資料庫中的資料。
                Database.shared.updateAndSave(updatedBill)
            }
        } else {
            // 如果提醒開關關閉，則移除任何現有提醒。
            bill.removeReminder()
            // 並更新資料庫中的資料。
            Database.shared.updateAndSave(bill)
        }
    }

    // MARK: - Actions
    // 切換提醒開關時的操作
    @IBAction func remindSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            isDueDatePickerShown = false
            isRemindDatePickerShown = true
        } else {
            isRemindDatePickerShown = false
        }
        
        tableView.beginUpdates()
        tableView.endUpdates()
        updateRemindUI()
    }
    
    // 切換支付開關時的操作
    @IBAction func paymentSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            paidDate = Date()
        } else {
            paidDate = nil
        }
        updatePaymentUI()
    }
    
    // 控制截止日期選擇器
    @IBAction func dueDatePickerValueChanged(_ sender: UIDatePicker) {
        updateDueDateUI()
    }
    
    // 控制提醒日期選擇器
    @IBAction func remindDatePickerValueChanged(_ sender: UIDatePicker) {
        updateRemindUI()
    }
    
    
    // MARK: - Helper Methods
    /// 更新到期日期的UI
    func updateDueDateUI() {
        dueDateLabel.text = dueDatePicker.date.formatted(date: .numeric, time: .omitted)
        remindDatePicker.maximumDate = dueDatePicker.date
    }
    
    /// 更新提醒的UI
    func updateRemindUI() {
        if remindSwitch.isOn {
            remindStatusLabel.text = remindDatePicker.date.formatted(date: .numeric, time: .shortened)
        } else {
            remindStatusLabel.text = "No"
        }
    }
    
    /// 更新支付的UI
    func updatePaymentUI() {
        if paidSwitch.isOn {
            paidStatusLabel.text = "Yes"
            paidDateLabel.text = Date().formatted(date: .abbreviated, time: .omitted)
        } else {
            paidStatusLabel.text = "No"
            paidDateLabel.text = ""
        }
    }
    
    /// 顯示警告
    func presentNeedAuthorizationAlert() {
        let alert = UIAlertController(title: "Authorization Needed", message: "We can't set reminders for you without notification permissions. Please go to the iOS Settings app and grant us notification permissions if you wish to make use of reminders.", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    // 點擊取消按鈕時的操作
    @objc func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    // 隱藏鍵盤的方法
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
}


// MARK: - extension UITextFieldDelegate

extension BillDetailTableViewController: UITextFieldDelegate {
    
    // 用於控制文字欄位的文字變更行為
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        // 檢查當前正在編輯的是不是金額的文字欄位
        if textField == amountTextField {
            // 獲取當前文字欄位的文字，如果為 nil 則使用空字串
            let text = (textField.text ?? "") as NSString
            // 根據用戶輸入或刪除的內容，生成新的文字內容
            let newText = text.replacingCharacters(in: range, with: string)
            
            // 嘗試將新的文字內容轉換成 Double，以檢查是否為有效的數字格式
            if let _ = Double(newText) {
                return true                             // 如果可以轉換成數字，則允許改變
            }
            return newText.isEmpty                     // 如果新的文字內容是空的，也允許改變（允許刪除操作）
        } else {
            return true                                // 對於非金額欄位，直接允許改變
        }
    }
}
