package com.songsari.starflower.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.songsari.starflower.model.Daypart
import com.songsari.starflower.model.SkyCondition
import com.songsari.starflower.ui.StargazingViewModel
import com.songsari.starflower.ui.components.DetailGrid
import com.songsari.starflower.ui.components.ForecastView
import com.songsari.starflower.ui.components.ScoreHero
import com.songsari.starflower.ui.components.SkyBackground
import com.songsari.starflower.ui.components.softLightSurface
import com.songsari.starflower.ui.theme.AppFontFamily
import kotlinx.coroutines.launch

@Composable
fun MainScreen(vm: StargazingViewModel) {
    val data by vm.data.collectAsState()
    val isLoading by vm.isLoading.collectAsState()
    val error by vm.errorMessage.collectAsState()
    val showSearch by vm.showSearch.collectAsState()
    val savedLocation by vm.savedLocation.collectAsState()
    val scope = rememberCoroutineScope()

    Box(modifier = Modifier.fillMaxSize()) {
        val d = data
        if (d != null) {
            SkyBackground(
                condition = d.condition, daypart = d.daypart,
                moonIllum = d.moonIllum, moonPhase = d.moonPhase,
                moonAltitude = d.moonAltitude, cloudCover = d.nightCloud,
                modifier = Modifier.fillMaxSize(),
            )
        } else {
            SkyBackground(
                condition = SkyCondition.CLEAR, daypart = Daypart.NIGHT,
                moonIllum = 0.5, moonPhase = 0.25, moonAltitude = 0.5, cloudCover = 0.0,
                modifier = Modifier.fillMaxSize(),
            )
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Column(
                modifier = Modifier
                    .widthIn(max = 600.dp)   // macOS MainWindowController 의 상한과 동일
                    .fillMaxWidth()
                    .padding(horizontal = 18.dp)
                    .padding(top = 56.dp, bottom = 24.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                when {
                    d != null -> {
                        ScoreHero(d.score, d.condition, d.temperature)
                        Box(modifier = Modifier.softLightSurface(RoundedCornerShape(24.dp))) {
                            ForecastView(d.forecast)
                        }
                        DetailGrid(d)
                        Text(
                            footer(d.location.name, d.location.admin1),
                            color = Color.White.copy(alpha = 0.45f),
                            fontFamily = AppFontFamily, fontSize = 12.sp,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.fillMaxWidth().padding(top = 6.dp, bottom = 8.dp),
                        )
                    }
                    isLoading -> {
                        Box(
                            modifier = Modifier.fillMaxWidth().padding(top = 160.dp),
                            contentAlignment = Alignment.Center,
                        ) {
                            CircularProgressIndicator(color = Color.White)
                        }
                    }
                    error != null -> {
                        Text(
                            error ?: "",
                            color = Color.White.copy(alpha = 0.7f),
                            fontFamily = AppFontFamily, fontSize = 14.sp,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.fillMaxWidth().padding(top = 160.dp)
                                .clickable { scope.launch { vm.loadData() } },
                        )
                    }
                }
            }
        }

        // 상단 바 (위치 이름 + 새로고침)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 18.dp, vertical = 14.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Row(
                modifier = Modifier.clickable { vm.setShowSearch(true) },
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(
                    Icons.Filled.LocationOn, contentDescription = null,
                    tint = Color.White.copy(alpha = 0.85f), modifier = Modifier.size(16.dp),
                )
                Text(
                    savedLocation?.name ?: "위치 선택",
                    color = Color.White.copy(alpha = 0.9f),
                    fontFamily = AppFontFamily, fontSize = 15.sp,
                    modifier = Modifier.padding(start = 6.dp),
                )
            }
            Icon(
                Icons.Filled.Refresh, contentDescription = null,
                tint = Color.White.copy(alpha = 0.85f),
                modifier = Modifier.size(18.dp).clickable { scope.launch { vm.loadData() } },
            )
        }

        if (showSearch) {
            SearchScreen(
                dismissable = savedLocation != null,
                onSelect = { vm.selectLocation(it) },
                onCancel = { vm.setShowSearch(false) },
            )
        }
    }
}

private fun footer(name: String, admin1: String?): String {
    var s = name
    if (admin1 != null) s += " · $admin1"
    return "$s · Open-Meteo"
}
