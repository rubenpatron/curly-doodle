package com.habitloss.app.presentation.cravings

import androidx.compose.foundation.background
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.EmojiFoodBeverage
import androidx.compose.material.icons.filled.Science
import androidx.compose.material.icons.filled.Waves
import androidx.compose.material3.BottomSheetDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.SheetState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.habitloss.app.domain.model.MexicanRescueSnacksCatalog
import com.habitloss.app.domain.model.RescueSnack
import com.habitloss.app.domain.model.TimerStatus
import com.habitloss.app.presentation.cravings.components.RescueSnackCard
import com.habitloss.app.presentation.cravings.components.SatietyScienceExplainerDialog
import com.habitloss.app.presentation.cravings.components.UrgeSurfingTimerView
import kotlinx.coroutines.flow.collectLatest

/**
 * ModalBottomSheet interactivo principal para la gestión de antojos y hambre entre comidas.
 * Integra la técnica de Urge Surfing (10-15 min) y los 5 snacks de rescate mexicanos de alta saciedad.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CravingsBottomSheet(
    viewModel: CravingsViewModel,
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
    sheetState: SheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
) {
    val uiState by viewModel.uiState.collectAsState()

    // Manejo de efectos secundarios del ViewModel
    LaunchedEffect(key1 = viewModel) {
        viewModel.sideEffects.collectLatest { effect ->
            when (effect) {
                CravingsSideEffect.DismissSheet -> {
                    sheetState.hide()
                    onDismissRequest()
                }
                is CravingsSideEffect.ShowToast -> {
                    // Feedback emitido al usuario
                }
                CravingsSideEffect.TimerCompletedVibration -> {
                    // Notificación háptica al vencer los 15 minutos
                }
            }
        }
    }

    ModalBottomSheet(
        onDismissRequest = onDismissRequest,
        sheetState = sheetState,
        dragHandle = {
            BottomSheetDefaults.DragHandle(
                color = Color(0xFF4B5563)
            )
        },
        containerColor = Color(0xFF111418),
        scrimColor = Color.Black.copy(alpha = 0.75f),
        modifier = modifier
    ) {
        CravingsBottomSheetContent(
            uiState = uiState,
            onEvent = viewModel::onEvent,
            onClose = onDismissRequest
        )
    }

    // Diálogo científico de saciedad si fue solicitado
    if (uiState.showScienceExplainerDialog) {
        SatietyScienceExplainerDialog(
            onDismissRequest = { viewModel.onEvent(CravingsEvent.ToggleScienceExplainer) }
        )
    }
}

/**
 * Contenido modular de la hoja inferior desacoplado del ViewModel para previews y testing.
 */
