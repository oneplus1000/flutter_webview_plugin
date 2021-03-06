#import "FlutterWebviewPlugin.h"
//#include <syslog.h>


static NSString *const CHANNEL_NAME = @"flutter_webview_plugin";

// UIWebViewDelegate
@interface FlutterWebviewPlugin() <WKNavigationDelegate, UIScrollViewDelegate, WKScriptMessageHandler> {
    BOOL _enableAppScheme;
    BOOL _enableZoom;
}
@end

@implementation FlutterWebviewPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    channel = [FlutterMethodChannel
               methodChannelWithName:CHANNEL_NAME
               binaryMessenger:[registrar messenger]];
    
    UIViewController *viewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    FlutterWebviewPlugin* instance = [[FlutterWebviewPlugin alloc] initWithViewController:viewController];
    
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithViewController:(UIViewController *)viewController {
    self = [super init];
    if (self) {
        self.viewController = viewController;
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result { 
    //syslog(LOG_ALERT,"xxxx");
    if ([@"launch" isEqualToString:call.method]) {
        if (!self.webview){
            [self initWebview:call];
        }else{
            [self navigate:call];
        }
        result(nil);
    } else if ([@"close" isEqualToString:call.method]) {
        [self closeWebView];
        result(nil);
    } else if ([@"eval" isEqualToString:call.method]) {
        [self evalJavascript:call completionHandler:^(NSString * response) {
            result(response);
        }];
    } else if ([@"resize" isEqualToString:call.method]) {
        [self resize:call];
        result(nil);
    } else if ([@"reloadUrl" isEqualToString:call.method]) {
        [self reloadUrl:call];
        result(nil);	
    } else if ([@"show" isEqualToString:call.method]) {
        [self show];
        result(nil);
    } else if ([@"hide" isEqualToString:call.method]) {
        [self hide];
        result(nil);
    } else if ([@"stopLoading" isEqualToString:call.method]) {
        [self stopLoading];
        result(nil);
    } else if([@"setContentOffset" isEqualToString:call.method]){
        [self setContentOffset:call];
        result(nil);
    } else if([@"touchInfo" isEqualToString:call.method]){
        BOOL isTouch = [self touchInfo:call];
        //NSNumber *result = [NSNumber numberWithBool:isTouch];
        result(@(isTouch));
    } else {
        result(FlutterMethodNotImplemented);
    }
}

-(BOOL) touchInfo:(FlutterMethodCall*)call{
    return self.webview.scrollView.tracking;
}

- (void) setContentOffset:(FlutterMethodCall*)call {
    NSNumber *x = call.arguments[@"x"];
    NSNumber *y = call.arguments[@"y"];
    CGFloat floatX = (CGFloat)x.doubleValue;
    CGFloat floatY = (CGFloat)y.doubleValue;
    //[self alertText:@"setContentOffset" withMsg:@"mmmmm"];
    //(CGFloat)x withY: (CGFloat) y
    CGPoint point = CGPointMake(floatX,floatY);
    [self.webview.scrollView setContentOffset:point animated:true];
    //self.webview.scrollView.contentOffset = point;
}

- (void)initWebview:(FlutterMethodCall*)call {
    //NSLog(@"xxxx");
    NSNumber *clearCache = call.arguments[@"clearCache"];
    NSNumber *clearCookies = call.arguments[@"clearCookies"];
    NSNumber *hidden = call.arguments[@"hidden"];
    NSDictionary *rect = call.arguments[@"rect"];
    _enableAppScheme = call.arguments[@"enableAppScheme"];
    NSString *userAgent = call.arguments[@"userAgent"];
    NSNumber *withZoom = call.arguments[@"withZoom"];
    NSNumber *scrollBar = call.arguments[@"scrollBar"];
    NSNumber *viewpageCount = call.arguments[@"viewpageCount"];
    
    if (clearCache != (id)[NSNull null] && [clearCache boolValue]) {
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
    }
    
    if (clearCookies != (id)[NSNull null] && [clearCookies boolValue]) {
        [[NSURLSession sharedSession] resetWithCompletionHandler:^{
        }];
    }
    
    if (userAgent != (id)[NSNull null]) {
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"UserAgent": userAgent}];
    }
    
    CGRect rc;
    if (rect != nil) {
        rc = [self parseRect:rect];
    } else {
        rc = self.viewController.view.bounds;
    }

    //configuration 
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    WKUserContentController *controller = [[WKUserContentController alloc] init];
    [controller addScriptMessageHandler:self name:@"flutterwebview"];
    configuration.userContentController = controller; 
    
    
    //webview
    //CGRect rctest = CGRectMake(0,200,200,200);
    self.webview = [[WKWebView alloc] initWithFrame:rc configuration:configuration ];
    /*self.webview = [[WKWebView alloc] initWithFrame:rctest];
    self.webview.navigationDelegate = self;
    self.webview.scrollView.delegate = self;
    self.webview.hidden = [hidden boolValue];
    self.webview.scrollView.showsHorizontalScrollIndicator = [scrollBar boolValue];
    self.webview.scrollView.showsVerticalScrollIndicator = [scrollBar boolValue];
    self.webview.scrollView.bounces = NO;
    self.webview.scrollView.pagingEnabled = true;
    */
 
    
    
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:@"Show View" forState:UIControlStateNormal];
    button.frame = CGRectMake(00.0, 210.0, 300.0, 40.0);
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button2 setTitle:@"Show View" forState:UIControlStateNormal];
    button2.frame = CGRectMake(300.0, 210.0, 300.0, 40.0);
    
    //scrollview
    self.scrollview = [[UIScrollView alloc] initWithFrame:rc];//[[UIScrollView alloc] init];
    self.scrollview.pagingEnabled = true;
    //[self.scrollview addSubview:self.webview];
    
    
    
    int i = 0;
    int size = viewpageCount.intValue;
    self.webviews = [NSMutableArray arrayWithCapacity:size];
    CGFloat scrollviewWidth = 0;
    while(i < size){
        CGRect subrc = CGRectMake(scrollviewWidth,0,rc.size.width,rc.size.height);
        WKWebView *webview = [[WKWebView alloc] initWithFrame:subrc configuration:configuration ];
        webview.navigationDelegate = self;
        webview.scrollView.delegate = self;
        webview.hidden = [hidden boolValue];
        webview.scrollView.showsHorizontalScrollIndicator = [scrollBar boolValue];
        webview.scrollView.showsVerticalScrollIndicator = [scrollBar boolValue];
        webview.scrollView.bounces = NO;
        webview.scrollView.pagingEnabled = true;
        self.webviews[i] = webview;
        [self.scrollview addSubview:webview];
        i = i + 1;
        scrollviewWidth = scrollviewWidth + rc.size.width;
    }
    
    self.scrollview.contentSize = CGSizeMake(scrollviewWidth,rc.size.height);
    [self.scrollview setBackgroundColor:[UIColor darkGrayColor]];
    [self.viewController.view addSubview:self.scrollview];
    _enableZoom = [withZoom boolValue];
    [self navigate:call];
}

