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
 [^\]]+ # One or more characters other than close bracket or a username or hashtag
 )        # Stop capturing
 \]         # Literal closing bracket
 \(         # Literal opening parenthesis
 (        # Capture what we find in here
 \S+(?=\))  # Find as many non-whitespace-characters but ensure that there is a ) afterwards
 )        # Stop capturing
 \)         # Literal closing parenthesis

 */

static NSString *titleRegex  = @"\\[([^\\]]+)\\]";
static NSString *urlRegex    = @"\\(\\S+(?=\\))\\)";
static NSString *regexString = @"\\[([^\\]]+)\\]\\(\\S+(?=\\))\\)";
static NSString *errorDomain = @"com.keithsmiley.KSADNPostParser";

typedef NS_ENUM(NSInteger, KSADNPostParserError) {
    KSADNInvalidMarkdown = -1000
};

@interface KSADNPostParser ()
@property (nonatomic, strong) NSDataDetector *dataDetector;
@property (nonatomic, strong) NSRegularExpression *regex;
@property (nonatomic, strong) NSCharacterSet *invalidCharacters;
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

    self.dataDetector      = [NSDataDetector dataDetectorWithTypes:(NSTextCheckingTypes)NSTextCheckingTypeLink error:nil];
    self.regex             = [NSRegularExpression regularExpressionWithPattern:regexString options:0 error:nil];
    self.invalidCharacters = [NSCharacterSet characterSetWithCharactersInString:@"#@"];

    return self;
}

#pragma mark

- (void)postDictionaryForText:(NSString *)text withBlock:(void(^)(NSDictionary *dictionary, NSError *error))block
{
    NSParameterAssert(text);
    NSParameterAssert(block);

    if (text.length < 1) {
        block(nil, nil);
        return;
    }

    NSString *postText = [text copy];
    NSMutableArray *links = [NSMutableArray array];
    NSString *errorText = @"";

    if ([self containsMarkdownURL:postText]) {
        BOOL hasTitleError = false;
        NSUInteger numberOfMatches  = [self numberOfMarkdownURLsInString:postText];
        NSMutableArray *titleRanges = [NSMutableArray array];

        for (NSUInteger i = 0; i < numberOfMatches; i++) {
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
                }

                if (!hasTitleError && [title rangeOfCharacterFromSet:self.invalidCharacters].location != NSNotFound) {
                    errorText = [NSString stringWithFormat:@"%@\n%@", NSLocalizedString(@"Usernames and hashtags are not allowed in the title", nil), errorText];
                    hasTitleError = true;
                }

                postText = [postText stringByReplacingCharactersInRange:range withString:title];
                NSRange titleRange = NSMakeRange(range.location, title.length);
                [titleRanges addObject:[NSValue valueWithRange:titleRange]];

                NSDictionary *linkDictionary = [self linkDictionaryWithPosition:titleRange.location length:titleRange.length andURL:urlString];
                [links addObject:linkDictionary];
            }
        }

        if (errorText.length > 0) {
            NSString *errorTitle = NSLocalizedString(@"Invalid inline URL", nil);
            NSError *error = [NSError errorWithDomain:errorDomain code:KSADNInvalidMarkdown userInfo:@{NSLocalizedDescriptionKey: errorTitle, NSLocalizedRecoverySuggestionErrorKey: errorText}];
            block(nil, error);

            return;
        }

        NSArray *matches = [self.dataDetector matchesInString:postText options:0 range:NSMakeRange(0, [postText length])];
        for (NSTextCheckingResult *result in matches) {
            NSRange linkRange = result.range;
            BOOL overlaps = false;

            for (NSValue *value in titleRanges) {
                NSRange aTitleRange  = [value rangeValue];
                NSRange intersection = NSIntersectionRange(linkRange, aTitleRange);
                if (intersection.length > 0) {
                    overlaps = true;
                    break;
                }
            }

            if (overlaps) {
                continue;
            }

            NSString *urlString = [postText substringWithRange:linkRange];
            [links addObject:[self linkDictionaryWithPosition:linkRange.location length:linkRange.length andURL:urlString]];
        }
    }

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:postText forKey:TEXT_KEY];

    if (links.count > 0) {
        [dictionary setValue:@{LINKS_KEY: links} forKey:ENTITIES_KEY];
    }

    block(dictionary, nil);
}

- (NSDictionary *)linkDictionaryWithPosition:(NSUInteger)position length:(NSUInteger)length andURL:(NSString *)url
{
    return @{POSITION_KEY: [NSNumber numberWithUnsignedInteger:position], LENGTH_KEY: [NSNumber numberWithUnsignedInteger:length], URL_KEY: [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]};
}

- (NSUInteger)postLengthForText:(NSString *)text
{
    if (![self containsMarkdownURL:text]) {
        return [self emojiLengthForText:text];
    }

    __block NSDictionary *returnDictionary = nil;
    [self postDictionaryForText:text withBlock:^(NSDictionary *dictionary, NSError *error) {
        returnDictionary = dictionary;
    }];

    NSString *returnText = [returnDictionary valueForKey:TEXT_KEY];
    if (returnText) {
        return [self emojiLengthForText:returnText];
    } else {
        return [self emojiLengthForText:text];
    }
}

- (NSUInteger)emojiLengthForText:(NSString *)text
{
    __block NSUInteger length = 0;
    [text enumerateSubstringsInRange:NSMakeRange(0, text.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        length++;
    }];

    return length;
}

- (NSArray *)extractURLandTitleFromMarkdownString:(NSString *)markdown
{
    NSRange titleSectionRange = [markdown rangeOfString:titleRegex options:NSRegularExpressionSearch];
    NSRange urlSectionRange = [markdown rangeOfString:urlRegex options:NSRegularExpressionSearch];

    if (![self possibleValidString:markdown] || titleSectionRange.location == NSNotFound || urlSectionRange.location == NSNotFound) {
        return @[];
    }

    NSString *title     = [markdown substringWithRange:NSMakeRange(titleSectionRange.location + 1, titleSectionRange.length - 2)];
    NSString *urlString = [markdown substringWithRange:NSMakeRange(urlSectionRange.location + 1, urlSectionRange.length - 2)];

    return @[title, urlString];
}

// Loosely checks that the string is of the valid format [title](URL)
- (BOOL)possibleValidString:(NSString *)text
{
    text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![text hasPrefix:@"["] ||
        ![text hasSuffix:@")"] ||
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

- (NSString *)twitterTextFromString:(NSString *)text
{
    if (![self containsMarkdownURL:text]) {
        return text;
    }

    NSArray *ranges = [self rangesOfMarkdownURLStrings:text];
    if (ranges.count < 1) {
        return text;
    }

    for (NSValue *value in [ranges reverseObjectEnumerator]) {
        @autoreleasepool {
            NSRange theRange = [value rangeValue];
            if (theRange.length < 1) {
                continue;
            }

            NSString *markdownString = [text substringWithRange:theRange];
            NSArray *results = [self extractURLandTitleFromMarkdownString:markdownString];
            if (results.count != 2) {
                continue;
            }

            NSString *title = results[0];
            NSString *urlString = results[1];
            NSString *cleanedMarkdown = [NSString stringWithFormat:@"%@ %@", title, urlString];
            text = [text stringByReplacingCharactersInRange:theRange withString:cleanedMarkdown];
        }
    }

    return text;
}

@end
