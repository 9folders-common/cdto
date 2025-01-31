//
//  TerminalLauncher.m
//  cd to
//
//  Created by Sungwoo Han on 2023/08/29.
//  Copyright © 2023 Jay Tuley. All rights reserved.
//

#import "TerminalLauncher.h"
#import "Terminal.h"

@interface TerminalLauncher()

@property (nonatomic, strong) NSURL *url;

@end

@implementation TerminalLauncher

+ (instancetype)launcherWithURL:(NSURL *)url
{
    return [[TerminalLauncher alloc] initWithURL:url];
}

- (instancetype)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        self.url = url;
    }
    return self;
}

- (void)run
{
    TerminalApplication* terminal = [SBApplication applicationWithBundleIdentifier:@"com.apple.Terminal"];
    TerminalWindow* win = nil;
    if ([[terminal windows] count] == 1){
        //get front most and then reference by id
        win = [[terminal windows] objectAtLocation:@1];
        win = [[terminal windows] objectWithID: [NSNumber numberWithInteger:win.id]];
    }
    [terminal open:@[self.url]];
    //get front most and then reference by id
    TerminalWindow* newWin = [[terminal windows] objectAtLocation:@1];
    newWin = [[terminal windows] objectWithID: [NSNumber numberWithInteger:newWin.id]];
    TerminalTab* newTab = [[newWin tabs] objectAtLocation:@1];
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSString* setName = [userDefault stringForKey:@"cdto-new-window-setting"];
    if(setName != nil && ![setName isEqualToString:@""]) { //setting set
        TerminalSettingsSet* chosenSet = nil;
        for (TerminalSettingsSet *set in [terminal settingsSets]) {
            if([[set name] isEqualToString:setName]){
                chosenSet = set;
            }
        }
        if(chosenSet != nil){
            newTab.currentSettings = chosenSet;
        }
    }
    
    if([userDefault boolForKey:@"cdto-close-default-window"]) { //close first launch window
        if([[win tabs] count] == 1){
            TerminalTab* tab = [[win tabs]objectAtLocation:@1];
            if(![tab busy]){
                //if history has same number of lines as new window
                // assume automatically opened new window, and close it
                NSUInteger oldTabLines = [self linesOfHistory:tab];
                while([newTab busy]){
                    [NSThread sleepForTimeInterval:0.1f];
                }
                NSUInteger newTabLines = [self linesOfHistory:newTab];
                if(oldTabLines == newTabLines){
                    [win closeSaving:TerminalSaveOptionsNo savingIn:nil];
                }
            }
        }
    }
    
    [terminal activate];
}

- (NSUInteger)linesOfHistory:(TerminalTab *)tab
{
    NSString* hist = [[tab history] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    return [[hist componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] count];
}

@end
