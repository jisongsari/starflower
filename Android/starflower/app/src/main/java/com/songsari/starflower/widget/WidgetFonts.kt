package com.songsari.starflower.widget

import android.content.Context
import android.graphics.Typeface

object WidgetFonts {

    enum class W(val asset: String, val fallback: Int) {
        THIN("fonts/pretendard_thin.ttf", Typeface.NORMAL),
        LIGHT("fonts/pretendard_light.ttf", Typeface.NORMAL),
        REGULAR("fonts/pretendard_regular.ttf", Typeface.NORMAL),
        MEDIUM("fonts/pretendard_medium.ttf", Typeface.NORMAL),
        SEMIBOLD("fonts/pretendard_semibold.ttf", Typeface.BOLD),
    }

    private val cache = HashMap<W, Typeface>()

    fun get(context: Context, weight: W): Typeface {
        cache[weight]?.let { return it }
        val tf = try {
            Typeface.createFromAsset(context.assets, weight.asset)
        } catch (e: Exception) {
            when (weight) {
                W.THIN, W.LIGHT -> Typeface.create("sans-serif-thin", Typeface.NORMAL)
                else -> Typeface.create(Typeface.SANS_SERIF, weight.fallback)
            }
        }
        cache[weight] = tf
        return tf
    }
}