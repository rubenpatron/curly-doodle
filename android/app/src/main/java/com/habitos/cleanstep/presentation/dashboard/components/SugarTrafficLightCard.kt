package com.habitos.cleanstep.presentation.dashboard.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Traffic
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.habitos.cleanstep.core.designsystem.theme.AmberAccent
import com.habitos.cleanstep.core.designsystem.theme.AmberContainer
import com.habitos.cleanstep.core.designsystem.theme.CleanStepTheme
import com.habitos.cleanstep.core.designsystem.theme.DarkOutline
import com.habitos.cleanstep.core.designsystem.theme.DarkSurface
import com.habitos.cleanstep.core.designsystem.theme.DarkSurfaceHighlight
import com.habitos.cleanstep.core.designsystem.theme.EmeraldContainer
import com.habitos.cleanstep.core.designsystem.theme.EmeraldLight
import com.habitos.cleanstep.core.designsystem.theme.EmeraldPrimary
import com.habitos.cleanstep.core.designsystem.theme.TextPrimary
import com.habitos.cleanstep.core.designsystem.theme.TextSecondary
import com.habitos.cleanstep.core.designsystem.theme.TextTertiary
import com.habitos.cleanstep.core.designsystem.theme.TrafficRed
import com.habitos.cleanstep.core.designsystem.theme.TrafficRedContainer
import com.habitos.cleanstep.domain.model.SugarTrafficLight
import com.habitos.cleanstep.domain.model.WeeklySugarDay

@Composable
fun SugarTrafficLightCard(
    currentSelection: SugarTrafficLight,
    weeklyHistory: List<WeeklySugarDay>,
    onSelectLevel: (SugarTrafficLight) -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .border(
                width = 1.dp,
                brush = Brush.verticalGradient(
                    colors = listOf(
                        when (currentSelection) {
                            SugarTrafficLight.GREEN -> EmeraldPrimary.copy(alpha = 0.5f)
                            SugarTrafficLight.AMBER -> AmberAccent.copy(alpha = 0.5f)
                            SugarTrafficLight.RED -> TrafficRed.copy(alpha = 0.5f)
                            SugarTrafficLight.NONE -> DarkOutline
                        },
                        DarkOutline
                    )
                ),
                shape = RoundedCornerShape(24.dp)
            ),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(
            containerColor = DarkSurface
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp)
        ) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(28.dp)
                            .clip(CircleShape)
                            .background(DarkSurfaceHighlight),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Traffic,
                            contentDescription = "Semáforo",
                            tint = when (currentSelection) {
                                SugarTrafficLight.GREEN -> EmeraldLight
                                SugarTrafficLight.AMBER -> AmberAccent
                                SugarTrafficLight.RED -> TrafficRed
                                SugarTrafficLight.NONE -> TextSecondary
                            },
                            modifier = Modifier.size(16.dp)
                        )
                    }

                    Text(
                        text = "SEMÁFORO DE AZÚCAR DIARIO",
                        style = MaterialTheme.typography.labelSmall,
                        color = TextSecondary,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 1.sp
                    )
                }

                Surface(
                    shape = RoundedCornerShape(10.dp),
                    color = DarkSurfaceHighlight
                ) {
                    Text(
                        text = "1 Toque",
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                        style = MaterialTheme.typography.labelSmall,
                        color = TextTertiary,
                        fontWeight = FontWeight.Medium
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Tu estado de hoy (entre comidas):",
                style = MaterialTheme.typography.titleMedium,
                color = TextPrimary,
                fontWeight = FontWeight.Bold
            )

            Spacer(modifier = Modifier.height(14.dp))

            // Three One-Touch Options
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                TrafficLightOption(
                    title = "0 azúcares",
                    subtitle = "Día limpio",
                    badgeEmoji = "🟢",
                    isSelected = currentSelection == SugarTrafficLight.GREEN,
                    activeColor = EmeraldPrimary,
                    containerColor = EmeraldContainer,
                    onClick = { onSelectLevel(SugarTrafficLight.GREEN) },
                    modifier = Modifier.weight(1f)
                )

                TrafficLightOption(
                    title = "Bebida dulce",
                    subtitle = "Refresco/jugo",
                    badgeEmoji = "🟡",
                    isSelected = currentSelection == SugarTrafficLight.AMBER,
                    activeColor = AmberAccent,
                    containerColor = AmberContainer,
                    onClick = { onSelectLevel(SugarTrafficLight.AMBER) },
                    modifier = Modifier.weight(1f)
                )

                TrafficLightOption(
                    title = "Snack proc.",
                    subtitle = "Galletas/papas",
                    badgeEmoji = "🔴",
                    isSelected = currentSelection == SugarTrafficLight.RED,
                    activeColor = TrafficRed,
                    containerColor = TrafficRedContainer,
                    onClick = { onSelectLevel(SugarTrafficLight.RED) },
                    modifier = Modifier.weight(1f)
                )
            }

            // Immediate Feedback Message Pill
            AnimatedVisibility(
                visible = currentSelection != SugarTrafficLight.NONE,
                enter = fadeIn(tween(250)),
                exit = fadeOut(tween(200))
            ) {
                val feedbackBorderColor by animateColorAsState(
                    targetValue = when (currentSelection) {
                        SugarTrafficLight.GREEN -> EmeraldPrimary.copy(alpha = 0.4f)
                        SugarTrafficLight.AMBER -> AmberAccent.copy(alpha = 0.4f)
                        SugarTrafficLight.RED -> TrafficRed.copy(alpha = 0.4f)
                        SugarTrafficLight.NONE -> Color.Transparent
                    },
                    label = "feedback_border"
                )

                Column(modifier = Modifier.padding(top = 14.dp)) {
                    Surface(
                        shape = RoundedCornerShape(12.dp),
                        color = DarkSurfaceHighlight,
                        border = androidx.compose.foundation.BorderStroke(1.dp, feedbackBorderColor),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            modifier = Modifier.padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Info,
                                contentDescription = "Feedback",
                                tint = when (currentSelection) {
                                    SugarTrafficLight.GREEN -> EmeraldLight
                                    SugarTrafficLight.AMBER -> AmberAccent
                                    SugarTrafficLight.RED -> TrafficRed
                                    SugarTrafficLight.NONE -> TextSecondary
                                },
                                modifier = Modifier.size(18.dp)
                            )
                            Text(
                                text = currentSelection.feedbackMessage,
                                style = MaterialTheme.typography.bodySmall,
                                color = TextPrimary,
                                lineHeight = 16.sp
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Weekly Progress Preview inside Card
            if (weeklyHistory.isNotEmpty()) {
                WeeklySugarPreview(weeklyDays = weeklyHistory)
            }
        }
    }
}

