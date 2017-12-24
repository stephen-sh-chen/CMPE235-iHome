//
//  ViewController.swift
//  iHome
//
//  Created by Sanaz Khosravi on 12/3/17.
//  Copyright © 2017 SpartanMaster. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var control: UIButton!
    
    @IBOutlet weak var report: UIButton!
    @IBOutlet weak var humidty: UIButton!
    @IBAction func controlButton(_ sender: Any) {
        
        self.performSegue(withIdentifier: "controlSe", sender: self)
    }
    
    @IBAction func humTempButton(_ sender: Any) {
        
        self.performSegue(withIdentifier: "humS", sender: self)
    }
    
    @IBAction func reportButton(_ sender: Any) {
        
        self.performSegue(withIdentifier: "thirdButton", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
      
        
    }


}

