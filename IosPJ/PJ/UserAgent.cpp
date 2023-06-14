//
//  UserAgent.cpp
//  IosPJ
//
//  Created by young on 2023/06/05.
//

#include "UserAgent.hpp"

void (*onRegistrationPtr)(bool, int, int) = 0;
void (*onMessageListenerPtr)() = 0;
void (*onIncomingCallPtr)() = 0;
void (*onCallPtr)(int) = 0;

int callId = 0;
Call *call = NULL;
std::string counterpart;
bool isRegistration = false;

Buddy *buddy = NULL;

std::string from;
std::string message;

// Subclass to extend the Call and get notifications etc.
class CallImpl : public Call {
public:
    CallImpl(Account &acc, int callId = PJSUA_INVALID_ID) : Call(acc, callId) {
        std::cout << "CallImpl.constructor" << std::endl;
    }
    ~CallImpl(){
        std::cout << "CallImpl.destructor" << std::endl;
    }
    
    // Notification when call's state has changed.
    virtual void onCallState(OnCallStateParam &prm) {
        CallInfo info = getInfo();
        std::cout << "CallImpl::onCallState info.state " << info.state << std::endl;
        counterpart = info.remoteUri;
//        PJSIP_INV_STATE_EARLY
        std::cout << "0 is PJSIP_INV_STATE_NULL" << std::endl;
        std::cout << "1 is PJSIP_INV_STATE_CALLING" << std::endl;
        std::cout << "2 is PJSIP_INV_STATE_INCOMING" << std::endl;
        std::cout << "3 is PJSIP_INV_STATE_EARLY" << std::endl;
        std::cout << "4 is PJSIP_INV_STATE_CONNECTING" << std::endl;
        std::cout << "5 is PJSIP_INV_STATE_CONFIRMED" << std::endl;
        std::cout << "6 is PJSIP_INV_STATE_DISCONNECTED" << std::endl;
        if (info.state == PJSIP_INV_STATE_CONFIRMED || info.state == PJSIP_INV_STATE_DISCONNECTED) {
            onCallPtr(info.state);
        } else if (info.state == PJSIP_INV_STATE_EARLY && info.role == PJSIP_ROLE_UAC) {
            onCallPtr(info.state);
        }
        
        if (info.state == PJSIP_INV_STATE_DISCONNECTED) {
            delete call;
            call = NULL;
        }
    }
    
    // Notification when call's media state has changed.
    virtual void onCallMediaState(OnCallMediaStateParam &prm) {
        std::cout << "CallImpl.onCallMediaState" << std::endl;
        CallInfo info = getInfo();
        // Iterate all the call medias
        for (unsigned i = 0; i < info.media.size(); i++) {
            if (info.media[i].type==PJMEDIA_TYPE_AUDIO && getMedia(i)) {
                AudioMedia *audioMedia = (AudioMedia *)getMedia(i);
                
                // Connect the call audio media to sound device
                AudDevManager& manager = Endpoint::instance().audDevManager();
                audioMedia->startTransmit(manager.getPlaybackDevMedia());
                manager.getCaptureDevMedia().startTransmit(*audioMedia);
            }
        }
    }
};

// Subclass to extend the Account and get notifications etc.
class AccountImpl : public Account {
public:
    AccountImpl() {
        std::cout << "AccountImpl.constructor" << std::endl;
    }
    ~AccountImpl() {
        std::cout << "AccountImpl.destructor" << std::endl;
        // Invoke shutdown() first..
        shutdown();
        // ..before deleting any member objects.
    }
    
    void addBuddy(BuddyConfig config) {
        buddy = new Buddy;
        buddy->create(*this, config);
        buddy->subscribePresence(config.subscribe);
    }
    
    void delBuddy() {
        if (buddy != NULL) {
            delete buddy;
            buddy = NULL;
        }
    }
    
    void sendBuddy(std::string msg);
    
    // This is getting for register status!
    virtual void onRegState(OnRegStateParam &prm);
    
    // This is getting for incoming call (We can either answer or hangup the incoming call)
    virtual void onIncomingCall(OnIncomingCallParam &iprm);
    
    virtual void onIncomingSubscribe(OnIncomingSubscribeParam &param);
    virtual void onInstantMessage(OnInstantMessageParam &param);
    virtual void onInstantMessageStatus(OnInstantMessageStatusParam &parma);
};

AccountImpl *accountImpl;

void AccountImpl::onRegState(OnRegStateParam &prm) {
    AccountInfo info = getInfo();
    std::cout << (info.regIsActive? "*** Register: code=" : "*** Unregister: code=") << prm.code << std::endl;
    std::cout << "expire " << info.regExpiresSec << std::endl;
    isRegistration = info.regIsActive;
    onRegistrationPtr(info.regIsActive, prm.code, info.regExpiresSec);
}

void AccountImpl::onIncomingCall(OnIncomingCallParam &iprm) {
    std::cout << "AccountImpl::onIncomingCall" << std::endl;
    onIncomingCallPtr();
    call = new CallImpl(*this, iprm.callId);
}

