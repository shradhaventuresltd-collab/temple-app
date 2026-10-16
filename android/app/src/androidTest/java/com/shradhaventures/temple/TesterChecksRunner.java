package com.shradhaventures.temple;

import android.os.Bundle;
import android.util.Log;
import androidx.test.runner.AndroidJUnitRunner;
import java.io.File;
import java.io.FileOutputStream;
import java.nio.charset.StandardCharsets;

/**
 * Writes the host's {@code -e phase} value into app files before the activity
 * starts. {@code pm clear} wipes that file; the next instrumentation run
 * writes it again. Release builds are not debuggable, so the host cannot
 * {@code run-as} into this directory.
 */
public class TesterChecksRunner extends AndroidJUnitRunner {
  private static final String TAG = "TesterChecks";
  private String phase = "";

  @Override
  public void onCreate(Bundle arguments) {
    if (arguments != null) {
      String value = arguments.getString("phase", "");
      if (value != null) {
        phase = value.trim();
      }
    }
    super.onCreate(arguments);
  }

  @Override
  public void onStart() {
    writePhase();
    super.onStart();
  }

  private void writePhase() {
    if (phase.isEmpty()) {
      Log.i(TAG, "no phase extra");
      return;
    }
    try {
      File dir = getTargetContext().getFilesDir();
      if (!dir.isDirectory() && !dir.mkdirs()) {
        Log.e(TAG, "files dir missing");
        return;
      }
      File file = new File(dir, "tester_checks_phase.txt");
      try (FileOutputStream out = new FileOutputStream(file, false)) {
        out.write(phase.getBytes(StandardCharsets.UTF_8));
      }
      Log.i(TAG, "phase " + phase);
    } catch (Exception e) {
      Log.e(TAG, "phase write failed", e);
    }
  }
}
