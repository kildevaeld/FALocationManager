//
//  ViewController.swift
//  FALocationManager
//
//  Created by Softshag & Me on 06/22/2015.
//  Copyright (c) 06/22/2015 Softshag & Me. All rights reserved.
//

import UIKit
import FALocationManager
class ViewController: UIViewController {
    
    @IBOutlet var label : UILabel?
    
    @IBAction func onButton(sender:UIButton) {
        let selected : Bool
        if sender.selected {
            self.listener?.unlisten()
            selected = false
        } else {
            self.listener?.listen()
            selected = true
        }
        sender.selected = selected
    }
    
    var listener : LocationListener?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.listener = FALocationManager.listen({ (error, location) -> Void in
            if error != nil {
                println("could not find location \(error)")
            } else if location != nil {
                self.label!.text = location!.description
                let predicate = NSPredicate.boundingBox(location!.coordinate, distance: 2000)
                
                println("found location \(location)")
            }
        })
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

