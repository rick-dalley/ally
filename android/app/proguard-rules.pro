# google_mlkit_text_recognition's plugin code references the optional per-script
# recognizer classes (Chinese/Devanagari/Japanese/Korean) regardless of which ones are
# actually depended on — this app only uses the default (Latin) recognizer, so those
# classes are never on the classpath. R8 fails the build over the missing references
# unless told they're expected to be absent.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
