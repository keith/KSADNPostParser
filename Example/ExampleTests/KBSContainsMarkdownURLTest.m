//
//  KBSContainsMarkdownURLTest.m
//  Example
//
//  Created by Keith Smiley on 4/9/13.
//  Copyright (c) 2013 Keith Smiley. All rights reserved.
//

#import "KBSCommon.h"

SpecBegin(ContainsMarkdown)

describe(@"containsMarkdownURL", ^{
    it(@"should return true when there is a markdown url", ^{
        NSString *post = @"This is a string with a [url](https://github.com/)";
        expect([[KSADNPostParser shared] containsMarkdownURL:post]).to.equal(true);
    });
    
    it(@"should return true when there are multiple markdown urls", ^{
        NSString *post = @"This is a [string](https://github.com/petejkim/expecta/) with many [markdown](http://daringfireball.net/projects/markdown/) URLs";
        expect([[KSADNPostParser shared] containsMarkdownURL:post]).to.equal(true);
    });
    
    it(@"should return false when there isn't a markdown url", ^{
        NSString *post = @"This is a post";
        expect([[KSADNPostParser shared] containsMarkdownURL:post]).to.equal(false);
    });
    
    it(@"should catch invalid markdown", ^{
        NSString *post = @"This is a post with a [url(http://google.com/)";
        expect([[KSADNPostParser shared] containsMarkdownURL:post]).to.equal(false);
    });
    
    it(@"should not allow either piece of the markdown to be empty", ^{
        NSString *post = @"[url]()";
        expect([[KSADNPostParser shared] containsMarkdownURL:post]).to.equal(false);
        
        post = @"[]()";
        expect([[KSADNPostParser shared] containsMarkdownURL:post]).to.equal(false);
        
        post = @"[](http://google.com)";
        expect([[KSADNPostParser shared] containsMarkdownURL:post]).to.equal(false);
    });
    
    it(@"should not allow invalid characters in the anchor text", ^{
        NSString *post = @"[@keith](http://google.com)";
        expect([[KSADNPostParser shared] containsMarkdownURL:post]).to.equal(false);
        
        post = @"[kei@th](http://google.com)";
        expect([[KSADNPostParser shared] containsMarkdownURL:post]).to.equal(false);
        
        post = @"[#keith](http://google.com)";
        expect([[KSADNPostParser shared] containsMarkdownURL:post]).to.equal(false);
        
        post = @"[ke#ith](http://google.com)";
        expect([[KSADNPostParser shared] containsMarkdownURL:post]).to.equal(false);

        post = @"[ke.th](http://google.com)";
        expect([[KSADNPostParser shared] containsMarkdownURL:post]).to.equal(false);
    });
    
    it(@"should allow strange URLs", ^{
        NSString *post = @"[wikipedia](http://en.wikipedia.org/wiki/Monad_(functional_programming))";
        expect([[KSADNPostParser shared] containsMarkdownURL:post]).to.equal(true);
    });
});

SpecEnd
