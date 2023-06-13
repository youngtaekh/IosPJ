//
//  IncomingViewController.swift
//  IosPJ
//
//  Created by young on 2023/06/08.
//

import UIKit

class IncomingViewController: UIViewController {
    
    @IBOutlet weak var tvTitle: UILabel!
    var counterpart: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("IncomingViewController")
        tvTitle.text = counterpart
        
        PJManager().addCallListener(onCallStateListener)
    }
}
