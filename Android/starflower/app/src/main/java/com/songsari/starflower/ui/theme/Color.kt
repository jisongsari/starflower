package com.songsari.starflower.ui.theme

import androidx.compose.ui.graphics.Color

/**
 * iOS 의 `Color.rgba(r, g, b, a)` 와 동일한 헬퍼.
 * 0~255 범위의 RGB 와 0~1 알파를 받아 Compose Color 를 만든다.
 *
 * 예) rgba(245, 247, 255)         // 불투명 흰빛
 *     rgba(46, 120, 138, 0.40)    // 반투명 청록
 */
fun rgba(r: Int, g: Int, b: Int, a: Double = 1.0): Color =
    Color(red = r / 255f, green = g / 255f, blue = b / 255f, alpha = a.toFloat())

/** iOS `Color(hex:)` 대응. "#RRGGBB" 또는 "RRGGBB". */
fun colorHex(hex: String): Color {
    val clean = hex.trim().removePrefix("#")
    val v = clean.toLong(16)
    return Color(
        red = ((v shr 16) and 0xFF) / 255f,
        green = ((v shr 8) and 0xFF) / 255f,
        blue = (v and 0xFF) / 255f,
        alpha = 1f
    )
}
