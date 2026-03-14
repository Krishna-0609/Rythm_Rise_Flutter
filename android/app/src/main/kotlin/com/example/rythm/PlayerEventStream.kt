package com.example.rythm

import io.flutter.plugin.common.EventChannel

object PlayerEventStream : EventChannel.StreamHandler {
    var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}
