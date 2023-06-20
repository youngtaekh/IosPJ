//
//  UserAgent.hpp
//  IosPJ
//
//  Created by young on 2023/06/05.
//

#include <iostream>
#include <pjsua2.hpp>
//#include "AccountImpl.hpp"
//#include "CallImpl.hpp"

using namespace pj;

class UserAgent {
public:
    UserAgent() {
        std::cout << "UserAgent constructor" << std::endl;
    }
    ~UserAgent() {
        std::cout << "UserAgent destructor" << std::endl;
    }
    void start(std::string outboundAddress, std::string userId, std::string password, std::string type);
    void stop();
    
    void makeCall(std::string callee);
    void answerCall();
    void busyCall();
    void ringingCall();
    void declineCall();
    void updateCall();
    void reInviteCall();
    void endCall();
    void onNetworkChanged();
    
    void sendRequest();
    
    void setBuddy(std::string uri, bool isSub);
    void deleteBuddy(std::string uri);
    
    void sendInstanceMessage(std::string uri, std::string msg);
    
    void addRegisterListener(void (*function)(bool, int, int));
    void addMessageListener(void (*function)());
    void addIncomingCallListener(void (*function)());
    void addCallListener(void (*function)(int));
    
    void activateAudioSession();
    void deactivateAudioSession();
    
    bool isRegistered();
    std::string getCounterpart();
    std::string getFrom();
    std::string getMessage();
    
private:
    void initLog();
    void setUaConfig();
    void setTransportConfig();
    std::string getUserName();
    
    SipHeader addCustomHeader(std::string name, std::string value);

    Endpoint *endPoint;
    EpConfig epConfig;
};
