//
//  ViewController.swift
//  IosPJ
//
//  Created by young on 2023/05/30.
//

import UIKit
import AVFAudio

class ViewController: UIViewController, RegistrationObserver, CallObserver {
    private let TAG = "ViewController"
    
    @IBOutlet weak var outbound: UITextField!
    @IBOutlet weak var port: UITextField!
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
    @IBOutlet weak var tvRinging: UIButton!
    @IBOutlet weak var tvReInvite: UIButton!
    @IBOutlet weak var tvBye: UIButton!
    
    @IBOutlet weak var tvMessage: UILabel!
    @IBOutlet weak var etTo: UITextField!
    @IBOutlet weak var etMessage: UITextField!
    @IBOutlet weak var tvSend: UIButton!
    
    private var registered = false
    
    private var manager: CallManager?
    private var delegate: CallDelegate?
    private var tempUUID: UUID?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        requestMicrophonePermission()
        
        manager = CallManager.getInstance()
        delegate = CallDelegate.instance
        
        outbound.placeholder = "address"
        port.placeholder = "port"
        id.placeholder = "id"
        password.placeholder = "password"
        etCounterpart.placeholder = "counterpart"
        etTo.placeholder = "To"
        etMessage.placeholder = "Message"
        
        outbound.addDoneButtonOnKeyboard()
        port.addDoneButtonOnKeyboard()
        id.addDoneButtonOnKeyboard()
        password.addDoneButtonOnKeyboard()
        etCounterpart.addDoneButtonOnKeyboard()
        etTo.addDoneButtonOnKeyboard()
        etMessage.addDoneButtonOnKeyboard()

        password.isSecureTextEntry = true

        outbound.text = Config.ADDRESS
        port.text = Config.PORT
        id.text = Config.ID
        password.text = Config.PASSWORD
        etCounterpart.text = Config.COUNTERPART
        etTo.text = Config.COUNTERPART
        etMessage.text = "Sample Message"
        