void AccountImpl::sendBuddy(std::string msg) {
    if (buddy != NULL) {
        SendInstantMessageParam param;
        param.contentType = "text/plain";
        param.content = msg;
        
        SipHeader header;
        header.hName = "Custom-Header";
        header.hValue = "iOS message";
        param.txOption.headers.clear();
        param.txOption.headers.push_back(header);
        
        buddy->sendInstantMessage(param);
    }
}

void AccountImpl::onIncomingSubscribe(OnIncomingSubscribeParam &param) {
    std::cout << "AccountImpl::onIncomingCall" << std::endl;
}

void AccountImpl::onInstantMessage(OnInstantMessageParam &param) {
    std::cout << "AccountImpl::onInstantMessage" << std::endl;
    from = param.fromUri;
    message = param.msgBody;
    onMessageListenerPtr();
}

void AccountImpl::onInstantMessageStatus(OnInstantMessageStatusParam &parma) {
    std::cout << "AccountImpl::onInstantMessageStatus" << std::endl;
}

void UserAgent::start(std::string outboundAddress, std::string userId, std::string password, std::string transportType) {
    std::cout << "UserAgent::start(address " << outboundAddress << ", userId " << userId << ", password " << password << ", type " << transportType << ")" << std::endl;
    endPoint = new Endpoint;
    
    pjsip_transport_type_e type = PJSIP_TRANSPORT_TLS;
    if (transportType == "UDP") {
        std::cout << "transport type is UDP" << std::endl;
        type = PJSIP_TRANSPORT_UDP;
    } else if (transportType == "TCP") {
        std::cout << "transport type is TCP" << std::endl;
        type = PJSIP_TRANSPORT_TCP;
    }
    
    try {
        endPoint->libCreate();
    } catch (Error& err) {
        std::cout << "Startup error: " << err.info() << std::endl;
    }
    
    initLog();
    setUaConfig();
    
    try {
        endPoint->libInit(epConfig);
    } catch (Error& err) {
        std::cout << "libInit error: " << err.info() << std::endl;
    }
    
    setTransportConfig();
    
    AccountConfig accountConfig;
    accountConfig.idUri = "sip:" + userId + "@" + outboundAddress;
    accountConfig.regConfig.registrarUri = "sip:" + outboundAddress;
    
    StringVector proxies;
    if (PJSIP_TRANSPORT_UDP == type) {
        std::cout << "transport type is UDP" << std::endl;
        proxies.push_back(accountConfig.regConfig.registrarUri);
    } else if (PJSIP_TRANSPORT_TCP == type) {
        std::cout << "transport type is TCP" << std::endl;
        proxies.push_back(accountConfig.regConfig.registrarUri + ";hide;transport=tcp");
    } else {
        std::cout << "transport type is TLS" << std::endl;
        proxies.push_back(accountConfig.regConfig.registrarUri + ";hide;transport=tls");
    }
    accountConfig.sipConfig.proxies = proxies;
    
    AuthCredInfo cred("digest", "*", userId, 0, password);
    accountConfig.sipConfig.authCreds.push_back(cred);
    
    try {
        endPoint->libStart();
    } catch (Error& err) {
        std::cout << "libStart error: " << err.info() << std::endl;
    }
    
    accountImpl = new AccountImpl;
    try {
        accountImpl->create(accountConfig);
    } catch (Error& err) {
        std::cout << "Account creation error: " << err.info() << std::endl;
    }
}

void UserAgent::stop() {
    std::cout << "UserAgent::stop()" << std::endl;
    try {
        endPoint->libDestroy();
    } catch (Error& err) {
        std::cout << "libDestroy error" << err.info() << std::endl;
    }
    delete endPoint;
    delete accountImpl;
}

