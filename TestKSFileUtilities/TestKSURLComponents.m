//
//  TestKSURLComponents.m
//  KSFileUtilities
//
//  Created by Mike on 06/07/2013.
//  Copyright (c) 2013 Jungle Candy Software. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KSURLComponents.h"

@interface TestKSURLComponents : XCTestCase

@end

@implementation TestKSURLComponents

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

#pragma mark Creating URL Components

- (void)testNilURL {
	XCTAssertThrows([NSURLComponents componentsWithURL:nil resolvingAgainstBaseURL:NO]);
	XCTAssertThrows([KSURLComponents componentsWithURL:nil resolvingAgainstBaseURL:NO]);
}

- (void)testURLStrings {
    NSURL *url = [[NSBundle bundleForClass:self.class] URLForResource:@"URLComponents" withExtension:@"testdata"];
    NSArray *data = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:url] options:0 error:NULL];
    
    for (NSDictionary *properties in data) {
		
		NSString *urlString = properties[@"String"];
		
		NSURL *url = nil;
		if (urlString) {
			url = [NSURL URLWithString:properties[@"String"] relativeToURL:[NSURL URLWithString:properties[@"baseURL"]]];
			XCTAssertNotNil(urlString, @"Been fed in an invalid URL string");
		}
		
		{{
			KSURLComponents *components = (url ?
										   [KSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO] :
										   [[KSURLComponents alloc] init]);
			
			XCTAssertEqual(components.scheme, properties[@"scheme"]);
			XCTAssertEqual(components.user, properties[@"user"]);
			XCTAssertEqual(components.percentEncodedUser, properties[@"percentEncodedUser"]);
			XCTAssertEqual(components.password, properties[@"password"]);
			XCTAssertEqual(components.percentEncodedPassword, properties[@"percentEncodedPassword"]);
			XCTAssertEqual(components.host, properties[@"host"]);
			XCTAssertEqual(components.percentEncodedHost, properties[@"percentEncodedHost"]);
			XCTAssertEqual(components.port, properties[@"port"]);
			XCTAssertEqual(components.path, properties[@"path"]);
			XCTAssertEqual(components.percentEncodedPath, properties[@"percentEncodedPath"]);
			XCTAssertEqual(components.query, properties[@"query"]);
			XCTAssertEqual(components.percentEncodedQuery, properties[@"percentEncodedQuery"]);
			XCTAssertEqual(components.fragment, properties[@"fragment"]);
			XCTAssertEqual(components.percentEncodedFragment, properties[@"percentEncodedFragment"]);
		}}
		
		{{
			NSURLComponents *components = (url ?
										   [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO] :
										   [[NSURLComponents alloc] init]);
			
			XCTAssertEqual(components.scheme, properties[@"scheme"]);
			XCTAssertEqual(components.user, properties[@"user"]);
			XCTAssertEqual(components.percentEncodedUser, properties[@"percentEncodedUser"]);
			XCTAssertEqual(components.password, properties[@"password"]);
			XCTAssertEqual(components.percentEncodedPassword, properties[@"percentEncodedPassword"]);
			XCTAssertEqual(components.host, properties[@"host"]);
			XCTAssertEqual(components.percentEncodedHost, properties[@"percentEncodedHost"]);
			XCTAssertEqual(components.port, properties[@"port"]);
			XCTAssertEqual(components.path, properties[@"path"]);
			XCTAssertEqual(components.percentEncodedPath, properties[@"percentEncodedPath"]);
			XCTAssertEqual(components.query, properties[@"query"]);
			XCTAssertEqual(components.percentEncodedQuery, properties[@"percentEncodedQuery"]);
			XCTAssertEqual(components.fragment, properties[@"fragment"]);
			XCTAssertEqual(components.percentEncodedFragment, properties[@"percentEncodedFragment"]);
		}}
    }
}

#pragma mark Escaping

- (void)testSchemeValidation;
{
    KSURLComponents *components = [[KSURLComponents alloc] init];
    XCTAssertThrowsSpecificNamed(components.scheme = @"!*'();:@&=+$,/?#[]", NSException, NSInvalidArgumentException);
}

