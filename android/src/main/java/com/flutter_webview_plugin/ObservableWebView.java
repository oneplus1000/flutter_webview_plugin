package com.flutter_webview_plugin;

import android.content.Context;
import android.util.AttributeSet;
import android.webkit.WebView;
import android.util.Log;
import android.view.DragEvent;
import android.view.MotionEvent;
import android.animation.ObjectAnimator;
import android.view.View;

public class ObservableWebView extends WebView {
    private final String TAG = "ObservableWebView";
    private OnScrollChangedCallback mOnScrollChangedCallback;

    public ObservableWebView(final Context context) {
        super(context);
        this.setOverScrollMode(View.OVER_SCROLL_NEVER);
    }

    public ObservableWebView(final Context context, final AttributeSet attrs) {
        super(context, attrs);
        this.setOverScrollMode(View.OVER_SCROLL_NEVER);
    }

    public ObservableWebView(final Context context, final AttributeSet attrs, final int defStyle) {
        super(context, attrs, defStyle);
        this.setOverScrollMode(View.OVER_SCROLL_NEVER);
    }

    @Override
    protected void onScrollChanged(final int l, final int t, final int oldl, final int oldt) {
        super.onScrollChanged(l, t, oldl, oldt);
        // Log.v(TAG, "onScrollChanged");
        if (mOnScrollChangedCallback != null)
            mOnScrollChangedCallback.onScroll(l, t, oldl, oldt);
    }

    float downX = 0.0f;
    float upX = 0.0f;

    @Override
    public boolean onTouchEvent(MotionEvent event) {

        int action = event.getAction();
        if (action == MotionEvent.ACTION_DOWN) {
            downX = event.getX();
            return super.onTouchEvent(event);
        } else if (action == MotionEvent.ACTION_UP) {
            upX = event.getX();
            final float w = this.getWidth();
            float deltaX = downX - upX;
            float minDistance = w / 4;
            // Log.d(TAG, "deltaX=" + deltaX + " , downX=" + downX + " , upX:" + upX);
            String go = null;
            if (deltaX > 0 && Math.abs(deltaX) >= minDistance) {
                // left to right
                go = "right";
            } else if (deltaX > 0 && Math.abs(deltaX) < minDistance) {
                // back to left
                go = "left";
            } else if (deltaX < 0 && Math.abs(deltaX) >= minDistance) {
                // right to left
                go = "left";
            } else if (deltaX < 0 && Math.abs(deltaX) < minDistance) {
                // back to right
                go = "right";
            }

            final float x = this.getScrollX();
            final float mod = x % w;
            final float left = x - mod;
            final float right = x + w - mod;
            // Log.d(TAG, "" + this.getScrollX());

            if ("right".endsWith(go)) {
                ObjectAnimator anim = ObjectAnimator.ofInt(this, "scrollX", (int) x, (int) right);
                anim.setDuration(200);
                anim.start();

            } else if ("left".endsWith(go)) {
                ObjectAnimator anim = ObjectAnimator.ofInt(this, "scrollX", (int) x, (int) left);
                anim.setDuration(200);
                anim.start();
            }

            return false;
        }
        return super.onTouchEvent(event);
    }

    private void jumpToY(final int xLocation) {
        this.postDelayed(new Runnable() {
            @Override
            public void run() {
                ObservableWebView.this.scrollTo(xLocation, 0);
            }
        }, 300);
    }

    public OnScrollChangedCallback getOnScrollChangedCallback() {
        return mOnScrollChangedCallback;
    }

    public void setOnScrollChangedCallback(final OnScrollChangedCallback onScrollChangedCallback) {
        mOnScrollChangedCallback = onScrollChangedCallback;
    }

    /**
     * Impliment in the activity/fragment/view that you want to listen to the
     * webview
     */
    public static interface OnScrollChangedCallback {
        public void onScroll(int l, int t, int oldl, int oldt);

    }

}