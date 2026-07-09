package com.songsari.starflower.ui.theme

import androidx.compose.ui.graphics.Color
import com.songsari.starflower.model.Daypart
import com.songsari.starflower.model.SkyCondition

/** iOS SkyTheme 대응: 별/구름 농도, 구름 색, 달 표시 여부 */
data class SkyTheme(
    val starOpacity: Double,
    val cloudOpacity: Double,
    val cloudTint: Color,
    val showMoon: Boolean,
)

object SkyThemeProvider {

    fun theme(c: SkyCondition, dp: Daypart): SkyTheme = when (dp) {
        Daypart.DAY -> day(c)
        Daypart.NIGHT -> night(c)
        Daypart.DAWN, Daypart.DUSK ->
            if (c == SkyCondition.CLEAR || c == SkyCondition.PARTLY || c == SkyCondition.CLOUDY)
                twilight(c, dp == Daypart.DAWN)
            else if (dp == Daypart.DAWN) day(c) else night(c)
    }

    private fun night(c: SkyCondition): SkyTheme = when (c) {
        SkyCondition.CLEAR -> SkyTheme(1.0, 0.0, rgba(180, 190, 230, 0.5), true)
        SkyCondition.PARTLY -> SkyTheme(0.5, 0.42, rgba(150, 165, 205, 0.55), true)
        SkyCondition.CLOUDY -> SkyTheme(0.14, 0.78, rgba(120, 132, 158, 0.7), false)
        SkyCondition.OVERCAST -> SkyTheme(0.0, 1.0, rgba(108, 116, 130, 0.8), false)
        SkyCondition.FOG -> SkyTheme(0.0, 0.9, rgba(150, 148, 166, 0.7), false)
        SkyCondition.SNOW -> SkyTheme(0.1, 0.85, rgba(180, 192, 216, 0.7), false)
        SkyCondition.RAIN -> SkyTheme(0.0, 0.92, rgba(96, 116, 128, 0.75), false)
    }

    private fun day(c: SkyCondition): SkyTheme = when (c) {
        SkyCondition.CLEAR -> SkyTheme(0.0, 0.0, Color.White.copy(alpha = 0.8f), false)
        SkyCondition.PARTLY -> SkyTheme(0.0, 0.5, Color.White.copy(alpha = 0.92f), false)
        SkyCondition.CLOUDY -> SkyTheme(0.0, 0.75, Color.White.copy(alpha = 0.85f), false)
        SkyCondition.OVERCAST -> SkyTheme(0.0, 1.0, Color.White.copy(alpha = 0.85f), false)
        SkyCondition.FOG -> SkyTheme(0.0, 0.9, Color.White.copy(alpha = 0.8f), false)
        SkyCondition.SNOW -> SkyTheme(0.0, 0.8, Color.White.copy(alpha = 0.95f), false)
        SkyCondition.RAIN -> SkyTheme(0.0, 0.95, rgba(235, 240, 245, 0.8), false)
    }

    private fun twilight(c: SkyCondition, dawn: Boolean): SkyTheme {
        val cloudOpacity = when (c) {
            SkyCondition.CLEAR -> 0.0
            SkyCondition.PARTLY -> 0.4
            else -> 0.7
        }
        val starOpacity = when (c) {
            SkyCondition.CLEAR -> if (dawn) 0.12 else 0.18
            SkyCondition.PARTLY -> 0.08
            else -> 0.0
        }
        return SkyTheme(
            starOpacity = starOpacity,
            cloudOpacity = cloudOpacity,
            cloudTint = if (dawn) rgba(244, 180, 162, 0.58) else rgba(242, 152, 142, 0.6),
            showMoon = c == SkyCondition.CLEAR || c == SkyCondition.PARTLY,
        )
    }
}
