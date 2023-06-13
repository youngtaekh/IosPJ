/*
 * Copyright (C) 2012-2012 Teluu Inc. (http://www.teluu.com)
 * Contributed by Emre Tufekci (github.com/emretufekci)
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include "CustomPJSUA2.hpp"
#include <list>

using namespace pj;

// Listen swift code via function pointers
void (*registrationPtr)(bool, int) = 0;
void (*incomingCallPtr)() = 0;
void (*callStatusListenerPtr)(int) = 0;

/**
 Dispatch queue to manage ios thread serially or concurrently on app's main thread
 for more information please visit:
 https://developer.apple.com/documentation/dispatch/dispatchqueue
 */
dispatch_queue_t queue;

//Getter & Setter function
std::string callerId;
bool registerState = false;

void setCallerId(std::string callerIdStr){
    std::cout << "CustomPJSUA2.setCallerId" << std::endl;
    callerId = callerIdStr;
}

std::string getCallerId(){
    std::cout << "CustomPJSUA2.getCallerId" << std::endl;
    return callerId;
}

void setRegisterState(bool registerStateBool){
    std::cout << "CustomPJSUA2.setRegisterState" << std::endl;
    registerState = registerStateBool;
}

bool getRegisterState(){
    std::cout << "CustomPJSUA2.getRegisterState" << std::endl;
    return registerState;
}


//Call object to manage call operations.
Call *myCall = NULL;


// Subclass to extend the Call and get notifications etc.
class MyCall : public Call
{
public:
    MyCall(Account &acc, int call_id = PJSUA_INVALID_ID) : Call(acc, call_id) {
        std::cout << "MyCall.constructor" << std::endl;
    }
    ~MyCall(){
        std::cout << "MyCall.destructor" << std::endl;
    }
    
    // Notification when call's state has changed.
    virtual void onCallState(OnCallStateParam &prm) {
        std::cout << "MyCall.onCallState" << std::endl;
        CallInfo ci = getInfo();
        if (ci.state == PJSIP_INV_STATE_DISCONNECTED) {
            callStatusListenerPtr(0);
            
            /* Delete the call */
            delete myCall;
            myCall = NULL;
        }
        if (ci.state == PJSIP_INV_STATE_CONFIRMED) {
            callStatusListenerPtr(1);
        }
        
        setCallerId(ci.remoteUri);
        
        //Notify caller ID:
        PJSua2 pjsua2;
        pjsua2.incomingCallInfo();
        
    }
    
    // Notification when call's media state has changed.
    virtual void onCallMediaState(OnCallMediaStateParam &prm) {
        std::cout << "MyCall.onCallMediaState" << std::endl;
        CallInfo ci = getInfo();
        // Iterate all the call medias
        for (unsigned i = 0; i < ci.media.size(); i++) {
            if (ci.media[i].type==PJMEDIA_TYPE_AUDIO && getMedia(i)) {
                AudioMedia *aud_med = (AudioMedia *)getMedia(i);
                
                // Connect the call audio media to sound device
                AudDevManager& mgr = Endpoint::instance().audDevManager();
                aud_med->startTransmit(mgr.getPlaybackDevMedia());
                mgr.getCaptureDevMedia().startTransmit(*aud_med);
            }
        }
    }
};


// Subclass to extend the Account and get notifications etc.
class MyAccount : public Account {
public:
    MyAccount() {
        std::cout << "MyAccount.constructor" << std::endl;
    }
    ~MyAccount() {
        std::cout << "MyAccount.destructor" << std::endl;
        // Invoke shutdown() first..
        shutdown();
        // ..before deleting any member objects.
    }
    
    
    // This is getting for register status!
    virtual void onRegState(OnRegStateParam &prm);
    
    // This is getting for incoming call (We can either answer or hangup the incoming call)
    virtual void onIncomingCall(OnIncomingCallParam &iprm);
};


//Creating objects
Endpoint *ep;
MyAccount *acc;

void MyAccount::onRegState(OnRegStateParam &prm) {
    std::cout << "MyAccount::onRegState" << std::endl;
    AccountInfo ai = getInfo();
    std::cout << (ai.regIsActive? "*** Register: code=" : "*** Unregister: code=") << prm.code << std::endl;
    PJSua2 pjsua2;
    setRegisterState(ai.regIsActive);
    pjsua2.registerStateInfo();
    registrationPtr(ai.regIsActive, prm.code);
}

void MyAccount::onIncomingCall(OnIncomingCallParam &iprm) {
    std::cout << "MyAccount::onIncomingCall" << std::endl;
    incomingCallPtr();
    myCall = new MyCall(*this, iprm.callId);
}


/**
 Create Lib with EpConfig
 */
void PJSua2::createLib() {
    std::cout << "PJSua2::createLib" << std::endl;
    ep = new Endpoint;
    try {
        ep->libCreate();
    } catch (Error& err){
        std::cout << "Startup error: " << err.info() << std::endl;
    }
    
    //LibInit
    try {
        EpConfig ep_cfg;
        ep->libInit( ep_cfg );
        ep_cfg.uaConfig.userAgent = "iOS UA";
        
    } catch(Error& err) {
        std::cout << "Initialization error: " << err.info() << std::endl;
    }
    
    // Create SIP transport. Error handling sample is shown
    TransportConfig transportConfig;
    transportConfig.port = 5060;
    try {
        ep->transportCreate(PJSIP_TRANSPORT_UDP, transportConfig);
        
    } catch(Error& err) {
        std::cout << "Transport creation error: " << err.info() << std::endl;
    }
    
    try {
        ep->transportCreate(PJSIP_TRANSPORT_TCP, transportConfig);
    } catch (Error& err) {}
    
    try {
        transportConfig.port = 5061;
        ep->transportCreate(PJSIP_TRANSPORT_TLS, transportConfig);
    } catch (Error& err) {}
    transportConfig.port = 5060;
    
    // Start the library (worker threads etc)
    try { ep->libStart();
    } catch(Error& err) {
        std::cout << "Startup error: " << err.info() << std::endl;
    }
}


