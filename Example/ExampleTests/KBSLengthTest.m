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

        [[KSADNPostParser shared] postLengthForText:post withBlock:^(NSUInteger length) {
            expect(length).to.equal(27);
        }];
    });
    
    it(@"should return the same length for posts without markdown URLs", ^{
        NSString *post = @"This is a post";

        [[KSADNPostParser shared] postLengthForText:post withBlock:^(NSUInteger length) {
            expect(length).to.equal(14);
        }];
    });
});

SpecEnd