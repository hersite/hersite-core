-keep class ai.onnxruntime. { *; }
-keep interface ai.onnxruntime. { ; }
-keep enum ai.onnxruntime.** {; }

-keep class com.microsoft.onnxruntime. { *; }
-keep interface com.microsoft.onnxruntime. { ; }
-keep enum com.microsoft.onnxruntime.** {; }

-dontwarn ai.onnxruntime.
-dontwarn com.microsoft.onnxruntime.