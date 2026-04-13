package com.electionassistant.app;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.speech.RecognizerIntent;

import androidx.activity.result.ActivityResult;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

import java.util.ArrayList;

@CapacitorPlugin(name = "VoiceInput")
public class VoicePlugin extends Plugin {

    private ActivityResultLauncher<Intent> speechLauncher;
    private PluginCall savedCall;

    @Override
    public void load() {
        // Register the activity result launcher once when the plugin loads
        speechLauncher = getActivity().registerForActivityResult(
            new ActivityResultContracts.StartActivityForResult(),
            result -> {
                if (savedCall == null) return;
                JSObject ret = new JSObject();

                if (result.getResultCode() == Activity.RESULT_OK
                        && result.getData() != null) {
                    ArrayList<String> matches = result.getData()
                        .getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS);
                    if (matches != null && !matches.isEmpty()) {
                        ret.put("transcript", matches.get(0));
                        savedCall.resolve(ret);
                        savedCall = null;
                        return;
                    }
                }
                ret.put("transcript", "");
                savedCall.resolve(ret);
                savedCall = null;
            }
        );
    }

    @PluginMethod
    public void startListening(PluginCall call) {
        savedCall = call;

        Intent intent = new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH);
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, "en-IN");
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, "en-IN");
        intent.putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1);
        intent.putExtra(RecognizerIntent.EXTRA_PROMPT, "Speak your election question");

        try {
            speechLauncher.launch(intent);
        } catch (ActivityNotFoundException e) {
            savedCall = null;
            call.reject("Speech recognition not available on this device");
        }
    }
}
