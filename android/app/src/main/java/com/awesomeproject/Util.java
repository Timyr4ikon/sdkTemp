package com.awesomeproject;

/*
 * Created by Julian Symes (ETI Ltd) on 01/12/2016.
 */

import android.annotation.SuppressLint;
import android.app.AlertDialog;
import android.content.Context;
import android.widget.Button;
import android.widget.Toast;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import uk.co.etiltd.thermalib.Device;
import uk.co.etiltd.thermalib.Sensor;

class Util {
    static void toast(Context context, String s, int len) {
        Toast.makeText(context, s, len).show();
    }
    static void toast(Context context, String s) {
        Toast.makeText(context, s, Toast.LENGTH_SHORT).show();
    }
    static void showDialogMessage(Context context, String msg) {
        new AlertDialog.Builder(context)
                .setMessage(msg)
                .setPositiveButton(android.R.string.ok, null)
                .create().show();
    }

    static void setButton(Button button, String s, boolean enabled) {
        button.setText(s);
        button.setEnabled(enabled);
    }

    @SuppressLint("DefaultLocale")
    static String formatReadingValue(float reading, int decimalPlaces) {
        final String s;
        if (reading == Sensor.NO_VALUE) {
            s = "-";
        } else {
            s = String.format(String.format("%%.%df", decimalPlaces), reading);
        }
        return s;
    }

    static String formatReadingValue(float reading) {
        return formatReadingValue(reading, 5);     // 5dp by default

    }

    public static Device getDeviceFromJson(String jsonDevice) {
        Gson gson = new GsonBuilder().create();
        Device device;
        device = gson.fromJson(jsonDevice, Device.class);
        return device;
    }
}
