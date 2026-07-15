package com.songsari.starflower.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import kotlin.math.roundToInt
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.songsari.starflower.calc.ScoreCalculator
import com.songsari.starflower.model.StargazingData
import com.songsari.starflower.ui.theme.AppFontFamily
import com.songsari.starflower.ui.theme.rgba
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

private val cardShape = RoundedCornerShape(24.dp)
private val valueColor = rgba(245, 247, 255)
private val subColor = rgba(255, 255, 255, 0.64)
private val unitColor = rgba(255, 255, 255, 0.55)

private fun hhmm(d: Date?): String =
    if (d == null) "—" else SimpleDateFormat("HH:mm", Locale.US).format(d)

@Composable
fun DetailGrid(data: StargazingData, modifier: Modifier = Modifier) {
    Column(modifier = modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            DetailCard(GlyphKind.SUNSET, "일몰") {
                ValueText(hhmm(data.sunset)); SubText("일출 ${hhmm(data.sunrise)}")
            }
            DetailCard(GlyphKind.MOON, "월출") {
                ValueText(hhmm(data.moonrise)); SubText("월몰 ${hhmm(data.moonset)}")
            }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            DetailCard(GlyphKind.MOONPHASE, "달 위상") {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    MoonView(data.moonIllum, data.moonPhase < 0.5, sizeDp = 46.dp)
                    Column(modifier = Modifier.padding(start = 10.dp)) {
                        ValueText("${(data.moonIllum * 100).roundToInt()}%")
                        SubText(data.moonName)
                    }
                }
            }
            DetailCard(GlyphKind.CLOUD, "운량") {
                ValueText("${data.nightCloud.roundToInt()}%")
                SubText("오늘 밤 · ${ScoreCalculator.cloudLabel(data.nightCloud)}")
            }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            DetailCard(GlyphKind.HUMIDITY, "습도") {
                ValueText("${data.nightHumidity.roundToInt()}%")
                SubText("오늘 밤 · ${ScoreCalculator.humLabel(data.nightHumidity)}")
            }
            DetailCard(GlyphKind.WIND, "풍속") {
                ValueUnit(String.format(Locale.US, "%.1f", data.nightWind), "m/s")
                SubText("오늘 밤 · ${ScoreCalculator.windLabel(data.nightWind)}")
            }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            DetailCard(GlyphKind.GAUGE, "기압") {
                ValueUnit(String.format(Locale.US, "%,d", data.pressure.roundToInt()), "hPa")
                SubText("지금")
            }
            DetailCard(GlyphKind.AQI, "미세먼지") {
                ValueUnit("${data.nightPm25.roundToInt()}", "㎍/㎥")
                SubText("오늘 밤 · ${ScoreCalculator.pmLabel(data.nightPm25)}")
            }
        }
    }
}

@Composable
private fun RowScope.DetailCard(
    icon: GlyphKind,
    label: String,
    content: @Composable () -> Unit,
) {
    Column(
        modifier = Modifier
            .weight(1f)
            .defaultMinSize(minHeight = 68.dp)
            .softLightSurface(cardShape)
            .padding(start = 16.dp, end = 16.dp, top = 10.dp, bottom = 10.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            DetailGlyph(icon, subColor, sizeDp = 14.dp)
            Text(
                label, color = subColor, fontFamily = AppFontFamily,
                fontSize = 12.5.sp, fontWeight = FontWeight.SemiBold,
                modifier = Modifier.padding(start = 5.dp),
            )
        }
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) { content() }
    }
}

@Composable
private fun ValueText(s: String) {
    Text(
        s, color = valueColor, fontFamily = AppFontFamily,
        fontSize = 30.sp, fontWeight = FontWeight.Light,
        maxLines = 1,
        style = TextStyle(
            letterSpacing = (-0.6).sp,
            lineHeight = 32.sp,
        ),
    )
}

@Composable
private fun ValueUnit(value: String, unit: String) {
    Row(verticalAlignment = Alignment.Bottom) {
        Text(
            value, color = valueColor, fontFamily = AppFontFamily,
            fontSize = 30.sp, fontWeight = FontWeight.Light, maxLines = 1,
            style = TextStyle(
                letterSpacing = (-0.6).sp,
                lineHeight = 32.sp,
            ),
        )
        Text(
            unit, color = unitColor, fontFamily = AppFontFamily,
            fontSize = 15.sp, fontWeight = FontWeight.Medium,
            modifier = Modifier.padding(start = 2.dp, bottom = 3.dp),
        )
    }
}

@Composable
private fun SubText(s: String) {
    Text(
        s, color = subColor, fontFamily = AppFontFamily,
        fontSize = 12.5.sp, fontWeight = FontWeight.Medium,
    )
}
