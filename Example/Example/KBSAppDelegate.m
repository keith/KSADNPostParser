//
//  KBSAppDelegate.m
//  Example
//
//  Created by Keith Smiley on 4/9/13.
//  Copyright (c) 2013 Keith Smiley. All rights reserved.
//

#import "KBSAppDelegate.h"
#import "KSADNPostParser.h"

@implementation KBSAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSString *post = @"[wikipedia](sometext) abc [stuff](invalid)";
    NSError *error = nil;
    NSDictionary *dictionary = [[KSADNPostParser shared] postDictionaryForText:post error:&error];
    [[NSAlert alertWithError:error] runModal];
    NSLog(@"%@", dictionary);
}

@end
