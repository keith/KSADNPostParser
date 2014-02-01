//
//  KBSTwitterTextTest.m
//  Example
//
//  Created by Keith Smiley on 4/23/13.
//  Copyright (c) 2013 Keith Smiley. All rights reserved.
//

#import "KBSCommon.h"

SpecBegin(TwitterTextSpec)

describe(@"twitterTextFromString", ^{
    describe(@"when it has no markdown", ^{
        it(@"should return the same string", ^{
            NSString *text = @"This is some text";
            NSString *twitterText = [[KSADNPostParser shared] twitterTextFromString:text];
            expect(twitterText).to.equal(text);
        });
    });
    
    describe(@"when it has a single markdown string", ^{
        it(@"should return the correctly formatted string", ^{
            NSString *text = @"This is some [url](http://google.com) text";
            NSString *expectedText = @"This is some url http://google.com text";
            NSString *twitterText = [[KSADNPostParser shared] twitterTextFromString:text];
            expect(twitterText).to.equal(expectedText);
        });
    });
    
    describe(@"when it has multiple markdown URLs", ^{
        it(@"should return the correctly formatted string", ^{
            NSString *text = @"Foo [url](http://google.com) bar [github](http://github.com) baz";
            NSString *expectedText = @"Foo url http://google.com bar github http://github.com baz";
            NSString *twitterText = [[KSADNPostParser shared] twitterTextFromString:text];
            expect(twitterText).to.equal(expectedText);
        });
    });
});

SpecEnd
