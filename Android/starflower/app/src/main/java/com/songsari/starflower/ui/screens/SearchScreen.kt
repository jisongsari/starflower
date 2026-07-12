package com.songsari.starflower.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.songsari.starflower.data.GeoService
import com.songsari.starflower.data.RecentSearchStore
import com.songsari.starflower.model.GeoResult
import com.songsari.starflower.ui.components.UiGlyph
import com.songsari.starflower.ui.components.UiIcon
import com.songsari.starflower.ui.theme.AppFontFamily
import com.songsari.starflower.ui.theme.rgba
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.launch

@Composable
fun SearchScreen(
    dismissable: Boolean,
    onSelect: (GeoResult) -> Unit,
    onCancel: () -> Unit,
) {
    var query by remember { mutableStateOf("") }
    var results by remember { mutableStateOf<List<GeoResult>>(emptyList()) }
    var loading by remember { mutableStateOf(false) }
    var hint by remember { mutableStateOf<String?>(null) }
    var recents by remember { mutableStateOf<List<GeoResult>>(emptyList()) }

    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    val focus = remember { FocusRequester() }
    LaunchedEffect(Unit) {
        delay(120)
        runCatching { focus.requestFocus() }
    }

    // 최근 검색 기록 로드
    LaunchedEffect(Unit) {
        recents = RecentSearchStore.load(context)
    }

    // 디바운스 검색
    LaunchedEffect(Unit) {
        snapshotFlow { query.trim() }
            .distinctUntilChanged()
            .debounce(500)
            .collect { q ->
                if (q.length < 2) {
                    results = emptyList(); hint = null; loading = false
                    return@collect
                }
                loading = true; hint = null
                val r = GeoService.search(q)
                if (query.trim() == q) {
                    results = r
                    hint = if (r.isEmpty()) "검색 결과가 없어요. 다른 이름으로 찾아보세요." else null
                    loading = false
                }
            }
    }

    Box(
        modifier = Modifier.fillMaxSize().background(rgba(8, 10, 22, 0.96)),
    ) {
        Column(modifier = Modifier.fillMaxSize().statusBarsPadding()) {
            // 검색 바
            Row(
                modifier = Modifier
                    .padding(horizontal = 16.dp, vertical = 18.dp)
                    .clip(RoundedCornerShape(14.dp))
                    .background(rgba(255, 255, 255, 0.1))
                    .fillMaxWidth()
                    .padding(11.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                UiIcon(UiGlyph.SEARCH, rgba(255, 255, 255, 0.7), 18.dp)
                Box(modifier = Modifier.weight(1f).padding(horizontal = 9.dp)) {
                    if (query.isEmpty()) {
                        Text(
                            "수원시, 제주시, 광양시 ...",
                            color = rgba(255, 255, 255, 0.5),
                            fontFamily = AppFontFamily, fontSize = 16.sp,
                        )
                    }
                    BasicTextField(
                        value = query,
                        onValueChange = { query = it },
                        singleLine = true,
                        textStyle = TextStyle(
                            color = rgba(255, 255, 255), fontFamily = AppFontFamily, fontSize = 16.sp,
                        ),
                        cursorBrush = SolidColor(rgba(142, 162, 255)),
                        modifier = Modifier.fillMaxWidth().focusRequester(focus),
                    )
                }
                if (query.isNotEmpty()) {
                    Box(modifier = Modifier.clickable { query = ""; results = emptyList(); hint = null }) {
                        UiIcon(UiGlyph.CLOSE, rgba(255, 255, 255, 0.5), 18.dp)
                    }
                }
                if (dismissable) {
                    Text(
                        "취소",
                        color = rgba(142, 162, 255), fontFamily = AppFontFamily,
                        fontSize = 15.sp, fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.padding(start = 10.dp).clickable { onCancel() },
                    )
                }
            }

            // 결과 / 최근검색 / 힌트
            when {
                loading -> HintText("검색 중…")
                hint != null -> HintText(hint!!)
                query.trim().length < 2 -> {
                    if (recents.isEmpty()) {
                        HintText(
                            "관측할 지역을 검색해 보세요.\n정확한 결과를 위해 수원시, 제주시처럼 '시·군·구'까지 입력해 주세요."
                        )
                    } else {
                        RecentList(recents, onSelect, context, scope)
                    }
                }
                else -> LazyColumn(modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)) {
                    items(results) { r ->
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { onSelect(r) }
                                .padding(vertical = 13.dp, horizontal = 8.dp),
                            verticalArrangement = Arrangement.spacedBy(2.dp),
                        ) {
                            Text(
                                r.name, color = rgba(255, 255, 255),
                                fontFamily = AppFontFamily, fontSize = 17.sp, fontWeight = FontWeight.SemiBold,
                            )
                            if (r.displayName.isNotEmpty()) {
                                Text(
                                    r.displayName, color = rgba(255, 255, 255, 0.55),
                                    fontFamily = AppFontFamily, fontSize = 13.sp,
                                )
                            }
                        }
                        Box(
                            Modifier.fillMaxWidth().padding(horizontal = 8.dp)
                                .background(rgba(255, 255, 255, 0.08))
                                .height(1.dp)
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun RecentList(
    recents: List<GeoResult>,
    onSelect: (GeoResult) -> Unit,
    context: android.content.Context,
    scope: CoroutineScope,
) {
    LazyColumn(modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)) {
        item {
            Text(
                "최근 검색",
                color = rgba(255, 255, 255, 0.5), fontFamily = AppFontFamily,
                fontSize = 13.sp, fontWeight = FontWeight.SemiBold,
                modifier = Modifier.padding(horizontal = 8.dp, vertical = 6.dp),
            )
        }
        items(recents) { r ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onSelect(r) }
                    .padding(vertical = 11.dp, horizontal = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                UiIcon(UiGlyph.HISTORY, rgba(255, 255, 255, 0.4), 15.dp)
                Column(
                    modifier = Modifier.padding(start = 10.dp),
                    verticalArrangement = Arrangement.spacedBy(2.dp),
                ) {
                    Text(
                        r.name, color = rgba(255, 255, 255),
                        fontFamily = AppFontFamily, fontSize = 16.sp, fontWeight = FontWeight.Medium,
                    )
                    if (r.displayName.isNotEmpty()) {
                        Text(
                            r.displayName, color = rgba(255, 255, 255, 0.5),
                            fontFamily = AppFontFamily, fontSize = 12.sp,
                        )
                    }
                }
            }
            Box(
                Modifier.fillMaxWidth().padding(horizontal = 8.dp)
                    .background(rgba(255, 255, 255, 0.08))
                    .height(1.dp)
            )
        }
    }
}

@Composable
private fun HintText(s: String) {
    Text(
        s, color = rgba(255, 255, 255, 0.6), fontFamily = AppFontFamily,
        fontSize = 14.sp, textAlign = TextAlign.Center, lineHeight = 21.sp,
        modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp, vertical = 40.dp),
    )
}