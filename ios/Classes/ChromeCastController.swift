//
//  ChromeCastController.swift
//  flutter_video_cast
//
//  Created by Alessio Valentini on 07/08/2020.
//

import Flutter
import GoogleCast

class ChromeCastController: NSObject, FlutterPlatformView {

    // MARK: - Internal properties

    private let channel: FlutterMethodChannel
    private let chromeCastButton: GCKUICastButton
    private let sessionManager = GCKCastContext.sharedInstance().sessionManager

    // MARK: - Init

    init(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        registrar: FlutterPluginRegistrar
    ) {
        self.channel = FlutterMethodChannel(name: "flutter_video_cast/chromeCast_\(viewId)", binaryMessenger: registrar.messenger())
        self.chromeCastButton = GCKUICastButton(frame: frame)
        super.init()
        self.configure(arguments: args)
    }

    func view() -> UIView {
        return chromeCastButton
    }

    private func configure(arguments args: Any?) {
        setTint(arguments: args)
        setMethodCallHandler()
    }

    // MARK: - Styling

    private func setTint(arguments args: Any?) {
        guard
            let args = args as? [String: Any],
            let red = args["red"] as? CGFloat,
            let green = args["green"] as? CGFloat,
            let blue = args["blue"] as? CGFloat,
            let alpha = args["alpha"] as? Int else {
                print("Invalid color")
                return
        }
        chromeCastButton.tintColor = UIColor(
            red: red / 255,
            green: green / 255,
            blue: blue / 255,
            alpha: CGFloat(alpha) / 255
        )
    }

    // MARK: - Flutter methods handling

    private func setMethodCallHandler() {
        channel.setMethodCallHandler { call, result in
            self.onMethodCall(call: call, result: result)
        }
    }

    private func onMethodCall(call: FlutterMethodCall, result: FlutterResult) {
        switch call.method {
        case "chromeCast#wait":
            result(nil)
            break
        case "chromeCast#loadMedia":
            loadMedia(args: call.arguments)
            result(nil)
            break
        case "chromeCast#play":
            play()
            result(nil)
            break
        case "chromeCast#pause":
            pause()
            result(nil)
            break
        case "chromeCast#seek":
            seek(args: call.arguments)
            result(nil)
            break
        case "chromeCast#stop":
            stop()
            result(nil)
            break
        case "chromeCast#isConnected":
            result(isConnected())
            break
        case "chromeCast#isPlaying":
            result(isPlaying())
            break
        case "chromeCast#addSessionListener":
            addSessionListener()
            result(nil)
        case "chromeCast#removeSessionListener":
            removeSessionListener()
            result(nil)
        case "chromeCast#position":
            result(position())
        case "chromeCast#endSession":
            endSession();
            result(nil)
        default:
            result(nil)
            break
        }
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
                                                   textTrackStyle: GCKTextTrackStyle()) // Add text track style as needed
                    mediaTracks.append(mediaTrack)
                }
            }
        }

        // Build media information
        let mediaInformation = GCKMediaInformation(contentID: url.absoluteString,
                                                    streamType: .buffered, // Correctly use enum
                                                    contentType: "video/mp4", // Update as needed
                                                    metadata: mediaMetadata,
                                                    streamDuration: 0, // Set as needed
                                                    mediaTracks: mediaTracks,
                                                    customData: nil)

        // Set load options (autoplay and position)
        let options = GCKMediaLoadOptions()
        if let autoPlay = args["autoplay"] as? Bool {
            options.autoplay = autoPlay
        }
        if let position = args["position"] as? Double {
            options.playPosition = position
        }

        // Load media
        if let request = sessionManager.currentCastSession?.remoteMediaClient?.loadMedia(mediaInformation, with: options) {
            request.delegate = self
        }
    }

    private func play() {
        if let request = sessionManager.currentCastSession?.remoteMediaClient?.play() {
            request.delegate = self
        }
    }

    private func pause() {
        if let request = sessionManager.currentCastSession?.remoteMediaClient?.pause() {
            request.delegate = self
        }
    }

    private func seek(args: Any?) {
        guard
            let args = args as? [String: Any],
            let relative = args["relative"] as? Bool,
            let interval = args["interval"] as? Double else {
                return
        }
        let seekOptions = GCKMediaSeekOptions()
        seekOptions.relative = relative
        seekOptions.interval = interval
        if let request = sessionManager.currentCastSession?.remoteMediaClient?.seek(with: seekOptions) {
            request.delegate = self
        }
    }

    private func stop() {
        if let request = sessionManager.currentCastSession?.remoteMediaClient?.stop() {
            request.delegate = self
        }
    }

    private func isConnected() -> Bool {
        return sessionManager.currentCastSession?.remoteMediaClient?.connected ?? false
    }

    private func isPlaying() -> Bool {
        return sessionManager.currentCastSession?.remoteMediaClient?.mediaStatus?.playerState == GCKMediaPlayerState.playing
    }

    private func addSessionListener() {
        sessionManager.add(self)
    }

    private func removeSessionListener() {
        sessionManager.remove(self)
    }

    private func position() -> Int {
        return Int(sessionManager.currentCastSession?.remoteMediaClient?.approximateStreamPosition() ?? 0) * 1000
    }

    private func endSession() {
        sessionManager.endSession()
    }

    private func updateSubtitle(args: Double?) {
        let trackIDs: [NSNumber] = args != nil ? [NSNumber(value: args!.int64Value)] : []

        let request = sessionManager.currentCastSession?.remoteMediaClient?.setActiveMediaTracks(trackIDs) { error in
            if let error = error {
                // Handle error if needed
                print("Error setting active media tracks: \(error.localizedDescription)")
            }
        }

        request?.delegate = self
    }

}

// MARK: - GCKSessionManagerListener

extension ChromeCastController: GCKSessionManagerListener {
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        channel.invokeMethod("chromeCast#didStartSession", arguments: nil)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
        channel.invokeMethod("chromeCast#didEndSession", arguments: nil)
    }
}

// MARK: - GCKRequestDelegate

extension ChromeCastController: GCKRequestDelegate {
    func requestDidComplete(_ request: GCKRequest) {
        channel.invokeMethod("chromeCast#requestDidComplete", arguments: nil)
    }

    func request(_ request: GCKRequest, didFailWithError error: GCKError) {
        channel.invokeMethod("chromeCast#requestDidFail", arguments: ["error" : error.localizedDescription])
    }
}
