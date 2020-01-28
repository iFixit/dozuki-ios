//
//  WikiVC.m
//  iFixit
//
//  Created by Robert Pascazio on 5/6/17.
//
//

#import "WikiVC.h"

@interface WikiVC ()

@end

@implementation WikiVC

- (void)viewDidLoad {
    [super viewDidLoad];
     NSURL *nsurl = [NSURL URLWithString:self.url];
     NSURLRequest *request = [NSURLRequest requestWithURL:nsurl];
     self.webView.delegate = self;
     self.webView.scalesPageToFit = YES;
     [self.webView loadRequest:request];
}

- (void)viewWillAppear:(BOOL)animated {
     [self.webView.scrollView setZoomScale:3.0 animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
     NSString *cssString = @"header#mainHeader { display: none; }";
     NSString *javascriptString = @"var style = document.createElement('style'); style.innerHTML = '%@'; document.head.appendChild(style)";
     NSString *javascriptWithCSSString = [NSString stringWithFormat:javascriptString, cssString];
     [webView stringByEvaluatingJavaScriptFromString:javascriptWithCSSString];
     
     //cssString = @"toolbar { display: none; }";
     //javascriptString = @"var style = document.createElement('style'); style.innerHTML = '%@'; document.getElementById(\"pdfembed\").contentWindow.document.head.appendChild(style)";
     
     javascriptString = //@"$('#pdfembed').contents().find('.toolbar').css({display: none});";

     //@"document.getElementById('#pdfembed').contentWindow.document.body.getElementById('toolbar').setAttribute('display', 'none';";
     //var y = (iframe.contentWindow || iframe.contentDocument);if (y.document)y = y.document;var elmnt = y.getElementById(\"secondaryToolbar\"); if (y.document) y = y.document;
     
     //@"window.onload = function(){var iframe = document.getElementById(\"pdfembed\");var y = (iframe.contentWindow || iframe.contentDocument);if (y.document) y = y.document;var elmnt = y.getElementById('toolbarContainer');elmnt.style.display='none'};";
     

     //cssString = @"div.toolbar { display: none; }";
     //javascriptString = @"var iframe = document.getElementById(\"pdfembed\");var y = (iframe.contentWindow || iframe.contentDocument);if (y.document) y = y.document;var style = document.createElement('style'); style.innerHTML = '%@'; y.head.appendChild(style)";
     //javascriptWithCSSString = [NSString stringWithFormat:javascriptString, cssString];
     //[webView stringByEvaluatingJavaScriptFromString:javascriptWithCSSString];

     //@"document.onreadystatechange = function(e){if (document.readyState === 'complete'){var iframe = document.getElementById(\"pdfembed\");var y = (iframe.contentWindow || iframe.contentDocument);if (y.document) y = y.document;var elmnt = y.getElementById('toolbarContainer');elmnt.style.display='none'}};";
     
     @"document.onreadystatechange = function(e){if (document.readyState === 'complete'){var iframe = document.getElementById(\"pdfembed\");var y = (iframe.contentWindow || iframe.contentDocument);if (y.document) y = y.document;var elmnt = y.getElementById('toolbarContainer');elmnt.style.display='none'}};";
     
     //window.onload = function(){var iframe = document.getElementById(\"pdfembed\");var y = (iframe.contentWindow || iframe.contentDocument);if (y.document) y = y.document;var elmnt = y.getElementById('toolbarContainer');elmnt.style.display='none'};";
     
                                                                                                                         
     //javascriptWithCSSString = [NSString stringWithFormat:javascriptString, cssString];
    [webView stringByEvaluatingJavaScriptFromString:javascriptString];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
     NSString *cssString = @"header#mainHeader { display: none; }";
     NSString *javascriptString = @"var style = document.createElement('style'); style.innerHTML = '%@'; document.head.appendChild(style)";
     NSString *javascriptWithCSSString = [NSString stringWithFormat:javascriptString, cssString];
     [webView stringByEvaluatingJavaScriptFromString:javascriptWithCSSString];

}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)dealloc {
    [_webView release];
    [super dealloc];
}
@end
