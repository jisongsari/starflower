package com.songsari.starflower.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable

/**
 * 앱은 항상 어두운 밤하늘 배경 위에서 동작하므로 다크 컬러스킴으로 고정한다.
 * (iOS 의 .preferredColorScheme(.dark) 와 동일)
 *
 * 실제 화면 색은 대부분 직접 지정하므로 ColorScheme 은 시스템 위젯(셀렉션 핸들 등)
 * 폴백 용도이며, 텍스트 기본색만 밝게 맞춰둔다.
 */
private val DarkColors = darkColorScheme(
    background = rgba(5, 6, 22),
    surface = rgba(10, 14, 46),
    primary = rgba(142, 162, 255),
    onBackground = rgba(245, 247, 255),
    onSurface = rgba(245, 247, 255),
)

@Composable
fun StarflowerTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = DarkColors,
        typography = AppTypography,
        content = content
    )
}
