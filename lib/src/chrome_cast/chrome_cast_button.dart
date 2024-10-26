part of flutter_video_cast;

/// Callback method for when the button is ready to be used.
///
/// Pass to [ChromeCastButton.onButtonCreated] to receive a [ChromeCastController]
/// when the button is created.
typedef OnButtonCreated = void Function(ChromeCastController controller);

/// Callback method for when a request has failed.
typedef OnRequestFailed = void Function(String? error);

///Callback when a cast session is starting to end.
typedef OnSessionEnding = void Function(int? position);

/// Widget that displays the ChromeCast button.
class ChromeCastButton extends StatelessWidget {
  /// Creates a widget displaying a ChromeCast button.
  ChromeCastButton({
    Key? key,
    this.size = 30.0,
    this.color = Colors.black,
    this.onButtonCreated,
    this.onSessionStarted,
    this.onSessionEnded,
    this.onRequestCompleted,
    this.onRequestFailed,
    this.onSessionEnding,
  })  : assert(
            defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.android,
            '$defaultTargetPlatform is not supported by this plugin'),
        super(key: key);

  /// The size of the button.
  final double size;

  /// The color of the button.
  /// This is only supported on iOS at the moment.
  final Color color;

  /// Callback method for when the button is ready to be used.
  ///
  /// Used to receive a [ChromeCastController] for this [ChromeCastButton].
  final OnButtonCreated? onButtonCreated;

  /// Called when a cast session has started.
  final VoidCallback? onSessionStarted;

  /// Called when a cast session has ended.
  final VoidCallback? onSessionEnded;

  /// Called when a cast request has successfully completed.
  final VoidCallback? onRequestCompleted;

  /// Called when a cast request has failed.
  final OnRequestFailed? onRequestFailed;

  ///Called when a cast session is starting to end.
  final OnSessionEnding? onSessionEnding;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = {
      'red': color.red,
      'green': color.green,
      'blue': color.blue,
      'alpha': color.alpha
    };
    return SizedBox(
      width: size,
      height: size,
      child: _chromeCastPlatform.buildView(args, _onPlatformViewCreated),
    );
  }

  Future<void> _onPlatformViewCreated(int id) async {
    final ChromeCastController controller = await ChromeCastController.init(id);
    if (onButtonCreated != null) {
      onButtonCreated!(controller);
    }
    if (onSessionStarted != null) {
      _chromeCastPlatform
          .onSessionStarted(id: id)
          .listen((_) => onSessionStarted!());
    }
    if (onSessionEnded != null) {
      _chromeCastPlatform
          .onSessionEnded(id: id)
          .listen((_) => onSessionEnded!());
    }
    if (onRequestCompleted != null) {
      _chromeCastPlatform
          .onRequestCompleted(id: id)
          .listen((_) => onRequestCompleted!());
    }
    if (onRequestFailed != null) {
      _chromeCastPlatform
          .onRequestFailed(id: id)
          .listen((event) => onRequestFailed!(event.error));
    }
    if (onSessionEnding != null) {
      _chromeCastPlatform
          .onSessionEnding(id: id)
          .listen((event) => onSessionEnding!(event.lastPosition));
    }
  }
}