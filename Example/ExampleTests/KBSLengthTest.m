//
//  KBSLengthTest.m
//  Example
//
//  Created by Keith Smiley on 4/9/13.
//  Copyright (c) 2013 Keith Smiley. All rights reserved.
//

#import "KBSCommon.h"

SpecBegin(LengthSpec)

describe(@"postLengthForText", ^{
    it(@"should return the correct length minus URL", ^{
        NSString *post = @"This is a string with a [url](https://github.com/)";
        expect([[KSADNPostParser shared] postLengthForText:post]).to.equal(27);
    });
    
    it(@"should return the same length for posts without markdown URLs", ^{
        NSString *post = @"This is a post";
        expect([[KSADNPostParser shared] postLengthForText:post]).to.equal(14);
    });
    
    it(@"should return the correct length for posts with emoji", ^{
        NSString *post = @"😄";
        expect([[KSADNPostParser shared] postLengthForText:post]).to.equal(1);
        
        post = @"😄 abc 😄 def";
        expect([[KSADNPostParser shared] postLengthForText:post]).to.equal(11);
        
        post = @"abc 😄 def [😄](https://github.com)";
        expect([[KSADNPostParser shared] postLengthForText:post]).to.equal(11);
        
        post = @"abc 😄 def [hij](https://github.com)";
        expect([[KSADNPostParser shared] postLengthForText:post]).to.equal(13);
    });
    
});

SpecEnd