//
//  main.m
//  cd to ...
//
//  Created by James Tuley on 10/9/19.
//  Copyright © 2019 Jay Tuley. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ScriptingBridge/ScriptingBridge.h>

#import "Finder.h"
#import "iTermLauncher.h"
#import "TerminalLauncher.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
        
        if (argc > 1) {
            BOOL changedSetting = NO;
            const char *lastOption = argv[1];
            if (strcmp("-use-iTerm", lastOption) == 0) {
                [userDefault setBool:YES forKey:@"cdto-use-iTerm"];
                changedSetting = YES;
            }
            else if (strcmp("-use-native", lastOption) == 0)  {
                [userDefault setBool:NO forKey:@"cdto-use-iTerm"];
                changedSetting = YES;
            }
            if (changedSetting) {
                return 0;
            }
        }

        // Setup code that might create autoreleased objects goes here.
        FinderApplication* finder = [SBApplication applicationWithBundleIdentifier:@"com.apple.Finder"];
        
        FinderItem *target = [(NSArray*)[[finder selection] get] firstObject];
        FinderFinderWindow* findWin = [[finder FinderWindows] objectAtLocation:@1];
        findWin = [[finder FinderWindows] objectWithID:[NSNumber numberWithInteger: findWin.id]];
        bool selected = true;
        if (target == nil){
            target = [[findWin target] get];
            selected = false;
        }
        
        if ([[target kind] isEqualToString:@"Alias"]){
            target = (FinderItem*)[(FinderAliasFile*)target originalItem];
        }
        
        NSString* fileUrl = [target URL];
        if(fileUrl != nil && ![fileUrl hasSuffix:@"/"] && selected){
            fileUrl = [fileUrl stringByDeletingLastPathComponent];
        }
        
        NSURL* url = [NSURL URLWithString:fileUrl];
        if (url != nil) {
            Class launcherClass = nil;
            if ([userDefault boolForKey:@"cdto-use-iTerm"]) {
                launcherClass = iTermLauncher.class;
            }
            else {
                launcherClass = TerminalLauncher.class;
            }
            
            id<LauncherProtocol> launcher = [launcherClass launcherWithURL:url];
            [launcher run];
        }
    }
}
