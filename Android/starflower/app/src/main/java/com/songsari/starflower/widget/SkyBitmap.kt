package com.songsari.starflower.widget

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Matrix
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

    // 맑은 밤: 작은 별 다수 (자연스러운 밤하늘)
    if (daypart == Daypart.NIGHT && condition == SkyCondition.CLEAR) {
        val rnd = Random(42)
        val area = w.toDouble() * h.toDouble()
        val count = (area / 6500.0).toInt().coerceIn(30, 160)
        val unit = minOf(w, h) / 300f          // 폭 큰 4x2 에서도 별이 커지지 않도록 min 기준
        for (i in 0 until count) {
            val x = rnd.nextDouble(0.0, 1.0).toFloat() * w
            val y = rnd.nextDouble(0.0, 0.88).toFloat() * h
            val r = (Math.pow(rnd.nextDouble(0.0, 1.0), 2.3) * 0.9 + 0.45).toFloat() * unit
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

    // 구름: iOS 처럼 중심만 진하고 밖으로 사라지는 RadialGradient 타원
    // (단색+블러는 중심이 꽉 차 뭉툭 → 그라데이션이라야 배경과 자연스럽게 섞임)
    val cloudAlpha = when (condition) {
        SkyCondition.CLOUDY, SkyCondition.OVERCAST, SkyCondition.FOG,
        SkyCondition.RAIN, SkyCondition.SNOW -> 0.22
        SkyCondition.PARTLY -> 0.14
        else -> 0.0
    }
    if (cloudAlpha > 0.0) {
        val cloudPaint = Paint(Paint.ANTI_ALIAS_FLAG)
        // 크고 적게 깔아 화면 전반에 은은하게 (점점이 박힌 느낌 제거)
        val blobs = listOf(
            Blob(0.30f, 0.28f, 1.25f, 1.0f),
            Blob(0.78f, 0.62f, 1.15f, 0.8f),
        )
        for (b in blobs) {
            val bw = w * b.wRatio
            val bh = bw * 0.62f
            val cx = w * b.x
            val cy = h * b.y
            val a = (cloudAlpha * b.o * 255).toInt().coerceIn(0, 255)
            val grad = RadialGradient(
                cx, cy, bw * 0.5f,
                intArrayOf(Color.argb(a, 255, 255, 255), Color.argb(0, 255, 255, 255)),
                floatArrayOf(0f, 1f),
                Shader.TileMode.CLAMP,
            )
            // 세로로 눌러 넓게 퍼지는 타원형 그라데이션
            val m = Matrix()
            m.setScale(1f, bh / bw, cx, cy)
            grad.setLocalMatrix(m)
            cloudPaint.shader = grad
            canvas.drawRect(cx - bw / 2f, cy - bh / 2f, cx + bw / 2f, cy + bh / 2f, cloudPaint)
            cloudPaint.shader = null
        }
    }

    return bmp
}

private data class Blob(val x: Float, val y: Float, val wRatio: Float, val o: Float)

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