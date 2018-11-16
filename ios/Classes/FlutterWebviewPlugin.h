#import <Flutter/Flutter.h>
#import <WebKit/WebKit.h>

static FlutterMethodChannel *channel;

@interface FlutterWebviewPlugin : NSObject <FlutterPlugin>
@property(nonatomic, retain) UIViewController *viewController;
@property(nonatomic, retain) WKWebView *webview;
@property(nonatomic, retain) NSMutableArray *webviews;
@property(nonatomic, retain) UIScrollView *scrollview;
@end
