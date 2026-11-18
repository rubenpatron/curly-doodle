package com.habitos.cleanstep.core.notification

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Test

class NotificationHelperTest {

    @Test
    fun `channel identifiers must be distinct and non-empty`() {
        assertNotEquals(
            NotificationHelper.CHANNEL_ID_MID_AFTERNOON,
            NotificationHelper.CHANNEL_ID_NIGHT_ROUTINE
        )
        assertNotEquals(
            NotificationHelper.NOTIFICATION_ID_MID_AFTERNOON,
            NotificationHelper.NOTIFICATION_ID_NIGHT_ROUTINE
        )
    }

    @Test
    fun `intent extras and destinations configured correctly`() {
        assertEquals("extra_notification_destination", NotificationHelper.EXTRA_DESTINATION)
        assertEquals("destination_cravings", NotificationHelper.DESTINATION_CRAVINGS)
        assertEquals("destination_night_routine", NotificationHelper.DESTINATION_NIGHT_ROUTINE)
    }
}
