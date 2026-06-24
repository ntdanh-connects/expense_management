# Keep rules for Google ML Kit Text Recognition
# Ignore warnings about missing classes for language packages that we do not use (we only use Latin text recognition)
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
