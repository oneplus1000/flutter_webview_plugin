package com.flutter_webview_plugin;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.graphics.Point;
import android.view.Display;
import android.widget.FrameLayout;

import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.PluginRegistry;
import android.widget.TextView;
import android.widget.LinearLayout;
import android.support.v4.view.ViewPager;
import android.util.Log;

/**
 * FlutterWebviewPlugin
 */
public class FlutterWebviewPlugin implements MethodCallHandler, PluginRegistry.ActivityResultListener {
    private static String TAG = "FlutterWebviewPlugin";
    private Activity activity;
    private WebviewManager webViewManager;
    private ViewPager pager;
    static MethodChannel channel;
    private static final String CHANNEL_NAME = "flutter_webview_plugin";

    public static void registerWith(PluginRegistry.Registrar registrar) {
        channel = new MethodChannel(registrar.messenger(), CHANNEL_NAME);
        final FlutterWebviewPlugin instance = new FlutterWebviewPlugin(registrar.activity());
        registrar.addActivityResultListener(instance);
        channel.setMethodCallHandler(instance);
    }

    private FlutterWebviewPlugin(Activity activity) {
        this.activity = activity;
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
        case "launch":
            openUrl(call, result);
            break;
        case "close":
            close(call, result);
            break;
        case "eval":
            eval(call, result);
            break;
        case "resize":
            resize(call, result);
            break;
        case "reload":
            reload(call, result);
            break;
        case "back":
            back(call, result);
            break;
        case "forward":
            forward(call, result);
            break;
        case "hide":
            hide(call, result);
            break;
        case "show":
            show(call, result);
            break;
        case "reloadUrl":
            reloadUrl(call, result);
            break;
        case "stopLoading":
            stopLoading(call, result);
            break;
        case "setContentOffset":
            setContentOffset(call, result);
            break;
        default:
            result.notImplemented();
            break;
        }
    }

    private void setContentOffset(MethodCall call, MethodChannel.Result result) {
        double x = call.argument("x");
        double y = call.argument("y");
        if (webViewManager == null || webViewManager.closed == true) {
            webViewManager = new WebviewManager(activity);
        }
        webViewManager.scrollTo(x, y);
        result.success(null);
    }

    private void openUrl(MethodCall call, MethodChannel.Result result) {
        boolean hidden = call.argument("hidden");
        String url = call.argument("url");
        String userAgent = call.argument("userAgent");
        boolean withJavascript = call.argument("withJavascript");
        boolean clearCache = call.argument("clearCache");
        boolean clearCookies = call.argument("clearCookies");
        boolean withZoom = call.argument("withZoom");
        boolean withLocalStorage = call.argument("withLocalStorage");
        Map<String, String> headers = call.argument("headers");
        boolean scrollBar = call.argument("scrollBar");
        int viewpageCount = call.argument("viewpageCount");

        if (webViewManager == null || webViewManager.closed == true) {
            webViewManager = new WebviewManager(activity);
        }

        FrameLayout.LayoutParams params = buildLayoutParams(call);

        addContentView(activity, params, viewpageCount);
        Log.d(TAG, "hidden:" + hidden + " url:" + url + " userAgent:" + userAgent + " withJavascript:" + withJavascript
                + " clearCache:" + clearCache);
        Log.d(TAG, "clearCookies:" + clearCookies + " withZoom=" + withZoom + " withLocalStorage=" + withLocalStorage
                + " headers:" + headers + " scrollBar:" + scrollBar);

        /*
         * activity.addContentView(webViewManager.webView, params);
         * webViewManager.openUrl(withJavascript, clearCache, hidden, clearCookies,
         * userAgent, url, headers, withZoom, withLocalStorage, scrollBar);
         */
        result.success(null);
        Log.d(TAG, "success=");
    }

    private void addContentView(Activity activity, FrameLayout.LayoutParams params, int viewpageCount) {
        pager = new ViewPager(activity);
        /*
         * LinearLayout layout = new LinearLayout(activity); LinearLayout.LayoutParams
         * layoutParams1 = new
         * LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT,
         * LinearLayout.LayoutParams.MATCH_PARENT, 2f);
         * layout.setLayoutParams(layoutParams1); layout.setBackgroundColor(0xff9900ff);
         */
        // layout.addView(pager);

        Log.d(TAG, "viewpageCount=" + viewpageCount);
        pager.setBackgroundColor(0xff00ff00);
        activity.addContentView(pager, params);
        WebViewPagerAdapter adapter = new WebViewPagerAdapter(activity, viewpageCount);
        pager.setLayoutParams(params);
        pager.setAdapter(adapter);
    }

    private FrameLayout.LayoutParams buildLayoutParams(MethodCall call) {
        Log.d(TAG, "buildLayoutParams");
        Map<String, Number> rc = call.argument("rect");
        FrameLayout.LayoutParams params;
        if (rc != null) {
            Log.d(TAG, "buildLayoutParams rc != null  " + dp2px(activity, rc.get("width").intValue()) + " , "
                    + dp2px(activity, rc.get("height").intValue()));
            params = new FrameLayout.LayoutParams(dp2px(activity, rc.get("width").intValue()),
                    dp2px(activity, rc.get("height").intValue()));
            params.setMargins(dp2px(activity, rc.get("left").intValue()), dp2px(activity, rc.get("top").intValue()), 0,
                    0);
        } else {
            Log.d(TAG, "buildLayoutParams rc == null");
            Display display = activity.getWindowManager().getDefaultDisplay();
            Point size = new Point();
            display.getSize(size);
            int width = size.x;
            int height = size.y;
            params = new FrameLayout.LayoutParams(width, height);
        }

        return params;
    }

    private void stopLoading(MethodCall call, MethodChannel.Result result) {
        if (webViewManager != null) {
            webViewManager.stopLoading(call, result);
        }
    }

    private void close(MethodCall call, MethodChannel.Result result) {
        if (webViewManager != null) {
            webViewManager.close(call, result);
            webViewManager = null;
        }
    }

    /**
     * Navigates back on the Webview.
     */
    private void back(MethodCall call, MethodChannel.Result result) {
        if (webViewManager != null) {
            webViewManager.back(call, result);
        }
    }

    /**
     * Navigates forward on the Webview.
     */
    private void forward(MethodCall call, MethodChannel.Result result) {
        if (webViewManager != null) {
            webViewManager.forward(call, result);
        }
    }

    /**
     * Reloads the Webview.
     */
    private void reload(MethodCall call, MethodChannel.Result result) {
        if (webViewManager != null) {
            webViewManager.reload(call, result);
        }
    }

    private void reloadUrl(MethodCall call, MethodChannel.Result result) {
        if (webViewManager != null) {
            String url = call.argument("url");
            webViewManager.openUrl(false, false, false, false, "", url, null, false, false, false);
        }
    }

    private void eval(MethodCall call, final MethodChannel.Result result) {
        if (webViewManager != null) {
            webViewManager.eval(call, result);
        }
    }

    private void resize(MethodCall call, final MethodChannel.Result result) {
        Log.d(TAG, "resize");
        if (webViewManager != null) {
            FrameLayout.LayoutParams params = buildLayoutParams(call);
            webViewManager.resize(params);
        }
        if (pager != null) {
            FrameLayout.LayoutParams params = buildLayoutParams(call);
            pager.setLayoutParams(params);
        }
        result.success(null);
    }

    private void hide(MethodCall call, final MethodChannel.Result result) {
        Log.d(TAG, "hide");
        if (webViewManager != null) {
            webViewManager.hide(call, result);
        }
    }

    private void show(MethodCall call, final MethodChannel.Result result) {
        Log.d(TAG, "show");
        if (webViewManager != null) {
            webViewManager.show(call, result);
        }
    }

    private int dp2px(Context context, float dp) {
        final float scale = context.getResources().getDisplayMetrics().density;
        Log.d(TAG, "dp2px scale=" + scale + " dp=" + dp);
        return (int) (dp * scale + 0.5f);
    }

    @Override
    public boolean onActivityResult(int i, int i1, Intent intent) {
        if (webViewManager != null && webViewManager.resultHandler != null) {
            return webViewManager.resultHandler.handleResult(i, i1, intent);
        }
        return false;
    }
}
