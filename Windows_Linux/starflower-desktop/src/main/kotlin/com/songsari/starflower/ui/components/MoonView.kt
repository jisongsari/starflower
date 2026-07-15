package com.songsari.starflower.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.songsari.starflower.ui.theme.rgba
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

/**
 * 달 위상 그림. iOS MoonView 와 동일한 구성:
 *   원 전체를 어두운 면으로 → 햇빛 받는 반원을 밝게 → 터미네이터 타원으로 위상 완성.
 * 캔버스 크기는 size*1.4 (달무리 여유), 달 지름은 0.92*size.
 *
 * @param sizeDp 논리 크기(iOS 의 size 파라미터와 동일 의미).
 */
@Composable
fun MoonView(
    illumination: Double,
    waxing: Boolean,
    sizeDp: Dp,
    modifier: Modifier = Modifier,
) {
    // 레이아웃 발자국은 sizeDp 로 잡되(카드 높이 정상화),
    // 달무리는 경계 밖으로 그려 잘리지 않게 한다. (Canvas 는 경계 밖 그리기를 자르지 않음)
    Canvas(modifier = modifier.size(sizeDp)) {
        val sizePx = sizeDp.toPx()
        val k = sizePx / 100f
        val cx = size.width / 2f
        val cy = size.height / 2f
        val R = 46f * k
        val illum = min(max(illumination, 0.0), 1.0)

        val dark = rgba(43, 50, 82)
        val lit = rgba(241, 236, 214)

        // 달무리
        val glowR = R + 14f * k
        drawCircle(
            brush = Brush.radialGradient(
                colors = listOf(
                    rgba(248, 244, 224, 0.55 * (0.35 + 0.5 * illum)),
                    rgba(248, 244, 224, 0.0),
                ),
                center = Offset(cx, cy),
                radius = glowR,
            ),
            radius = glowR,
            center = Offset(cx, cy),
        )

        // 달 원으로 클립
        val moon = Path().apply {
            addOval(Rect(Offset(cx - R, cy - R), Size(R * 2, R * 2)))
        }
        clipPath(moon) {
            // 어두운 면
            drawCircle(color = dark, radius = R, center = Offset(cx, cy))

            // 햇빛 받는 반원
            val rx0 = if (waxing) cx else cx - R
            drawRect(color = lit, topLeft = Offset(rx0, cy - R), size = Size(R, R * 2))

            // 터미네이터 타원
            val tx = R * (1 - 2 * illum).toFloat()
            drawOval(
                color = if (tx < 0) lit else dark,
                topLeft = Offset(cx - abs(tx), cy - R),
                size = Size(abs(tx) * 2, R * 2),
            )

            // 바다(mare) 질감 — iOS 좌표를 k 스케일로 옮김
            fun pt(x: Float, y: Float) = Offset(cx + (x - 50f) * k, cy + (y - 50f) * k)
            drawOval(
                color = rgba(207, 199, 168, 0.25),
                topLeft = pt(42f, 40f).let { Offset(it.x - 14f * k, it.y - 10f * k) },
                size = Size(28f * k, 20f * k),
            )
            drawOval(
                color = rgba(203, 195, 164, 0.20),
                topLeft = pt(60f, 62f).let { Offset(it.x - 9f * k, it.y - 7f * k) },
                size = Size(18f * k, 14f * k),
            )
            drawOval(
                color = rgba(199, 191, 159, 0.22),
                topLeft = pt(64f, 36f).let { Offset(it.x - 4.5f * k, it.y - 4.5f * k) },
                size = Size(9f * k, 9f * k),
            )
        }
    }
}
