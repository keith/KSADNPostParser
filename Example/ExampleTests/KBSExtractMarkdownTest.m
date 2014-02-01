//
//  KBSExtractMarkdownTest.m
//  Example
//
//  Created by Keith Smiley on 4/10/13.
//  Copyright (c) 2013 Keith Smiley. All rights reserved.
//

#import "KBSCommon.h"

SpecBegin(ExtractMarkdown)

describe(@"extractURLandTitleFromMarkdownString", ^{
    it(@"should return an empty array for a nil string", ^{
        expect([[KSADNPostParser shared] extractURLandTitleFromMarkdownString:@""].count).to.equal(0);
    });
    
    it(@"should return an empty array for incorrectly formatted markdown", ^{
        expect([[KSADNPostParser shared] extractURLandTitleFromMarkdownString:@"title](url)"].count).to.equal(0);
        expect([[KSADNPostParser shared] extractURLandTitleFromMarkdownString:@"title](url"].count).to.equal(0);
        expect([[KSADNPostParser shared] extractURLandTitleFromMarkdownString:@"title url)"].count).to.equal(0);
        expect([[KSADNPostParser shared] extractURLandTitleFromMarkdownString:@"[title](url"].count).to.equal(0);
    });
    
    it(@"should return the title and URL for the passed valid markdown", ^{
        NSArray *returnArray = [[KSADNPostParser shared] extractURLandTitleFromMarkdownString:@"[title](url)"];
        expect(returnArray.count).to.equal(2);
        expect(returnArray[0]).to.equal(@"title");
        expect(returnArray[1]).to.equal(@"url");
    });
    
    it(@"should return the correct title and URL even with weird markdown", ^{
        NSString *title = @"Wikipedia [URL";
        NSString *url   = @"http://wikipedia.org/wiki/Monad_(functional_programming)";
        NSArray *returnArray = [[KSADNPostParser shared] extractURLandTitleFromMarkdownString:[NSString stringWithFormat:@"[%@](%@)", title, url]];
        expect(returnArray.count).to.equal(2);
        expect(returnArray[0]).to.equal(title);
        expect(returnArray[1]).to.equal(url);
    });
});

SpecEnd
