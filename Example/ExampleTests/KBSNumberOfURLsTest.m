//
//  KBSNumberOfURLsTest.m
//  Example
//
//  Created by Keith Smiley on 4/11/13.
//  Copyright (c) 2013 Keith Smiley. All rights reserved.
//

#import "KBSCommon.h"

SpecBegin(NumberOfURLs)

describe(@"numberOfMarkdownURLsInString", ^{
    it(@"should return 0 when there are no URLs", ^{
        expect([[KSADNPostParser shared] numberOfMarkdownURLsInString:@""]).to.equal(0);
        expect([[KSADNPostParser shared] numberOfMarkdownURLsInString:@"This is a test string"]).to.equal(0);
    });
    
    it(@"should return the correct number of URLs when there is one or more", ^{
        NSString *singleURL = @"This is something with [one](url)";
        expect([[KSADNPostParser shared] numberOfMarkdownURLsInString:singleURL]).to.equal(1);
        NSString *doubleURL = @"This is [something](with) multiple [md](urls)";
        expect([[KSADNPostParser shared] numberOfMarkdownURLsInString:doubleURL]).to.equal(2);
    });
});

SpecEnd