void UserAgent::makeCall(std::string callee) {
    std::cout << "UserAgent::makeCall(" << callee << ")" << std::endl;
    CallOpParam param(true);
    try {
        call = new CallImpl(*accountImpl);
        
        param.txOption.headers.clear();
        param.txOption.headers.push_back(addCustomHeader("Custom-Header", "iOS make call"));
        call->makeCall(callee, param);
    } catch (Error& err) {
        std::cout << "Make call err: " << err.info() << std::endl;
    }
}
void UserAgent::answerCall() {
    std::cout << "UserAgent::answerCall()" << std::endl;
    CallOpParam param;
    param.statusCode = PJSIP_SC_OK;
    
    param.txOption.headers.clear();
    param.txOption.headers.push_back(addCustomHeader("Custom-Header", "iOS answer call"));
    call->answer(param);
}
void UserAgent::busyCall() {
    std::cout << "UserAgent::busyCall()" << std::endl;
    CallOpParam param;
    param.statusCode = PJSIP_SC_BUSY_HERE;
    
    param.txOption.headers.clear();
    param.txOption.headers.push_back(addCustomHeader("Custom-Header", "iOS busy call"));
    
    call->hangup(param);
}
void UserAgent::ringingCall() {
    std::cout << "UserAgent::ringingCall()" << std::endl;
    CallOpParam param(false);
    param.statusCode = PJSIP_SC_RINGING;
    
    param.txOption.headers.clear();
    param.txOption.headers.push_back(addCustomHeader("Custom-Header", "iOS ringing call"));
    call->answer(param);
}
void UserAgent::declineCall() {
    std::cout << "UserAgent::declineCall()" << std::endl;
    CallOpParam param(false);
    param.statusCode = PJSIP_SC_DECLINE;
    
    param.txOption.headers.clear();
    param.txOption.headers.push_back(addCustomHeader("Custom-Header", "iOS decline call"));
    call->hangup(param);
    delete call;
    call = NULL;
}
void UserAgent::updateCall() {
    std::cout << "UserAgent::updateCall()" << std::endl;
    CallOpParam param(true);
    
    param.txOption.headers.clear();
    param.txOption.headers.push_back(addCustomHeader("Custom-Header", "iOS update call"));
    call->update(param);
}
void UserAgent::reInviteCall() {
    std::cout << "UserAgent::reInviteCall()" << std::endl;
    CallOpParam param(true);
    
    param.txOption.headers.clear();
    param.txOption.headers.push_back(addCustomHeader("Custom-Header", "iOS reinvite call"));
    call->reinvite(param);
}
void UserAgent::endCall() {
    std::cout << "UserAgent::endCall()" << std::endl;
    CallOpParam param;
    
    param.txOption.headers.clear();
    param.txOption.headers.push_back(addCustomHeader("Custom-Header", "iOS hangup call"));
    call->hangup(param);
    delete call;
    call = NULL;
}
void UserAgent::onNetworkChanged() {
    std::cout << "UserAgent::onNetworkChanged()" << std::endl;
    IpChangeParam param;
    endPoint->handleIpChange(param);
}

void UserAgent::sendRequest() {
    std::cout << "UserAgent::sendRequest()" << std::endl;
}

void UserAgent::setBuddy(std::string uri, bool isSub) {
    std::cout << "UserAgent::setBuddy()" << std::endl;
    BuddyConfig config;
    config.uri = uri;
    config.subscribe = isSub;
    accountImpl->addBuddy(config);
}

void UserAgent::deleteBuddy(std::string uri) {
    std::cout << "UserAgent::deleteBuddy()" << std::endl;
    accountImpl->delBuddy();
}

void UserAgent::sendInstanceMessage(std::string uri, std::string msg) {
    std::cout << "UserAgent::sendInstanceMessage()" << std::endl;
    BuddyConfig config;
    config.uri = uri;
    config.subscribe = false;
    accountImpl->addBuddy(config);
    accountImpl->sendBuddy(msg);
}

void UserAgent::addRegisterListener(void (*function)(bool, int, int)) {
    onRegistrationPtr = function;
}

void UserAgent::addMessageListener(void (*function)()) {
    onMessageListenerPtr = function;
}

void UserAgent::addIncomingCallListener(void (*function)()) {
    onIncomingCallPtr = function;
}

void UserAgent::addCallListener(void (*function)(int)) {
    onCallPtr = function;
}

bool UserAgent::isRegistered() {
    return isRegistration;
}

std::string UserAgent::getCounterpart() {
    return counterpart;
}

std::string UserAgent::getFrom() {
    return from;
}

std::string UserAgent::getMessage() {
    return message;
}

void UserAgent::initLog() {
    std::cout << "UserAgent::initLog()" << std::endl;
    epConfig.logConfig.level = 4;
    epConfig.logConfig.consoleLevel = 4;
}
void UserAgent::setUaConfig() {
    std::cout << "UserAgent::setUaConfig()" << std::endl;
    epConfig.uaConfig.userAgent = "iOS PJ";
}
void UserAgent::setTransportConfig() {
    std::cout << "UserAgent::setTransportConfig()" << std::endl;
    
    TransportConfig transportConfig;
    transportConfig.port = 5060;
    try {
        endPoint->transportCreate(PJSIP_TRANSPORT_UDP, transportConfig);
    } catch(Error& err) {
        std::cout << "UDP Transport creation error: " << err.info() << std::endl;
    }
    try {
        endPoint->transportCreate(PJSIP_TRANSPORT_TCP, transportConfig);
    } catch(Error& err) {
        std::cout << "TCP Transport creation error: " << err.info() << std::endl;
    }
    try {
        transportConfig.port = 5061;
        endPoint->transportCreate(PJSIP_TRANSPORT_TLS, transportConfig);
    } catch(Error& err) {
        std::cout << "TLS Transport creation error: " << err.info() << std::endl;
    }
    transportConfig.port = 5060;
}
std::string UserAgent::getUserName() {
    std::cout << "UserAgent::getUserName()" << std::endl;
    return "testUserName";
}

SipHeader UserAgent::addCustomHeader(std::string name, std::string value) {
    SipHeader header;
    header.hName = name;
    header.hValue = value;
    return header;
}
