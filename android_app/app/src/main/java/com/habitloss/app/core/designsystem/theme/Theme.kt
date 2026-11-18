package com.habitloss.app.core.designsystem.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val DarkColorScheme = darkColorScheme(
    primary = EmeraldGreenPrimary,
    onPrimary = DeepOledBlack,
    primaryContainer = EmeraldGreenContainer,
    onPrimaryContainer = EmeraldGreenLight,

    secondary = HydrationWaterBlue,
    onSecondary = DeepOledBlack,
    secondaryContainer = HydrationWaterBlueContainer,
    onSecondaryContainer = HydrationWaterBlue,

    tertiary = AmberWarning,
    onTertiary = DeepOledBlack,
    tertiaryContainer = AmberWarningContainer,
    onTertiaryContainer = AmberWarning,

    error = CoralRedAlert,
    onError = DeepOledBlack,
    errorContainer = CoralRedContainer,
    onErrorContainer = CoralRedAlert,

    background = DeepOledBlack,
    onBackground = TextPrimary,
    surface = DarkSurface100,
    onSurface = TextPrimary,
    surfaceVariant = DarkSurface200,
    onSurfaceVariant = TextSecondary,
    outline = OutlineDark
)

@Composable
fun HabitLossTheme(
    content: @Composable () -> Unit
) {
    val colorScheme = DarkColorScheme
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as? Activity)?.window
            if (window != null) {
                window.statusBarColor = DeepOledBlack.toArgb()
                window.navigationBarColor = DeepOledBlack.toArgb()
                WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = false
                WindowCompat.getInsetsController(window, view).isAppearanceLightNavigationBars = false
            }
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        content = content
    )
}
