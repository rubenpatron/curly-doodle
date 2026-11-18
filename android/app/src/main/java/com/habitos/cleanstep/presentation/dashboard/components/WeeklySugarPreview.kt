package com.habitos.cleanstep.presentation.dashboard.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.habitos.cleanstep.core.designsystem.theme.AmberAccent
import com.habitos.cleanstep.core.designsystem.theme.DarkOutline
import com.habitos.cleanstep.core.designsystem.theme.DarkSurfaceHighlight
import com.habitos.cleanstep.core.designsystem.theme.EmeraldPrimary
import com.habitos.cleanstep.core.designsystem.theme.TextDisabled
import com.habitos.cleanstep.core.designsystem.theme.TextPrimary
import com.habitos.cleanstep.core.designsystem.theme.TextSecondary
import com.habitos.cleanstep.core.designsystem.theme.TrafficRed
import com.habitos.cleanstep.domain.model.SugarTrafficLight
import com.habitos.cleanstep.domain.model.WeeklySugarDay

@Composable
fun WeeklySugarPreview(
    weeklyDays: List<WeeklySugarDay>,
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        color = DarkSurfaceHighlight.copy(alpha = 0.5f),
        border = androidx.compose.foundation.BorderStroke(1.dp, DarkOutline.copy(alpha = 0.5f))
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "SEMANA EN CURSO",
                    style = MaterialTheme.typography.labelSmall,
                    color = TextSecondary,
                    fontWeight = FontWeight.Bold,
                    fontSize = 10.sp
                )
                Text(
                    text = "Semáforo diario",
                    style = MaterialTheme.typography.labelSmall,
                    color = TextSecondary,
                    fontSize = 10.sp
                )
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                weeklyDays.forEach { day ->
                    WeeklyDayPill(day = day)
                }
            }
        }
    }
}

@Composable
private fun WeeklyDayPill(
    day: WeeklySugarDay,
    modifier: Modifier = Modifier
) {
    val (statusColor, icon) = when (day.status) {
        SugarTrafficLight.GREEN -> EmeraldPrimary to Icons.Default.Check
        SugarTrafficLight.AMBER -> AmberAccent to Icons.Default.Warning
        SugarTrafficLight.RED -> TrafficRed to Icons.Default.Close
        SugarTrafficLight.NONE -> TextDisabled to null
    }

    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Text(
            text = day.dayOfWeek,
            style = MaterialTheme.typography.labelSmall,
            color = if (day.isToday) EmeraldPrimary else TextSecondary,
            fontWeight = if (day.isToday) FontWeight.Bold else FontWeight.Normal,
            fontSize = 11.sp
        )

        Box(
            modifier = Modifier
                .size(30.dp)
                .clip(CircleShape)
                .background(
                    if (day.status == SugarTrafficLight.NONE) Color.Transparent else statusColor.copy(alpha = 0.2f)
                )
                .border(
                    width = if (day.isToday) 2.dp else 1.dp,
                    color = if (day.isToday) statusColor else statusColor.copy(alpha = 0.6f),
                    shape = CircleShape
                ),
            contentAlignment = Alignment.Center
        ) {
            if (icon != null) {
                Icon(
                    imageVector = icon,
                    contentDescription = day.status.name,
                    tint = statusColor,
                    modifier = Modifier.size(14.dp)
                )
            } else {
                Box(
                    modifier = Modifier
                        .size(6.dp)
                        .clip(CircleShape)
                        .background(TextDisabled)
                )
            }
        }
    }
}
