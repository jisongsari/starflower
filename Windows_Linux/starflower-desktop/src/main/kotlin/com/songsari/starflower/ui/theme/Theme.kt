package com.songsari.starflower.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable

private val DarkColors = darkColorScheme(
    primary = rgba(142, 162, 255),
    background = rgba(8, 10, 22),
    surface = rgba(8, 10, 22),
)

/** 앱은 항상 다크 테마(배경이 밤하늘이라 라이트 모드 개념이 없음). */
@Composable
fun StarflowerTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = DarkColors,
        typography = AppTypography,
        content = content,
    )
}
