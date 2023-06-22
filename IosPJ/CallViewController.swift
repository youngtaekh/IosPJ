//
//  OutgoingViewController.swift
//  IosPJ
//
//  Created by young on 2023/06/08.
//

import UIKit

class CallViewController: UIViewController, CallObserver {
    private let TAG = "CallViewController"
    
    @IBOutlet weak var tvTitle: UILabel!
    @IBOutlet weak var tvCounterpart: UILabel!
    
    @IBOutlet weak var tvDecline: UIButton!
    @IBOutlet weak var tvAnswer: UIButton!
    
    @IBOutlet weak var tvEnd: UIButton!
    
    @IBOutlet weak var tvMute: UIButton!
    @IBOutlet weak var tvSpeaker: UIButton!
    private var manager: CallManager? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("\(TAG) \(#function)")
        
        manager = CallManager.getInstance()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("\(TAG) \(#function)")
        PublisherImpl.instance.add(key: TAG, observer: self as CallObserver)
        
        let model = manager!.callModel!
        tvCounterpart.text = model.counterpart
        
        if (model.terminated) {
            self.navigationController?.popViewController(animated: false)
        } else if (model.connected) {
            tvTitle.text = "Calling..."
            tvDecline.isHidden = true
            tvAnswer.isHidden = true
            tvEnd.isHidden = false
            tvEnd.setTitle("Bye", for: .normal)
            tvMute.isHidden = false
            tvSpeaker.isHidden = false
        } else if (model.outgoing) {
            tvTitle.text = "Outgoing Call"
            tvDecline.isHidden = true
            tvAnswer.isHidden = true
            tvEnd.isHidden = false
            tvEnd.setTitle("Cancel", for: .normal)
            tvMute.isHidden = false
            tvSpeaker.isHidden = false
        } else if (model.incoming) {
            tvTitle.text = "Incoming Call"
            tvDecline.isHidden = false
            tvAnswer.isHidden = false
            tvEnd.isHidden = true
            tvMute.isHidden = true
            tvSpeaker.isHidden = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("\(TAG) \(#function)")
        PublisherImpl.instance.removeCallObserver(key: TAG)
    }
    
    @IBAction func declineCall(_ sender: Any) {
        CallDelegate.instance.decline()
    }
    @IBAction func answerCall(_ sender: Any) {
        CallDelegate.instance.answer()
    }
    @IBAction func endCall(_ sender: Any) {
        if (manager!.callModel!.connected) {
            CallDelegate.instance.bye()
        } else {
            CallDelegate.instance.cancel()
        }
    }
    @IBAction func mute(_ sender: Any) {
        manager!.callModel!.mute = !manager!.callModel!.mute
        manager!.mute(mute: manager!.callModel!.mute)
        if (manager!.callModel!.mute) {
            tvMute.setTitle("Mute Off", for: .normal)
        } else {
            tvMute.setTitle("Mute On", for: .normal)
        }
    }
    @IBAction func speaker(_ sender: Any) {
        manager!.callModel!.speaker = !manager!.callModel!.speaker
        if (manager!.callModel!.speaker) {
            manager!.useSpeaker()
            tvSpeaker.setTitle("Speaker Off", for: .normal)
        } else {
            manager!.useEarpiece()
            tvSpeaker.setTitle("Speaker On", for: .normal)
        }
    }
    func onOutgoingCall(model: CallModel) {}
    
    func onConnected(model: CallModel) {
        print("\(TAG) \(#function)")
        tvTitle.text = "Calling..."
        tvDecline.isHidden = true
        tvAnswer.isHidden = true
        tvEnd.isHidden = false
        tvEnd.setTitle("Hangup", for: .normal)
        tvMute.isHidden = false
        tvSpeaker.isHidden = false
    }
    
    func onTerminated(model: CallModel) {
        print("\(TAG) \(#function)")
        self.navigationController?.popViewController(animated: false)
    }
}
