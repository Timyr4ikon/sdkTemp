package com.awesomeproject;

import android.Manifest;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.core.content.ContextCompat;

import com.facebook.react.ReactActivity;

import java.util.Arrays;

import uk.co.etiltd.thermalib.Device;
import uk.co.etiltd.thermalib.ThermaLib;
import uk.co.etiltd.thermalib.ThermaLibException;

public class MainActivity2 extends ReactActivity {

    /**
     * Returns the name of the main component registered from JavaScript. This is used to schedule
     * rendering of the component.
     */
    @Override
    protected String getMainComponentName() {
        return "AwesomeProject";
    }

    private static final String TAG = "MainActivity2";

    // ThermaLib
    private ThermaLib mThermaLib;
    private Object mThermaLibCallbackHandle;    // set when mCallbacks are registered, and used to deregister
    private String mAppKey;

    /**
     * Illustrates: ThermaLib mCallbacks.
     * <ul>
     * <li>ThermaLib.ClientCallbacksBase is provided as a convenience, and contains null implementations
     * of all mCallbacks, so that only those required need be overridden.</li>
     * <li>There is no need to call through to the superclass for any method.</li>
     * <li>The library also contains a LoggingClientCallbacks class, which will log all mCallbacks in a uniform way.</li>
     * </ul>
     */
    private ThermaLib.ClientCallbacks mThermalibCallbacks = new ThermaLib.ClientCallbacksBase() {

        @Override
        public void onScanComplete(int errorCode, int numDevices) {
            if (errorCode != ThermaLib.SUCCESS) {
                Util.toast(MainActivity2.this, "scan failed");
            } else {
                Util.toast(MainActivity2.this, String.format("%d device%s found", numDevices, numDevices == 1 ? "" : "s"));
            }
            mAdapter.notifyDataSetChanged();
            updateUI();
        }

        // new device discovered
        @Override
        public void onNewDevice(Device device, long timestamp) {
            // just tell the Adapter to update the list
            mAdapter.notifyDataSetChanged();
            updateUI();
        }

        // device connection state change
        @Override
        public void onDeviceConnectionStateChanged(Device device, Device.ConnectionState newState, long timestamp) {
            mAdapter.setFieldsForDevice(device); // reflect the change
        }

        // device object updated, which can be stimulated by a device event (e.g. new reading) or an SDK event (e.g.
        // a call to a settings method such as setHighAlarm.
        @Override
        public void onDeviceUpdated(Device device, long timestamp) {
            mAdapter.setFieldsForDevice(device); // reflect the change
        }

        // Not all devices report all events. Most events are currently reported only by Bluetooth LE events.
        @Override
        public void onDeviceNotificationReceived(Device device, int notificationType, byte[] payload, long timestamp) {
            super.onDeviceNotificationReceived(device, notificationType, payload, timestamp);
            Toast.makeText(getApplicationContext(), Device.NotificationType.toString(notificationType), Toast.LENGTH_SHORT).show();
        }

        // This is called when ThermaLib.requestService has completed. Currently only relevant for Cloud devices.
        @Override
        public void onRequestServiceComplete(int transport, boolean succeeded, String errorMessage, String appKey) {
            Log.d(TAG, "WiFi Service Connection" + errorMessage);

            if (succeeded) {

                // check app key is as expected
                Log.d(TAG, "WiFi Service Connection succeeded: key " + appKey);
                if (mAppKey != null && !mAppKey.equals(appKey)) {
                    Log.e(TAG, String.format("Service connection returned unexpected app key: expected = [%s], actual = [%s]", mAppKey, appKey));
                }

                // cache and persist the returned key in all cases.
                mAppKey = appKey;
                persistAppKey();

                Toast.makeText(MainActivity2.this, "Service Connected", Toast.LENGTH_SHORT).show();

            } else {
                Log.e(TAG, "WiFi Service Connection failed: " + errorMessage);
                Toast.makeText(MainActivity2.this, "Service connection failed: " + errorMessage, Toast.LENGTH_SHORT).show();

            }

        }

        // called when a request to revoke access to a device (==deregistration, ==unpairing) completes. Currently only
        // relevant for Cloud devices.
        @Override
        public void onDeviceRevokeRequestComplete(Device device, boolean succeeded, String errorMessage) {

            if (succeeded) {
                Toast.makeText(MainActivity2.this, "Device Forgotten", Toast.LENGTH_SHORT).show();
                ThermaLib.instance(MainActivity2.this).deleteDevice(device);
            } else {
                Toast.makeText(MainActivity2.this, "Unable to forget device : " + errorMessage, Toast.LENGTH_SHORT).show();
            }

            updateUI();

        }

        // called when a change to a device's actual settings has been reported. Only relevant for Cloud devices, where
        // changes to settings do not take effect until the next time the device communicates with the central service.

        @Override
        public void onRemoteSettingsReceived(Device device) {

            Toast.makeText(MainActivity2.this, "Settings received for " + device.getDeviceName(), Toast.LENGTH_SHORT).show();

        }

        // called when a disconnection has occurred that is not correlated with client app action, such as a disconnection request.;
        @Override
        public void onUnexpectedDeviceDisconnection(Device device, String exceptionMessage, DeviceDisconnectionReason reason, long timestamp) {
            Log.e(TAG, "Unexpected Disconnection : " + exceptionMessage);
        }

    };

