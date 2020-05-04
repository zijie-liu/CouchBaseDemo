//
//  ViewController.swift
//  JieCouchBase
//
//  Created by Peter on 4/7/20.
//  Copyright © 2020 Peter. All rights reserved.
//

import UIKit
import CouchbaseLiteSwift

class ViewController: UIViewController {
    
    @IBOutlet weak var jieTableView: UITableView!
    @IBOutlet weak var textField: UITextField!
    
    var stringArray = [String]()
    
    let database: Database = {
        do {
            return try Database(name: "mydb")
        } catch {
            fatalError("Error opening database")
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getData()
    }
    
    @IBAction func tappedOnAdd(_ sender: UIButton) {
        guard !(textField.text?.isEmpty ?? true) else { return }
        saveData()
        getData()
    }
    
    func saveData() {
        do {
            let mutableDoc = MutableDocument()
                .setString(textField.text, forKey: "input")
                .setString("MyString", forKey: "type")
            try database.saveDocument(mutableDoc)
        } catch {
            fatalError("Error saving document")
        }
    }
    
    func getData() {
        do {
            let query = QueryBuilder
                .select(SelectResult.property("input"))
                .from(DataSource.database(database))
                .where(Expression.property("type").equalTo(Expression.string("MyString")))
            
            let items  = try query.execute()
            
            
            let newArr = items.map { (item) -> String in
                return item.string(forKey: "input") ?? ""
            }
            
            print(newArr)
            
            stringArray = newArr
            self.jieTableView.reloadData()
            
        } catch  {
            fatalError("Error running the query")
        }
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stringArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = stringArray[indexPath.row]
        return cell
    }
    
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let action = UIContextualAction(style: .destructive, title: "Delete") {[unowned self] (action, view, handler) in
            self.deleteRow(at: indexPath.row)
            
            tableView.performBatchUpdates({
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }, completion: nil)
            
            handler(true)
        }
        let configuration = UISwipeActionsConfiguration(actions: [action])
        return configuration
    }
    
    func deleteRow(at index: Int) {
        let element = stringArray.remove(at: index)
        
        do {
            let query = QueryBuilder
                .select(SelectResult.expression(Meta.id))
                .from(DataSource.database(database))
                .where(Expression.property("type").equalTo(Expression.string("MyString")).and(Expression.property("input").equalTo(Expression.string(element))))
                
            for result in try query.execute() {
                
                if let dict = result.toDictionary() as? [String: String],
                    let id = dict["id"],
                    let doc = database.document(withID: id) {

                    try database.deleteDocument(doc)
                }
            }

        } catch {
            fatalError("Error delete document")
        }
        
        
    }
}
