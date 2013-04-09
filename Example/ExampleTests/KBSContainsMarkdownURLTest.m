//
//  KBSContainsMarkdownURLTest.m
//  Example
//
//  Created by Keith Smiley on 4/9/13.
//  Copyright (c) 2013 Keith Smiley. All rights reserved.
//

#import "KBSCommon.h"

SpecBegin(ContainsMarkdownURL)

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wall"

describe(@"containsMarkdownURL", ^{
    it(@"should return true when there is a markdown url", ^{
        NSString *post = @"This is a string with a [url](https://github.com/)";
        expect([[KSADNPostParser shared] containsMarkdownURL:post]).to.beTruthy;
    });
    
    it(@"should return true when there are multiple markdown urls", ^{
        NSString *post = @"This is a [string](https://github.com/petejkim/expecta/) with many [markdown](http://daringfireball.net/projects/markdown/) URLs";
        expect([[KSADNPostParser shared] containsMarkdownURL:post]).to.beTruthy;
    });
    
    it(@"should return false when there isn't a markdown url", ^{
        NSString *post = @"This is a post";
        expect([[KSADNPostParser shared] containsMarkdownURL:post]).to.beFalsy;
    });
});

#pragma GCC diagnostic pop

SpecEnd
