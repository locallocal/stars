package com.example.stars

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.AnimatorSet
import android.animation.ObjectAnimator
import android.os.Bundle
import android.view.View
import android.view.animation.DecelerateInterpolator
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        val splashScreen = installSplashScreen()
        super.onCreate(savedInstanceState)

        splashScreen.setOnExitAnimationListener { provider ->
            val splashView = provider.view
            val iconView = provider.iconView

            val fadeOut = ObjectAnimator.ofFloat(splashView, View.ALPHA, 1f, 0f)
            val scaleX = ObjectAnimator.ofFloat(iconView, View.SCALE_X, 1f, 0.92f)
            val scaleY = ObjectAnimator.ofFloat(iconView, View.SCALE_Y, 1f, 0.92f)

            AnimatorSet().apply {
                playTogether(fadeOut, scaleX, scaleY)
                duration = SPLASH_EXIT_DURATION_MS
                interpolator = DecelerateInterpolator()
                addListener(
                    object : AnimatorListenerAdapter() {
                        override fun onAnimationEnd(animation: Animator) {
                            provider.remove()
                            if (!isFinishing && !isDestroyed) {
                                updateSystemUiOverlays()
                            }
                        }
                    },
                )
                start()
            }
        }
    }

    private companion object {
        const val SPLASH_EXIT_DURATION_MS = 180L
    }
}
