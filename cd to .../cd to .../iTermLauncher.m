//
//  iTermManager.m
//  cd to
//
//  Created by Sungwoo Han on 2023/08/29.
//  Copyright © 2023 Jay Tuley. All rights reserved.
//

#import "iTermLauncher.h"
#import <Cocoa/Cocoa.h>
#import <ScriptingBridge/ScriptingBridge.h>

@interface iTermLauncher()

@property (nonatomic, strong) NSString *path;

@end

@implementation iTermLauncher

+ (instancetype)launcherWithURL:(NSURL *)url
{
    return [[iTermLauncher alloc] initWithTargetPath:url.path];
}

- (instancetype)initWithTargetPath:(NSString *)path
{
    if (self = [super init]) {
        self.path = path;
    }
    return self;
}

- (void)run
{
    NSString * const iTermBundleId = @"com.googlecode.iterm2";
    
    SBApplication *terminal = [SBApplication applicationWithBundleIdentifier:iTermBundleId];
    if (!terminal.isRunning) {
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        NSWorkspace *ws = NSWorkspace.sharedWorkspace;
        NSURL *url = [ws URLForApplicationWithBundleIdentifier:iTermBundleId];
        [ws openApplicationAtURL:url configuration:NSWorkspaceOpenConfiguration.configuration completionHandler:^(NSRunningApplication * _Nullable app, NSError * _Nullable error) {
            SBApplication *terminal = [SBApplication applicationWithBundleIdentifier:iTermBundleId];
            [terminal activate];
            
            while ([[terminal performSelector:@selector(windows)] firstObject] == nil) {
                [NSThread sleepForTimeInterval:0.2];
            }
            [self _runAppleScript:YES];
            dispatch_semaphore_signal(sema);
        }];
        dispatch_time_t waitTime = dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);
        dispatch_semaphore_wait(sema, waitTime);
    }
    else {
        [terminal activate];
        [self _runAppleScript:NO];
    }
}

- (void)_runAppleScript:(BOOL)isFirtLaunch
{
    NSMutableString *scriptStr =
    [NSMutableString stringWithFormat:
     @"tell application \"iTerm\"\n"
      "   set aWindow to current window\n"
      ""
      "   if aWindow is missing value then\n"
      "       delay 0.4\n"
      "       set aWindow to current window\n"
      "   end if\n"];
    
    if (!isFirtLaunch) {
        [scriptStr appendString:
         @"   create window with default profile\n"
          "   set aWindow to current window\n"];
    }

    [scriptStr appendFormat:
     @"   tell current tab of aWindow\n"
      "       tell current session\n"
      "           write text \"cd '%@'\"\n"
      "       end tell\n"
      "   end tell\n"
      "end tell", self.path];
    
    NSAppleScript *sc = [[NSAppleScript alloc] initWithSource:scriptStr];
    NSDictionary *retDic = nil;
    [sc executeAndReturnError:&retDic];
}

@end