@Composable
private fun TrafficLightOption(
    title: String,
    subtitle: String,
    badgeEmoji: String,
    isSelected: Boolean,
    activeColor: Color,
    containerColor: Color,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val borderColor by animateColorAsState(
        targetValue = if (isSelected) activeColor else DarkOutline,
        animationSpec = tween(200),
        label = "option_border"
    )

    val bgColor by animateColorAsState(
        targetValue = if (isSelected) containerColor.copy(alpha = 0.45f) else DarkSurfaceHighlight,
        animationSpec = tween(200),
        label = "option_bg"
    )

    Surface(
        modifier = modifier
            .clip(RoundedCornerShape(16.dp))
            .border(
                width = if (isSelected) 2.dp else 1.dp,
                color = borderColor,
                shape = RoundedCornerShape(16.dp)
            )
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(16.dp),
        color = bgColor
    ) {
        Column(
            modifier = Modifier.padding(vertical = 12.dp, horizontal = 8.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Text(text = badgeEmoji, fontSize = 14.sp)
                if (isSelected) {
                    Icon(
                        imageVector = Icons.Default.Check,
                        contentDescription = "Seleccionado",
                        tint = activeColor,
                        modifier = Modifier.size(14.dp)
                    )
                }
            }

            Text(
                text = title,
                style = MaterialTheme.typography.labelMedium,
                color = if (isSelected) activeColor else TextPrimary,
                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                maxLines = 1
            )

            Text(
                text = subtitle,
                style = MaterialTheme.typography.labelSmall,
                color = TextSecondary,
                fontSize = 10.sp,
                maxLines = 1
            )
        }
    }
}

@Preview
@Composable
private fun SugarTrafficLightCardPreview() {
    CleanStepTheme {
        SugarTrafficLightCard(
            currentSelection = SugarTrafficLight.GREEN,
            weeklyHistory = listOf(
                WeeklySugarDay("Lun", "10 Nov", SugarTrafficLight.GREEN),
                WeeklySugarDay("Mar", "11 Nov", SugarTrafficLight.GREEN),
                WeeklySugarDay("Mié", "12 Nov", SugarTrafficLight.AMBER),
                WeeklySugarDay("Jue", "13 Nov", SugarTrafficLight.GREEN),
                WeeklySugarDay("Vie", "14 Nov", SugarTrafficLight.RED),
                WeeklySugarDay("Sáb", "15 Nov", SugarTrafficLight.GREEN),
                WeeklySugarDay("Dom", "16 Nov", SugarTrafficLight.GREEN, isToday = true)
            ),
            onSelectLevel = {},
            modifier = Modifier.padding(16.dp)
        )
    }
}
