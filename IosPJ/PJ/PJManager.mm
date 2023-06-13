//
//  PJManager.m
//  IosPJ
//
//  Created by young on 2023/06/05.
//

#import "PJManager.h"
#import "UserAgent.hpp"
//#import "CustomPJSUA2.hpp"

@implementation PJManager
UserAgent ua;
//PJSua3 pjsua3;

-(void) startRegistration:(NSString *)outboundAddress
                   userId:(NSString *)userId
                 password:(NSString *)password
            transportType:(NSString *)transportType
         registerListener:(void (*)(bool, int))registerListener
          messageListener:(void (*)())messageListener
         incomingListener:(void (*)())incomingListener
{
    printf("PJManager startRegistration");
    std::string userName = std::string([[userId componentsSeparatedByString:@"*"][0] UTF8String]);
    std::string pwd = std::string([[password componentsSeparatedByString:@"*"][0] UTF8String]);
    std::string address = std::string([[outboundAddress componentsSeparatedByString:@"*"][0] UTF8String]);
    std::string type = std::string([[transportType componentsSeparatedByString:@"*"][0] UTF8String]);
    
    ua.start(address, userName, pwd, type);
    ua.addRegisterListener(registerListener);
    ua.addMessageListener(messageListener);
    ua.addIncomingCallListener(incomingListener);
    
//    pjsua2.createLib();
//    pjsua2.createAccount(userName, pwd, address);
//    pjsua2.onRegisterListener(registerListener);
//    pjsua2.incoming_call(incomingListener);
}

-(void) stopRegistration {
    ua.stop();
//    pjsua2.unregisterAccount();
//    pjsua2.deleteLib();
}

-(void) makeCall:(NSString *)counterpart {
    std::string callee = std::string([[counterpart componentsSeparatedByString:@"*"][0] UTF8String]);
    ua.makeCall(callee);
}

-(void) ringingCall {
    ua.ringingCall();
}

-(void) answerCall {
    ua.answerCall();
}

-(void) busyCall {
    ua.busyCall();
}

-(void) declineCall {
    ua.declineCall();
}

-(void) updateCall {
    ua.updateCall();
}

-(void) reInviteCall {
    ua.reInviteCall();
}

-(void) endCall {
    ua.endCall();
}

-(void) onNetworkChanged {
    ua.onNetworkChanged();
}

-(void) sendRequest {
    ua.sendRequest();
}

-(void) setBuddy:(NSString *)uri isSub:(BOOL)isSub {
    std::string to = std::string([[uri componentsSeparatedByString:@"*"][0] UTF8String]);
    ua.setBuddy(to, isSub);
}

-(void) deleteBuddy:(NSString *)uri {
    std::string to = std::string([[uri componentsSeparatedByString:@"*"][0] UTF8String]);
    ua.deleteBuddy(to);
}

-(void) sendInstanceMessage:(NSString *)uri msg:(NSString *)msg {
    std::string to = std::string([[uri componentsSeparatedByString:@"*"][0] UTF8String]);
    std::string message = std::string([[msg componentsSeparatedByString:@"*"][0] UTF8String]);
    ua.sendInstanceMessage(to, message);
}

-(void) addCallListener: (void (*)(int)) function {
    ua.addCallListener(function);
}

-(BOOL) isRegistered {
    return ua.isRegistered();
}

-(NSString *) getCounterpart {
    NSString *result = [NSString stringWithUTF8String:ua.getCounterpart().c_str()];
    return result;
}

-(NSString *) getFrom {
    NSString *result = [NSString stringWithUTF8String:ua.getFrom().c_str()];
    return result;
}

-(NSString *) getMessage {
    NSString *result = [NSString stringWithUTF8String:ua.getMessage().c_str()];
    return result;
}

@end
