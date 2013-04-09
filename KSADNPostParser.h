//
//  KSADNPostParser.h
//  Sail
//
//  Created by Keith Smiley on 2/22/13.
//  Copyright (c) 2013 Keith Smiley. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KSADNPostParser : NSObject

/*
 Parameter: NSString, the post text
 
 Return: NSDictionary
    Returns an NSDictionary containing all the post metadata
        including the links array in the entites key for each
        Markdown formatted link
 
 NOTE:
    If you need other items in your post dictionary you'll
        have to deal with that elsewhere
    You still need to put the user's access token as an HTTP header field
 */
+ (NSDictionary *)postDictionaryForText:(NSString *)text;

/*
 Parameter: NSString, the post text
 
 Return: NSUInteger
    Returns the length of the given text after embedding the
        Markdown formatted links
 */
+ (NSUInteger)postLengthForText:(NSString *)text;


/*
 Parameter: NSString, the string of the Markdown text.
    EX: [some anchor text](http://thewebsite.com/)
 
 Return: NSArray, contains two NSStrings
    Returns an array of length 2 (unless there's an error)
    The first item is the title
        EX: some anchor text
    The second item is the URL
        EX: http://thewebsite.com/
 
    NOTE:
        Check to make sure the array contains 2 items, otherwise
            the string was formatted correctly.
        String MUST be in the format [anchor](url)
 */
+ (NSArray *)extractURLandTitleFromMarkdownString:(NSString *)markdown;


/*
 Parameter: NSString, the string of Markdown text
    EX: [some anchor text](http://thewebsite.com/)
 
 Return: BOOL
    true if the string appears to be formatted correctly
    false if the string is incorrectly formatted
 
 NOTE:
    This is not a perfect check
        It checks that the first and last characters are [ and ) respectively
        It checks that ] and ( are also in the string
 */
+ (BOOL)possibleValidString:(NSString *)text;


/*
 Parameter: NSString of the text for posting
    EX: This is my post [mysite](http://website.com)
        This is some post
 
 Return: BOOL
    true if a valid Markdown string is found
    false if no Markdown url formatted string is found
 */
+ (BOOL)containsMarkdownURL:(NSString *)text;


/*
 Parameter: NSString of the text for posting
    EX: This is my post [mysite](http://website.com)
        This is some post
 
 Return: NSUInteger
    returns the number of valid Markdown formatted URLs in the string
 */
+ (NSUInteger)numberOfMarkdownURLsInString:(NSString *)text;


/*
 Parameter: NSString of the text for posting
    EX: This is my post [mysite](http://website.com)
        This is some post
 
 Return: NSValue containing NSRange
    returns the NSRange of the first Markdown formatted string
        Access with `[value rangeValue]
    if there is no Markdown formatted string it returns nil
 
 */
+ (NSValue *)rangeOfFirstMarkdownString:(NSString *)text;


/*
 Parameter: NSString of the text for posting
    EX: This is my post [mysite](http://website.com)
        This is some post
 
 Return: NSArray of NSValues containing NSRanges
    returns an array of NSValues containing the NSRanges
        of each match in the string. Access with `[array[index] rangeValue]`
 
 NOTE:
    I you attept to loop through this while replacing the text in the string
        watch out for changing ranges
 */
+ (NSArray *)rangesOfMarkdownURLStrings:(NSString *)text;

@end
