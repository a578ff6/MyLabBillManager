//
//  BillListTableViewController.swift
//  MyLabBillManager
//
//  Created by 曹家瑋 on 2023/11/25.
//

import UIKit
import CoreData

/// 自定義的數據源，支持滑動操作
private class SwipeableDataSource: UITableViewDiffableDataSource<Int, Bill> {
    // 允許每個行都可以進行編輯（例如滑動刪除）
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
}


class BillListTableViewController: UITableViewController {

    fileprivate var dataSource: SwipeableDataSource!
    
    // 用於存放 重用id 和 segue id
    struct PropertyKeys {
        static let billCell = "BillCell"
        static let billDetail = "billDetail"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = editButtonItem
        
        // 初始化並配置數據源
        dataSource = SwipeableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, bill in
            let cell = tableView.dequeueReusableCell(withIdentifier: PropertyKeys.billCell, for: indexPath)
            
            let bill = Database.shared.bills[indexPath.row]
            
            // 配置cell的內容
            var content = cell.defaultContentConfiguration()
            content.text = bill.payee
            content.secondaryText = String(format: "%@ - Due: %@", arguments: [(bill.amount ?? 0).formatted(.currency(code: "usd")), bill.formattedDueDate])
            cell.contentConfiguration = content
            
            return cell
        })
        
        // 設置tableView的數據源
        tableView.dataSource = dataSource
        // 加載初始數據
        updateSnapshot()
        
        // 註冊通知，用於賬單更新時刷新列表
        NotificationCenter.default.addObserver(forName: Database.billUpdatedNotification, object: nil, queue: nil) { _ in
            self.updateSnapshot()
        }
    
    }
    
    /// 更新數據快照，用於數據變更時更新tableView
    func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Bill>()
        snapshot.appendSections([0])
        snapshot.appendItems(Database.shared.bills, toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: true, completion: nil)
    }
    
    // 配置滑動刪除動作
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (contextualAction, view, completionHandler) in
            guard let bill = self.dataSource.itemIdentifier(for: indexPath) else { return }
            Database.shared.delete(bill: bill)  // 從數據庫刪除賬單
            Database.shared.save()              // 保存更改
            self.updateSnapshot()               // 更新列表
            completionHandler(true)
        }
        deleteAction.image = UIImage(systemName: "trash.fill")
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    // 實現accessory按鈕的點擊事件，進行頁面跳轉
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        performSegue(withIdentifier: PropertyKeys.billDetail, sender: indexPath)
    }
    
    // 配置segue，傳遞數據到下一個頁面
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let indexpath = sender as? IndexPath,
           segue.identifier == PropertyKeys.billDetail {
            let navigationController = segue.destination as? UINavigationController
            let billDetailTableViewController = navigationController?.viewControllers.first as? BillDetailTableViewController
            billDetailTableViewController?.bill = Database.shared.bills[indexpath.row]
        }
    }
    
    // 從賬單詳情頁面返回時的動作
    @IBAction func unwindFromBillDetail(segue: UIStoryboardSegue) { }

}
