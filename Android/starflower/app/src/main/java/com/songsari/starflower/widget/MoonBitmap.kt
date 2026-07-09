package com.songsari.starflower.widget

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RadialGradient
import android.graphics.RectF
import android.graphics.Shader
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

/**
 * 달 위상 비트맵 렌더러.
 *
 * Glance 위젯은 Compose Canvas 를 쓸 수 없어, 앱의 MoonView(Canvas) 로직을
 * android.graphics.Canvas 로 옮겨 미리 Bitmap 을 만들어 Image 로 넣는다.
 * 구성은 MoonView 와 동일: 어두운 면 → 햇빛 반원 → 터미네이터 타원 → 바다 질감 → 달무리.
 *
 * @param sizePx 최종 비트맵 한 변 픽셀. 달 지름은 약 0.92*(sizePx/1.4) 비율을 따른다.
 */
fun renderMoonBitmap(
    illumination: Double,
    waxing: Boolean,
    sizePx: Int,
): Bitmap {
    val bmp = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bmp)

    // MoonView 와 동일 비율: 캔버스는 논리크기 s 의 1.4배, 달 반경 R = 46*(s/100)
    val logical = sizePx / 1.4f
    val k = logical / 100f
    val cx = sizePx / 2f
    val cy = sizePx / 2f
    val R = 46f * k
    val illum = min(max(illumination, 0.0), 1.0)

    val dark = Color.rgb(43, 50, 82)
    val lit = Color.rgb(241, 236, 214)

    val paint = Paint(Paint.ANTI_ALIAS_FLAG)

    // 달무리
    val glowR = R + 14f * k
    val glowAlpha = (0.55 * (0.35 + 0.5 * illum) * 255).toInt().coerceIn(0, 255)
    paint.shader = RadialGradient(
        cx, cy, glowR,
        intArrayOf(Color.argb(glowAlpha, 248, 244, 224), Color.argb(0, 248, 244, 224)),
        floatArrayOf(0f, 1f),
        Shader.TileMode.CLAMP,
    )
    canvas.drawCircle(cx, cy, glowR, paint)
    paint.shader = null

    // 달 원으로 클립
    val save = canvas.save()
    val clip = Path().apply { addCircle(cx, cy, R, Path.Direction.CW) }
    canvas.clipPath(clip)

    // 어두운 면
    paint.color = dark
    canvas.drawCircle(cx, cy, R, paint)

    // 햇빛 받는 반원
    paint.color = lit
    val rx0 = if (waxing) cx else cx - R
    canvas.drawRect(rx0, cy - R, rx0 + R, cy + R, paint)

    // 터미네이터 타원
    val tx = R * (1 - 2 * illum).toFloat()
    paint.color = if (tx < 0) lit else dark
    canvas.drawOval(RectF(cx - abs(tx), cy - R, cx + abs(tx), cy + R), paint)

    // 바다(mare) 질감
    fun pt(x: Float, y: Float) = floatArrayOf(cx + (x - 50f) * k, cy + (y - 50f) * k)
    fun mare(x: Float, y: Float, w: Float, h: Float, a: Int, r: Int, g: Int, b: Int) {
        val c = pt(x, y)
        paint.color = Color.argb(a, r, g, b)
        canvas.drawOval(RectF(c[0] - w, c[1] - h, c[0] + w, c[1] + h), paint)
    }
    mare(42f, 40f, 14f * k, 10f * k, (0.25 * 255).toInt(), 207, 199, 168)
    mare(60f, 62f, 9f * k, 7f * k, (0.20 * 255).toInt(), 203, 195, 164)
    mare(64f, 36f, 4.5f * k, 4.5f * k, (0.22 * 255).toInt(), 199, 191, 159)

    canvas.restoreToCount(save)
    return bmp
}
