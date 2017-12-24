//
//  ViewController.swift
//  IHome
//
//  Created by Maryam Jafari on 12/18/17.
//  Copyright © 2017 Maryam Jafari. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var iHome: UILabel!
    @IBOutlet weak var ac: UILabel!
    @IBOutlet weak var light: UILabel!
    @IBOutlet weak var fan: UILabel!
    @IBOutlet weak var tv: UILabel!
    @IBOutlet weak var door: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
         let color = UIColor(red:0.76, green:0.34, blue:0.0, alpha:1.0)
        ac.textColor = color
        light.textColor = color
        fan.textColor = color
        tv.textColor = color
        door.textColor = color
        iHome.textColor = color
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