- (void)testUserEscaping;
{
    KSURLComponents *components = [[KSURLComponents alloc] init];
    
    components.user = @"!*'();:@&=+$,/?#[]";
    XCTAssertEqual(components.percentEncodedUser, @"!*'();%3A%40&=+$,%2F%3F%23%5B%5D");
    
}

- (void)testPasswordEscaping;
{
    KSURLComponents *components = [[KSURLComponents alloc] init];
    
    components.password = @"!*'();:@&=+$,/?#[]";
    XCTAssertEqual(components.percentEncodedPassword, @"!*'();%3A%40&=+$,%2F%3F%23%5B%5D");
    
}

- (void)testHostEscaping;
{
    KSURLComponents *components = [[KSURLComponents alloc] init];
    
    components.host = @"!*'();:@&=+$,/?#[]";
    XCTAssertEqual(components.percentEncodedHost, @"!*'();%3A%40&=+$,%2F%3F%23%5B%5D");
    
}

- (void)testLiteralHostEscaping;
{
    KSURLComponents *components = [[KSURLComponents alloc] init];
    
    components.host = @"[!*'();:@&=+$,/?#[]]";
    XCTAssertEqual(components.percentEncodedHost, @"[!*'();:%40&=+$,%2F%3F%23%5B%5D]", @"Bracketing in [ ] indicates a literal host, which is allowed to contain : characters, e.g. for IPv6 addresses");
    
}

- (void)testPathEscaping;
{
    KSURLComponents *components = [[KSURLComponents alloc] init];
    
    components.path = @"!*'();:@&=+$,/?#[]";
    XCTAssertEqual(components.percentEncodedPath, @"!*'()%3B%3A@&=+$,/%3F%23%5B%5D");
    
}

- (void)testQueryEscaping;
{
    KSURLComponents *components = [[KSURLComponents alloc] init];
    
    components.query = @"!*'();:@&=+$,/?#[]";
    XCTAssertEqual(components.percentEncodedQuery, @"!*'();:@&=+$,/?%23%5B%5D");
    
}

- (void)testFragmentEscaping;
{
    KSURLComponents *components = [[KSURLComponents alloc] init];
    
    components.fragment = @"!*'();:@&=+$,/?#[]";
    XCTAssertEqual(components.percentEncodedFragment, @"!*'();:@&=+$,/?%23%5B%5D");
    
}

#pragma mark Creating a URL

- (void)testURL;
{
    KSURLComponents *components = [[KSURLComponents alloc] init];
    components.scheme = @"scheme";
    components.user = @"user";
    components.password = @"password";
    components.host = @"host";
    components.port = @(0);
    components.path = @"/path";
    components.query = @"query";
    components.fragment = @"fragment";
    
    NSURL *url = [components URL];
    XCTAssertEqual(url.relativeString, @"scheme://user:password@host:0/path?query#fragment");
    
}

- (void)testURLFromScheme;
{
    KSURLComponents *components = [[KSURLComponents alloc] init];
    components.scheme = @"scheme";
    
    NSURL *url = [components URL];
    XCTAssertEqual(url.relativeString, @"scheme:");
}

- (void)testURLFromUser;
{
    KSURLComponents *components = [[KSURLComponents alloc] init];
    components.user = @"user";
    
    NSURL *url = [components URL];
    XCTAssertEqual(url.relativeString, @"//user@");
}

- (void)testURLFromPassword;
{
    KSURLComponents *components = [[KSURLComponents alloc] init];
    components.password = @"password";
    
    NSURL *url = [components URL];
    XCTAssertEqual(url.relativeString, @"//:password@");
}

- (void)testURLFromHost;
{
    KSURLComponents *components = [[KSURLComponents alloc] init];
    components.host = @"host";
    
    NSURL *url = [components URL];
    XCTAssertEqual(url.relativeString, @"//host");
}

