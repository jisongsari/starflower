package com.songsari.starflower.widget

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.RadialGradient
import android.graphics.RectF
import android.graphics.Shader
import com.songsari.starflower.model.Daypart
import com.songsari.starflower.model.SkyCondition
import kotlin.random.Random

/**
 * 위젯 배경 비트맵. iOS WidgetSky 이식.
 * 대각선 그라데이션 + (맑은밤 별 / 맑은낮 해 / 흐림·구름 은은한 구름).
 * Glance 는 그라데이션·드로잉을 직접 못 해서 비트맵으로 만들어 Image 배경으로 깐다.
 */
fun renderSkyBitmap(
    condition: SkyCondition,
    daypart: Daypart,
    widthPx: Int,
    heightPx: Int,
): Bitmap {
    val w = widthPx.coerceAtLeast(1)
    val h = heightPx.coerceAtLeast(1)
    val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bmp)
    val paint = Paint(Paint.ANTI_ALIAS_FLAG)

    // 대각선 그라데이션 (topLeading → bottomTrailing)
    val stops = skyStops(condition, daypart)
    paint.shader = LinearGradient(
        0f, 0f, w.toFloat(), h.toFloat(),
        stops.map { it.second }.toIntArray(),
        stops.map { it.first }.toFloatArray(),
        Shader.TileMode.CLAMP,
    )
    canvas.drawRect(0f, 0f, w.toFloat(), h.toFloat(), paint)
    paint.shader = null

    // 맑은 밤: 별 40개
    if (daypart == Daypart.NIGHT && condition == SkyCondition.CLEAR) {
        val rnd = Random(42)
        for (i in 0 until 40) {
            val x = rnd.nextDouble(0.0, 1.0).toFloat() * w
            val y = rnd.nextDouble(0.0, 0.85).toFloat() * h
            val r = (Math.pow(rnd.nextDouble(0.0, 1.0), 2.0) * 1.3 + 0.4).toFloat() * (w / 170f)
            val a = rnd.nextDouble(0.4, 0.95).toFloat()
            paint.color = Color.argb((a * 255).toInt(), 255, 255, 255)
            canvas.drawCircle(x, y, r, paint)
        }
    }

    // 맑은 낮: 연한 해 (오른쪽 위)
    if (daypart == Daypart.DAY && condition == SkyCondition.CLEAR) {
        val sunX = w * 0.78f
        val sunY = h * 0.22f
        val sunR = w * 0.5f
        paint.shader = RadialGradient(
            sunX, sunY, sunR,
            intArrayOf(Color.argb(128, 255, 240, 180), Color.argb(0, 255, 236, 170)),
            floatArrayOf(0f, 1f),
            Shader.TileMode.CLAMP,
        )
        canvas.drawCircle(sunX, sunY, sunR, paint)
        paint.shader = null
    }

    // 구름은 위젯 비트맵에서 블러 처리가 불가해 어색하므로 넣지 않는다.
    // (그라데이션 자체가 흐림/구름 상태를 색으로 표현)

    return bmp
}

private fun c(r: Int, g: Int, b: Int) = Color.rgb(r, g, b)

/** iOS WidgetSky.stops 이식 (location, color) */
private fun skyStops(condition: SkyCondition, daypart: Daypart): List<Pair<Float, Int>> =
    when (daypart) {
        Daypart.NIGHT -> when (condition) {
            SkyCondition.CLEAR -> listOf(0f to c(8, 10, 34), 0.6f to c(20, 27, 77), 1f to c(33, 42, 110))
            SkyCondition.PARTLY -> listOf(0f to c(12, 18, 44), 1f to c(28, 38, 78))
            else -> listOf(0f to c(26, 32, 48), 1f to c(48, 56, 74))
        }
        Daypart.DAY -> when (condition) {
            SkyCondition.CLEAR -> listOf(0f to c(64, 128, 200), 1f to c(140, 185, 228))
            SkyCondition.PARTLY -> listOf(0f to c(96, 134, 184), 1f to c(168, 193, 220))
            else -> listOf(0f to c(120, 132, 150), 1f to c(168, 177, 189))
        }
        Daypart.DAWN -> listOf(0f to c(38, 52, 98), 0.55f to c(120, 96, 140), 1f to c(224, 176, 140))
        Daypart.DUSK -> listOf(0f to c(34, 44, 92), 0.55f to c(128, 82, 128), 1f to c(228, 160, 116))
    }
