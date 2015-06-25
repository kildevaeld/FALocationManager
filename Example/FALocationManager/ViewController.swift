//
//  ViewController.swift
//  FALocationManager
//
//  Created by Softshag & Me on 06/22/2015.
//  Copyright (c) 06/22/2015 Softshag & Me. All rights reserved.
//

import UIKit
import FALocationManager

func dispatch_after_delay(delay: NSTimeInterval, queue: dispatch_queue_t, block: dispatch_block_t) {
    let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
    dispatch_after(time, queue, block)
}

class ViewController: UIViewController {
    
    @IBOutlet var label : UILabel?
    var queue = dispatch_queue_create("test", DISPATCH_QUEUE_CONCURRENT)
    @IBAction func onButton(sender:UIButton) {
        let selected : Bool
        if sender.selected {
            self.listener?.unlisten()
            selected = false
        } else {
            self.listener?.listen()
            selected = true
        }
        
        
        
        dispatch_after_delay(5, self.queue) { () -> Void in
            FALocationManager.address(string: "København, Danmark", block: { (error, address) -> Void in
                
                println("\(address)")
            })
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

