package com.songsari.starflower.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import java.io.File

// 폰트 파일은 src/main/resources/font/ 에 pretendard_*.ttf 로 넣는다.
// (안드로이드/위젯용으로 이미 갖고 있는 Pretendard 파일을 그대로 재사용하면 된다)
private fun loadFont(name: String, weight: FontWeight): Font {
    val stream = object {}.javaClass.getResourceAsStream("/font/$name.ttf")
        ?: throw IllegalStateException("폰트를 찾을 수 없음: $name (src/main/resources/font/$name.ttf 확인)")
    val temp = File.createTempFile(name, ".ttf")
    temp.deleteOnExit()
    stream.use { input -> temp.outputStream().use { input.copyTo(it) } }
    return Font(temp, weight)
}

val AppFontFamily: FontFamily = FontFamily(
    loadFont("pretendard_thin", FontWeight.Thin),
    loadFont("pretendard_light", FontWeight.Light),
    loadFont("pretendard_regular", FontWeight.Normal),
    loadFont("pretendard_medium", FontWeight.Medium),
    loadFont("pretendard_semibold", FontWeight.SemiBold),
)

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
