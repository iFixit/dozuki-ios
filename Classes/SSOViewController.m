//
//  SSOViewController.m
//  iFixit
//
//  Created by David Patierno on 2/12/12.
//  Copyright (c) 2012 iFixit. All rights reserved.
//

#import "SSOViewController.h"
#import "Config.h"
#import "iFixitAPI.h"

@implementation SSOViewController

static bool ssoActive;

@synthesize delegate;

+ (id)viewControllerForURLNoSSO:(NSString *)url delegate:(id<LoginViewControllerDelegate>)delegate {
     
     SSOViewController* vc = [[SSOViewController alloc] initWithAddress:url withTitle:@""];
     ssoActive = false;
     vc.delegate = delegate;
     vc.tintColor = UIColor.whiteColor;
     return [vc autorelease];
}

- (BOOL)prefersStatusBarHidden {
     return YES;
}

+ (id)viewControllerForURL:(NSString *)url delegate:(id<LoginViewControllerDelegate>)delegate {
    // First clear all cookies.
    ssoActive = true;
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
          for (NSHTTPCookie *cookie in [storage cookies]) {
               [storage deleteCookie:cookie];
          }
          //     BFLog(@"sso %@", url);

          // Set a custom cookie for simple success SSO redirect: sso-origin=SHOW_SUCCESS
          NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:
                            [NSDictionary dictionaryWithObjectsAndKeys:@"sso-origin", NSHTTPCookieName,
                                                                       @"SHOW_SUCCESS", NSHTTPCookieValue,
                                                                       [Config host], NSHTTPCookieDomain,
                                                                       @"/", NSHTTPCookiePath,
                                                                       nil]];
          [storage setCookie:cookie];
     SSOViewController* vc = [[SSOViewController alloc] initWithAddress:url];
     vc.delegate = delegate;
     return [vc autorelease];
}

- (void)viewWillAppear:(BOOL)animated {
    // Ensure we have a solid navigation bar
    self.navigationController.navigationBar.translucent = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [super webViewDidFinishLoad:webView];
     
     if (!ssoActive) {
          NSString *cssString = @"header#mainHeader { display: none; }";
          NSString *javascriptString = @"var style = document.createElement('style'); style.innerHTML = '%@'; document.head.appendChild(style)";
          NSString *javascriptWithCSSString = [NSString stringWithFormat:javascriptString, cssString];
          [webView stringByEvaluatingJavaScriptFromString:javascriptWithCSSString];
          return;
     }
     
    NSString *host = [webView.request.URL host];
     NSLog(@"sso finished loading %@", host);

     if ([host isEqual:[Config currentConfig].host] || [host isEqual:[Config currentConfig].custom_domain]) {
        // Extract the sessionid.
        NSString *sessionid = nil;
        NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (NSHTTPCookie *cookie in [storage cookies]) {
             if ([cookie.name rangeOfString:@"session"].location == NSNotFound) {
                // ignore this cookie
             } else {
                sessionid = cookie.value;
                break;
            }
        }

//     BFLog(@"sso session %@", sessionid);
       // Validate and obtain user data.
        [[iFixitAPI sharedInstance] loginWithSessionId:sessionid forObject:self withSelector:@selector(loginResults:)];
     } else {
          
          NSLog(@"hosts are not equal host %@ customdomain %@", [Config currentConfig].host, [Config currentConfig].custom_domain);

          
     }
}

- (void)loginResults:(NSDictionary *)results {
    if (!results) {
        [iFixitAPI displayConnectionErrorAlert];
        return;
    }
//     BFLog(@"results %@", results);
    
    if ([results objectForKey:@"error"]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                        message:[results objectForKey:@"msg"]
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:NSLocalizedString(@"Okay", nil), nil];
        [alert show];
        [alert release];
    } else {
        [self dismissViewControllerAnimated:NO completion:^(void) {
            // The delegate is responsible for removing the login view.
            [delegate refresh];
        }];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self dismissModalViewControllerAnimated:YES];
}

@end
