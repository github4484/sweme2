//
//  ViewController.swift
//  Sweme2
//
//  Copyright (c) 2014 knj4484@gmail.com All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    let evaluator = Evaluator()
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var codeTextView: UITextView!
    @IBAction func button() {
        let expression = evaluator.parse(codeTextView.text)
        let evaluated = evaluator.eval(expression!)
        textView.text = evaluated.toString()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //let url: NSURL = NSURL(string: "http://www.yahoo.com")!
        let path = NSBundle.mainBundle().pathForResource("a", ofType: "html")
        let requestURL = NSURL(string: path!)
        let request = NSURLRequest(URL: requestURL!)
        webView.loadRequest(request)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

