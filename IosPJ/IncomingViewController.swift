//
//  IncomingViewController.swift
//  IosPJ
//
//  Created by young on 2023/06/08.
//

import UIKit

class IncomingViewController: UIViewController {
    
    @IBOutlet weak var tvCounterpart: UILabel!
    
    private var manager: CallManager? = nil
    var counterpart: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("IncomingViewController")
        manager = CallManager.getInstance()
        tvCounterpart.text = manager?.callModel?.counterpart
        
    }
    @IBAction func declineCall(_ sender: Any) {
        CallDelegate.instance.decline()
    }
    @IBAction func answerCall(_ sender: Any) {
        CallDelegate.instance.answer()
    }
}
