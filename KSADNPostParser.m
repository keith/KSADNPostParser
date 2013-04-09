//
//  KSADNPostParser.m
//  Sail
//
//  Created by Keith Smiley on 2/22/13.
//  Copyright (c) 2013 Keith Smiley. All rights reserved.
//

#import "KSADNPostParser.h"
#import "KSConstants.h"

/*
 Uses regex to determine if there is a Markdown URL and parse it.
 
 From: http://stackoverflow.com/questions/9268407/how-to-convert-markdown-style-links-using-regex
 
 \[         # Literal opening bracket
    (        # Capture what we find in here
        [^@^#^\]]+ # One or more characters other than close bracket or a username or hashtag
    )        # Stop capturing
 \]         # Literal closing bracket
 \(         # Literal opening parenthesis
    (        # Capture what we find in here
        [^)]+  # One or more characters other than close parenthesis
    )        # Stop capturing
 \)         # Literal closing parenthesis
 
 */
static NSString *regexString = @"\\[([^@^#^\\]]+)\\]\\(([^)]+)\\)";


@implementation KSADNPostParser

+ (KSADNPostParser *)shared
{
    static KSADNPostParser *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[KSADNPostParser alloc] init];
    });
    
    return shared;
}

+ (NSDictionary *)postDictionaryForText:(NSString *)text
{
    if (text.length < 1) {
        return @{};
    }
    
    NSString *postText = [text copy];
    NSMutableArray *links = [NSMutableArray array];

    if ([self containsMarkdownURL:postText])
    {
        for (NSInteger i = 0; i <= [self numberOfMarkdownURLsInString:postText]; ++i)
        {
            @autoreleasepool {
                NSValue *value = [self rangeOfFirstMarkdownString:postText];
                if (!value) {
                    continue;
                }
                
                NSRange range = [value rangeValue];
                NSString *markdownString = [postText substringWithRange:range];
                NSArray *results = [self extractURLandTitleFromMarkdownString:markdownString];
                if (results.count != 2) {
                    NSLog(@"Bad extraction return: %@", results);
                    continue;
                }

                NSString *title = results[0];
                NSString *urlString = results[1];
                postText = [postText stringByReplacingCharactersInRange:range withString:title];
                NSRange titleRange = NSMakeRange(range.location, title.length);
                NSDictionary *linkDictionary = [self linkDictionaryWithPosition:titleRange.location
                                                                         length:titleRange.length
                                                                         andURL:urlString];
                [links addObject:linkDictionary];
            }
        }
        
        NSError *dataDetectorError = nil;
        NSDataDetector *dataDetector = [NSDataDetector dataDetectorWithTypes:(NSTextCheckingTypes)NSTextCheckingTypeLink error:&dataDetectorError];
        if (dataDetectorError) {
            NSLog(@"Sail: Failed to create data detector with error %@, continuing", dataDetectorError);
        } else {
            NSArray *matches = [dataDetector matchesInString:postText options:0 range:NSMakeRange(0, [postText length])];
            for (NSTextCheckingResult *result in matches)
            {
                NSRange linkRange = result.range;
                NSString *urlString = [postText substringWithRange:linkRange];
                [links addObject:[self linkDictionaryWithPosition:linkRange.location
                                                           length:linkRange.length
                                                           andURL:urlString]];
            }
        }
    }

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:postText forKey:TEXT_KEY];
    
    if (links.count > 0) {
        [dictionary setValue:@{LINKS_KEY: links} forKey:ENTITIES_KEY];
    }
    
    return dictionary;
}

+ (NSDictionary *)linkDictionaryWithPosition:(NSUInteger)position length:(NSUInteger)length andURL:(NSString *)url
{
    return @{POSITION_KEY: [NSNumber numberWithUnsignedInteger:position],
             LENGTH_KEY: [NSNumber numberWithUnsignedInteger:length],
             URL_KEY: url};
}

+ (NSUInteger)postLengthForText:(NSString *)text
{
    if (![self containsMarkdownURL:text]) {
        return text.length;
    }
    
    NSDictionary *dictionary = [self postDictionaryForText:text];
    return [[dictionary valueForKey:TEXT_KEY] length];
}

+ (NSArray *)extractURLandTitleFromMarkdownString:(NSString *)markdown
{
    if (![self possibleValidString:markdown]) {
        return @[];
    }
    
    // Locations of all punctuation
    NSUInteger openBracketLocation = [markdown rangeOfString:@"["].location;
    NSUInteger closeBracketLocation = [markdown rangeOfString:@"]"].location;
    NSUInteger openParenLocation = [markdown rangeOfString:@"("].location;
    NSUInteger closeParenLocation = [markdown rangeOfString:@")"].location;
    
    // Total length of the title and URL minus the punctuation character
    NSUInteger titleLength = closeBracketLocation - openBracketLocation - 1;
    NSUInteger urlLength = closeParenLocation - openParenLocation - 1;
    
    // Get the appropriate substrings
    NSString *title = [markdown substringWithRange:NSMakeRange(openBracketLocation + 1, titleLength)];
    NSString *urlString = [markdown substringWithRange:NSMakeRange(openParenLocation + 1, urlLength)];
    
    return @[title, urlString];
}

// Loosely checks that the string is of the valid format [title](URL)
+ (BOOL)possibleValidString:(NSString *)text
{
    text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([text characterAtIndex:0] != '[' ||
        [text characterAtIndex:text.length - 1] != ')' ||
        [text rangeOfString:@"]"].location == NSNotFound ||
        [text rangeOfString:@"("].location == NSNotFound)
    {
        return false;
    }
    
    return true;
}

+ (BOOL)containsMarkdownURL:(NSString *)text
{
    return [self numberOfMarkdownURLsInString:text] > 0;
}

+ (NSUInteger)numberOfMarkdownURLsInString:(NSString *)text
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString
                                                                           options:0
                                                                             error:nil];
    
    return [regex numberOfMatchesInString:text options:0 range:NSMakeRange(0, [text length])];
}

+ (NSValue *)rangeOfFirstMarkdownString:(NSString *)text
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString
                                                                           options:0
                                                                             error:nil];
    
    NSTextCheckingResult *match = [regex firstMatchInString:text options:0 range:NSMakeRange(0, [text length])];
    if (match) {
        return [NSValue valueWithRange:[match range]];
    }
    
    return nil;
}

+ (NSArray *)rangesOfMarkdownURLStrings:(NSString *)text
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString
                                                                           options:0
                                                                             error:nil];
    
    NSMutableArray *ranges = [NSMutableArray array];
    NSArray *matches = [regex matchesInString:text options:0 range:NSMakeRange(0, [text length])];
    for (NSTextCheckingResult *result in matches)
    {
        [ranges addObject:[NSValue valueWithRange:result.range]];
    }
    
    return ranges;
}

@end
