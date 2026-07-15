package com.songsari.starflower

import androidx.compose.runtime.remember
import androidx.compose.ui.window.Window
import androidx.compose.ui.window.WindowPosition
import androidx.compose.ui.window.application
import androidx.compose.ui.window.rememberWindowState
import androidx.compose.ui.Alignment
import androidx.compose.ui.unit.dp
import com.songsari.starflower.ui.StargazingViewModel
import com.songsari.starflower.ui.screens.MainScreen
import com.songsari.starflower.ui.theme.StarflowerTheme
import java.awt.Dimension

/**
 * 데스크탑(Windows/Linux) 앱 진입점.
 * macOS MainWindowController 의 창 동작(초기크기 800x900, 최소크기 500x650)을 이식.
 * 위젯 등 외부 연동 기능은 제외하고 앱 창만 구성한다.
 */
fun main() = application {
    val vm = remember { StargazingViewModel() }

    val windowState = rememberWindowState(
        width = 800.dp, height = 900.dp,
        position = WindowPosition(Alignment.Center),
    )

    Window(
        onCloseRequest = ::exitApplication,
        state = windowState,
        title = "별바라기",
    ) {
        window.minimumSize = Dimension(500, 650)
        StarflowerTheme {
            MainScreen(vm)
        }
    }
}
