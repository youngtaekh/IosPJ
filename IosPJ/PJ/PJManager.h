//
//  PJManager.h
//  IosPJ
//
//  Created by young on 2023/06/05.
//

#import <Foundation/Foundation.h>

@interface PJManager: NSObject

-(void) startRegistration:(NSString *)outboundAddress
                   userId:(NSString *)userId
                 password:(NSString *)password
            transportType:(NSString *)transportType
         registerListener:(void (*)(bool, int, int))registerListener
          messageListener:(void (*)())messageListener
         incomingListener:(void (*)())incomingListener;

-(void) stopRegistration;

-(void) makeCall:(NSString *)counterpart;
-(void) ringingCall;
-(void) answerCall;
-(void) busyCall;
-(void) declineCall;
-(void) updateCall;
-(void) reInviteCall;
-(void) endCall;
-(void) onNetworkChanged;

-(void) sendRequest;

-(void) setBuddy:(NSString *)uri isSub:(BOOL)isSub;
-(void) deleteBuddy:(NSString *)uri;

-(void) sendInstanceMessage:(NSString *)uri msg:(NSString *)msg;

-(void) addCallListener: (void(*)(int))function;

-(void) activateAudioSession;
-(void) deactivateAudioSession;

-(BOOL) isRegistered;
-(NSString *) getCounterpart;
-(NSString *) getFrom;
-(NSString *) getMessage;
    
@end
