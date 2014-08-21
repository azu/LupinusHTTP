//
// Created by azu on 2014/08/20.
//


#import <XCTest/XCTest.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <XCTestCase-RunAsync/XCTestCase-RunAsync.h>
#import <OHHTTPStubs/OHHTTPStubsResponse+JSON.h>
#import "LupinusHTTP.h"
#import "LupinusHTTPRequest.h"
#import <OCHamcrest/OCHamcrest.h>

@interface LupinusHTTPRequest (mock)
@property(nonatomic, strong) NSURLRequest *request;
@property(nonatomic, strong) NSURLSessionDataTask *dataTask;
@property(nonatomic, strong) NSError *response_error;
@property(nonatomic, strong) NSData *response_data;
@property(nonatomic, strong) dispatch_queue_t queue;
@end

@interface LupinusHTTPRequestTests : XCTestCase
@end

@implementation LupinusHTTPRequestTests {
}
- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
    [OHHTTPStubs removeAllStubs];
}

- (void)shouldReturnJSONObject:(id) JSONObject {
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithJSONObject:JSONObject statusCode:200 headers:@{@"Content-Type" : @"text/json"}];
    }];
}

- (void)shouldReturnString:(id) string {
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithData:[string dataUsingEncoding:NSUTF8StringEncoding] statusCode:200 headers:@{}];
    }];
}

- (void)shouldReturnError {
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithError:[NSError errorWithDomain:@"test" code:400 userInfo:@{}]];
    }];
}

#pragma mark - cancel

- (void)test_request_cancel {
    [self runAsyncWithBlock:^(AsyncDone done) {
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return YES;
        } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
            return [[OHHTTPStubsResponse responseWithJSONObject:@{} statusCode:200 headers:nil]
                requestTime:5.0 responseTime:5.0];
        }];
        LupinusHTTPRequest *httpRequest = [LupinusHTTP request:LupinusMethodGET URL:@"http://httpbin.org/get"];
        // cancel request
        [httpRequest cancel];
        XCTAssertEqual(httpRequest.dataTask.state, NSURLSessionTaskStateCanceling);
        done();
    }];
}

#pragma mark - common

- (void)test_response_in_main_thread {
    [self runAsyncWithBlock:^(AsyncDone done) {
        LupinusHTTPRequest *httpRequest = [LupinusHTTP request:LupinusMethodGET URL:@"http://httpbin.org/get"];
        [httpRequest responseJSON:^(NSURLRequest *request, NSURLResponse *response, id JSON, NSError *error) {
            XCTAssert([NSThread isMainThread]);
            done();
        }];
    }];
}

#pragma mark - json

- (void)test_responseJSON_should_return_JSON {
    NSDictionary *expected = @{
        @"result" : @"OK"
    };
    [self shouldReturnJSONObject:expected];
    [self runAsyncWithBlock:^(AsyncDone done) {
        LupinusHTTPRequest *httpRequest = [LupinusHTTP request:LupinusMethodGET URL:@"http://httpbin.org/get"];
        [httpRequest responseJSON:^(NSURLRequest *request, NSURLResponse *response, id JSON, NSError *error) {
            HC_assertThat(JSON, HC_is(HC_equalTo(expected)));
            done();
        }];
    }];
}

- (void)test_responseJSON_when_error_should_return_error {
    [self shouldReturnError];
    [self runAsyncWithBlock:^(AsyncDone done) {
        LupinusHTTPRequest *httpRequest = [LupinusHTTP request:LupinusMethodGET URL:@"http://httpbin.org/get"];
        [httpRequest responseJSON:^(NSURLRequest *request, NSURLResponse *response, id JSON, NSError *error) {
            HC_assertThat(JSON, HC_is(HC_nilValue()));
            HC_assertThat(error, HC_isA([NSError class]));
            done();
        }];
    }];
}

- (void)test_responseJSON_when_non_valid_json_should_return_parse_error {
    [self shouldReturnString:@"non json"];
    [self runAsyncWithBlock:^(AsyncDone done) {
        LupinusHTTPRequest *httpRequest = [LupinusHTTP request:LupinusMethodGET URL:@"http://httpbin.org/get"];
        [httpRequest responseJSON:^(NSURLRequest *request, NSURLResponse *response, id JSON, NSError *error) {
            HC_assertThat(JSON, HC_is(HC_nilValue()));
            HC_assertThat(error, HC_isA([NSError class]));
            done();
        }];
    }];
}

#pragma mark - string

- (void)test_responseString_return_string {
    NSString *expected = @"result";
    [self shouldReturnString:expected];
    [self runAsyncWithBlock:^(AsyncDone done) {
        LupinusHTTPRequest *httpRequest = [LupinusHTTP request:LupinusMethodGET URL:@"http://httpbin.org/get"];
        [httpRequest responseString:^(NSURLRequest *request, NSURLResponse *response, NSString *string, NSError *error) {
            HC_assertThat(string, HC_is(HC_equalTo(expected)));
            HC_assertThat(error, HC_is(HC_nilValue()));
            done();
        }];
    }];
}

- (void)test_responseString_when_error_return_error {
    [self shouldReturnError];
    [self runAsyncWithBlock:^(AsyncDone done) {
        LupinusHTTPRequest *httpRequest = [LupinusHTTP request:LupinusMethodGET URL:@"http://httpbin.org/get" query:@{
            @"key" : @"value"
        }];
        [httpRequest responseJSON:^(NSURLRequest *request, NSURLResponse *response, id JSON, NSError *error) {
            HC_assertThat(JSON, HC_is(HC_nilValue()));
            HC_assertThat(error, HC_isA([NSError class]));
            done();
        }];
    }];
}

#pragma mark - rawData

- (void)test_responseRawData_return_nsdata {
    NSString *expected = @"result";
    [self shouldReturnString:expected];
    [self runAsyncWithBlock:^(AsyncDone done) {
        LupinusHTTPRequest *httpRequest = [LupinusHTTP request:LupinusMethodGET URL:@"http://httpbin.org/get"];
        [httpRequest responseRawData:^(NSURLRequest *request, NSURLResponse *response, NSData *rawData, NSError *error) {
            NSString *string = [[NSString alloc] initWithData:rawData encoding:NSUTF8StringEncoding];
            HC_assertThat(string, HC_is(HC_equalTo(expected)));
            HC_assertThat(error, HC_is(HC_nilValue()));
            done();
        }];
    }];
}

- (void)test_responseRawData_when_error_return_error {
    [self shouldReturnError];
    [self runAsyncWithBlock:^(AsyncDone done) {
        LupinusHTTPRequest *httpRequest = [LupinusHTTP request:LupinusMethodGET URL:@"http://httpbin.org/get"];
        [httpRequest responseRawData:^(NSURLRequest *request, NSURLResponse *response, id JSON, NSError *error) {
            HC_assertThat(JSON, HC_is(HC_nilValue()));
            HC_assertThat(error, HC_isA([NSError class]));
            done();
        }];
    }];
}
@end
