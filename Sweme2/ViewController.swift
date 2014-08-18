//
//  ViewController.swift
//  Sweme2
//
//  Created by YOSHIHASHI Kenji on 8/17/14.
//  Copyright (c) 2014 mannan. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    let evaluator = Evaluator()
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var textView: UITextView!
    @IBAction func button() {
        let expression = evaluator.parse(textField.text)
        let evaluated = evaluator.eval(expression!)
        textView.text = evaluated.toString()
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

