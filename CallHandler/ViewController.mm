//
//  ViewController.m
//  CallHandler
//
//  Created by lex on 02/03/14.
//  Copyright (c) 2014 Aleksey Cherkasskiy. All rights reserved.
//

#import "ViewController.h"

#include <dlfcn.h>
#include <stdio.h>

#import <CoreTelephony/CTCall.h>

#define CORETELPATH "/System/Library/PrivateFrameworks/CoreTelephony.framework/CoreTelephony"

NSString* (*CTCallCopyAddress)(void*, CTCall *);

id(*CTTelephonyCenterGetDefault)();

void (*CTTelephonyCenterAddObserver) (id,id,CFNotificationCallback,NSString*,void*,int);
void (*CTCallDisconnect)(CTCall*);

static ViewController *viewController = nil;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self registerCallback];
    
    viewController = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//call this method somewhere to register callback and listen sms.
-(void) registerCallback {
    
    void *handle = dlopen(CORETELPATH, RTLD_LAZY);
    CTTelephonyCenterGetDefault = (id (*)())dlsym(handle, "CTTelephonyCenterGetDefault");
    CTTelephonyCenterAddObserver = (void(*)(id,id,CFNotificationCallback,NSString*,void*,int))dlsym(handle,"CTTelephonyCenterAddObserver");
    CTCallCopyAddress = (NSString* (*)(void*, CTCall *))dlsym(handle, "CTCallCopyAddress");
    CTCallDisconnect = (void (*)(CTCall *))dlsym(handle, "CTCallDisconnect");
    dlclose(handle);
    id ct = CTTelephonyCenterGetDefault();
    
    CTTelephonyCenterAddObserver(
                                 ct,
                                 NULL,
                                 telephonyEventCallback,
                                 NULL,
                                 NULL,
                                 CFNotificationSuspensionBehaviorDeliverImmediately);
    
}

static void telephonyEventCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    NSString *notifyname = (__bridge NSString*)name;
    if ([notifyname isEqualToString:@"kCTCallIdentificationChangeNotification"])
    {
        NSDictionary* info = (__bridge NSDictionary*)userInfo;
        CTCall* call = (CTCall*)[info objectForKey:@"kCTCall"];
        NSString* caller = CTCallCopyAddress(NULL, call);
        
        /* or one of the following functions: CTCallAnswer
         CTCallAnswerEndingActive
         CTCallAnswerEndingAllOthers
         CTCallAnswerEndingHeld
         */
        
        NSLog(@"%@", call); //call.status == 4 is equal to call.callState == CTCallStateIncoming
        NSLog(@"caller id: %@", caller);
        
        viewController.callNumberLabel.text = [NSString stringWithFormat:@"Call number: %@", caller];
        
        NSString *blackNum = @"+79200317611";
        
        if ([caller isEqualToString:blackNum]) {
            NSLog(@"Trying to disconnect: %@", blackNum);
            CTCallDisconnect(call);
        }
        
        return;
    }
}

@end
