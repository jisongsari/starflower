package com.songsari.starflower

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import com.songsari.starflower.ui.screens.MainScreen
import com.songsari.starflower.ui.theme.StarflowerTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        setContent {
            StarflowerTheme {
                Surface(modifier = Modifier.fillMaxSize(), color = Color.Transparent) {
                    MainScreen()
                }
            }
        }
    }
}
