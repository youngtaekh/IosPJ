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

#import "wrapper.h"
#import "CustomPJSUA2.hpp"


/**
 Create a object from .hpp class & wrapper to be able to use it via Swift
 */
@implementation CPPWrapper
PJSua2 pjsua2;



//Lib
/**
 Create Lib with EpConfig
 */
-(void) createLibWrapper
{
    printf("wrapper.createLibWrapper\n");
    return pjsua2.createLib();
};

/**
 Delete lib
 */
-(void) deleteLibWrapper {
    printf("wrapper.deleteLibWrapper\n");
    pjsua2.deleteLib();
}



//Account
/**
 Create Account via following config(string username, string password, string ip, string port)
 */
-(void) createAccountWrapper :(NSString*) usernameNS :(NSString*) passwordNS :(NSString*) addressNS
{
    printf("wrapper.createAccountWrapper\n");
    std::string username = std::string([[usernameNS componentsSeparatedByString:@"*"][0] UTF8String]);
    std::string password = std::string([[passwordNS componentsSeparatedByString:@"*"][0] UTF8String]);
    std::string address = std::string([[addressNS componentsSeparatedByString:@"*"][0] UTF8String]);
    
    pjsua2.createAccount(username, password, address);
}

/**
 Unregister account
 */
-(void) unregisterAccountWrapper {
    printf("wrapper.unregisterAccountWrapper\n");
    return pjsua2.unregisterAccount();
}



//Register State Info
/**
 Get register state true / false
 */
-(bool) registerStateInfoWrapper {
    printf("wrapper.registerStateInfoWrapper\n");
    return pjsua2.registerStateInfo();
}



// Factory method to create NSString from C++ string
/**
 Get caller id for incoming call, checks account currently registered (ai.regIsActive)
 */
- (NSString*) incomingCallInfoWrapper {
    printf("wrapper.incomingCallInfoWrapper\n");
    NSString* result = [NSString stringWithUTF8String:pjsua2.incomingCallInfo().c_str()];
    return result;
}

- (void)onRegisterListenerWrapper: (void(*)(bool, int))function {
    printf("wrapper.onRegisterListenerWrapper\n");
    pjsua2.onRegisterListener(function);
}

/**
 Listener (When we have incoming call, this function pointer will notify swift.)
 */
- (void)incoming_call_wrapper: (void(*)())function {
    printf("wrapper.incoming_call_wrapper\n");
    pjsua2.incoming_call(function);
}

/**
 Listener (When we have changes on the call state, this function pointer will notify swift.)
 */
- (void)call_listener_wrapper: (void(*)(int))function {
    printf("wrapper.call_listener_wrapper\n");
    pjsua2.call_listener(function);
}

-(void) ringingCallWrapper {
    printf("wrapper.ringingCallWrapper\n");
    pjsua2.ringingCall();
}

/**
 Answer incoming call
 */
- (void) answerCallWrapper {
    printf("wrapper.answerCallWrapper\n");
    pjsua2.answerCall();
}

/**
 Hangup active call (Incoming/Outgoing/Active)
 */
- (void) hangupCallWrapper {
    printf("wrapper.hangupCallWrapper\n");
    pjsua2.hangupCall();
}

/**
 Hold the call
 */
- (void) holdCallWrapper{
    printf("wrapper.holdCallWrapper\n");
    pjsua2.holdCall();
}

/**
 unhold the call
 */
- (void) unholdCallWrapper{
    printf("wrapper.unholdCallWrapper\n");
    pjsua2.unholdCall();
}

/**
 Make outgoing call (string dest_uri) -> e.g. makeCall(sip:<SIP_USERNAME@SIP_IP:SIP_PORT>)
 */
-(void) outgoingCallWrapper :(NSString*) dest_uriNS
{
    printf("wrapper.outgoingCallWrapper\n");
    std::string dest_uri = std::string([[dest_uriNS componentsSeparatedByString:@"*"][0] UTF8String]);
    pjsua2.outgoingCall(dest_uri);
}

@end

