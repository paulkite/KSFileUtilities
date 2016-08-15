//
//  KSURLFormatter.m
//
//  Created by Mike Abdullah
//  Copyright © 2008 Karelia Software
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "KSURLFormatter.h"

#import "KSURLUtilities.h"
//#import "NSURL+IFUnicodeURL.h"


@implementation KSURLFormatter

#pragma mark Class Methods

+ (NSURL *)URLFromString:(NSString *)string;
{
    // Encode the URL string
    CFStringRef escapedString = CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                        (CFStringRef)string,
                                                                        (CFStringRef)@"%+#",
                                                                        NULL,
                                                                        kCFStringEncodingUTF8);
    
    
    // If we're still left with a valid string, turn it into a URL
    NSURL *result = nil;
    if (escapedString)
    {
        // Any hashes after first # needs to be escaped. e.g. Apple's dev docs hand out URLs like this
        NSRange range = [(__bridge NSString *)escapedString rangeOfString:@"#"];
        if (range.location != NSNotFound)
        {
            NSRange postFragmentRange = NSMakeRange(NSMaxRange(range), ((__bridge NSString *)escapedString).length - NSMaxRange(range));
            range = [(__bridge NSString *)escapedString rangeOfString:@"#" options:0 range:postFragmentRange];
            
            if (range.location != NSNotFound)
            {
                NSString *extraEscapedString = [(__bridge NSString *)escapedString stringByReplacingOccurrencesOfString:@"#"
                                                                                                    withString:@"%23"   // not ideal, encoding ourselves
                                                                                                       options:0
                                                                                                         range:postFragmentRange];
                
                CFRelease(escapedString);
                return [NSURL URLWithString:extraEscapedString];
            }
        }
        
        result = [NSURL URLWithString:(__bridge NSString *)escapedString];
        CFRelease(escapedString);
    }
    
    return result;
}

+ (BOOL)isValidEmailAddress:(NSString *)address;
{
    // for now, just validate that syntactically it it at least _@_.__
	// though we are not checking actual other characters.
    // we can refine this over time
    NSRange whereAt = [address rangeOfString:@"@"];
    BOOL OK = (whereAt.location != NSNotFound && whereAt.location >= 1);	// make sure there is an @ and it's not the first character
	if (OK)
	{
		NSInteger len = address.length - whereAt.location;
		NSRange whereDot = [address rangeOfString:@"." options:0 range:NSMakeRange(whereAt.location, len)];
		OK = (whereDot.location != NSNotFound);
		if (OK)
		{
			// make sure there is room between the @ and the .
			OK = (whereDot.location - whereAt.location >= 2) && (address.length - whereDot.location >= 3);
		}
	}
	return OK;
}

+ (BOOL)isLikelyEmailAddress:(NSString *)address;
{
    BOOL result = [self isValidEmailAddress:address];
    if (result)
    {
        NSURL *URL = [[NSURL alloc] initWithString:address];
        if (URL)
        {
            // Account for strings like http://example.com/@foo which seem to be technically valid as an email address, but unlikely to be one
            if (URL.scheme) result = NO;
        }
    }
    
    return result;
}

#pragma mark Init & Dealloc

- (instancetype)init
{
    if (self = [super init])
    {
        _defaultScheme = @"http";
        _fallbackTopLevelDomain = @"com";
    }
    return self;
}

#pragma mark Managing Behaviour

@synthesize useDisplayNameForFileURLs = _useDisplayNameForFileURLs;
@synthesize defaultScheme = _defaultScheme;

@synthesize allowedSchemes = _allowedSchemes;
- (void)setAllowedSchemes:(NSArray *)schemes;
{
    if (schemes) NSParameterAssert([schemes count] > 0);
    
    schemes = [schemes copy];
    _allowedSchemes = schemes;
}

@synthesize fallbackTopLevelDomain = _fallbackTopLevelDomain;

#pragma mark Textual Representation of Cell Content

- (NSString *)stringForObjectValue:(id)anObject
{
    if ([anObject isKindOfClass:[NSString class]])
    {
        anObject = [NSURL URLWithString:anObject];
    }
    
    if (![anObject isKindOfClass:[NSURL class]]) return [anObject description];
    
    NSURL *URL = anObject;
    
    NSString *result;
    if (self.useDisplayNameForFileURLs && [anObject isFileURL])
    {
        result = [[NSFileManager defaultManager] displayNameAtPath:URL.path];
    }
    else
    {
        result = URL.absoluteString;
        
        // Append trailing slash if needed
        if ([URL ks_hasNetworkLocation] && [URL.path isEqualToString:@""])
        {
            result = [result stringByAppendingString:@"/"];
        }
    }
    
    return result;
}

#pragma mark Object Equivalent to Textual Representation

+ (NSURL *)URLFromString:(NSString *)string useValueTransformerIfAvailable:(BOOL)useValueTransformer;
{
    NSURL *result = nil;
    if (useValueTransformer) result = [[self encodeStringValueTransformer] transformedValue:string];
    if (!result) result = [self URLFromString:string];
    return result;
}

+ (NSURL *)URLFromString:(NSString *)string defaultScheme:(NSString *)fallbackScheme
{
    return [self URLFromString:string defaultScheme:fallbackScheme appendTrailingSlashToPaths:NO];
}

