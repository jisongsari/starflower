package com.songsari.starflower.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.BlurredEdgeTreatment
import androidx.compose.ui.unit.dp
import com.songsari.starflower.model.Daypart
import com.songsari.starflower.model.SkyCondition
import com.songsari.starflower.ui.theme.SkyThemeProvider
import com.songsari.starflower.ui.theme.rgba
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

@Composable
fun SkyBackground(
    condition: SkyCondition,
    daypart: Daypart,
    moonIllum: Double,
    moonPhase: Double,
    moonAltitude: Double,
    cloudCover: Double,
    modifier: Modifier = Modifier,
) {
    val theme = SkyThemeProvider.theme(condition, daypart)
    val moonVisible = theme.showMoon && moonAltitude > 0.02
    val moonTop = 0.22 - min(1.0, max(0.0, sin(moonAltitude))) * 0.06
    val moonSize = 104.0 + moonIllum * 34.0

    // 운량 0~1, 10% 이하는 0 (완전 맑음), 10~100%를 0~1로 재매핑
    val coverage = run {
        val c = cloudCover / 100.0
        if (c <= 0.10) 0.0 else ((c - 0.10) / 0.90).coerceIn(0.0, 1.0)
    }
    val cloudOpacity = run {
        if (coverage <= 0.0) 0.0
        else {
            val base = theme.cloudOpacity
            if (base <= 0.03) coverage * 0.5 else min(1.0, base * (0.4 + 0.6 * coverage))
        }
    }

    BoxWithConstraints(modifier = modifier.fillMaxSize()) {
        val w = maxWidth
        val h = maxHeight

        // 배경 그라데이션
        Canvas(Modifier.fillMaxSize()) { drawSky(condition, daypart) }

        // 해 (맑은 낮) — 그라데이션과 분리해 자체 블러
        if (daypart == Daypart.DAY && condition == SkyCondition.CLEAR) {
            Canvas(Modifier.fillMaxSize().blur(40.dp, BlurredEdgeTreatment.Unbounded)) {
                val c = Offset(size.width * 0.8f, size.height * 0.12f)
                val r = size.width * 0.63f
                drawCircle(
                    brush = Brush.radialGradient(
                        colors = listOf(rgba(255, 240, 180, 0.9), rgba(255, 236, 170, 0.0)),
                        center = c, radius = r,
                    ),
                    radius = r, center = c,
                )
            }
        }

        // 별
        Starfield(theme.starOpacity, Modifier.fillMaxSize())

        // 달
        if (moonVisible) {
            // MoonView 발자국이 sizeDp 이므로 그 절반으로 중심 정렬 (달무리는 밖으로 흘러 안 잘림)
            val offX = w * 0.18f - (moonSize / 2).dp
            val offY = h * moonTop.toFloat() - (moonSize / 2).dp
            MoonView(
                illumination = moonIllum,
                waxing = moonPhase < 0.5,
                sizeDp = moonSize.dp,
                modifier = Modifier.offset(x = offX, y = offY),
            )
        }

        // 구름
        CloudView(cloudOpacity, theme.cloudTint, coverage, Modifier.fillMaxSize())

        // 하단 비네트
        Canvas(Modifier.fillMaxSize()) {
            drawRect(
                brush = Brush.verticalGradient(
                    colors = listOf(Color.Transparent, Color.Black.copy(alpha = 0.28f)),
                    startY = size.height * 0.5f,
                    endY = size.height,
                )
            )
        }
    }
}

// ── 배경 그라데이션 그리기 ────────────────────────────────
private fun DrawScope.drawSky(c: SkyCondition, dp: Daypart) {
    when (dp) {
        Daypart.NIGHT -> nightSky(c)
        Daypart.DAY -> daySky(c)
        Daypart.DAWN -> twilightSky(c, dawn = true)
        Daypart.DUSK -> twilightSky(c, dawn = false)
    }
}

private fun DrawScope.linearV(vararg stops: Pair<Float, Color>) {
    drawRect(brush = Brush.verticalGradient(*stops))
}

private fun DrawScope.radialOverlay(
    cx: Float, cy: Float, rFrac: Float, vararg stops: Pair<Float, Color>,
) {
    drawRect(
        brush = Brush.radialGradient(
            *stops,
            center = Offset(size.width * cx, size.height * cy),
            radius = max(size.width, size.height) * rFrac,
        )
    )
}

