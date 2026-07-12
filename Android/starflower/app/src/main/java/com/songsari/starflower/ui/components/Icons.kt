package com.songsari.starflower.ui.components

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AcUnit
import androidx.compose.material.icons.filled.Air
import androidx.compose.material.icons.filled.Bedtime
import androidx.compose.material.icons.filled.Contrast
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.Cloud
import androidx.compose.material.icons.filled.CloudQueue
import androidx.compose.material.icons.filled.Grain
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Speed
import androidx.compose.material.icons.filled.WaterDrop
import androidx.compose.material.icons.filled.WbTwilight
import androidx.compose.material.icons.filled.History
import androidx.compose.material3.Icon
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.songsari.starflower.model.SkyCondition


// 기존 호출부 호환을 위해 enum 은 그대로 유지한다.
enum class GlyphKind { SUNSET, MOON, MOONPHASE, CLOUD, HUMIDITY, WIND, GAUGE, AQI }
enum class UiGlyph { SEARCH, CLOSE, LOCATION, CHEVRON_DOWN, REFRESH, HISTORY }

/** 디테일 카드 라벨 아이콘 (Material Icons) */
@Composable
fun DetailGlyph(kind: GlyphKind, color: Color, sizeDp: Dp = 15.dp, modifier: Modifier = Modifier) {
    val icon: ImageVector = when (kind) {
        GlyphKind.SUNSET -> Icons.Filled.WbTwilight
        GlyphKind.MOON -> Icons.Filled.Bedtime
        GlyphKind.MOONPHASE -> Icons.Filled.Contrast
        GlyphKind.CLOUD -> Icons.Filled.Cloud
        GlyphKind.HUMIDITY -> Icons.Filled.WaterDrop
        GlyphKind.WIND -> Icons.Filled.Air
        GlyphKind.GAUGE -> Icons.Filled.Speed
        GlyphKind.AQI -> Icons.Filled.Grain
    }
    Icon(icon, contentDescription = null, tint = color, modifier = modifier.size(sizeDp))
}

/** 예보/조건 날씨 아이콘 (Material Icons). 달위상은 MoonView 를 별도로 쓴다. */
@Composable
fun WeatherIcon(condition: SkyCondition, color: Color, sizeDp: Dp = 22.dp, modifier: Modifier = Modifier) {
    val icon: ImageVector = when (condition) {
        SkyCondition.CLEAR -> Icons.Filled.Bedtime          // 맑은 밤 = 초승달
        SkyCondition.PARTLY -> Icons.Filled.CloudQueue       // 구름 조금
        SkyCondition.CLOUDY, SkyCondition.OVERCAST, SkyCondition.FOG -> Icons.Filled.Cloud
        SkyCondition.RAIN -> Icons.Filled.Grain              // 비
        SkyCondition.SNOW -> Icons.Filled.AcUnit             // 눈
    }
    Icon(icon, contentDescription = null, tint = color, modifier = modifier.size(sizeDp))
}

/** 검색/상단바 UI 아이콘 (Material Icons) */
@Composable
fun UiIcon(kind: UiGlyph, color: Color, sizeDp: Dp, modifier: Modifier = Modifier) {
    val icon: ImageVector = when (kind) {
        UiGlyph.SEARCH -> Icons.Filled.Search
        UiGlyph.CLOSE -> Icons.Filled.Cancel
        UiGlyph.LOCATION -> Icons.Filled.LocationOn
        UiGlyph.CHEVRON_DOWN -> Icons.Filled.KeyboardArrowDown
        UiGlyph.REFRESH -> Icons.Filled.Refresh
        UiGlyph.HISTORY -> Icons.Filled.History
    }
    Icon(icon, contentDescription = null, tint = color, modifier = modifier.size(sizeDp))
}