- (CGRect)parseRect:(NSDictionary *)rect {
    return CGRectMake([[rect valueForKey:@"left"] doubleValue],
                      [[rect valueForKey:@"top"] doubleValue],
                      [[rect valueForKey:@"width"] doubleValue],
                      [[rect valueForKey:@"height"] doubleValue]);
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView { 
    id xDirection = @{@"xDirection": @(scrollView.contentOffset.x), @"isTouch":@(scrollView.tracking)};
    [channel invokeMethod:@"onScrollXChanged" arguments:xDirection];

    id yDirection = @{@"yDirection": @(scrollView.contentOffset.y), @"isTouch":@(scrollView.tracking)};
    [channel invokeMethod:@"onScrollYChanged" arguments:yDirection];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView 
                     withVelocity:(CGPoint)velocity 
              targetContentOffset:(inout CGPoint *)targetContentOffset {
    id xDirection = @{@"xDirection": @(scrollView.contentOffset.x), @"isTouch":@(scrollView.tracking)};
    [channel invokeMethod:@"scrollXViewWillEndDragging" arguments:xDirection]; 

    id yDirection = @{@"yDirection": @(scrollView.contentOffset.y), @"isTouch":@(scrollView.tracking)};
    [channel invokeMethod:@"scrollYViewWillEndDragging" arguments:yDirection];                 
}

- (void)navigate:(FlutterMethodCall*)call {
    if (self.webview != nil) {
        NSString *url = call.arguments[@"url"];
        NSNumber *withLocalUrl = call.arguments[@"withLocalUrl"];
        if ( [withLocalUrl boolValue]) {
            NSURL *htmlUrl = [NSURL fileURLWithPath:url isDirectory:false];
            if (@available(iOS 9.0, *)) {
                [self.webview loadFileURL:htmlUrl allowingReadAccessToURL:htmlUrl];
            } else {
                @throw @"not available on version earlier than ios 9.0";
            }
        } else {
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
            NSDictionary *headers = call.arguments[@"headers"];
            
            if (headers != nil) {
                [request setAllHTTPHeaderFields:headers];
            }
            
            [self.webview loadRequest:request];
            int size = (int)self.webviews.count;
            int i = 0;
            while(i < size){
                NSString *pageUrl = [url stringByAppendingFormat: @"?position=%d", i];
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:pageUrl]];
                NSDictionary *headers = call.arguments[@"headers"];
                
                if (headers != nil) {
                    [request setAllHTTPHeaderFields:headers];
                }
                
                WKWebView *webview = self.webviews[i];
                [webview loadRequest:request];
                i = i + 1;
            }
        }
    }
}

- (void)evalJavascript:(FlutterMethodCall*)call
     completionHandler:(void (^_Nullable)(NSString * response))completionHandler {
    if (self.webview != nil) {
        NSString *code = call.arguments[@"code"];
        [self.webview evaluateJavaScript:code
                       completionHandler:^(id _Nullable response, NSError * _Nullable error) {
            completionHandler([NSString stringWithFormat:@"%@", response]);
        }];
    } else {
        completionHandler(nil);
    }
}

