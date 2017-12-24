//
//  Alert.swift
//  IHome
//
//  Created by Maryam Jafari on 12/18/17.
//  Copyright © 2017 Maryam Jafari. All rights reserved.
//

import Foundation
import UIKit

func Alert(title: String,
           placeholder: String)
    -> UIAlertController {
        
        let alertController = UIAlertController(title: title,
                                                message: nil,
                                                preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = placeholder
        }
        
        return alertController
}

func addActions(toAlertController alertController: UIAlertController,
                saveActionHandler: @escaping ((UIAlertAction) -> Swift.Void))
    -> UIAlertController {
        
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: saveActionHandler)
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel,
                                         handler: { action in
                                            alertController.dismiss(animated: true, completion: nil)
        })
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        return alertController
}
