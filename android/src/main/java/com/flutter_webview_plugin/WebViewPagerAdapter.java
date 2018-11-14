package com.flutter_webview_plugin;

import android.support.v4.view.PagerAdapter;
import android.content.Context;
import android.widget.TextView;
import android.view.View;
import android.view.ViewGroup;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.util.Log;
import android.widget.LinearLayout;
import android.app.Activity;
import java.util.Map;

public class WebViewPagerAdapter extends PagerAdapter {
    private static String TAG = "WebViewPagerAdapter";
    private Activity ctx;
    private int countItems = 0;
    // private WebviewManager webViewManager;

    public WebViewPagerAdapter(Activity ctx, int countItems) {
        this.ctx = ctx;
        this.countItems = countItems;
        // this.webViewManager = new WebviewManager(ctx);
    }

    @Override
    public int getCount() {
        return countItems;
    }

    @Override
    public boolean isViewFromObject(@NonNull View view, @NonNull Object object) {
        return view == object;
    }

    @NonNull
    @Override
    public Object instantiateItem(@NonNull ViewGroup container, int position) {
        Log.d(TAG, "instantiateItem:" + position);
        WebviewManager webViewManager = new WebviewManager(this.ctx);
        /*
         * LinearLayout innerLayout1 = new LinearLayout(this.ctx);
         * LinearLayout.LayoutParams layoutParams1 = new
         * LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT,
         * LinearLayout.LayoutParams.MATCH_PARENT, 2f);
         * innerLayout1.setLayoutParams(layoutParams1);
         * innerLayout1.setBackgroundColor(0xff00ffff);
         * innerLayout1.addView(webViewManager.webView);
         */

        container.addView(webViewManager.webView);

        // hidden:false url:http://127.0.0.1:9999 userAgent:null withJavascript:true
        // clearCache:true
        // D/FlutterWebviewPlugin(14866): hidden:false url:http://127.0.0.1:9999
        // userAgent:null withJavascript:true clearCache:true
        // D/FlutterWebviewPlugin(14866): clearCookies:false withZoom=false
        // withLocalStorage=true headers:null
        boolean withJavascript = true;
        boolean clearCache = true;
        boolean hidden = false;
        boolean clearCookies = false;
        String userAgent = null;
        String url = "http://127.0.0.1:9999?position=" + position;
        Map<String, String> headers = null;
        boolean withZoom = false;
        boolean withLocalStorage = true;
        boolean scrollBar = true;

        webViewManager.openUrl(withJavascript, clearCache, hidden, clearCookies, userAgent, url, headers, withZoom,
                withLocalStorage, scrollBar);

        return webViewManager.webView;
    }

    @Override
    public void destroyItem(@NonNull ViewGroup container, int position, @NonNull Object object) {
        container.removeView((View) object);
    }
}