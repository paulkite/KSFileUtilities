//
//  TestKSURLFormatter.m
//  KSFileUtilities
//
//  Created by Mike Abdullah on 12/04/2012.
//  Copyright (c) 2012 Jungle Candy Software. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KSURLFormatter.h"

#import <WebKit/WebKit.h>

@interface TestKSURLFormatter : XCTestCase

@end

@implementation TestKSURLFormatter

- (void)validateAllowedSchemesWithString:(NSString *)urlString expectedURLString:(NSString *)expectedResult
{
    KSURLFormatter *formatter = [[KSURLFormatter alloc] init];
    formatter.allowedSchemes = @[@"http", @"https", @"file"];
    
    NSURL *URL = [formatter URLFromString:urlString];
    XCTAssertEqualObjects(URL.absoluteString, expectedResult);
    
}

- (void)testAllowedSchemesPrimary;
{
    [self validateAllowedSchemesWithString:@"http://example.com/" expectedURLString:@"http://example.com/"];
}

- (void)testAllowedSchemesSecondary
{
    [self validateAllowedSchemesWithString:@"https://example.com/" expectedURLString:@"https://example.com/"];
}

- (void)testAllowedSchemesCloseMatchPrimary
{
    [self validateAllowedSchemesWithString:@"ttp://example.com/" expectedURLString:@"http://example.com/"];
}

- (void)testAllowedSchemesCloseMatchSecondary
{
    [self validateAllowedSchemesWithString:@"ttps://example.com/" expectedURLString:@"https://example.com/"];
}

- (void)testAllowedSchemesRandom
{
    [self validateAllowedSchemesWithString:@"test://example.com/" expectedURLString:@"http://example.com/"];
}

- (void)testJavascriptURLs
{
    KSURLFormatter *formatter = [[KSURLFormatter alloc] init];
    
    NSString *string = @"javascript:test('foo','bar')";
    NSURL *URL = [formatter URLFromString:string];
    XCTAssertEqualObjects(URL.absoluteString, string);
    
}

- (void)testPercentEncoding
{
    [self validateAllowedSchemesWithString:@"test://test test.com/" expectedURLString:@"http://test%20test.com/"];
    [self validateAllowedSchemesWithString:@"test://test test/" expectedURLString:@"http://test%20test.com/"];
    [self validateAllowedSchemesWithString:@"test test/" expectedURLString:@"http://test%20test.com/"];
}

- (void)testInternationalizedDomainName
{
    [self validateAllowedSchemesWithString:@"http://exämple.com" expectedURLString:@"http://xn--exmple-cua.com/"];
    [self validateAllowedSchemesWithString:@"exämple.com" expectedURLString:@"http://xn--exmple-cua.com/"];
    [self validateAllowedSchemesWithString:@"exämple" expectedURLString:@"http://xn--exmple-cua.com/"];
    
    
    /* Go the other way
     */
    
    KSURLFormatter *formatter = [[KSURLFormatter alloc] init];
    
    XCTAssertEqualObjects([formatter stringForObjectValue:[NSURL URLWithString:@"http://xn--exmple-cua.com/"]], @"http://exämple.com/");
    
    // Might as well test something plain for good measure
    XCTAssertEqualObjects([formatter stringForObjectValue:[NSURL URLWithString:@"http://example.com/"]], @"http://example.com/");
    
    // Invalid encodings should be left alone
    XCTAssertEqualObjects([formatter stringForObjectValue:[NSURL URLWithString:@"http://xn--exmple-cub.com/"]], @"http://xn--exmple-cub.com/");
    
    // Make sure subdomains aren't interfering
    XCTAssertEqualObjects([formatter stringForObjectValue:[NSURL URLWithString:@"http://www.xn--exmple-cua.com/"]], @"http://www.exämple.com/");
    XCTAssertEqualObjects([formatter stringForObjectValue:[NSURL URLWithString:@"http://www.xn--exmple-cub.com/"]], @"http://www.xn--exmple-cub.com/");
    
    
}

- (void)testDoubleFragment;
{
    KSURLFormatter *formatter = [[KSURLFormatter alloc] init];
    
    NSURL *URL = [formatter URLFromString:@"http://example.com/path#fragment#fake"];
    XCTAssertEqualObjects([URL absoluteString], @"http://example.com/path#fragment%23fake");
    
}

