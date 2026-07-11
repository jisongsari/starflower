package com.songsari.starflower.widget

import android.content.Context
import android.graphics.Typeface
import androidx.core.content.res.ResourcesCompat
import com.songsari.starflower.R

/**
 * 위젯 캔버스 렌더링용 Pretendard 로더.
 * 앱과 폰트를 공유한다 (res/font/ 의 것을 그대로 사용 → assets 중복 제거).
 */
object WidgetFonts {

    enum class W(val resId: Int, val fallback: Int) {
        THIN(R.font.pretendard_thin, Typeface.NORMAL),
        LIGHT(R.font.pretendard_light, Typeface.NORMAL),
        REGULAR(R.font.pretendard_regular, Typeface.NORMAL),
        MEDIUM(R.font.pretendard_medium, Typeface.NORMAL),
        SEMIBOLD(R.font.pretendard_semibold, Typeface.BOLD),
    }

    private val cache = HashMap<W, Typeface>()

    fun get(context: Context, weight: W): Typeface {
        cache[weight]?.let { return it }
        val tf = try {
            ResourcesCompat.getFont(context, weight.resId)
                ?: Typeface.create(Typeface.SANS_SERIF, weight.fallback)
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