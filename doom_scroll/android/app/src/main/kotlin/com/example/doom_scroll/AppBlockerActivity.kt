package com.example.doom_scroll

import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.activity.ComponentActivity

/**
 * Full-screen activity that launches on top of a blocked/exceeded app.
 * Shown by MonitorService when a tracked app that has been locked is detected
 * in the foreground.
 *
 * - Back press → goes to home screen (not back to the blocked app)
 * - "Open DoomScroll" → opens DoomScroll's MainActivity
 * - "Go Home" → goes to home screen
 */
class AppBlockerActivity : ComponentActivity() {

    companion object {
        const val EXTRA_APP_LABEL = "appLabel"
        const val EXTRA_PACKAGE_NAME = "packageName"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val appLabel = intent.getStringExtra(EXTRA_APP_LABEL) ?: "This app"
        val packageName = intent.getStringExtra(EXTRA_PACKAGE_NAME) ?: ""

        // Build the UI programmatically (no XML layout needed)
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(32), dp(48), dp(32), dp(48))
            background = GradientDrawable(
                GradientDrawable.Orientation.TOP_BOTTOM,
                intArrayOf(
                    Color.parseColor("#0A0E1A"),
                    Color.parseColor("#031415"),
                    Color.parseColor("#0A0E1A")
                )
            )
        }

        // Shield icon (text emoji as placeholder)
        val iconView = TextView(this).apply {
            text = "🛡️"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 64f)
            gravity = Gravity.CENTER
        }
        root.addView(iconView)

        // Spacer
        root.addView(spacer(24))

        // "INTERVENTION ACTIVE" label
        val labelView = TextView(this).apply {
            text = "INTERVENTION ACTIVE"
            setTextColor(Color.parseColor("#00E5CC"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            letterSpacing = 0.25f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            gravity = Gravity.CENTER
        }
        root.addView(labelView)

        // Spacer
        root.addView(spacer(20))

        // Main title
        val titleView = TextView(this).apply {
            text = "You've exceeded\nyour $appLabel limit."
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 34f)
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            gravity = Gravity.CENTER
            setLineSpacing(0f, 1.1f)
        }
        root.addView(titleView)

        // Spacer
        root.addView(spacer(16))

        // Subtitle
        val subtitleView = TextView(this).apply {
            text = "Your mind deserves a reset.\nTake a moment to breathe."
            setTextColor(Color.parseColor("#8899AA"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            gravity = Gravity.CENTER
            setLineSpacing(0f, 1.4f)
        }
        root.addView(subtitleView)

        // Spacer
        root.addView(spacer(48))

        // "Open DoomScroll" button
        val openButton = Button(this).apply {
            text = "Open DoomScroll"
            setTextColor(Color.parseColor("#0A0E1A"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            isAllCaps = false
            setPadding(dp(24), dp(16), dp(24), dp(16))
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#00E5CC"))
                cornerRadius = dp(28).toFloat()
            }
            setOnClickListener { openDoomScroll() }
        }
        val buttonParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            dp(56)
        )
        root.addView(openButton, buttonParams)

        // Spacer
        root.addView(spacer(16))

        // "Go Home" button
        val homeButton = Button(this).apply {
            text = "Go Home"
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            isAllCaps = false
            setPadding(dp(24), dp(16), dp(24), dp(16))
            background = GradientDrawable().apply {
                setColor(Color.TRANSPARENT)
                setStroke(dp(1), Color.parseColor("#2A3A4A"))
                cornerRadius = dp(28).toFloat()
            }
            setOnClickListener { goHome() }
        }
        val homeParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            dp(56)
        )
        root.addView(homeButton, homeParams)

        setContentView(root)
    }

    @Deprecated("Use onBackPressedDispatcher instead")
    override fun onBackPressed() {
        // Don't let back go to the blocked app — go home instead
        goHome()
    }

    private fun openDoomScroll() {
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        startActivity(intent)
        finish()
    }

    private fun goHome() {
        val intent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
        finish()
    }

    private fun dp(value: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            resources.displayMetrics
        ).toInt()
    }

    private fun spacer(heightDp: Int): View {
        return View(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(heightDp)
            )
        }
    }
}
