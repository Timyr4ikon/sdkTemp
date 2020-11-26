package com.awesomeproject;

import android.bluetooth.BluetoothClass;
import android.util.Log;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import uk.co.etiltd.thermalib.Device;
import uk.co.etiltd.thermalib.ThermaLib;

public class ThermaLibUtils {

    private static final String TAG = "DENIS_TAG";

    public static String getJsonDeviceObject(Device device) {
        Gson gson = new GsonBuilder().create();
        return gson.toJson(device, Device.class);
    }

    public static String getJsonScanResultObject(ThermaLib.ScanResult scanResult) {
        Gson gson = new GsonBuilder().create();
        return gson.toJson(scanResult, ThermaLib.ScanResult.class);
    }
}