- (void)testURLFromPort;
{
    KSURLComponents *components = [[KSURLComponents alloc] init];
    components.port = @(0);
    
    NSURL *url = [components URL];
    XCTAssertEqual(url.relativeString, @"//:0");
}

- (void)testURLFromAbsolutePath;
{
    KSURLComponents *components = [[KSURLComponents alloc] init];
    components.path = @"/path";
    
    NSURL *url = [components URL];
    XCTAssertEqual(url.relativeString, @"/path");
}

- (void)testURLFromRelativePath;
{
    KSURLComponents *components = [[KSURLComponents alloc] init];
    components.path = @"path";
    
    NSURL *url = [components URL];
    XCTAssertEqual(url.relativeString, @"path");
}

- (void)testURLFromQuery;
{
    KSURLComponents *components = [[KSURLComponents alloc] init];
    components.query = @"query";
    
    NSURL *url = [components URL];
    XCTAssertEqual(url.relativeString, @"?query");
}

- (void)testURLFromFragment;
{
    KSURLComponents *components = [[KSURLComponents alloc] init];
    components.fragment = @"fragment";
    
    NSURL *url = [components URL];
    XCTAssertEqual(url.relativeString, @"#fragment");
}

- (void)testURLWithoutSchemeOrHost;
{
    KSURLComponents *components = [[KSURLComponents alloc] init];
    components.user = @"user";
    components.password = @"password";
    components.port = @(0);
    components.path = @"/path";
    
    NSURL *url = [components URL];
    XCTAssertEqual(url.relativeString, @"//user:password@:0/path");
}

- (void)testURLWithNoAuthorityComponentButAbsolutePath;
{
    KSURLComponents *components = [[KSURLComponents alloc] init];
    components.scheme = @"scheme";
    components.path = @"/path";
    
    NSURL *url = [components URL];
    XCTAssertEqual(url.relativeString, @"scheme:/path");
}

- (void)testURLWithEmptyAuthorityComponentButAbsolutePath;
{
    KSURLComponents *components = [[KSURLComponents alloc] init];
    components.scheme = @"scheme";
    components.host = @"";
    components.path = @"/path";
    
    NSURL *url = [components URL];
    XCTAssertEqual(url.relativeString, @"scheme:///path");
}

- (void)testURLWithNoAuthorityComponentButRelativePath;
{
    KSURLComponents *components = [[KSURLComponents alloc] init];
    components.scheme = @"scheme";
    components.path = @"path";
    
    NSURL *url = [components URL];
    XCTAssertEqual(url.relativeString, @"scheme:path");
}

- (void)testURLWithEmptyAuthorityComponentButRelativePath;
{
    KSURLComponents *components = [[KSURLComponents alloc] init];
    components.scheme = @"scheme";
    components.host = @"";
    components.path = @"path";
    
    NSURL *url = [components URL];
    XCTAssertNil(url);
}

- (void)testURLFromAuthorityComponentAndRelativePath
{
    KSURLComponents *components = [KSURLComponents componentsWithString:@"http://example.com"];
    components.path = @"relative";
    
    NSURL *url = [components URL];
    XCTAssertNil(url, @"If the KSURLComponents has an authority component (user, password, host or port) and a path component, then the path must either begin with \"/\" or be an empty string");
}

- (void)testURLFromNoAuthorityComponentAndProtocolRelativePath
{
    KSURLComponents *components = [[KSURLComponents alloc] init];
    components.scheme = @"scheme";
    components.path = @"//protocol/relative";
    
    NSURL *url = [components URL];
    XCTAssertNil(url, @"If the KSURLComponents does not have an authority component (user, password, host or port) and has a path component, the path component must not start with \"//\"");
    
}

#pragma mark NSCopying

- (void)testCopying;
{
    KSURLComponents *components = [KSURLComponents componentsWithURL:[NSURL URLWithString:@"scheme://user:password@host:0/path?query#fragment"]
                                             resolvingAgainstBaseURL:NO];
    
    KSURLComponents *components2 = [components copy];
    
    XCTAssertEqual(components, components2);
}

@end