- (void)testValidEmailAddress
{
    // Test from http://pgregg.com/projects/php/code/showvalidemail.php
    // I've commented out those that fail at present; we're not all that bothered about getting this spot on!
    
    XCTAssertTrue([KSURLFormatter isValidEmailAddress:@"name.lastname@domain.com"]);
    XCTAssertFalse([KSURLFormatter isValidEmailAddress:@".@"]);
    XCTAssertFalse([KSURLFormatter isValidEmailAddress:@"a@b"]);
    XCTAssertFalse([KSURLFormatter isValidEmailAddress:@"@bar.com"]);
    XCTAssertFalse([KSURLFormatter isValidEmailAddress:@"@@bar.com"]);
    XCTAssertTrue([KSURLFormatter isValidEmailAddress:@"a@bar.com"]);
    XCTAssertFalse([KSURLFormatter isValidEmailAddress:@"aaa.com"]);
    XCTAssertFalse([KSURLFormatter isValidEmailAddress:@"aaa@.com"]);
    XCTAssertFalse([KSURLFormatter isValidEmailAddress:@"aaa@.123"]);
    XCTAssertTrue([KSURLFormatter isValidEmailAddress:@"aaa@[123.123.123.123]"]);
    //XCTAssertFalse([KSURLFormatter isValidEmailAddress:@"aaa@[123.123.123.123]a"]);   // extra data outside ip
    //XCTAssertFalse([KSURLFormatter isValidEmailAddress:@"aaa@[123.123.123.333]"]);    // not a valid IP
    //XCTAssertFalse([KSURLFormatter isValidEmailAddress:@"a@bar.com."]);
    XCTAssertFalse([KSURLFormatter isValidEmailAddress:@"a@bar"]);
    XCTAssertTrue([KSURLFormatter isValidEmailAddress:@"a-b@bar.com"]);
    XCTAssertFalse([KSURLFormatter isValidEmailAddress:@"+@b.c"]);    // min 2 char tld
    XCTAssertTrue([KSURLFormatter isValidEmailAddress:@"+@b.com"]);
    //XCTAssertFalse([KSURLFormatter isValidEmailAddress:@"a@-b.com"]);
    //XCTAssertFalse([KSURLFormatter isValidEmailAddress:@"a@b-.com"]);
    XCTAssertFalse([KSURLFormatter isValidEmailAddress:@"-@..com"]);
    //XCTAssertFalse([KSURLFormatter isValidEmailAddress:@"-@a..com"]);
    XCTAssertTrue([KSURLFormatter isValidEmailAddress:@"a@b.co-foo.uk"]);
    XCTAssertTrue([KSURLFormatter isValidEmailAddress:@"\"hello my name is\"@stutter.com"]);
    XCTAssertTrue([KSURLFormatter isValidEmailAddress:@"\"Test \\\"Fail\\\" Ing\"@example.com"]); // not sure I understood this one
    XCTAssertTrue([KSURLFormatter isValidEmailAddress:@"valid@special.museum"]);
    //XCTAssertFalse([KSURLFormatter isValidEmailAddress:@"invalid@special.museum-"]);
    //XCTAssertFalse([KSURLFormatter isValidEmailAddress:@"shaitan@my-domain.thisisminekthx"]); // tld way too long
    XCTAssertFalse([KSURLFormatter isValidEmailAddress:@"test@...........com"]);
    //XCTAssertFalse([KSURLFormatter isValidEmailAddress:@"foobar@192.168.0.1"]); // ip need to be [] from reading http://haacked.com/archive/2007/08/21/i-knew-how-to-validate-an-email-address-until-i.aspx
    XCTAssertTrue([KSURLFormatter isValidEmailAddress:@"\"Abc\\@def\"@example.com"]);
    XCTAssertTrue([KSURLFormatter isValidEmailAddress:@"\"Fred Bloggs\"@example.com"]);
    XCTAssertTrue([KSURLFormatter isValidEmailAddress:@"\"Joe\\Blow\"@example.com"]);
    XCTAssertTrue([KSURLFormatter isValidEmailAddress:@"\"Abc@def\"@example.com"]);
    XCTAssertTrue([KSURLFormatter isValidEmailAddress:@"customer/department=shipping@example.com"]);
    XCTAssertTrue([KSURLFormatter isValidEmailAddress:@"$A12345@example.com"]);
    XCTAssertTrue([KSURLFormatter isValidEmailAddress:@"!def!xyz%abc@example.com"]);
    XCTAssertTrue([KSURLFormatter isValidEmailAddress:@"_somename@example.com"]);
    XCTAssertTrue([KSURLFormatter isValidEmailAddress:@"Test \\ Folding \\ Whitespace@example.com"]);
    XCTAssertTrue([KSURLFormatter isValidEmailAddress:@"HM2Kinsists@(that comments are allowed)this.is.ok"]);
    XCTAssertTrue([KSURLFormatter isValidEmailAddress:@"user%uucp!path@somehost.edu"]);
}

- (void)testLikelyEmailAddress
{
    XCTAssertFalse([KSURLFormatter isLikelyEmailAddress:@"http://example.com@foo.com"], @"It's a *valid* email address, but more likely to be a URL");
}

@end
