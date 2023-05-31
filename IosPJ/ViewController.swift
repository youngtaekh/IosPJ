//
//  ViewController.swift
//  IosPJ
//
//  Created by young on 2023/05/30.
//

import UIKit
import AVFAudio

class ViewController: UIViewController {
    @IBOutlet weak var outbound: UITextField!
    @IBOutlet weak var id: UITextField!
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var tvStart: UIButton!
    @IBOutlet weak var tvStop: UIButton!
    @IBOutlet weak var tvRefresh: UIButton!
    
    @IBOutlet weak var tvCall: UILabel!
    @IBOutlet weak var etCounterpart: UITextField!
    @IBOutlet weak var tvStartCall: UIButton!
    @IBOutlet weak var tvUpdateCall: UIButton!
    @IBOutlet weak var tvCancelCall: UIButton!
    @IBOutlet weak var tvAnswer: UIButton!
    @IBOutlet weak var tvBusy: UIButton!
    @IBOutlet weak var tvDecline: UIButton!
    @IBOutlet weak var tvReInvite: UIButton!
    @IBOutlet weak var tvBye: UIButton!
    
    private let ADDRESS = "sip.linphone.org"
    private let PORT = "5061"
    private let ID = "everareen"
    private let PASSWORD = "lidue638"
    private let COUNTERPART = "youngtaek.people"
    
    private let OUTGOING = 0
    private let INCOMING = 1
    private let CONNECTED = 2
    private let TERMINATED = 3

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        requestMicrophonePermission()
        
        outbound.placeholder = "address:port"
        id.placeholder = "id"
        password.placeholder = "password"
        etCounterpart.placeholder = "counterpart"

        password.isSecureTextEntry = true

        outbound.text = "sip:\(ADDRESS):\(PORT)"
        id.text = ID
        password.text = PASSWORD
        etCounterpart.text = COUNTERPART
        
        setRegistrationVisibility(registered: false)
    }
    @IBAction func startRegistration(_ sender: UIButton) {
        print("startRegistration")
        print("\(CPPWrapper().registerStateInfoWrapper())")
        setRegistrationVisibility(registered: true)
        Register().test()
    }
    @IBAction func stopRegistration(_ sender: UIButton) {
        print("stopRegistration")
        setRegistrationVisibility(registered: false)
    }
    @IBAction func refreshRegistration(_ sender: UIButton) {
        print("refreshRegistration")
        setCallVisibility(state: INCOMING)
    }
    @IBAction func startCall(_ sender: Any) {
        print("startCall")
        setCallVisibility(state: OUTGOING)
    }
    @IBAction func updateCall(_ sender: Any) {
        print("updateCall")
    }
    @IBAction func cancelCall(_ sender: Any) {
        print("cancelCall")
        setCallVisibility(state: TERMINATED)
    }
    @IBAction func answerCall(_ sender: UIButton) {
        print("answerCall")
        setCallVisibility(state: CONNECTED)
    }
    @IBAction func busyCall(_ sender: Any) {
        print("busyCall")
        setCallVisibility(state: TERMINATED)
    }
    @IBAction func declineCall(_ sender: Any) {
        print("declineCall")
        setCallVisibility(state: TERMINATED)
    }
    @IBAction func reInvite(_ sender: Any) {
        print("reInvite")
    }
    @IBAction func byeCall(_ sender: Any) {
        print("byeCall")
        setCallVisibility(state: TERMINATED)
    }
    
    private func setRegistrationVisibility(registered: Bool) {
        tvStart.isHidden = registered
        tvStop.isHidden = !registered
        tvRefresh.isHidden = !registered
        
        tvCall.isHidden = !registered
        etCounterpart.isHidden = !registered
        
        tvStartCall.isHidden = !registered
        tvUpdateCall.isHidden = true
        tvCancelCall.isHidden = true
        
        tvAnswer.isHidden = true
        tvBusy.isHidden = true
        tvDecline.isHidden = true
        
        tvReInvite.isHidden = true
        tvBye.isHidden = true
    }
    
    private func setCallVisibility(state: Int) {
        switch (state) {
            case OUTGOING:
                tvStartCall.isHidden = true
                tvUpdateCall.isHidden = false
                tvCancelCall.isHidden = false
                tvAnswer.isHidden = true
                tvBusy.isHidden = true
                tvDecline.isHidden = true
                tvReInvite.isHidden = true
                tvBye.isHidden = true
                break
            case INCOMING:
                tvStartCall.isHidden = true
                tvUpdateCall.isHidden = true
                tvCancelCall.isHidden = true
                tvAnswer.isHidden = false
                tvBusy.isHidden = false
                tvDecline.isHidden = false
                tvReInvite.isHidden = true
                tvBye.isHidden = true
                break
            case CONNECTED:
                tvStartCall.isHidden = true
                tvUpdateCall.isHidden = true
                tvCancelCall.isHidden = true
                tvAnswer.isHidden = true
                tvBusy.isHidden = true
                tvDecline.isHidden = true
                tvReInvite.isHidden = false
                tvBye.isHidden = false
                break
            case TERMINATED:
                tvStartCall.isHidden = false
                tvUpdateCall.isHidden = true
                tvCancelCall.isHidden = true
                tvAnswer.isHidden = true
                tvBusy.isHidden = true
                tvDecline.isHidden = true
                tvReInvite.isHidden = true
                tvBye.isHidden = true
                break
            default:
                print("default")
        }
    }
    
    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
            if granted {
                print("Mic: 권한 허용")
            } else {
                print("Mic: 권한 거부")
            }
        })
    }
}
