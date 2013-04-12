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
    it(@"should return nil when there's no text", ^{
        NSString *post = @"";

        [[KSADNPostParser shared] postDictionaryForText:post withBlock:^(NSDictionary *dictionary, NSError *error) {
            expect(dictionary).to.equal(nil);
            expect(error).to.equal(nil);
        }];
    });

    it(@"should return an empty dictionary for text with no URL", ^{
      NSString *post = @"Some random post text";
      [[KSADNPostParser shared] postDictionaryForText:post withBlock:^(NSDictionary *dictionary, NSError *error) {
        expect(dictionary.count).to.equal(1);
        expect(error).to.equal(nil);
        expect([dictionary valueForKey:TEXT_KEY]).to.equal(post);
      }];
    });
    
    it(@"should return an dictionary with correct metadata", ^{
        NSString *post = @"This is a string with a [url](https://github.com/)";
        NSString *cleanPost = @"This is a string with a url";

        [[KSADNPostParser shared] postDictionaryForText:post withBlock:^(NSDictionary *dictionary, NSError *error) {
            expect(error).to.equal(nil);
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
        }];
    });
    
    it(@"should have a correctly formatted error", ^{
      NSString *post = @"A string with an [invalid](fakeurl)";

      [[KSADNPostParser shared] postDictionaryForText:post withBlock:^(NSDictionary *dictionary, NSError *error) {
          expect(dictionary).to.equal(nil);
          expect(error).notTo.equal(nil);
          NSDictionary *info = [error userInfo];
          
          NSString *body = [info valueForKey:NSLocalizedRecoverySuggestionErrorKey];
          expect([body rangeOfString:@"invalid"].location == NSNotFound).to.equal(false);
      }];
    
      post = @"A string with a [@username](url)";
      [[KSADNPostParser shared] postDictionaryForText:post withBlock:^(NSDictionary *dictionary, NSError *error) {
        expect(dictionary).to.equal(nil);
        expect(error).notTo.equal(nil);
        NSDictionary *info = [error userInfo];
        expect(info).notTo.equal(nil);
        
        NSString *body = [info valueForKey:NSLocalizedRecoverySuggestionErrorKey];
        expect([body rangeOfString:@"Usernames"].location == NSNotFound).to.equal(false);
      }];
    });
  
    describe(@"invalid title characters", ^{
      it(@"should allow dots in the title", ^{
        NSString *post = @"This is [val.id](https://github.com/)";
        [[KSADNPostParser shared] postDictionaryForText:post withBlock:^(NSDictionary *dictionary, NSError *error) {
          expect(error).to.equal(nil);
          expect(dictionary.count).to.equal(2);
          expect([dictionary valueForKey:TEXT_KEY]).to.equal(@"This is val.id");
        }];
      });
      
      it(@"should not allow URLs in the title", ^{
        NSString *post = @"[https://github.com/](https://github.com/)";
        [[KSADNPostParser shared] postDictionaryForText:post withBlock:^(NSDictionary *dictionary, NSError *error) {
          expect(dictionary).to.equal(nil);
          expect(error).notTo.equal(nil);
          NSDictionary *userInfo = [error userInfo];
          NSString *body = [userInfo valueForKey:NSLocalizedRecoverySuggestionErrorKey];
          expect([body rangeOfString:@"Usernames"].location == NSNotFound).to.equal(false);
        }];
      });
      
      it(@"should not allow @ signs in the title", ^{
        NSString *post = @"This is [@invalid](https://github.com/)";
        [[KSADNPostParser shared] postDictionaryForText:post withBlock:^(NSDictionary *dictionary, NSError *error) {
          expect(dictionary).to.equal(nil);
          expect(error).notTo.equal(nil);
          NSDictionary *userInfo = [error userInfo];
          NSString *body = [userInfo valueForKey:NSLocalizedRecoverySuggestionErrorKey];
          expect([body rangeOfString:@"Usernames"].location == NSNotFound).to.equal(false);
        }];
      });
      
      it(@"should not allow # symbols in the title", ^{
        NSString *post = @"This is [#invalid](https://github.com/)";
        [[KSADNPostParser shared] postDictionaryForText:post withBlock:^(NSDictionary *dictionary, NSError *error) {
          expect(dictionary).to.equal(nil);
          expect(error).notTo.equal(nil);
          NSDictionary *userInfo = [error userInfo];
          NSString *body = [userInfo valueForKey:NSLocalizedRecoverySuggestionErrorKey];
          expect([body rangeOfString:@"Usernames"].location == NSNotFound).to.equal(false);
        }];
      });
    });
  
    it(@"should have a different url with multiple invalid URLs", ^{
      NSString *post = @"A string with multiple [invalid](fakeurl) and [something](else)";

      [[KSADNPostParser shared] postDictionaryForText:post withBlock:^(NSDictionary *dictionary, NSError *error) {
        expect(dictionary).to.equal(nil);
        expect(error).notTo.equal(nil);
        NSDictionary *info = [error userInfo];
        
        NSString *body = [info valueForKey:NSLocalizedRecoverySuggestionErrorKey];
        NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:@"invalid" options:0 error:nil];
        NSUInteger count = [expression numberOfMatchesInString:body options:0 range:NSMakeRange(0, [body length])];
        expect(count).to.equal(2);
        expect([body rangeOfString:@"invalid"].location != NSNotFound).to.equal(true);
      }];
    });
});

SpecEnd
