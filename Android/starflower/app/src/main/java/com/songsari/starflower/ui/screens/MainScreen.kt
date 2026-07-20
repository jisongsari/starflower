package com.songsari.starflower.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Text
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.material3.pulltorefresh.rememberPullToRefreshState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.songsari.starflower.model.Daypart
import com.songsari.starflower.model.SkyCondition
import com.songsari.starflower.model.StargazingData
import com.songsari.starflower.ui.StargazingViewModel
import com.songsari.starflower.ui.components.DetailGrid
import com.songsari.starflower.ui.components.ForecastView
import com.songsari.starflower.ui.components.ScoreHero
import com.songsari.starflower.ui.components.SkyBackground
import com.songsari.starflower.ui.components.softLightSurface
import com.songsari.starflower.ui.components.UiGlyph
import com.songsari.starflower.ui.components.UiIcon
import com.songsari.starflower.ui.theme.AppFontFamily
import com.songsari.starflower.ui.theme.rgba

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen(vm: StargazingViewModel = viewModel()) {
    val data by vm.data.collectAsStateWithLifecycle()
    val isLoading by vm.isLoading.collectAsStateWithLifecycle()
    val error by vm.errorMessage.collectAsStateWithLifecycle()
    val showSearch by vm.showSearch.collectAsStateWithLifecycle()
    val savedLocation by vm.savedLocation.collectAsStateWithLifecycle()

    Box(modifier = Modifier.fillMaxSize()) {
        // 배경
        val d = data
        if (d != null) {
            SkyBackground(
                condition = d.condition, daypart = d.daypart,
                moonIllum = d.moonIllum, moonPhase = d.moonPhase,
                moonAltitude = d.moonAltitude, cloudCover = d.nightCloud,
            )
        } else {
            SkyBackground(
                condition = SkyCondition.CLEAR, daypart = Daypart.NIGHT,
                moonIllum = 0.5, moonPhase = 0.25, moonAltitude = 0.5, cloudCover = 0.0,
            )
        }

        // 스크롤 콘텐츠 + 당겨서 새로고침
        val refreshState = rememberPullToRefreshState()
        PullToRefreshBox(
            isRefreshing = isLoading && data != null,
            onRefresh = { vm.loadData() },
            state = refreshState,
            modifier = Modifier.fillMaxSize(),
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .statusBarsPadding()
                    .padding(top = 56.dp, bottom = 24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                Column(
                    modifier = Modifier
                        .widthIn(max = 600.dp)
                        .fillMaxWidth()
                        .padding(horizontal = 18.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(16.dp),
                ) {
                    when {
                        data == null && isLoading -> LoadingBlock()
                        data == null && error != null -> ErrorBlock(error!!) { vm.loadData() }
                        d != null -> {
                            ScoreHero(d.score, d.condition, d.temperature)
                            Column(
                                verticalArrangement = Arrangement.spacedBy(10.dp)
                            ) {
                                Box(
                                    modifier = Modifier.softLightSurface(RoundedCornerShape(24.dp)),
                                ) { ForecastView(d.forecast) }
                                DetailGrid(d)
                            }
                            Text(
                                footer(d),
                                color = rgba(255, 255, 255, 0.45),
                                fontFamily = AppFontFamily, fontSize = 12.sp,
                                textAlign = TextAlign.Center,
                                modifier = Modifier.padding(top = 6.dp),
                            )
                        }
                    }
                }
            }
        }

        // 상단 바
        Column(modifier = Modifier.statusBarsPadding()) {
            Row(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 6.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.clickable { vm.setShowSearch(true) },
                ) {
                    UiIcon(UiGlyph.LOCATION, rgba(255, 255, 255, 0.95), 15.dp)
                    Text(
                        savedLocation?.name ?: "위치 선택",
                        color = rgba(255, 255, 255, 0.95), fontFamily = AppFontFamily,
                        fontSize = 17.sp, fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.padding(horizontal = 6.dp),
                    )
                    UiIcon(UiGlyph.CHEVRON_DOWN, rgba(255, 255, 255, 0.95), 12.dp)
                }
                Spacer(Modifier.weight(1f))
                if (savedLocation != null) {
                    Box(
                        modifier = Modifier
                            .size(34.dp)
                            .softLightSurface(CircleShape, borderAlpha = 0.12)
                            .clickable { vm.loadData() },
                        contentAlignment = Alignment.Center,
                    ) {
                        UiIcon(UiGlyph.REFRESH, rgba(255, 255, 255, 0.85), 16.dp)
                    }
                }
            }
        }

        // 검색 오버레이
        if (showSearch) {
            SearchScreen(
                dismissable = savedLocation != null,
                onSelect = { vm.selectLocation(it) },
                onCancel = { vm.setShowSearch(false) },
            )
        }
    }
}

@Composable
private fun LoadingBlock() {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.padding(top = 180.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        CircularProgressIndicator(color = rgba(245, 247, 255))
        Text(
            "하늘을 살펴보는 중…",
            color = rgba(255, 255, 255, 0.6), fontFamily = AppFontFamily, fontSize = 14.sp,
        )
    }
}

@Composable
private fun ErrorBlock(msg: String, onRetry: () -> Unit) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.padding(top = 180.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(msg, color = rgba(255, 255, 255, 0.7), fontFamily = AppFontFamily)
        Text(
            "다시 시도",
            color = rgba(245, 247, 255), fontFamily = AppFontFamily, fontWeight = FontWeight.SemiBold,
            modifier = Modifier
                .clip(RoundedCornerShape(99.dp))
                .border(1.dp, rgba(255, 255, 255, 0.2), RoundedCornerShape(99.dp))
                .clickable { onRetry() }
                .padding(horizontal = 20.dp, vertical = 9.dp),
        )
    }
}

private fun footer(d: StargazingData): String {
    var s = d.location.name
    if (d.location.admin1 != null) s += " · ${d.location.admin1}"
    return "$s · Open-Meteo"
}
