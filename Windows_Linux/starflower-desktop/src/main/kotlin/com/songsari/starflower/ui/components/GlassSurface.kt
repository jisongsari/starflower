package com.songsari.starflower.ui.components

import androidx.compose.foundation.border
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.unit.dp
import com.songsari.starflower.ui.theme.rgba

/**
 * iOS 의 반투명 카드/버튼 배경을 그대로 재현한다.
 *
 *   .background {
 *       Color.black.opacity(0.3).blendMode(.softLight)
 *   }
 *   + 흰색 0.08 테두리
 *
 * softLight 블렌드가 배경과 정확히 섞이려면 요소가 오프스크린 compositing
 * 레이어로 분리돼야 해서 graphicsLayer(compositingStrategy = Offscreen) 를 함께 건다.
 */
fun Modifier.softLightSurface(
    shape: Shape,
    borderAlpha: Double = 0.08,
    darkness: Float = 0.1f,
): Modifier = this
    .clip(shape)
    .graphicsLayer(compositingStrategy = CompositingStrategy.Offscreen)
    .drawBehind {
        drawRect(color = Color.Black.copy(alpha = darkness))//, blendMode = BlendMode.Softlight)
    }
    .border(1.dp, rgba(255, 255, 255, borderAlpha), shape)
