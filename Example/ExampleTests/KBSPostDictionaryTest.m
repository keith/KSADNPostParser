//
//  KBSPostDictionaryTest.m
//  Example
//
//  Created by Keith Smiley on 4/9/13.
//  Copyright (c) 2013 Keith Smiley. All rights reserved.
//

#import "KBSCommon.h"

SpecBegin(PostDictionarySpec)

describe(@"postDictionaryForText", ^{
    it(@"should return an empty dictionary when there's no text", ^{
        NSString *post = @"";
        NSDictionary *dictionary = [[KSADNPostParser shared] postDictionaryForText:post];
        expect(dictionary.count).to.equal(0);
    });
    
    it(@"should return an dictionary with metadata", ^{
        NSString *post = @"This is a string with a [url](https://github.com/)";
        NSDictionary *dictionary = [[KSADNPostParser shared] postDictionaryForText:post];
        expect(dictionary).notTo.beNil;
        expect(dictionary.count).to.beGreaterThan(1);
    });
});

SpecEnd