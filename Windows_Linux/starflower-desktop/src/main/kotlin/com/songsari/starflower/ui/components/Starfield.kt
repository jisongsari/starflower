package com.songsari.starflower.ui.components

import androidx.compose.animation.core.withInfiniteAnimationFrameMillis
import androidx.compose.foundation.Canvas
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import com.songsari.starflower.ui.theme.rgba
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.sin
import kotlin.random.Random
import androidx.compose.ui.graphics.Brush

private data class Star(
    val x: Double, val y: Double, val r: Double,
    val baseA: Double, val speed: Double, val phase: Double,
)

/**
 * 밤하늘 별. iOS StarfieldView 와 동일:
 * 미리 생성한 별 풀에서 화면 면적·opacity 에 비례한 개수만 그리고, sin 으로 반짝임.
 */
@Composable
fun Starfield(opacity: Double, modifier: Modifier = Modifier) {
    if (opacity <= 0.02) return

    val stars = remember {
        List(600) {
            Star(
                x = Random.nextDouble(0.0, 1.0),
                y = Random.nextDouble(0.0, 0.92),
                r = Random.nextDouble(0.0, 1.0).pow(2.2) * 0.75 + 0.03,
                baseA = Random.nextDouble(0.35, 0.95),
                speed = Random.nextDouble(0.4, 2.0),
                phase = Random.nextDouble(0.0, 2 * Math.PI),
            )
        }
    }

    val timeSec by produceState(0f) {
        while (true) {
            withInfiniteAnimationFrameMillis { value = it / 1000f }
        }
    }

    Canvas(modifier = modifier) {
        val area = size.width.toDouble() * size.height.toDouble()
        val count = min(stars.size, (area / 13000.0 * opacity).toInt())
        val t = timeSec.toDouble()
        for (i in 0 until count) {
            val s = stars[i]
            val tw = 0.55 + 0.45 * sin(t * s.speed + s.phase)
            val a = (s.baseA * tw * opacity).toFloat().coerceIn(0f, 1f)
            val x = (s.x * size.width).toFloat()
            val y = (s.y * size.height).toFloat()
            val r = (s.r * density).toFloat()

            // 빛무리(부드러운 radial gradient)를 먼저, 그 위에 별 본체
            if (s.r > 0.55) {
                val h = r * 3.6f
                drawCircle(
                    brush = Brush.radialGradient(
                        colors = listOf(
                            rgba(205, 222, 255, (a * 0.55).toDouble()),
                            rgba(205, 222, 255, 0.0),
                        ),
                        center = Offset(x, y),
                        radius = h,
                    ),
                    radius = h,
                    center = Offset(x, y),
                )
            }
            val color = if (s.r > 1.0) rgba(220, 230, 255) else Color.White
            drawCircle(color = color.copy(alpha = a), radius = r, center = Offset(x, y))
        }
    }
}
