package it.aesys.flutter_video_cast_example

import android.os.Bundle
import com.google.android.gms.cast.framework.CastContext
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        CastContext.getSharedInstance(applicationContext)
    }
}
