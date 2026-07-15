package com.songsari.starflower.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.songsari.starflower.model.DayForecast
import com.songsari.starflower.ui.theme.AppFontFamily
import com.songsari.starflower.ui.theme.rgba

@Composable
fun ForecastView(forecast: List<DayForecast>, modifier: Modifier = Modifier) {
    val text = rgba(245, 247, 255)

    Column(modifier = modifier.fillMaxWidth()) {
        Text(
            "앞으로 3일 관측 지수",
            color = rgba(255, 255, 255, 0.64), fontFamily = AppFontFamily,
            fontSize = 12.5.sp, fontWeight = FontWeight.SemiBold,
            modifier = Modifier.padding(start = 18.dp, top = 10.dp, bottom = 0.dp),
        )

        Column(modifier = Modifier.padding(horizontal = 16.dp, vertical = 2.dp)) {
            forecast.forEachIndexed { i, day ->
                if (i > 0) {
                    Box(
                        Modifier.fillMaxWidth().height(1.dp).background(rgba(255, 255, 255, 0.06))
                    )
                }
                Row(
                    modifier = Modifier.fillMaxWidth().padding(vertical = 9.dp, horizontal = 4.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        day.label,
                        color = text, fontFamily = AppFontFamily,
                        fontSize = 16.sp, fontWeight = FontWeight.Normal,
                        modifier = Modifier.width(37.dp),
                    )
                    WeatherIcon(
                        day.condition, text.copy(alpha = 0.9f), sizeDp = 20.dp,
                        modifier = Modifier.padding(start = 4.dp, end = 14.dp),
                    )
                    // 게이지
                    var barW by remember { mutableIntStateOf(0) }
                    val density = LocalDensity.current
                    Box(
                        modifier = Modifier
                            .weight(1f).padding(end = 12.dp).height(6.dp)
                            .clip(RoundedCornerShape(3.dp))
                            .background(rgba(255, 255, 255, 0.13))
                            .onSizeChanged { barW = it.width },
                    ) {
                        val fillDp = with(density) { (barW * day.score / 100).toDp() }
                        Box(
                            Modifier
                                .width(fillDp.coerceAtLeast(4.dp)).height(6.dp)
                                .clip(RoundedCornerShape(3.dp))
                                .background(text),
                        )
                    }
                    Text(
                        "${day.score}%",
                        color = text, fontFamily = AppFontFamily,
                        fontSize = 16.sp, fontWeight = FontWeight.Normal,
                        textAlign = TextAlign.End,
                        maxLines = 1, softWrap = false,
                        modifier = Modifier.width(46.dp),
                    )
                }
            }
        }
    }
}
