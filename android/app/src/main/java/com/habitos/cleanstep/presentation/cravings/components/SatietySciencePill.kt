package com.habitos.cleanstep.presentation.cravings.components

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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Science
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.habitos.cleanstep.core.designsystem.theme.DarkBackground
import com.habitos.cleanstep.core.designsystem.theme.DarkSurface
import com.habitos.cleanstep.core.designsystem.theme.EmeraldPrimary
import com.habitos.cleanstep.domain.model.SatietyMechanism

/**
 * Píldora visual que destaca el mecanismo científico detrás de la saciedad de cada snack.
 */
@Composable
fun SatietySciencePill(
    mechanism: SatietyMechanism,
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null
) {
    val pillColor = Color(mechanism.colorHex)

    Box(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(pillColor.copy(alpha = 0.15f))
            .border(width = 1.dp, color = pillColor.copy(alpha = 0.4f), shape = RoundedCornerShape(12.dp))
            .then(
                if (onClick != null) Modifier.clickable { onClick() } else Modifier
            )
            .padding(horizontal = 10.dp, vertical = 5.dp),
        contentAlignment = Alignment.Center
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center
        ) {
            Icon(
                imageVector = Icons.Default.Science,
                contentDescription = "Ciencia de la Saciedad",
                tint = pillColor,
                modifier = Modifier.size(13.dp)
            )
            Spacer(modifier = Modifier.width(5.dp))
            Text(
                text = mechanism.badgeLabel,
                color = pillColor,
                fontSize = 11.sp,
                fontWeight = FontWeight.SemiBold,
                letterSpacing = 0.2.sp
            )
        }
    }
}

/**
 * Diálogo explicativo que detalla la neuroquímica y fisiología de la saciedad:
 * Cómo la proteína, la fibra y la distensión mecánica apagan la grelina sin necesidad
 * de contar calorías ni modificar la comida familiar cocinada por mamá.
 */
@Composable
fun SatietyScienceExplainerDialog(
    onDismissRequest: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismissRequest,
        confirmButton = {
            TextButton(onClick = onDismissRequest) {
                Text("Entendido, gracias", color = EmeraldPrimary, fontWeight = FontWeight.Bold)
            }
        },
        title = {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Default.Science,
                    contentDescription = null,
                    tint = EmeraldPrimary,
                    modifier = Modifier.size(24.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "La Ciencia de la Saciedad",
                    style = MaterialTheme.typography.titleLarge,
                    color = Color.White,
                    fontWeight = FontWeight.Bold
                )
            }
        },
        text = {
            Column(
                modifier = Modifier
                    .verticalScroll(rememberScrollState())
                    .padding(vertical = 4.dp)
            ) {
                Text(
                    text = "Por qué no necesitas contar calorías en tus comidas principales",
                    style = MaterialTheme.typography.titleSmall,
                    color = EmeraldPrimary,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "La comida y cena de mamá te nutren y son sagradas. La pérdida de grasa real se logra eliminando el picoteo de chatarra entre comidas (refrescos, galletas, Sabritas). Al entender cómo funciona tu estómago, el hambre se apaga biológicamente:",
                    style = MaterialTheme.typography.bodyMedium,
                    color = Color(0xFFD1D5DB)
                )

                Spacer(modifier = Modifier.height(14.dp))

                ScienceExplainerItem(
                    title = "1. Grelina vs. Proteína (Huevos Cocidos)",
                    explanation = "La grelina es la 'hormona del hambre' segregada por el fondo del estómago. La proteína pura estimula PYY y GLP-1 en el intestino, bloqueando la señal de grelina en el hipotálamo hasta por 4-6 horas.",
                    pillColor = Color(0xFF10B981)
                )

                ScienceExplainerItem(
                    title = "2. Mecanorreceptores y Masticación (Pepino/Jícama)",
                    explanation = "Tu estómago tiene sensores de estiramiento. Al meter volumen crujiente (agua + fibra vegetal), los mecanorreceptores le gritan al cerebro que ya estás lleno. El crujido sonoro además apaga la necesidad de 'masticar papitas por estrés'.",
                    pillColor = Color(0xFF06B6D4)
                )

                ScienceExplainerItem(
                    title = "3. Gas Carbónico y Acidez (Agua Mineral con Limón)",
                    explanation = "El ácido carbónico distiende de inmediato el antro del estómago y el limón engaña a las papilas que pedían acidez y dulzor de un refresco. Cero calorías, cero azúcar, hidratación pura.",
                    pillColor = Color(0xFF3B82F6)
                )

                ScienceExplainerItem(
                    title = "4. Freno Ileal (Puñado de Cacahuates)",
                    explanation = "Las grasas buenas activan receptores en el íleon que le ordenan al estómago vaciarse más despacio, estabilizando la glucosa y evitando bajones súbitos de energía.",
                    pillColor = Color(0xFFF59E0B)
                )

                ScienceExplainerItem(
                    title = "5. Estimulación Vagal Térmica (Té o Café Caliente)",
                    explanation = "El calor obliga al consumo a sorbos lentos, activando el sistema nervioso parasimpático (descanso y digestión) y frenando el modo de ansiedad impulsiva dopaminérgica.",
                    pillColor = Color(0xFF8B5CF6)
                )
            }
        },
        containerColor = DarkSurface,
        shape = RoundedCornerShape(20.dp)
    )
}

@Composable
private fun ScienceExplainerItem(
    title: String,
    explanation: String,
    pillColor: Color
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        colors = CardDefaults.cardColors(containerColor = DarkBackground),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Bold,
                color = pillColor
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = explanation,
                style = MaterialTheme.typography.bodySmall,
                color = Color(0xFF9CA3AF),
                lineHeight = 18.sp
            )
        }
    }
}
