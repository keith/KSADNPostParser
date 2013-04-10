//
//  KBSPossiblyValidTest.m
//  Example
//
//  Created by Keith Smiley on 4/10/13.
//  Copyright (c) 2013 Keith Smiley. All rights reserved.
//

#import "KBSCommon.h"

SpecBegin(PossiblyValid)

describe(@"possibleValidString", ^{
    it(@"should return false for various incorrect formats", ^{
        expect([[KSADNPostParser shared] possibleValidString:@""]).to.equal(false);
        expect([[KSADNPostParser shared] possibleValidString:@"[test](url"]).to.equal(false);
        expect([[KSADNPostParser shared] possibleValidString:@"test](url"]).to.equal(false);
        expect([[KSADNPostParser shared] possibleValidString:@"test](url)"]).to.equal(false);
        expect([[KSADNPostParser shared] possibleValidString:@"test](url)"]).to.equal(false);
    });
    
    it(@"should return true for correctly formatted strings", ^{
        expect([[KSADNPostParser shared] possibleValidString:@"[test](url)"]).to.equal(true);
    });
});

SpecEnd