/**
 Delete lib
 */
void PJSua2::deleteLib() {
    std::cout << "PJSua2::deleteLib" << std::endl;
    
    // Here we don't have anything else to do..
    pj_thread_sleep(500);
    
    // Delete the account. This will unregister from server
    delete acc;
    
    ep->libDestroy();
    delete ep;
}


/**
 Create Account via following config(string username, string password, string ip, string port)
 */
void PJSua2::createAccount(std::string username, std::string password, std::string address) {
    std::cout << "PJSua2::createAccount" << std::endl;
    
    // Configure an AccountConfig
    AccountConfig acfg;
    acfg.idUri = "sip:" + username + "@" + address;
    acfg.regConfig.registrarUri = "sip:" + address;
    StringVector proxies;
    proxies.push_back(acfg.regConfig.registrarUri + ";hide;transport=tls");
    acfg.sipConfig.proxies = proxies;
    AuthCredInfo cred("digest", "*", username, 0, password);
    acfg.sipConfig.authCreds.push_back(cred);
    
    acc = new MyAccount;
    //  TODO:: GET ID -1 IS EXPERIMENTAL, NOT SURE THAT, IT IS GOOD WAY TO CHECK ACC IS CREATED. FIX IT!
    if(acc->getId() == -1){
        // Create the account
        try {
            acc->create(acfg);
        } catch(Error& err) {
            std::cout << "Account creation error: " << err.info() << std::endl;
        }
    }else {
        // Modify the account
        try {
            //Update the registration
            acc->modify(acfg);
            acc->setRegistration(true);
        } catch(Error& err) {
            std::cout << "Account modify error: " << err.info() << std::endl;
        }
    }
    
}


/**
 Unregister account
 */
void PJSua2::unregisterAccount() {
    std::cout << "PJSua2::unregisterAccount" << std::endl;
    acc->setRegistration(false);
}


/**
 Get register state true / false
 */
bool PJSua2::registerStateInfo(){
    std::cout << "PJSua2::registerStateInfo" << std::endl;
    return getRegisterState();
}


/**
 Get caller id for incoming call, checks account currently registered (ai.regIsActive)
 */
std::string PJSua2::incomingCallInfo() {
    std::cout << "PJSua2::incomingCallInfo" << std::endl;
    return getCallerId();
}

void PJSua2::onRegisterListener(void (* funcpntr)(bool, int)) {
    std::cout << "PJSua2::onRegisterListener" << std::endl;
    registrationPtr = funcpntr;
}

/**
 Listener (When we have incoming call, this function pointer will notify swift.)
 */
void PJSua2::incoming_call(void (* funcpntr)()){
    std::cout << "PJSua2::incoming_call" << std::endl;
    incomingCallPtr = funcpntr;
}


/**
 Listener (When we have changes on the call state, this function pointer will notify swift.)
 */
void PJSua2::call_listener(void (* funcpntr)(int)) {
    std::cout << "PJSua2::call_listener" << std::endl;
    callStatusListenerPtr = funcpntr;
}

void PJSua2::ringingCall() {
    std::cout << "PJSua2::ringingCall" << std::endl;
    CallOpParam op;
    op.statusCode = PJSIP_SC_RINGING;
    myCall->answer(op);
}

/**
 Answer incoming call
 */
void PJSua2::answerCall() {
    std::cout << "PJSua2::answerCall" << std::endl;
    CallOpParam op;
    op.statusCode = PJSIP_SC_OK;
    myCall->answer(op);
}


/**
 Hangup active call (Incoming/Outgoing/Active)
 */
void PJSua2::hangupCall() {
    std::cout << "PJSua2::hangupCall" << std::endl;
    
    if (myCall != NULL) {
        CallOpParam op;
        op.statusCode = PJSIP_SC_DECLINE;
        myCall->hangup(op);
        delete myCall;
        myCall = NULL;
    }
}

/**
 Hold the call
 */
void PJSua2::holdCall() {
    std::cout << "PJSua2::holdCall" << std::endl;
    
    if (myCall != NULL) {
        CallOpParam op;
        
        try {
            myCall->setHold(op);
        } catch(Error& err) {
            std::cout << "Hold error: " << err.info() << std::endl;
        }
    }
    
}

/**
 Unhold the call
 */
void PJSua2::unholdCall() {
    std::cout << "PJSua2::unholdCall" << std::endl;
    
    if (myCall != NULL) {
        
        CallOpParam op;
        op.opt.flag=PJSUA_CALL_UNHOLD;
        
        try {
            myCall->reinvite(op);
        } catch(Error& err) {
            std::cout << "Unhold/Reinvite error: " << err.info() << std::endl;
        }
    }
    
}
/**
 Make outgoing call (string dest_uri) -> e.g. makeCall(sip:<SIP_USERNAME@SIP_IP:SIP_PORT>)
 */
void PJSua2::outgoingCall(std::string dest_uri) {
    std::cout << "PJSua2::outgoingCall" << std::endl;
    CallOpParam prm(true); // Use default call settings
    try {
        myCall = new MyCall(*acc);
        myCall->makeCall(dest_uri, prm);
    } catch(Error& err) {
        std::cout << err.info() << std::endl;
    }
}