@Composable
fun CravingsBottomSheetContent(
    uiState: CravingsUiState,
    onEvent: (CravingsEvent) -> Unit,
    onClose: () -> Unit,
    modifier: Modifier = Modifier
) {
    LazyColumn(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 18.dp)
            .padding(bottom = 32.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // 1. Header con Título, Botón de Ciencia y Cerrar
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = "¿Antojo o Hambre Real?",
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.ExtraBold,
                            color = Color.White
                        )
                    }
                    Text(
                        text = "Surfea el pico de dopamina durante 10-15 minutos antes de comer.",
                        style = MaterialTheme.typography.bodySmall,
                        color = Color(0xFF9CA3AF)
                    )
                }

                Row(verticalAlignment = Alignment.CenterVertically) {
                    IconButton(
                        onClick = { onEvent(CravingsEvent.ToggleScienceExplainer) },
                        modifier = Modifier
                            .size(36.dp)
                            .clip(CircleShape)
                            .background(Color(0xFF1E242E))
                    ) {
                        Icon(
                            imageVector = Icons.Default.Science,
                            contentDescription = "Ciencia de la saciedad",
                            tint = Color(0xFF10B981),
                            modifier = Modifier.size(18.dp)
                        )
                    }

                    Spacer(modifier = Modifier.width(8.dp))

                    IconButton(
                        onClick = onClose,
                        modifier = Modifier
                            .size(36.dp)
                            .clip(CircleShape)
                            .background(Color(0xFF1E242E))
                    ) {
                        Icon(
                            imageVector = Icons.Default.Close,
                            contentDescription = "Cerrar",
                            tint = Color(0xFF9CA3AF),
                            modifier = Modifier.size(18.dp)
                        )
                    }
                }
            }
        }

        // 2. Temporizador de Urge Surfing
        item {
            UrgeSurfingTimerView(
                uiState = uiState,
                onDurationSelected = { minutes -> onEvent(CravingsEvent.ChangeDuration(minutes)) },
                onStartTimer = { onEvent(CravingsEvent.StartTimer) },
                onPauseTimer = { onEvent(CravingsEvent.PauseTimer) },
                onResumeTimer = { onEvent(CravingsEvent.ResumeTimer) },
                onResetTimer = { onEvent(CravingsEvent.ResetTimer) },
                onConfirmNoFood = { onEvent(CravingsEvent.ConfirmCravingPassedWithoutEating) }
            )
        }

        // 3. Encabezado de la Sección de Snacks de Rescate Saciantes
        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = Color(0xFF181C22)),
                shape = RoundedCornerShape(16.dp)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                text = "🇲🇽 Snacks de Rescate Saciantes",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = Color.White
                            )
                        }
                        Text(
                            text = "0 azúcar añadida • Baratos (<$12 MXN) • Apagan la grelina",
                            style = MaterialTheme.typography.bodySmall,
                            color = Color(0xFF00E676),
                            fontSize = 11.sp
                        )
                    }

                    TextButton(onClick = { onEvent(CravingsEvent.ToggleScienceExplainer) }) {
                        Text(
                            text = "¿Por qué?",
                            color = Color(0xFF06B6D4),
                            fontWeight = FontWeight.Bold,
                            fontSize = 12.sp
                        )
                    }
                }
            }
        }

        // 4. Lista de los 5 Snacks Canónicos Mexicanos
        items(
            items = uiState.rescueSnacks,
            key = { it.id }
        ) { snack ->
            RescueSnackCard(
                snack = snack,
                isSelected = uiState.selectedSnack?.id == snack.id,
                onSelectRescue = { selected ->
                    onEvent(CravingsEvent.ConfirmAteRescueSnack(selected))
                },
                onSciencePillClick = {
                    onEvent(CravingsEvent.ToggleScienceExplainer)
                }
            )
        }

        // 5. Nota de Contexto Familiar y Cero Culpa
        item {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(Color(0xFF151921))
                    .padding(14.dp)
            ) {
                Text(
                    text = "💡 Recordatorio: Tu comida y cena cocinadas por mamá son sagradas. No cuentas calorías ni alteras su menú. La victoria de hoy se gana evitando galletas, papas y refrescos entre comidas.",
                    style = MaterialTheme.typography.bodySmall,
                    color = Color(0xFF9CA3AF),
                    lineHeight = 16.sp
                )
            }
        }
    }
}

// ================= PREVIEWS =================

@Preview(name = "Urge Surfing Sheet - Dark Mode", showBackground = true, backgroundColor = 0xFF111418)
@Composable
private fun CravingsBottomSheetPreview() {
    MaterialTheme {
        CravingsBottomSheetContent(
            uiState = CravingsUiState(
                remainingSeconds = 12 * 60 + 35,
                totalSeconds = 15 * 60,
                timerStatus = TimerStatus.RUNNING,
                rescueSnacks = MexicanRescueSnacksCatalog.snacks
            ),
            onEvent = {},
            onClose = {}
        )
    }
}

@Preview(name = "Urge Surfing Sheet - Completed Victory", showBackground = true, backgroundColor = 0xFF111418)
@Composable
private fun CravingsBottomSheetCompletedPreview() {
    MaterialTheme {
        CravingsBottomSheetContent(
            uiState = CravingsUiState(
                remainingSeconds = 0,
                totalSeconds = 15 * 60,
                timerStatus = TimerStatus.COMPLETED,
                rescueSnacks = MexicanRescueSnacksCatalog.snacks
            ),
            onEvent = {},
            onClose = {}
        )
    }
}
