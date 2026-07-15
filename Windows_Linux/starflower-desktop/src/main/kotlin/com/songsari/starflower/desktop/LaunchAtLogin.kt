package com.songsari.starflower.desktop

import java.io.File

/**
 * macOS SMAppService 대응. OS별로 자동실행 등록 방식이 완전히 다르다.
 *  - Windows: 레지스트리 HKCU\...\Run 에 실행 경로 등록
 *  - Linux: ~/.config/autostart/ 에 .desktop 파일 생성
 */
object LaunchAtLogin {

    private val os = System.getProperty("os.name").lowercase()
    private val isWindows = os.contains("win")
    private val isLinux = os.contains("linux") || os.contains("nux")

    private const val APP_NAME = "Starflower"

    var isEnabled: Boolean
        get() = when {
            isWindows -> windowsIsEnabled()
            isLinux -> linuxDesktopFile().exists()
            else -> false
        }
        set(value) {
            if (isWindows) setWindows(value)
            else if (isLinux) setLinux(value)
        }

    // ── 실행 파일 경로 ─────────────────────────────────────
    private fun exePath(): String =
        ProcessHandle.current().info().command().orElse("")

    // ── Windows: 레지스트리 Run 키 ────────────────────────
    private fun windowsIsEnabled(): Boolean = try {
        val p = ProcessBuilder(
            "reg", "query",
            "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run",
            "/v", APP_NAME,
        ).redirectErrorStream(true).start()
        p.waitFor() == 0
    } catch (e: Exception) {
        false
    }

    private fun setWindows(enable: Boolean) {
        try {
            if (enable) {
                ProcessBuilder(
                    "reg", "add",
                    "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run",
                    "/v", APP_NAME, "/t", "REG_SZ", "/d", "\"${exePath()}\"", "/f",
                ).start().waitFor()
            } else {
                ProcessBuilder(
                    "reg", "delete",
                    "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run",
                    "/v", APP_NAME, "/f",
                ).start().waitFor()
            }
        } catch (e: Exception) {
            println("자동실행 설정 실패: ${e.message}")
        }
    }

    // ── Linux: ~/.config/autostart/*.desktop ──────────────
    private fun linuxDesktopFile(): File =
        File(System.getProperty("user.home"), ".config/autostart/starflower.desktop")

    private fun setLinux(enable: Boolean) {
        val file = linuxDesktopFile()
        if (enable) {
            file.parentFile.mkdirs()
            file.writeText(
                """
                [Desktop Entry]
                Type=Application
                Name=$APP_NAME
                Exec=${exePath()}
                X-GNOME-Autostart-enabled=true
                """.trimIndent(),
            )
        } else {
            file.delete()
        }
    }
}