+ (NSURL *)URLFromString:(NSString *)string defaultScheme:(NSString *)fallbackScheme appendTrailingSlashToPaths:(BOOL)appendTrailingSlashToPaths
{
	//  Tries to interpret the string as a complete URL. If there is no scheme specified, try it as an email address. If that doesn't seem reasonable, combine with fallbackScheme

    
    // Use value transformer when possible. For some strings it will produce nothing, or it won't be available, so then fall back to our cruder routine
    NSURL *result = [self URLFromString:string useValueTransformerIfAvailable:YES];
    
    
    // Allow fragment links as-is
	if ([string hasPrefix:@"#"] && (string.length > (@"#").length && result))
    {
        return result;
    }
    
    
	// This is probably a really naive check
	if ((!result.scheme && ![string hasPrefix:@"/"]) ||   // e.g. foo
        (!result.host))                                   // e.g. foo.com:8888
	{
        // if it looks like an email address, use mailto:
        if ([self isLikelyEmailAddress:string])
        {
            result = [NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@", string]];
        }
		else
        {
            NSString *scheme = result.scheme;
            
            if (!scheme || (!result.fileURL &&
                            [scheme caseInsensitiveCompare:@"javascript"] != NSOrderedSame))
            {
                result = [self URLFromString:[NSString stringWithFormat:
                                              @"%@://%@",
                                              fallbackScheme,
                                              string]
              useValueTransformerIfAvailable:YES];
            }
        }
	}
    
    
    // Append a trailing slash if needed
    if ([result ks_hasNetworkLocation])
    {
        NSURLComponents *components = [NSURLComponents componentsWithString:result.absoluteString];

        if ([components.path isEqualToString:@""])
        {
            components.path = @"/";
        }
        else if ([components.path isEqualToString:@"/"] == NO &&
                 [[components.path substringFromIndex:components.path.length - 1] isEqualToString:@"/"] == NO &&
                 appendTrailingSlashToPaths)
        {
            components.path = [components.path stringByAppendingString:@"/"];
        }
        
        result = components.URL;
    }
	
    return result;
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error
{
    if (anObject)
    {
        NSURL *URL = [self URLFromString:string];
        if (self.generatesURLStrings)
        {
            *anObject = URL.absoluteString;
        }
        else
        {
            *anObject = URL;
        }
    }
    
    return YES;
}

- (NSURL *)URLFromString:(NSString *)string;
{
    NSURL *result = nil;
    
    if (string.length > 0)
    {
        result = [KSURLFormatter URLFromString:string
                                 defaultScheme:self.defaultScheme
                    appendTrailingSlashToPaths:self.appendTrailingSlashToPaths];
        
        // Does the URL have no useful resource specified? If so, generate nil URL
        if (result && !result.fileURL)
        {
            NSString *scheme = result.scheme;
            if ([scheme caseInsensitiveCompare:@"mailto"] != NSOrderedSame &&
                [scheme caseInsensitiveCompare:@"javascript"] != NSOrderedSame)
            {
                NSString *resource = result.resourceSpecifier;
                if (resource.length == 0 ||
                    [resource isEqualToString:@"/"] ||
                    [resource isEqualToString:@"//"])
                {
                    result = nil;
                }
                
                
                
                // URLs should also really have a host and a path
                if (result)
                {
                    NSString *host = result.host;
                    NSString *path = result.path;
                    if (!host && !path && !result.fragment)
                    {
                        result = nil;
                    }
                }
            }
        }
        
        
        // Did the user not enter a top-level domain? We'll guess for them
        if (result && !result.fileURL && self.fallbackTopLevelDomain)
        {
            if ([result ks_domains].count == 1)
            {
                NSString *urlString = [NSString stringWithFormat:
                                       @"%@://%@.%@/",
                                       result.scheme,
                                       result.host,
                                       self.fallbackTopLevelDomain];
                result = [self URLFromString:urlString];
            }
        }
        
        
        // Make sure the scheme is allowed
        NSArray *allowedSchemes = self.allowedSchemes;
        if (allowedSchemes)
        {
            NSString *scheme = result.scheme;
            if (scheme && ![allowedSchemes containsObject:result.scheme])
            {
                // Look for the best matching scheme based on the assumption that the URL was simply pasted in missing a small number of initial characters
                for (NSString *aScheme in allowedSchemes)
                {
                    if ([aScheme hasSuffix:scheme])
                    {
                        result = [result ks_URLWithScheme:aScheme];
                        return result;
                    }
                }
                
                // Nothing matched? Alright, go for the first one then
                result = [result ks_URLWithScheme:allowedSchemes[0]];
            }
        }
    }
    
    return result;
}

@synthesize generatesURLStrings = _generateStrings;

#pragma mark Value Transformer Backend

static NSValueTransformer *_transformer;

+ (NSValueTransformer *)encodeStringValueTransformer;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _transformer = [NSValueTransformer valueTransformerForName:@"KSEncodeURLString"];
    });
    
    return _transformer;
}

+ (void)setEncodeStringValueTransformer:(NSValueTransformer *)transformer;
{
    [self encodeStringValueTransformer]; // ensure initial search has run
    
    if (transformer != _transformer) return;
	_transformer = transformer;
    
    if (![[[transformer class] transformedValueClass] isSubclassOfClass:[NSURL class]])
    {
        NSLog(@"Internationalized Domain Name value transformer appears not to output URLs");
    }
}

@end
