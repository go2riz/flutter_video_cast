package it.aesys.flutter_video_cast

import android.content.Context
import android.net.Uri
import android.util.Log
import android.view.ContextThemeWrapper
import androidx.mediarouter.app.MediaRouteButton
import com.google.android.gms.cast.MediaInfo
import com.google.android.gms.cast.MediaLoadOptions
import com.google.android.gms.cast.MediaMetadata
import com.google.android.gms.cast.MediaTrack
import com.google.android.gms.cast.framework.CastButtonFactory
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.Session
import com.google.android.gms.cast.framework.SessionManagerListener
import com.google.android.gms.cast.framework.media.RemoteMediaClient
import com.google.android.gms.common.api.PendingResult
import com.google.android.gms.common.api.Status
import com.google.android.gms.common.images.WebImage
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import java.util.*

class ChromeCastController(
    messenger: BinaryMessenger,
    viewId: Int,
    context: Context?
) : PlatformView, MethodChannel.MethodCallHandler, SessionManagerListener<Session>, PendingResult.StatusListener {
    private val channel = MethodChannel(messenger, "flutter_video_cast/chromeCast_$viewId")
    private val chromeCastButton = MediaRouteButton(ContextThemeWrapper(context, R.style.Theme_AppCompat_NoActionBar))
    private val sessionManager = CastContext.getSharedInstance()?.sessionManager

    private val movie = 0

    init {
        CastButtonFactory.setUpMediaRouteButton(context!!, chromeCastButton)
        channel.setMethodCallHandler(this)
    }

    private func loadMedia(args: Any?) {
        guard let args = args as? [String: Any],
              let urlString = args["url"] as? String,
              let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }

        // Set media type metadata
        let mediaMetadata = (args["type"] as? Int == 0) ? GCKMediaMetadata(metadataType: .movie) : GCKMediaMetadata(metadataType: .tvShow)

        // Set title, description, season, and episode
        if let title = args["title"] as? String {
            mediaMetadata.setString(title, forKey: kGCKMetadataKeyTitle)
        }
        if let description = args["desc"] as? String {
            mediaMetadata.setString(description, forKey: kGCKMetadataKeySubtitle)
        }
        if let season = args["season"] as? Int {
            mediaMetadata.setInteger(season, forKey: kGCKMetadataKeySeasonNumber)
        }
        if let episode = args["episode"] as? Int {
            mediaMetadata.setInteger(episode, forKey: kGCKMetadataKeyEpisodeNumber)
        }

        // Set image
        if let imageUrlString = args["image"] as? String, let imageUrl = URL(string: imageUrlString) {
            mediaMetadata.addImage(GCKImage(url: imageUrl, width: 480, height: 720))
        }

        // Set up subtitle tracks
        var mediaTracks: [GCKMediaTrack] = []
        if let subtitles = args["subtitles"] as? [[String: Any]] {
            for subtitle in subtitles {
                if let trackID = subtitle["id"] as? Double,
                   let source = subtitle["source"] as? String,
                   let language = subtitle["language"] as? String,
                   let name = subtitle["name"] as? String {
                    let mediaTrack = GCKMediaTrack(identifier: Int(trackID),
                                                   contentIdentifier: source,
                                                   contentType: "text/vtt",
                                                   type: .text,
                                                   textSubtype: .subtitles,
                                                   name: name,
                                                   languageCode: language,
                                                   customData: nil) // Remove textTrackStyle if not needed
                    mediaTracks.append(mediaTrack)
                }
            }
        }

        // Build media information
        let mediaInformation = GCKMediaInformation.builder(contentURL: url)
            .setStreamType(.buffered)
            .setMetadata(mediaMetadata)
            .setMediaTracks(mediaTracks)
            .build()

        // Set load options (autoplay and position)
        let options = GCKMediaLoadOptions()
        if let autoPlay = args["autoplay"] as? Bool {
            options.autoplay = autoPlay
        }
        if let position = args["position"] as? Double {
            options.playPosition = Int64(position) // Adjusted for Int64
        }

        // Load media
        if let request = sessionManager.currentCastSession?.remoteMediaClient?.load(mediaInformation, with: options) {
            request.delegate = self
        }
    }

    private fun play() {
        val request = sessionManager?.currentCastSession?.remoteMediaClient?.play()
        request?.addStatusListener(this)
    }

    private fun pause() {
        val request = sessionManager?.currentCastSession?.remoteMediaClient?.pause()
        request?.addStatusListener(this)
    }

    private fun seek(args: Any?) {
        if (args is Map<*, *>) {
            val relative = (args["relative"] as? Boolean) ?: false
            var interval = args["interval"] as? Double
            interval = interval?.times(1000)
            if (relative) {
                interval = interval?.plus(sessionManager?.currentCastSession?.remoteMediaClient?.mediaStatus?.streamPosition ?: 0)
            }
            val request = sessionManager?.currentCastSession?.remoteMediaClient?.seek(interval?.toLong() ?: 0)
            request?.addStatusListener(this)
        }
    }

    private fun setVolume(args: Any?) {
        if (args is Map<*, *>) {
            val volume = args["volume"] as? Double
            val request = sessionManager?.currentCastSession?.remoteMediaClient?.setStreamVolume(volume ?: 0.0)
            request?.addStatusListener(this)
        }
    }

    private fun updateSubtitle(args: Double?) {
        if (args != null){
            val request = sessionManager?.currentCastSession?.remoteMediaClient?.setActiveMediaTracks(longArrayOf(args.toLong()))
            request?.addStatusListener(this)
        } else {
            val request = sessionManager?.currentCastSession?.remoteMediaClient?.setActiveMediaTracks(longArrayOf())
            request?.addStatusListener(this)
        }
    }

    private fun getVolume() = sessionManager?.currentCastSession?.volume ?: 0.0

    private fun stop() {
        val request = sessionManager?.currentCastSession?.remoteMediaClient?.stop()
        request?.addStatusListener(this)
    }

    private fun isPlaying() = sessionManager?.currentCastSession?.remoteMediaClient?.isPlaying ?: false

    private fun isConnected() = sessionManager?.currentCastSession?.isConnected ?: false

    private fun endSession() = sessionManager?.endCurrentSession(true)

    private fun position() = sessionManager?.currentCastSession?.remoteMediaClient?.approximateStreamPosition ?: 0

    private fun duration() = sessionManager?.currentCastSession?.remoteMediaClient?.mediaInfo?.streamDuration ?: 0

    private fun addSessionListener() {
        sessionManager?.addSessionManagerListener(this)
    }

    private fun removeSessionListener() {
        sessionManager?.removeSessionManagerListener(this)
    }

    override fun getView() = chromeCastButton

    override fun dispose() {

    }

    // Flutter methods handling

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when(call.method) {
            "chromeCast#wait" -> result.success(null)
            "chromeCast#loadMedia" -> {
                loadMedia(call.arguments)
                result.success(null)
            }
            "chromeCast#play" -> {
                play()
                result.success(null)
            }
            "chromeCast#pause" -> {
                pause()
                result.success(null)
            }
            "chromeCast#seek" -> {
                seek(call.arguments)
                result.success(null)
            }
            "chromeCast#setVolume" -> {
                setVolume(call.arguments)
                result.success(null)
            }
            "chromeCast#updateSubtitles" -> {
                updateSubtitle(call.arguments as Double?)
                result.success(null)
            }
            "chromeCast#removeSubtitles" -> {
                updateSubtitle(null)
                result
                    .success(null)
            }
            "chromeCast#getVolume" -> result.success(getVolume())
            "chromeCast#stop" -> {
                stop()
                result.success(null)
            }
            "chromeCast#isPlaying" -> result.success(isPlaying())
            "chromeCast#isConnected" -> result.success(isConnected())
            "chromeCast#endSession" -> {
                endSession()
                result.success(null)
            }
            "chromeCast#position" -> result.success(position())
            "chromeCast#duration" -> result.success(duration())
            "chromeCast#addSessionListener" -> {
                addSessionListener()
                result.success(null)
            }
            "chromeCast#removeSessionListener" -> {
                removeSessionListener()
                result.success(null)
            }
        }
    }

    // SessionManagerListener

    override fun onSessionStarted(p0: Session, p1: String) {
        channel.invokeMethod("chromeCast#didStartSession", null)
    }

    override fun onSessionEnded(p0: Session, p1: Int) {
        channel.invokeMethod("chromeCast#didEndSession", null)
    }

    override fun onSessionResuming(p0: Session, p1: String) {

    }

    override fun onSessionResumed(p0: Session, p1: Boolean) {

    }

    override fun onSessionResumeFailed(p0: Session, p1: Int) {

    }

    override fun onSessionSuspended(p0: Session, p1: Int) {

    }

    override fun onSessionStarting(p0: Session) {

    }

    override fun onSessionEnding(p0: Session) {
        channel.invokeMethod("chromeCast#onSessionEnding", sessionManager?.currentCastSession?.remoteMediaClient?.approximateStreamPosition)
    }

    override fun onSessionStartFailed(p0: Session, p1: Int) {

    }

    // PendingResult.StatusListener

    override fun onComplete(p0: Status) {
        if (p0.isSuccess) {
            channel.invokeMethod("chromeCast#requestDidComplete", null)
        }
    }
}