    /**
     * Illustrates: One-time initialisation
     */
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // real apps would probably check status of Bluetooth, Wi-Fi, and app permissions at this point.

        // ThermaLib is a singleton whose reference may be cached.
        mThermaLib = ThermaLib.instance(this);

        // pass the stable device list object to the adapter
        mAdapter = new DeviceListAdapter(this, mThermaLib.getDeviceList());

        ((TextView) findViewById(R.id.versionNumber)).setText("SDK Version Number : " + mThermaLib.getVersionNumber());

        initialiseUI();

        // for illustration, enable Bluetooth, Cloud and Simulation.
        // a real app would just enable the ones required.
        // if supported transports are not explicitly set, then only Bluetooth LE is supported.
        mThermaLib.setSupportedTransports(Arrays.asList(new Integer[]{
                ThermaLib.Transport.BLUETOOTH_LE,
                ThermaLib.Transport.WS_THERMACLOUD,
                ThermaLib.Transport.SIMULATED
        }));

    }

    // It's advisable to make sure your callback object is only registered when required, to avoid unnecessary
    // background processing. In this case we only want updates when this activity is in the foreground,
    // so register in onResume and deregister in onPause.

    // On the other hand your app may contain components, for example alert state monitors or data recorders,
    // that require their mCallbacks to be registered permanently.

    @Override
    protected void onPause() {
        if (mThermaLibCallbackHandle != null) {
            mThermaLib.deregisterCallbacks(mThermaLibCallbackHandle);
            mThermaLibCallbackHandle = null;
        }
        super.onPause();
    }

    @Override
    protected void onResume() {
        super.onResume();
        // the second parameter is a tag that will be used in Android logging.
        mThermaLibCallbackHandle = mThermaLib.registerCallbacks(mThermalibCallbacks, TAG);

        // get the adapter to fully refresh, in case anything changed while the activity
        // wasn't active in the foreground.
        mAdapter.notifyDataSetChanged();
        updateUI();
    }

    // --- SCAN BUTTON HANDLING ---

    /**
     * Illustrates: scanning; device connection state testing; requesting connection and disconnection
     */
    public void onClick(View view) throws ThermaLibException {
        Device device;
        int scanTimeout = Integer.parseInt(((TextView) findViewById(R.id.scanTimeout)).getText().toString());
        switch (view.getId()) {
            case R.id.stopScanButton:

                mThermaLib.stopScanForDevices();
                break;

            case R.id.scanBleButton:
                if (checkBluetooth()) {
                    Log.d(TAG, "Start Scan button pressed Timeout = " + scanTimeout);
                    mThermaLib.startScanForDevices(ThermaLib.Transport.BLUETOOTH_LE, scanTimeout);
                }
                break;

            case R.id.scanCloudButton:

                if (ThermaLib.instance(this).isServiceConnected(ThermaLib.Transport.WS_THERMACLOUD)) {
                    ThermaLib.instance(this).startScanForDevices(ThermaLib.Transport.WS_THERMACLOUD, scanTimeout);
                } else {
                    Toast.makeText(this, "Can only scan for cloud devices if service is connected", Toast.LENGTH_SHORT).show();
                }

                break;

            case R.id.scanSimButton:

                ThermaLib.instance(this).startScanForDevices(ThermaLib.Transport.SIMULATED, 5);
                break;

            case R.id.connectButton:
                device = (Device) view.getTag();

                // ThermaLib will throw an exception if a connection request is made when
                // already connected, and vice versa

                try {
                    // connection state changes are reported via
                    // onConnectionStateChange above.

                    if (!device.isConnected()) {
                        device.requestConnection();
                    } else {
                        device.requestDisconnection();
                    }
                } catch (Exception x) {
                    Util.toast(this, x.getMessage());
                }
                break;

            case R.id.pairCloudButton: {

                if (mThermaLib.isServiceConnected(ThermaLib.Transport.WS_THERMACLOUD)) {
                    startCloudPairActivity();
                } else {
                    Toast.makeText(this, "Can not pair until service is connected", Toast.LENGTH_SHORT).show();
                }
                break;

            }

            case R.id.connectCloudButton: {

                // This connects Thermalib to the cloud service.
                connectCloudService();

                break;

            }

            case R.id.addDeviceSimButton: {

                Device device1 = mThermaLib.createDevice(this, "", ThermaLib.Transport.SIMULATED);
                mThermaLib.requestDeviceAccess(device1, null);

                break;

            }

            case R.id.clearListButton: {

                Log.d(TAG, "Clear device list");

                mThermaLib.reset();
                mAdapter.notifyDataSetChanged();
                updateUI();
                break;

            }

        }
    }

    private void startCloudPairActivity() {
        Intent intent = new Intent(this, PairCloudActivity.class);
        startActivity(intent);
    }

    // --- UI Handling - mostly done in DeviceListAdapter

    private ListView mListView;

    private DeviceListAdapter mAdapter;


    private void initialiseUI() {

        mListView = (ListView) findViewById(R.id.deviceList);
        mListView.setAdapter(mAdapter);

    }

    private void updateUI() {

        ((TextView) findViewById(R.id.totalBLEText)).setText("" + mThermaLib.deviceCount(ThermaLib.Transport.BLUETOOTH_LE));
        ((TextView) findViewById(R.id.totalCloudText)).setText("" + mThermaLib.deviceCount(ThermaLib.Transport.WS_THERMACLOUD));
        ((TextView) findViewById(R.id.totalSimText)).setText("" + mThermaLib.deviceCount(ThermaLib.Transport.SIMULATED));

    }

    // -- General Bluetooth Low Energy status check

    private boolean checkBluetooth() {
        boolean bOK = true;
        // check that Bluetooth is available
        final BluetoothManager bleManager = (BluetoothManager) getSystemService(Context.BLUETOOTH_SERVICE);
        if (bleManager == null) {
            Util.showDialogMessage(this, "Bluetooth is not available");
            bOK = false;
        } else {
            BluetoothAdapter bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
            if (bluetoothAdapter == null || !bluetoothAdapter.isEnabled()) {
                Util.showDialogMessage(this, "Bluetooth is not enabled. Real Bluetooth devices will not be accessible.");
                bOK = false;
            } else if (!getPackageManager().hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
                Util.showDialogMessage(this, "Bluetooth Low Energy is not available on this Android phone/tablet. Real Bluetooth devices will not be accessible.");
                bOK = false;
            }
        }
        if (bOK) { // have bluetooth: check app permissions
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION)
                    != PackageManager.PERMISSION_GRANTED
                    &&
                    ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
                            != PackageManager.PERMISSION_GRANTED
            ) {
                // A real application would take a more sophisticated approach. See
                // https://developer.android.com/training/permissions/requesting.html
                Util.showDialogMessage(this, "To access real Bluetooth devices, you must enabled Location Services for this app via Android Settings.");
                bOK = false;
            }
        }
        return bOK;
    }

    // This function tries to retrieve the app key from SharedPreferences and then requests access to the cloud service.
    // If appKey is null, ThermaLib will generate a new key.
    private boolean connectCloudService() {

        boolean ret = false;
        String appKey = unpersistAppKey();
        Log.d(TAG, String.format("Requesting WiFi service with key : %s", appKey));

        try {

            // Once this is called we should get a callback on onRequestServiceComplete;
            mThermaLib.requestService(ThermaLib.Transport.WS_THERMACLOUD, appKey);

            // if no exception, succeed.
            ret = true;
        } catch (Exception x) {
            //Log.e(TAG, "WiFi Service request failed", x);
            Toast.makeText(this, "WiFi service request failed", Toast.LENGTH_SHORT).show();
        }

        return ret;
    }

    // This is used to store and retrieve the app key from SharedPreferences
    private String unpersistAppKey() {
        SharedPreferences sp = getSharedPreferences(null, Context.MODE_PRIVATE);
        mAppKey = sp.getString(Defs.SP_APPKEY_WIFI, null);
        return mAppKey;
    }

    private void persistAppKey() {
        if (mAppKey != null) {
            SharedPreferences sp = getSharedPreferences(null, Context.MODE_PRIVATE);
            sp.edit().putString(Defs.SP_APPKEY_WIFI, mAppKey).commit();
        }
    }

    private String getTransportString(int transport) {

        switch (transport) {

            case ThermaLib.Transport.BLUETOOTH_LE:
                return "BLE";
            case ThermaLib.Transport.SIMULATED:
                return "Simulated";
            case ThermaLib.Transport.UNKNOWN:
                return "Unknown";
            case ThermaLib.Transport.WS_THERMACLOUD:
                return "Cloud";

        }

        return "";

    }

}
