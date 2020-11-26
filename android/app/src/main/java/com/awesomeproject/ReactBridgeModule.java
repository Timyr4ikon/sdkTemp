package com.awesomeproject;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.uimanager.IllegalViewOperationException;

import java.util.Arrays;

import uk.co.etiltd.thermalib.Device;
import uk.co.etiltd.thermalib.ThermaLib;
import uk.co.etiltd.thermalib.ThermaLibException;

public class ReactBridgeModule extends ReactContextBaseJavaModule {

    private static final String TAG = "ReactBridgeTag";

    private ThermaLib thermaLib;
    private Object thermaLibCallbackHandler;

    public ReactBridgeModule(ReactApplicationContext reactContext) {
        super(reactContext); //required by React Native
        thermaLib = ThermaLib.instance(reactContext);
        thermaLib.setSupportedTransports(Arrays.asList(new Integer[]{
                ThermaLib.Transport.BLUETOOTH_LE,
                ThermaLib.Transport.WS_THERMACLOUD,
                ThermaLib.Transport.SIMULATED
        }));
    }

    @Override
    //getName is required to define the name of the module represented in JavaScript
    public String getName() {
        return "ReactBridge";
    }

    @ReactMethod
    public void addDevice(Promise promise) {
        try {
            Device device1 = thermaLib.createDevice(getReactApplicationContext(), "", ThermaLib.Transport.SIMULATED);
            thermaLib.requestDeviceAccess(device1, null);
            if (thermaLibCallbackHandler != null)
                thermaLib.deregisterCallbacks(thermaLibCallbackHandler);
            thermaLibCallbackHandler = thermaLib.registerCallbacks(new MThermaLibCallback(promise), TAG);

        } catch (Exception e) {
            e.printStackTrace();
            promise.reject(e);
        }

//        successCallback.invoke("Add device");
    }

    @ReactMethod
    public void stopScan() {
        thermaLib.stopScanForDevices();
    }

    @ReactMethod
    public void requestDeviceConnect(String jsonDevice) {
        Device device = Util.getDeviceFromJson(jsonDevice);
        if (device != null)
            if (!device.isConnected()) {
                try {
                    device.requestConnection();
                } catch (ThermaLibException e) {
                    e.printStackTrace();
                }
            }
    }

    @ReactMethod
    public void requestDeviceDisconnection(String jsonDevice) {
        Device device = Util.getDeviceFromJson(jsonDevice);
        if (device != null)
            if (device.isConnected())
                device.requestDisconnection();
    }

    @ReactMethod
    public void startScan(int timeout, Promise promise) {
        if (thermaLibCallbackHandler != null)
            thermaLib.deregisterCallbacks(thermaLibCallbackHandler);
        thermaLibCallbackHandler = thermaLib.registerCallbacks(new MThermaLibCallback(promise), TAG);
        thermaLib.startScanForDevices(ThermaLib.Transport.BLUETOOTH_LE, timeout);
    }

    @ReactMethod
    public void startScanSimulated(int timeout, Promise promise) {
        if (thermaLibCallbackHandler != null)
            thermaLib.deregisterCallbacks(thermaLibCallbackHandler);
        thermaLibCallbackHandler = thermaLib.registerCallbacks(new MThermaLibCallback(promise), TAG);
//        thermaLib.startScanForDevices(ThermaLib.Transport.BLUETOOTH_LE, timeout);
        ThermaLib.instance(getReactApplicationContext()).startScanForDevices(ThermaLib.Transport.SIMULATED, 5);
    }


    @ReactMethod
    public void promise(Promise promise) {
        try {
            Boolean yes = true; // could be any data type listed under https://facebook.github.io/react-native/docs/native-modules-android.html#argument-types
            if (yes) {
                promise.resolve("Android promise test");
            }
        } catch (Exception e) {
            promise.reject("error", e);
        }
    }

    @ReactMethod
    public void callback(double time, Callback errorCallback, Callback successCallback) {
        try {
            System.out.println(time);
            String fString = String.format("Android callback test: %f", time);
            successCallback.invoke(fString);
        } catch (IllegalViewOperationException e) {
            errorCallback.invoke(e.getMessage());
        }
    }
}