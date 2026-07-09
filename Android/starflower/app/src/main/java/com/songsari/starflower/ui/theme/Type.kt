package com.songsari.starflower.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.font.FontFamily

/**
 * Pretendard 사용 여부 플래그.
 *
 * 폰트를 적용하려면:
 *   1. res/font/ 에 Pretendard TTF 들을 아래 이름으로 넣는다.
 *        pretendard_thin.ttf        (100)
 *        pretendard_extralight.ttf  (200)
 *        pretendard_light.ttf       (300)
 *        pretendard_regular.ttf     (400)
 *        pretendard_medium.ttf      (500)
 *        pretendard_semibold.ttf    (600)
 *        pretendard_bold.ttf        (700)
 *   2. 아래 pretendardFamily() 의 주석을 해제한다.
 *   3. USE_PRETENDARD 를 true 로 바꾸고, AppFontFamily 의 해당 줄도 활성화한다.
 *
 * 파일을 넣기 전(기본값 false)에는 시스템 폰트로 동작하며,
 * R.font 를 컴파일 시점에 참조하지 않으므로 폰트 파일이 없어도 빌드된다.
 */
const val USE_PRETENDARD = true


private fun pretendardFamily(): FontFamily = FontFamily(
    androidx.compose.ui.text.font.Font(
        com.songsari.starflower.R.font.pretendard_thin,
        androidx.compose.ui.text.font.FontWeight.Thin),
    androidx.compose.ui.text.font.Font(
        com.songsari.starflower.R.font.pretendard_extralight,
        androidx.compose.ui.text.font.FontWeight.ExtraLight),
    androidx.compose.ui.text.font.Font(
        com.songsari.starflower.R.font.pretendard_light,
        androidx.compose.ui.text.font.FontWeight.Light),
    androidx.compose.ui.text.font.Font(
        com.songsari.starflower.R.font.pretendard_regular,
        androidx.compose.ui.text.font.FontWeight.Normal),
    androidx.compose.ui.text.font.Font(
        com.songsari.starflower.R.font.pretendard_medium,
        androidx.compose.ui.text.font.FontWeight.Medium),
    androidx.compose.ui.text.font.Font(
        com.songsari.starflower.R.font.pretendard_semibold,
        androidx.compose.ui.text.font.FontWeight.SemiBold),
    androidx.compose.ui.text.font.Font(
        com.songsari.starflower.R.font.pretendard_bold,
        androidx.compose.ui.text.font.FontWeight.Bold),
    androidx.compose.ui.text.font.Font(
        com.songsari.starflower.R.font.pretendard_black,
        androidx.compose.ui.text.font.FontWeight.Black),
    androidx.compose.ui.text.font.Font(
        com.songsari.starflower.R.font.pretendard_extrabold,
        androidx.compose.ui.text.font.FontWeight.ExtraBold),
)

val AppFontFamily: FontFamily =
    if (USE_PRETENDARD) {
        pretendardFamily()
    } else {
        FontFamily.Default
    }

// Material3 기본 Typography 에 앱 폰트를 입힌다 (폴백 용도).
val AppTypography: Typography = Typography().let { base ->
    Typography(
        displayLarge = base.displayLarge.copy(fontFamily = AppFontFamily),
        displayMedium = base.displayMedium.copy(fontFamily = AppFontFamily),
        displaySmall = base.displaySmall.copy(fontFamily = AppFontFamily),
        headlineLarge = base.headlineLarge.copy(fontFamily = AppFontFamily),
        headlineMedium = base.headlineMedium.copy(fontFamily = AppFontFamily),
        headlineSmall = base.headlineSmall.copy(fontFamily = AppFontFamily),
        titleLarge = base.titleLarge.copy(fontFamily = AppFontFamily),
        titleMedium = base.titleMedium.copy(fontFamily = AppFontFamily),
        titleSmall = base.titleSmall.copy(fontFamily = AppFontFamily),
        bodyLarge = base.bodyLarge.copy(fontFamily = AppFontFamily),
        bodyMedium = base.bodyMedium.copy(fontFamily = AppFontFamily),
        bodySmall = base.bodySmall.copy(fontFamily = AppFontFamily),
        labelLarge = base.labelLarge.copy(fontFamily = AppFontFamily),
        labelMedium = base.labelMedium.copy(fontFamily = AppFontFamily),
        labelSmall = base.labelSmall.copy(fontFamily = AppFontFamily),
    )
}
