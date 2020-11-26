package com.awesomeproject;

import android.telecom.Call;
import android.util.Log;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.WritableMap;

import uk.co.etiltd.thermalib.Device;
import uk.co.etiltd.thermalib.ThermaLib;

public class MThermaLibCallback extends ThermaLib.ClientCallbacksBase {
    private Promise promise;

    private static final String TAG = "DENIS_TAG";

    public MThermaLibCallback(Promise promise) {
        this.promise = promise;
    }

    @Override
    public void onNewDevice(Device device, long timestamp) {
        super.onNewDevice(device, timestamp);
        Log.i(TAG, "onNewDevice: ");
        WritableMap map = Arguments.createMap();
        map.putDouble("timestamp", (double) timestamp);
        map.putString("device", ThermaLibUtils.getJsonDeviceObject(device));
        promise.resolve(map);
    }

    @Override
    public void onDeviceDeleted(String deviceAddress, int transportType) {
        Log.i(TAG, "onDeviceDeleted: ");
        super.onDeviceDeleted(deviceAddress, transportType);
    }

    @Override
    public void onDeviceConnectionStateChanged(Device device, Device.ConnectionState newState, long timestamp) {
        Log.i(TAG, "onDeviceConnectionStateChanged: ");
        super.onDeviceConnectionStateChanged(device, newState, timestamp);
    }

    @Override
    public void onBatteryLevelReceived(Device device, int levelPercent, long timestamp) {
        Log.i(TAG, "onBatteryLevelReceived: ");
        super.onBatteryLevelReceived(device, levelPercent, timestamp);
    }

    @Override
    public void onDeviceUpdated(Device device, long timestamp) {
        Log.i(TAG, "onDeviceUpdated: ");
        super.onDeviceUpdated(device, timestamp);
    }

    @Override
    public void onRefreshComplete(Device device, boolean userRefresh, long timestamp) {
        Log.i(TAG, "onRefreshComplete: ");
        super.onRefreshComplete(device, userRefresh, timestamp);
    }

    @Override
    public void onScanComplete(int errorCode, int numDevices) {
        Log.i(TAG, "onScanComplete: 0");
        super.onScanComplete(errorCode, numDevices);
        if(errorCode!=ThermaLib.SUCCESS){
            promise.reject("ERROR", "No devices detected");
        } else {
            WritableMap map = Arguments.createMap();
            map.putInt("numDevices", numDevices);
            promise.resolve(map);
        }
    }

    @Override
    public void onScanComplete(int transport, ThermaLib.ScanResult scanResult, int numDevices, String errorMsg) {
        Log.i(TAG, "onScanComplete: 1");
        super.onScanComplete(transport, scanResult, numDevices, errorMsg);
        WritableMap map = Arguments.createMap();
        map.putInt("transport", transport);
        map.putString("scanResult", ThermaLibUtils.getJsonScanResultObject(scanResult));
        map.putInt("numDevices", numDevices);
        map.putString("errorMsg", errorMsg);
        promise.resolve(map);
    }

    @Override
    public void onMessage(Device device, String msg, long timestamp) {
        Log.i(TAG, "onMessage: ");
        super.onMessage(device, msg, timestamp);
    }

    @Override
    public void onDeviceReady(Device device, long timestamp) {
        Log.i(TAG, "onDeviceReady: ");
        super.onDeviceReady(device, timestamp);
    }

    @Override
    public void onDeviceNotificationReceived(Device device, int notificationType, byte[] payload, long timestamp) {
        Log.i(TAG, "onDeviceNotificationReceived: ");
        super.onDeviceNotificationReceived(device, notificationType, payload, timestamp);
    }

    @Override
    public void onRssiUpdated(Device device, int rssi) {
        Log.i(TAG, "onRssiUpdated: ");
        super.onRssiUpdated(device, rssi);
    }

    @Override
    public void onUnexpectedDeviceDisconnection(Device device, long timestamp) {
        Log.i(TAG, "onUnexpectedDeviceDisconnection: ");
        super.onUnexpectedDeviceDisconnection(device, timestamp);
    }

    @Override
    public void onUnexpectedDeviceDisconnection(Device device, String exceptionMessage, DeviceDisconnectionReason reason, long timestamp) {
        Log.i(TAG, "onUnexpectedDeviceDisconnection: ");
        super.onUnexpectedDeviceDisconnection(device, exceptionMessage, reason, timestamp);
    }

    @Override
    public void onRequestServiceComplete(int transport, boolean succeeded, String errorMessage, String appKey) {
        Log.i(TAG, "onRequestServiceComplete: ");
        super.onRequestServiceComplete(transport, succeeded, errorMessage, appKey);
    }

    @Override
    public void onDeviceAccessRequestComplete(Device device, boolean succeeded, String errorMessage) {
        Log.i(TAG, "onDeviceAccessRequestComplete: ");
        super.onDeviceAccessRequestComplete(device, succeeded, errorMessage);
        if (succeeded) {
            
        }
    }

    @Override
    public void onDeviceRevokeRequestComplete(Device device, boolean succeeded, String errorMessage) {
        Log.i(TAG, "onDeviceRevokeRequestComplete: ");
        super.onDeviceRevokeRequestComplete(device, succeeded, errorMessage);
    }

    @Override
    public void onRemoteSettingsReceived(Device device) {
        Log.i(TAG, "onRemoteSettingsReceived: ");
        super.onRemoteSettingsReceived(device);
    }
}
