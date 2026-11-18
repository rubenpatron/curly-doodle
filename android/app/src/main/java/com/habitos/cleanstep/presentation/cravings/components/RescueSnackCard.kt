package com.habitos.cleanstep.presentation.cravings.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
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
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.AttachMoney
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ExpandLess
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Storefront
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.habitos.cleanstep.core.designsystem.theme.AmberAccent
import com.habitos.cleanstep.core.designsystem.theme.CoralContainer
import com.habitos.cleanstep.core.designsystem.theme.CoralPrimary
import com.habitos.cleanstep.core.designsystem.theme.DarkOutline
import com.habitos.cleanstep.core.designsystem.theme.DarkSurface
import com.habitos.cleanstep.core.designsystem.theme.DarkSurfaceHighlight
import com.habitos.cleanstep.core.designsystem.theme.DarkSurfaceVariant
import com.habitos.cleanstep.core.designsystem.theme.EmeraldContainer
import com.habitos.cleanstep.core.designsystem.theme.EmeraldPrimary
import com.habitos.cleanstep.core.designsystem.theme.TextPrimary
import com.habitos.cleanstep.core.designsystem.theme.TextSecondary
import com.habitos.cleanstep.core.designsystem.theme.WaterCyan
import com.habitos.cleanstep.domain.model.RescueSnack

/**
 * Tarjeta interactiva para cada uno de los 5 snacks de rescate mexicanos de alta saciedad.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun RescueSnackCard(
    snack: RescueSnack,
    isSelected: Boolean,
    onSelectRescue: (RescueSnack) -> Unit,
    onSciencePillClick: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    var isExpanded by remember { mutableStateOf(false) }

    Card(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .border(
                width = if (isSelected) 1.5.dp else 1.dp,
                color = if (isSelected) EmeraldPrimary else DarkOutline,
                shape = RoundedCornerShape(20.dp)
            ),
        colors = CardDefaults.cardColors(
            containerColor = if (isSelected) EmeraldContainer.copy(alpha = 0.35f) else DarkSurface
        ),
        shape = RoundedCornerShape(20.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            // Fila superior: Emoji, Nombre, y botón expandir
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.weight(1f)
                ) {
                    Box(
                        modifier = Modifier
                            .size(46.dp)
                            .clip(CircleShape)
                            .background(DarkSurfaceVariant),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(text = snack.emoji, fontSize = 24.sp)
                    }

                    Spacer(modifier = Modifier.width(12.dp))

                    Column {
                        Text(
                            text = snack.name,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = TextPrimary
                        )
                        Text(
                            text = snack.shortSubtitle,
                            style = MaterialTheme.typography.bodySmall,
                            color = TextSecondary
                        )
                    }
                }

                Box(
                    modifier = Modifier
                        .clip(CircleShape)
                        .clickable { isExpanded = !isExpanded }
                        .padding(4.dp)
                ) {
                    Icon(
                        imageVector = if (isExpanded) Icons.Default.ExpandLess else Icons.Default.ExpandMore,
                        contentDescription = if (isExpanded) "Colapsar" else "Expandir",
                        tint = TextSecondary
                    )
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            // Fila de Badges: Píldora científica + Reemplazo de Chatarra
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                SatietySciencePill(
                    mechanism = snack.mechanism,
                    onClick = onSciencePillClick
                )

                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(12.dp))
                        .background(CoralContainer.copy(alpha = 0.5f))
                        .border(1.dp, CoralPrimary.copy(alpha = 0.4f), RoundedCornerShape(12.dp))
                        .padding(horizontal = 8.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = "Sustituye: ${snack.replacesJunkFood.take(24)}...",
                        color = Color(0xFFFECDD3),
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Medium
                    )
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            // Datos rápidos: Costo MXN, Tiempo de Prep, Calorías
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(10.dp))
                    .background(DarkSurfaceHighlight)
                    .padding(horizontal = 10.dp, vertical = 6.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                QuickMetricItem(
                    icon = Icons.Default.AttachMoney,
                    label = snack.estimatedCostMxn,
                    tint = EmeraldPrimary
                )
                QuickMetricItem(
                    icon = Icons.Default.AccessTime,
                    label = snack.preparationTime,
                    tint = WaterCyan
                )
                QuickMetricItem(
                    icon = Icons.Default.LocalFireDepartment,
                    label = snack.caloriesApprox,
                    tint = AmberAccent
                )
            }

            // Sección desplegable detallada
            AnimatedVisibility(
                visible = isExpanded,
                enter = fadeIn() + expandVertically(),
                exit = fadeOut() + shrinkVertically()
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 12.dp)
                ) {
                    Text(
                        text = "🔬 Mecanismo Neuroquímico:",
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.Bold,
                        color = EmeraldPrimary
                    )
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = snack.whyItWorksScience,
                        style = MaterialTheme.typography.bodySmall,
                        color = Color(0xFFD1D5DB),
                        lineHeight = 17.sp
                    )

                    Spacer(modifier = Modifier.height(10.dp))

                    Text(
                        text = "🛒 Lo que necesitas en México:",
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.Bold,
                        color = WaterCyan
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    snack.ingredients.forEach { ingredient ->
                        Row(
                            verticalAlignment = Alignment.Top,
                            modifier = Modifier.padding(vertical = 1.dp)
                        ) {
                            Text(text = "• ", color = WaterCyan, fontWeight = FontWeight.Bold)
                            Text(
                                text = ingredient,
                                style = MaterialTheme.typography.bodySmall,
                                color = Color(0xFFE5E7EB)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(8.dp))
                            .background(DarkSurfaceVariant)
                            .padding(8.dp)
                    ) {
                        Row(verticalAlignment = Alignment.Top) {
                            Icon(
                                imageVector = Icons.Default.Storefront,
                                contentDescription = null,
                                tint = AmberAccent,
                                modifier = Modifier.size(16.dp)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = "${snack.preparationTip} ${snack.mexicanContextTip}",
                                style = MaterialTheme.typography.bodySmall,
                                color = Color(0xFFFDE68A),
                                fontSize = 11.sp
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Botón de acción: Elegir snack
            Button(
                onClick = { onSelectRescue(snack) },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(42.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (isSelected) EmeraldPrimary else DarkSurfaceVariant
                ),
                shape = RoundedCornerShape(12.dp)
            ) {
                Icon(
                    imageVector = if (isSelected) Icons.Default.CheckCircle else Icons.Default.Check,
                    contentDescription = null,
                    tint = if (isSelected) Color.White else EmeraldPrimary,
                    modifier = Modifier.size(16.dp)
                )
                Spacer(modifier = Modifier.width(6.dp))
                Text(
                    text = if (isSelected) "Snack Seleccionado" else "Comeré este snack de rescate",
                    color = if (isSelected) Color.White else TextPrimary,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.SemiBold
                )
            }
        }
    }
}

@Composable
private fun QuickMetricItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    tint: Color
) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = tint,
            modifier = Modifier.size(14.dp)
        )
        Spacer(modifier = Modifier.width(4.dp))
        Text(
            text = label,
            fontSize = 11.sp,
            fontWeight = FontWeight.Medium,
            color = Color(0xFFD1D5DB)
        )
    }
}
