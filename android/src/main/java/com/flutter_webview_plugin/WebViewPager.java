package com.flutter_webview_plugin;

import android.support.v4.view.ViewPager;
import android.content.Context;
import android.util.AttributeSet;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;

public class WebViewPager extends ViewPager {
    public WebViewPager(@NonNull Context context) {
        super(context);
    }

    public WebViewPager(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
    }

}
