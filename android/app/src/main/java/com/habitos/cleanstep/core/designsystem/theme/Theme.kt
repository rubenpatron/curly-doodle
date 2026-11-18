package com.habitos.cleanstep.core.designsystem.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

/**
 * Extended semantic colors for domain-specific visual language:
 * Habit Streaks, Sugar Traffic Light, Hydration tracking, and Craving Rescue.
 */
@Immutable
data class ExtendedHabitColors(
    val emeraldPrimary: Color = EmeraldPrimary,
    val emeraldContainer: Color = EmeraldContainer,
    val emeraldOnContainer: Color = EmeraldOnContainer,
    val amberWarning: Color = AmberAccent,
    val amberContainer: Color = AmberContainer,
    val amberOnContainer: Color = AmberOnContainer,
    val trafficRed: Color = TrafficRed,
    val trafficRedContainer: Color = TrafficRedContainer,
    val trafficRedOnContainer: Color = TrafficRedOnContainer,
    val cravingCoral: Color = CoralPrimary,
    val cravingCoralContainer: Color = CoralContainer,
    val cravingCoralOnContainer: Color = CoralOnContainer,
    val waterCyan: Color = WaterCyan,
    val waterCyanContainer: Color = WaterCyanContainer,
    val waterCyanOnContainer: Color = WaterCyanOnContainer,
    val nightViolet: Color = NightViolet,
    val nightVioletContainer: Color = NightVioletContainer,
    val nightVioletOnContainer: Color = NightVioletOnContainer
)

val LocalExtendedHabitColors = staticCompositionLocalOf { ExtendedHabitColors() }

private val DarkColorScheme = darkColorScheme(
    primary = EmeraldPrimary,
    onPrimary = Color.Black,
    primaryContainer = EmeraldContainer,
    onPrimaryContainer = EmeraldOnContainer,
    secondary = AmberAccent,
    onSecondary = Color.Black,
    secondaryContainer = AmberContainer,
    onSecondaryContainer = AmberOnContainer,
    tertiary = WaterCyan,
    onTertiary = Color.Black,
    tertiaryContainer = WaterCyanContainer,
    onTertiaryContainer = WaterCyanOnContainer,
    background = DarkBackground,
    onBackground = TextPrimary,
    surface = DarkSurface,
    onSurface = TextPrimary,
    surfaceVariant = DarkSurfaceVariant,
    onSurfaceVariant = TextSecondary,
    outline = DarkOutline,
    outlineVariant = DarkOutlineVariant,
    error = TrafficRed,
    onError = Color.Black,
    errorContainer = TrafficRedContainer,
    onErrorContainer = TrafficRedOnContainer
)

@Composable
fun CleanStepTheme(
    darkTheme: Boolean = true, // Default to deep night theme for optimal melatonin/circadian comfort
    content: @Composable () -> Unit
) {
    val extendedColors = ExtendedHabitColors()
    val colorScheme = DarkColorScheme

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as? Activity)?.window
            if (window != null) {
                window.statusBarColor = DarkBackground.toArgb()
                window.navigationBarColor = DarkBackground.toArgb()
                val insetsController = WindowCompat.getInsetsController(window, view)
                insetsController.isAppearanceLightStatusBars = false
                insetsController.isAppearanceLightNavigationBars = false
            }
        }
    }

    CompositionLocalProvider(
        LocalExtendedHabitColors provides extendedColors
    ) {
        MaterialTheme(
            colorScheme = colorScheme,
            typography = CleanStepTypography,
            content = content
        )
    }
}

object CleanStepThemeDefaults {
    val habitColors: ExtendedHabitColors
        @Composable
        get() = LocalExtendedHabitColors.current
}
