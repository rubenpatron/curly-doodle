package com.habitos.cleanstep.presentation

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import com.habitos.cleanstep.CleanStepApplication
import com.habitos.cleanstep.core.designsystem.theme.CleanStepTheme
import com.habitos.cleanstep.core.notification.NotificationHelper
import com.habitos.cleanstep.presentation.cravings.CravingsBottomSheet
import com.habitos.cleanstep.presentation.cravings.CravingsViewModel
import com.habitos.cleanstep.presentation.dashboard.DashboardRoute
import com.habitos.cleanstep.presentation.dashboard.DashboardViewModel
import com.habitos.cleanstep.presentation.nightroutine.NightRoutineRoute
import com.habitos.cleanstep.presentation.nightroutine.NightRoutineViewModel
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {

    @OptIn(ExperimentalMaterial3Api::class)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        val app = application as CleanStepApplication
        val habitRepository = app.habitRepository
        val cravingRepository = app.cravingRescueRepository
        val nightRoutinePlanRepository = app.nightRoutinePlanRepository

        val dashboardViewModel: DashboardViewModel by viewModels {
            object : ViewModelProvider.Factory {
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>): T {
                    return DashboardViewModel(habitRepository) as T
                }
            }
        }

        val cravingsViewModel: CravingsViewModel by viewModels {
            object : ViewModelProvider.Factory {
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>): T {
                    return CravingsViewModel(cravingRepository) as T
                }
            }
        }

        val nightRoutineViewModel: NightRoutineViewModel by viewModels {
            object : ViewModelProvider.Factory {
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>): T {
                    return NightRoutineViewModel(nightRoutinePlanRepository) as T
                }
            }
        }

        val initialDestination = intent?.getStringExtra(NotificationHelper.EXTRA_DESTINATION)

        setContent {
            CleanStepTheme {
                var showCravingsSheet by remember {
                    mutableStateOf(initialDestination == NotificationHelper.DESTINATION_CRAVINGS)
                }
                var showNightRoutineScreen by remember {
                    mutableStateOf(initialDestination == NotificationHelper.DESTINATION_NIGHT_ROUTINE)
                }
                val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
                val scope = rememberCoroutineScope()

                Box(modifier = Modifier.fillMaxSize()) {
                    if (showNightRoutineScreen) {
                        NightRoutineRoute(
                            viewModel = nightRoutineViewModel,
                            onNavigateBack = {
                                showNightRoutineScreen = false
                            }
                        )
                    } else {
                        DashboardRoute(
                            viewModel = dashboardViewModel,
                            onNavigateToCravingRescue = {
                                showCravingsSheet = true
                            },
                            onNavigateToNightRoutine = {
                                showNightRoutineScreen = true
                            }
                        )
                    }

                    if (showCravingsSheet) {
                        CravingsBottomSheet(
                            viewModel = cravingsViewModel,
                            onDismissRequest = {
                                scope.launch {
                                    sheetState.hide()
                                    showCravingsSheet = false
                                }
                            },
                            sheetState = sheetState
                        )
                    }
                }
            }
        }
    }
}
