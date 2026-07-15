package com.songsari.starflower.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.ui.text.TextStyle
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.songsari.starflower.calc.ScoreCalculator
import com.songsari.starflower.model.SkyCondition
import com.songsari.starflower.ui.theme.AppFontFamily
import com.songsari.starflower.ui.theme.rgba

@Composable
fun ScoreHero(score: Int, condition: SkyCondition, temperature: Double, modifier: Modifier = Modifier) {
    val text = rgba(245, 247, 255)
    val sub = rgba(255, 255, 255, 0.64)

    Column(
        modifier = modifier.fillMaxWidth().padding(vertical = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            "오늘 밤 관측 지수",
            color = sub, fontFamily = AppFontFamily,
            fontSize = 14.sp, fontWeight = FontWeight.SemiBold,
        )

        Row(verticalAlignment = Alignment.Top) {
            Text(
                "$score",
                color = text, fontFamily = AppFontFamily,
                fontSize = 128.sp, fontWeight = FontWeight.Thin,
                style = TextStyle(letterSpacing = (-10).sp),
            )
            Text(
                "%",
                color = text.copy(alpha = 0.85f), fontFamily = AppFontFamily,
                fontSize = 42.sp, fontWeight = FontWeight.Light,
                modifier = Modifier.padding(top = 22.dp),
            )
        }

        Text(
            ScoreCalculator.verdict(score),
            color = text, fontFamily = AppFontFamily,
            fontSize = 21.sp, fontWeight = FontWeight.SemiBold,
            modifier = Modifier.padding(top = 2.dp),
        )

        Text(
            "${ScoreCalculator.conditionLabel(condition)} · ${temperature.toInt()}°",
            color = sub, fontFamily = AppFontFamily,
            fontSize = 15.sp, fontWeight = FontWeight.Medium,
            modifier = Modifier.padding(top = 5.dp),
        )

        // 게이지
        Box(
            modifier = Modifier
                .padding(top = 16.dp)
                .width(220.dp).height(6.dp)
                .clip(RoundedCornerShape(3.dp))
                .background(rgba(255, 255, 255, 0.14)),
        ) {
            Box(
                modifier = Modifier
                    .width((220 * score / 100).dp).height(6.dp)
                    .clip(RoundedCornerShape(3.dp))
                    .background(text),
            )
        }

        Text(
            "오늘 밤 19-05시",
            color = sub.copy(alpha = 0.6f), fontFamily = AppFontFamily,
            fontSize = 12.sp, fontWeight = FontWeight.Normal,
            modifier = Modifier.padding(top = 10.dp),
        )
    }
}
