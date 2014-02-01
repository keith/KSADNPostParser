//
//  KBSRangeOfFirstMatchTest.m
//  Example
//
//  Created by Keith Smiley on 4/9/13.
//  Copyright (c) 2013 Keith Smiley. All rights reserved.
//

#import "KBSCommon.h"

SpecBegin(RangeOfMatch)

describe(@"rangeOfFirstMarkdownString", ^{
    it(@"should return nil if there is no markdown", ^{
        NSString *post = @"This is a string";
        expect([[KSADNPostParser shared] rangeOfFirstMarkdownString:post]).to.equal(nil);
    });
    
    it(@"should return the entire range of the markdown", ^{
        NSString *post = @"This is a post [url](http://google.com)";
        NSRange range = [[[KSADNPostParser shared] rangeOfFirstMarkdownString:post] rangeValue];
        expect(range.location).to.equal(15);
        expect(range.length).to.equal(24);
    });
});

SpecEnd

SpecBegin(RangesOfMatches)

describe(@"rangesOfMarkdownURLStrings", ^{
    it(@"should return an empty array if there are no matches", ^{
        NSString *post = @"This is a string";
        NSArray *ranges = [[KSADNPostParser shared] rangesOfMarkdownURLStrings:post];
        expect(ranges.count).to.equal(0);
    });
    
    it(@"should return the ranges when there is one or more matches", ^{
        NSString *singleURL = @"This is a [single](url)";
        NSRange urlRange = [singleURL rangeOfString:@"[single](url)"];
        NSArray *ranges = [[KSADNPostParser shared] rangesOfMarkdownURLStrings:singleURL];
        expect(ranges.count).to.equal(1);
        NSRange theRange = [ranges[0] rangeValue];
        expect(NSEqualRanges(urlRange, theRange)).to.equal(true);
    });
});

SpecEnd