        setRegistrationVisibility(registered: manager?.registrationModel?.registered ?? false)
        if (manager!.callModel != nil && !manager!.callModel!.terminated) {
            if (manager!.callModel!.connected) {
                setCallVisibility(state: Config.CONNECTED)
            } else if (manager!.callModel!.incoming) {
                setCallVisibility(state: Config.INCOMING)
            } else if (manager!.callModel!.outgoing) {
                setCallVisibility(state: Config.OUTGOING)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("\(TAG) \(#function)")
        PublisherImpl.instance.add(key: TAG, observer: self as RegistrationObserver)
        PublisherImpl.instance.add(key: TAG, observer: self as CallObserver)
        setRegistrationVisibility(registered: manager?.registrationModel?.registered ?? false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        print("\(TAG) \(#function)")
        PublisherImpl.instance.removeRegistrationObserver(key: TAG)
        PublisherImpl.instance.removeCallObserver(key: TAG)
    }

    @IBAction func startRegistration(_ sender: UIButton) {
        print("startRegistration")
        manager?.startRegistration(address: "\(outbound.text!):\(port.text!)", id: id.text!, pwd: password.text!, type: Config.TRANSPORT)
    }
    @IBAction func stopRegistration(_ sender: UIButton) {
        print("stopRegistration")
        manager?.stopRegistration()
    }
    @IBAction func refreshRegistration(_ sender: UIButton) {
        print("refreshRegistration")
        manager?.networkChanged()
    }
    @IBAction func startCall(_ sender: Any) {
        let callee = "sip:\(etCounterpart.text!)@\(outbound.text!)"
        print("startCall to \(callee)")
        manager?.startCall(counterpart: callee)
        manager?.addCallListener()
        moveToCallController()
    }
    @IBAction func updateCall(_ sender: Any) {
        print("updateCall")
        manager?.updateCall()
    }
    @IBAction func cancelCall(_ sender: Any) {
        print("cancelCall")
        delegate?.cancel()
    }
    @IBAction func answerCall(_ sender: UIButton) {
        print("answerCall")
        delegate?.answer()
    }
    @IBAction func busyCall(_ sender: Any) {
        print("busyCall")
        delegate?.busy()
    }
    @IBAction func declineCall(_ sender: Any) {
        print("declineCall")
        delegate?.decline()
    }
    @IBAction func ringing(_ sender: Any) {
        print("ringing")
        manager?.ringingCall()
    }
    @IBAction func reInvite(_ sender: Any) {
        print("reInvite")
        manager?.networkChanged()
    }
    @IBAction func byeCall(_ sender: Any) {
        print("byeCall")
        delegate?.bye()
    }
    @IBAction func sendMessage(_ sender: Any) {
        print("sendMessage")
        let to = "sip:\(etTo.text!)@\(outbound.text!)"
        manager?.sendMessage(to: to, msg: etMessage.text!)
    }
    
    func onRegistrationSuccess(model: RegistrationModel) {
        print("\(TAG) \(#function)")
        if (!manager!.registrationModel!.registered) {
            setRegistrationVisibility(registered: true)
        }
    }
    
    func onRegistrationFailure(model: RegistrationModel) {
        print("\(TAG) \(#function)")
        if (manager!.registrationModel!.registered) {
            setRegistrationVisibility(registered: false)
        }
    }
    
    func onUnRegistrationSuccess(model: RegistrationModel) {
        print("\(TAG) \(#function)")
        if (manager!.registrationModel!.registered) {
            setRegistrationVisibility(registered: false)
        }
    }
    
    func onUnRegistrationFailure(model: RegistrationModel) {
        print("\(TAG) \(#function)")
    }
    
    func onInstantMessage(model: MessageModel) {
        print("\(TAG) \(#function) message - \(String(describing: model.message))")
        tvMessage.text = "\(String(describing: model.message))"
    }
    
    func onIncomingCall(model: CallModel) {
        print("\(TAG) \(#function)")
        print("\(TAG) callModel is \(model)")
        moveToCallController()
        setCallVisibility(state: Config.INCOMING)
    }
    
    func onOutgoingCall(model: CallModel) {
        print("\(TAG) \(#function)")
        print("\(TAG) callModel is \(model)")
        setCallVisibility(state: Config.OUTGOING)
    }
    
    func onConnected(model: CallModel) {
        print("\(TAG) \(#function)")
        print("\(TAG) callModel is \(model)")
        setCallVisibility(state: Config.CONNECTED)
    }
    
    func onTerminated(model: CallModel) {
        print("\(TAG) \(#function)")
        print("\(TAG) callModel is \(model)")
        setCallVisibility(state: Config.TERMINATED)
    }
    
    func modalCallController() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let callController = storyBoard.instantiateViewController(withIdentifier: "incomingCallVC")
        callController.modalTransitionStyle = .coverVertical
        self.present(callController, animated: true, completion: nil)
    }
    
    func moveToCallController() {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyBoard.instantiateViewController(withIdentifier: "callVC")
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    private func moveToOutgoing() {
        let vcToPresent = self.storyboard!.instantiateViewController(withIdentifier: "callVC") as! CallViewController
        self.present(vcToPresent, animated: true, completion: nil)
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
        
        tvRinging.isHidden = true
        tvReInvite.isHidden = true
        tvBye.isHidden = true
        
        tvMessage.isHidden = !registered
        etTo.isHidden = !registered
        etMessage.isHidden = !registered
        tvSend.isHidden = !registered
    }
    
    private func setCallVisibility(state: Int) {
        switch (state) {
            case Config.OUTGOING:
                tvStartCall.isHidden = true
                tvUpdateCall.isHidden = false
                tvCancelCall.isHidden = false
                tvAnswer.isHidden = true
                tvBusy.isHidden = true
                tvDecline.isHidden = true
                tvRinging.isHidden = true
                tvReInvite.isHidden = true
                tvBye.isHidden = true
                tvCall.text = "Call - Outgoing"
                break
            case Config.INCOMING:
                tvStartCall.isHidden = true
                tvUpdateCall.isHidden = true
                tvCancelCall.isHidden = true
                tvAnswer.isHidden = false
                tvBusy.isHidden = false
                tvDecline.isHidden = false
                tvRinging.isHidden = false
                tvReInvite.isHidden = true
                tvBye.isHidden = true
                tvCall.text = "Call - Incoming"
                break
            case Config.CONNECTED:
                tvStartCall.isHidden = true
                tvUpdateCall.isHidden = true
                tvCancelCall.isHidden = true
                tvAnswer.isHidden = true
                tvBusy.isHidden = true
                tvDecline.isHidden = true
                tvRinging.isHidden = true
                tvReInvite.isHidden = false
                tvBye.isHidden = false
                tvCall.text = "Call - Connected"
                break
            case Config.TERMINATED:
                tvStartCall.isHidden = false
                tvUpdateCall.isHidden = true
                tvCancelCall.isHidden = true
                tvAnswer.isHidden = true
                tvBusy.isHidden = true
                tvDecline.isHidden = true
                tvRinging.isHidden = true
                tvReInvite.isHidden = true
                tvBye.isHidden = true
                tvCall.text = "Call - Terminated"
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

extension UITextField {
    @IBInspectable var doneAccessory: Bool {
        get {
            print("doneAccessory get")
            return self.doneAccessory
        }
        set (hasDone) {
            print("doneAccessory set \(hasDone)")
            if hasDone{
                addDoneButtonOnKeyboard()
            }
        }
    }
    
    func addDoneButtonOnKeyboard() {
        print("addDoneButtonOnKeyboard")
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonAction))
        
        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction() {
        print("doneButtonAction")
        self.resignFirstResponder()
    }
}