- (void)resize:(FlutterMethodCall*)call {
    if (self.webview != nil) {
        NSDictionary *rect = call.arguments[@"rect"];
        CGRect rc = [self parseRect:rect];
        self.webview.frame = rc;
    }
}

- (void)closeWebView {
    if (self.webview != nil) {
        [self.webview stopLoading];
        [self.webview removeFromSuperview];
        self.webview.navigationDelegate = nil;
        self.webview = nil;

        // manually trigger onDestroy
        [channel invokeMethod:@"onDestroy" arguments:nil];
    }
}

- (void)reloadUrl:(FlutterMethodCall*)call {
    if (self.webview != nil) {
		NSString *url = call.arguments[@"url"];
		NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        [self.webview loadRequest:request];
    }
}
- (void)show {
    if (self.webview != nil) {
        self.webview.hidden = false;
    }
}

- (void)hide {
    if (self.webview != nil) {
        self.webview.hidden = true;
    }
}
- (void)stopLoading {
    if (self.webview != nil) {
        [self.webview stopLoading];
    }
}

#pragma mark -- WkWebView Delegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
    decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {

    id data = @{@"url": navigationAction.request.URL.absoluteString,
                @"type": @"shouldStart",
                @"navigationType": [NSNumber numberWithInt:navigationAction.navigationType]};
    [channel invokeMethod:@"onState" arguments:data];

    if (navigationAction.navigationType == WKNavigationTypeBackForward) {
        [channel invokeMethod:@"onBackPressed" arguments:nil];
    } else {
        id data = @{@"url": navigationAction.request.URL.absoluteString};
        [channel invokeMethod:@"onUrlChanged" arguments:data];
    }

    if (_enableAppScheme ||
        ([webView.URL.scheme isEqualToString:@"http"] ||
         [webView.URL.scheme isEqualToString:@"https"] ||
         [webView.URL.scheme isEqualToString:@"about"])) {
        decisionHandler(WKNavigationActionPolicyAllow);
    } else {
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}


- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [channel invokeMethod:@"onState" arguments:@{@"type": @"startLoad", @"url": webView.URL.absoluteString}];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [channel invokeMethod:@"onState" arguments:@{@"type": @"finishLoad", @"url": webView.URL.absoluteString}];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    id data = [FlutterError errorWithCode:[NSString stringWithFormat:@"%ld", error.code]
                                  message:error.localizedDescription
                                  details:error.localizedFailureReason];
    [channel invokeMethod:@"onError" arguments:data];
    //[channel invokeMethod:@"onError" arguments:@{@"code": [NSString stringWithFormat:@"%ld", error.code], @"error": error.localizedDescription}];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    if ([navigationResponse.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse * response = (NSHTTPURLResponse *)navigationResponse.response;

        [channel invokeMethod:@"onHttpError" arguments:@{@"code": [NSString stringWithFormat:@"%ld", response.statusCode], @"url": webView.URL.absoluteString}];
    }
    decisionHandler(WKNavigationResponsePolicyAllow);
}

#pragma mark -- UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (scrollView.pinchGestureRecognizer.isEnabled != _enableZoom) {
        scrollView.pinchGestureRecognizer.enabled = _enableZoom;
    }
}

//call from webkit
- (void) userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {

    if ([message.name isEqualToString:@"flutterwebview"]) {
        //[self alertText:@"hi" withMsg: @"start"];
        //if( [message.body isKindOfClass:[NSString class]] ){
        //    [self alertText:@"hi" withMsg:message.body];
        //} else 
        if( [message.body isKindOfClass:[NSDictionary class]] ){ 
            //[self alertText:@"mmm" withMsg: NSStringFromClass([message.body[@"argsCount"] class]) ];
            /*NSString *funcname = @"";
            NSNumber *argsCount = [NSNumber numberWithInteger:0];
            NSMutableArray *argsType = [[NSMutableArray alloc] init];
            if([message.body[@"funcname"] isKindOfClass:[NSString class]]){
                funcname = message.body[@"funcname"];  
            }
            if([message.body[@"argsCount"] isKindOfClass:[NSNumber class]]){
                argsCount = message.body[@"argsCount"];
            }
            if([message.body[@"argsType"] isKindOfClass:[NSArray class]]){
                [self alertText:@"hix" withMsg: NSStringFromClass([message.body[@"argsType"]  class])];
            }
            if([message.body[@"argsVal"] isKindOfClass:[NSArray class]]){}
            */
            [channel invokeMethod: @"onJsCallFlutter" arguments:message.body];
        }
    }      
}

-(void) alertText:(NSString *)title 
    withMsg:(NSString *)msg {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                        message:msg
                        preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
    handler:^(UIAlertAction * action) {}];
    [alert addAction:defaultAction];
    [[self viewController] presentViewController:alert animated:YES completion:nil];                  
}

@end
