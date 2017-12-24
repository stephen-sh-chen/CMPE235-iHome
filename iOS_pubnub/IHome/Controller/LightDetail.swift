//
//  LightDetail.swift
//  IHome
//
//  Created by Maryam Jafari on 12/18/17.
//  Copyright © 2017 Maryam Jafari. All rights reserved.
//



 
    
    import UIKit
    
    class LightDetail: UIViewController, UITableViewDataSource {
        
        private var cellIdentifier = "TasksCell"
        var listName: String? = "Lights"
        var tasks: [String] = [String]()
        @IBOutlet weak var tableView: UITableView!
        
        override func viewDidLoad() {
            super.viewDidLoad()
             let color = UIColor(red:0.76, green:0.34, blue:0.0, alpha:1.0)
            self.title = listName
            self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor:color]
            self.navigationController?.navigationBar.tintColor = UIColor.gray
            //  tableView.delegate = self as! UITableViewDelegate
            tableView.dataSource = self
            tasks = ListsManager.sharedInstance.tasksForList(withName: listName!)
        }
        
        // MARK: UITableViewDataSource
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return tasks.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? CustomedCell
            if cell == nil {
                cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier) as? CustomedCell
            }
            
            
            let taskName = tasks[indexPath.row]
            cell?.configureCell(lableName: taskName, newStatus : "OFF")
            
            return cell!
        }
        
        func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return true
        }
        
        func tableView(_ tableView: UITableView,
                       commit editingStyle: UITableViewCellEditingStyle,
                       forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                let name = tasks[indexPath.row]
                ListsManager.sharedInstance.finish(task: name)
                self.reloadTasks()
            }
        }
        
        // MARK: IBAction
        
        @IBAction func addButtonClicked(sender: UIBarButtonItem) {
            let alertController = self.alertForAddingItems()
            self.present(alertController, animated: true, completion: nil)
        }
        
        
        // MARK: private
        
        private func alertForAddingItems() -> UIAlertController {
            let alertController =  IHome.Alert(title: "Please provide the light name",
                                                               placeholder: "Task name")
            return addActions(toAlertController: alertController,
                              saveActionHandler: { [unowned self] action in
                                let textField = alertController.textFields![0]
                                if let text = textField.text {
                                    if text != "" {
                                        ListsManager.sharedInstance.add(tasks: [text],
                                                                        toList: self.listName!)
                                        self.reloadTasks()
                                    }
                                }
                                alertController.dismiss(animated: true, completion: nil)
            })
        }
        
        private func reloadTasks() {
            tasks = ListsManager.sharedInstance.tasksForList(withName: listName!)
            self.tableView.reloadData()
        }
        
        
}





