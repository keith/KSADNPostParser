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
    
    it(@"should return an dictionary with correct metadata", ^{
        NSString *post = @"This is a string with a [url](https://github.com/)";
        NSString *cleanPost = @"This is a string with a url";
        NSDictionary *dictionary = [[KSADNPostParser shared] postDictionaryForText:post];
        expect(dictionary.count).to.equal(2);
        
        NSString *postText = [dictionary valueForKey:TEXT_KEY];
        expect(postText).to.equal(cleanPost);
        
        NSDictionary *entities = [dictionary valueForKey:ENTITIES_KEY];
        expect(entities.count).to.equal(1);
        
        NSArray *links = [entities valueForKey:LINKS_KEY];
        expect(links.count).to.equal(1);
        
        NSDictionary *link = [links objectAtIndex:0];
        NSUInteger position = [[link valueForKey:POSITION_KEY] unsignedIntegerValue];
        expect(position).to.equal(24);
        NSUInteger length = [[link valueForKey:LENGTH_KEY] unsignedIntegerValue];
        expect(length).to.equal(3);
        NSString *url = [link valueForKey:URL_KEY];
        expect(url).to.equal(@"https://github.com/");
    });
});

SpecEnd