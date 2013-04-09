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
        [^@#\.\]]+ # One or more characters other than close bracket or a username or hashtag
    )        # Stop capturing
 \]         # Literal closing bracket
 \(         # Literal opening parenthesis
    (        # Capture what we find in here
        \S+(?=\))  # Find as many non-whitespace-characters but ensure that there is a ) afterwards
    )        # Stop capturing
 \)         # Literal closing parenthesis
 
 */
static NSString *regexString = @"\\[([^@#\\.\\]]+)\\]\\(\\S+(?=\\))\\)";
static NSString *invalidRegx = @"\\[([^\\]]+)\\]\\(\\S+(?=\\))\\)";
static NSString *errorDomain = @"com.keithsmiley.KSADNPostParser";

typedef NS_ENUM(NSInteger, KSADNPostParserError) {
    KSADNInvalidURL = -1000
};

@interface KSADNPostParser ()
@property (nonatomic, strong) NSDataDetector *dataDetector;
@property (nonatomic, strong) NSRegularExpression *regex;
@end

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

- (id)init
{
    self = [super init];
    if (!self) {
        return nil;
    }

    self.dataDetector = [NSDataDetector dataDetectorWithTypes:(NSTextCheckingTypes)NSTextCheckingTypeLink error:nil];
    self.regex = [NSRegularExpression regularExpressionWithPattern:regexString options:0 error:nil];
    
    return self;
}

#pragma mark

- (void)postDictionaryForText:(NSString *)text withBlock:(void(^)(NSDictionary *dictionary, NSError *error))block
{
    if (text.length < 1) {
        if (block) {
            block(nil, nil);
        }
        
        return;
    }
    
    NSString *postText = [text copy];
    NSMutableArray *links = [NSMutableArray array];
    NSString *errorText = @"";

    if ([self containsMarkdownURL:postText])
    {
        NSInteger numberOfErrors = 0;
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
                NSUInteger matches = [self.dataDetector numberOfMatchesInString:urlString options:0 range:NSMakeRange(0, [urlString length])];
                if (matches < 1) {
                    // Handle error
                    errorText = [errorText stringByAppendingFormat:@"'%@' %@\n", urlString, NSLocalizedString(@"is an invalid URL", nil)];
                    numberOfErrors++;
                }
                
                // TODO: Fix this
                matches = [self.dataDetector numberOfMatchesInString:title options:0 range:NSMakeRange(0, [title length])];
                if (matches < 1) {
                    errorText = [errorText stringByAppendingFormat:@"'%@' %@\n", title, NSLocalizedString(@"Usernames, hashtags and URLs are invalid in the link's title", nil)];
                    numberOfErrors++;
                }

                postText = [postText stringByReplacingCharactersInRange:range withString:title];
                NSRange titleRange = NSMakeRange(range.location, title.length);
                NSDictionary *linkDictionary = [self linkDictionaryWithPosition:titleRange.location
                                                                         length:titleRange.length
                                                                         andURL:urlString];
                [links addObject:linkDictionary];
            }
        }
        
        if (errorText.length > 0) {
            NSString *errorTitle = NSLocalizedString(@"Invalid URL", nil);
            if (numberOfErrors > 1) {
                errorTitle = NSLocalizedString(@"Invalid URLs", nil);
            }
            
            NSError *error = [NSError errorWithDomain:errorDomain code:KSADNInvalidURL userInfo:@{NSLocalizedDescriptionKey: errorTitle, NSLocalizedRecoverySuggestionErrorKey: errorText}];
            if (block) {
                block(nil, error);
            }
            
            return;
        }

        NSArray *matches = [self.dataDetector matchesInString:postText options:0 range:NSMakeRange(0, [postText length])];
        for (NSTextCheckingResult *result in matches)
        {
            NSRange linkRange = result.range;
            NSString *urlString = [postText substringWithRange:linkRange];
            [links addObject:[self linkDictionaryWithPosition:linkRange.location
                                                       length:linkRange.length
                                                       andURL:urlString]];
        }
    }

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:postText forKey:TEXT_KEY];
    
    if (links.count > 0) {
        [dictionary setValue:@{LINKS_KEY: links} forKey:ENTITIES_KEY];
    }

    if (block) {
        block(dictionary, nil);
    }
}

- (NSDictionary *)linkDictionaryWithPosition:(NSUInteger)position length:(NSUInteger)length andURL:(NSString *)url
{
    return @{POSITION_KEY: [NSNumber numberWithUnsignedInteger:position],
             LENGTH_KEY: [NSNumber numberWithUnsignedInteger:length],
             URL_KEY: url};
}

- (void)postLengthForText:(NSString *)text withBlock:(void(^)(NSUInteger length))block
{
    if (![self containsMarkdownURL:text]) {
        if (block) {
            block(text.length);
        }
        
        return;
    }

    [self postDictionaryForText:text withBlock:^(NSDictionary *dictionary, NSError *error) {
        if (block) {
            if (dictionary) {
                block([[dictionary valueForKey:TEXT_KEY] length]);
            } else {
                block(text.length);
            }
        }
    }];
}

- (NSArray *)extractURLandTitleFromMarkdownString:(NSString *)markdown
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
- (BOOL)possibleValidString:(NSString *)text
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

- (BOOL)containsMarkdownURL:(NSString *)text
{
    return [self numberOfMarkdownURLsInString:text] > 0;
}

- (NSUInteger)numberOfMarkdownURLsInString:(NSString *)text
{
    return [self.regex numberOfMatchesInString:text options:0 range:NSMakeRange(0, [text length])];
}

- (NSValue *)rangeOfFirstMarkdownString:(NSString *)text
{
    NSTextCheckingResult *match = [self.regex firstMatchInString:text options:0 range:NSMakeRange(0, [text length])];
    if (match) {
        return [NSValue valueWithRange:[match range]];
    }
    
    return nil;
}

- (NSArray *)rangesOfMarkdownURLStrings:(NSString *)text
{
    NSMutableArray *ranges = [NSMutableArray array];
    NSArray *matches = [self.regex matchesInString:text options:0 range:NSMakeRange(0, [text length])];
    for (NSTextCheckingResult *result in matches)
    {
        [ranges addObject:[NSValue valueWithRange:result.range]];
    }
    
    return ranges;
}

@end