private fun DrawScope.nightSky(c: SkyCondition) {
    when (c) {
        SkyCondition.CLEAR -> {
            linearV(
                0f to rgba(5, 6, 22), 0.38f to rgba(10, 14, 46),
                0.72f to rgba(19, 26, 77), 1f to rgba(29, 37, 102),
            )
            radialOverlay(
                0.78f, -0.10f, 0.8f,
                0f to rgba(96, 72, 168, 0.45), 1f to rgba(96, 72, 168, 0.0),
            )
            radialOverlay(
                0.5f, 1.18f, 0.9f,
                0f to rgba(46, 120, 138, 0.40), 1f to rgba(46, 120, 138, 0.0),
            )
        }
        SkyCondition.PARTLY -> {
            linearV(
                0f to rgba(10, 16, 36), 0.55f to rgba(20, 29, 62), 1f to rgba(36, 48, 86),
            )
            radialOverlay(
                0.5f, 1.15f, 0.85f,
                0f to rgba(70, 96, 150, 0.40), 1f to rgba(70, 96, 150, 0.0),
            )
        }
        SkyCondition.CLOUDY -> linearV(
            0f to rgba(26, 32, 48), 0.5f to rgba(38, 46, 63), 1f to rgba(53, 62, 80),
        )
        SkyCondition.OVERCAST -> linearV(
            0f to rgba(35, 39, 47), 0.5f to rgba(47, 52, 61), 1f to rgba(59, 65, 75),
        )
        SkyCondition.FOG -> linearV(
            0f to rgba(42, 44, 56), 0.55f to rgba(58, 58, 72), 1f to rgba(70, 68, 79),
        )
        SkyCondition.SNOW -> linearV(
            0f to rgba(31, 39, 56), 0.55f to rgba(49, 60, 82), 1f to rgba(74, 90, 118),
        )
        SkyCondition.RAIN -> linearV(
            0f to rgba(22, 29, 40), 0.55f to rgba(32, 48, 58), 1f to rgba(43, 65, 74),
        )
    }
}

private fun DrawScope.daySky(c: SkyCondition) {
    when (c) {
        SkyCondition.CLEAR -> linearV(
            0f to rgba(47, 116, 192), 0.45f to rgba(79, 147, 212), 1f to rgba(143, 192, 232),
        )   // 해는 별도 블러 레이어에서 그린다 (SkyBackground 본문)
        SkyCondition.PARTLY -> linearV(
            0f to rgba(90, 130, 180), 0.5f to rgba(125, 159, 198), 1f to rgba(170, 195, 222),
        )
        SkyCondition.CLOUDY, SkyCondition.OVERCAST -> linearV(
            0f to rgba(116, 128, 145), 0.5f to rgba(139, 149, 163), 1f to rgba(163, 171, 182),
        )
        SkyCondition.FOG -> linearV(
            0f to rgba(154, 154, 166), 0.5f to rgba(174, 174, 184), 1f to rgba(194, 194, 202),
        )
        SkyCondition.SNOW -> linearV(
            0f to rgba(138, 155, 184), 0.5f to rgba(174, 188, 207), 1f to rgba(211, 221, 233),
        )
        SkyCondition.RAIN -> linearV(
            0f to rgba(95, 111, 126), 0.5f to rgba(118, 133, 143), 1f to rgba(144, 156, 165),
        )
    }
}

private fun DrawScope.twilightSky(c: SkyCondition, dawn: Boolean) {
    if (c == SkyCondition.CLEAR || c == SkyCondition.PARTLY || c == SkyCondition.CLOUDY) {
        if (dawn) {
            linearV(
                0f to rgba(22, 36, 74), 0.34f to rgba(59, 58, 107), 0.56f to rgba(111, 86, 136),
                0.76f to rgba(184, 127, 147), 1f to rgba(227, 180, 141),
            )
            radialOverlay(
                0.5f, 1.13f, 0.85f,
                0f to rgba(255, 200, 150, 0.50), 0.5f to rgba(240, 170, 170, 0.22),
                1f to rgba(240, 170, 170, 0.0),
            )
        } else {
            linearV(
                0f to rgba(20, 34, 78), 0.32f to rgba(58, 49, 104), 0.55f to rgba(122, 79, 126),
                0.76f to rgba(194, 114, 127), 1f to rgba(231, 165, 118),
            )
            radialOverlay(
                0.5f, 1.13f, 0.85f,
                0f to rgba(255, 170, 120, 0.55), 0.47f to rgba(255, 150, 140, 0.25),
                1f to rgba(255, 150, 140, 0.0),
            )
        }
    } else {
        if (dawn) daySky(c) else nightSky(c)
    }
}
