package com.songsari.starflower.ui.components

import androidx.compose.animation.core.withInfiniteAnimationFrameMillis
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.BlurredEdgeTreatment
import androidx.compose.ui.unit.dp
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min
import kotlin.random.Random

private data class Blob(
    val y: Double, val w: Float, val dur: Double, val o: Double,
    val phase: Double, val jitterY: Double,
)

/**
 * 떠다니는 구름. iOS CloudView 이식(모바일은 창 리사이즈가 없어 단순화).
 * 각 덩어리는 화면 밖에서 들어와 반대편 밖으로 나가며 무한 순환하고,
 * 시작 위상이 무작위라 처음부터 화면 전체에 흩어져 있다.
 * blur 대신 radial 그라데이션(색→투명)으로 부드러움을 낸다(구버전 호환).
 */
@Composable
fun CloudView(opacity: Double, tint: Color, coverage: Double, modifier: Modifier = Modifier) {
    if (opacity <= 0.03) return

    val timeSec by produceState(0f) {
        while (true) {
            withInfiniteAnimationFrameMillis { value = it / 1000f }
        }
    }

    val basePool = remember {
        List(48) { i ->
            val rnd = Random(i * 1013904223 + 1)
            Blob(
                y = 0.02 + rnd.nextDouble() * 0.44,
                w = (220 + rnd.nextDouble() * 200).toFloat(),
                dur = 70 + rnd.nextDouble() * 60,
                o = 0.45 + rnd.nextDouble() * 0.45,
                phase = rnd.nextDouble(),
                jitterY = (rnd.nextDouble() - 0.5) * 0.04,
            )
        }
    }

    Canvas(modifier = modifier.fillMaxSize().blur(18.dp, BlurredEdgeTreatment.Unbounded)) {
        val w = size.width
        val h = size.height
        val density = coverage.coerceIn(0.0, 1.0)
        val maxByWidth = ceil(w / 320.0).toInt() + 1
        val count = min(basePool.size, max(if (density > 0) 1 else 0, (maxByWidth * 2 * density).toInt()))
        val t = timeSec.toDouble()

        for (i in 0 until count) {
            val b = basePool[i]
            val wPx = b.w.dp.toPx()          // iOS 값은 dp 기준 → 픽셀로 변환
            val travel = w + wPx
            val prog = ((t / b.dur + b.phase) % 1.0)
            val x = -wPx / 2f + travel * prog.toFloat()
            val cy = (h * (b.y + b.jitterY)).toFloat()
            val brush = Brush.radialGradient(
                colors = listOf(tint.copy(alpha = (tint.alpha * b.o).toFloat()), Color.Transparent),
                center = Offset(x, cy),
                radius = wPx * 0.5f,
            )
            drawOval(
                brush = brush,
                topLeft = Offset(x - wPx / 2f, cy - wPx * 0.25f),
                size = Size(wPx, wPx * 0.5f),
                alpha = opacity.toFloat().coerceIn(0f, 1f),
            )
        }
    }
}
