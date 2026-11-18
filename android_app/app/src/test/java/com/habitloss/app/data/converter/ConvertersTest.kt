package com.habitloss.app.data.converter

import com.habitloss.app.data.local.converter.Converters
import com.habitloss.app.domain.model.RoutineDifficulty
import com.habitloss.app.domain.model.SugarTrafficLight
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

class ConvertersTest {

    private val converters = Converters()

    @Test
    fun testLocalDateConversion() {
        val date = LocalDate.of(2026, 11, 18)
        val converted = converters.fromLocalDate(date)
        assertEquals("2026-11-18", converted)

        val restored = converters.toLocalDate(converted)
        assertEquals(date, restored)

        assertNull(converters.fromLocalDate(null))
        assertNull(converters.toLocalDate(null))
        assertNull(converters.toLocalDate("invalid-date-string"))
    }

    @Test
    fun testSugarTrafficLightConversion() {
        assertEquals("GREEN", converters.fromSugarTrafficLight(SugarTrafficLight.GREEN))
        assertEquals(SugarTrafficLight.GREEN, converters.toSugarTrafficLight("GREEN"))
        assertEquals(SugarTrafficLight.AMBER, converters.toSugarTrafficLight("AMBER"))
        assertEquals(SugarTrafficLight.RED, converters.toSugarTrafficLight("RED"))

        // Default fallback
        assertEquals(SugarTrafficLight.GREEN, converters.toSugarTrafficLight("UNKNOWN"))
        assertNull(converters.toSugarTrafficLight(null))
    }

    @Test
    fun testRoutineDifficultyConversion() {
        assertEquals("GENTLE", converters.fromRoutineDifficulty(RoutineDifficulty.GENTLE))
        assertEquals(RoutineDifficulty.GENTLE, converters.toRoutineDifficulty("GENTLE"))
        assertEquals(RoutineDifficulty.MODERATE, converters.toRoutineDifficulty("MODERATE"))

        // Fallback
        assertEquals(RoutineDifficulty.GENTLE, converters.toRoutineDifficulty("UNKNOWN"))
        assertNull(converters.toRoutineDifficulty(null))
    }

    @Test
    fun testStringListConversion() {
        val exercises = listOf("Elevaciones de pantorrilla", "Sentadillas pared", "Estiramientos lumbares")
        val joined = converters.fromStringList(exercises)
        assertTrue(joined!!.contains("|||"))

        val restored = converters.toStringList(joined)
        assertEquals(exercises, restored)

        assertTrue(converters.toStringList(null).isEmpty())
        assertTrue(converters.toStringList("").isEmpty())
    }
}
