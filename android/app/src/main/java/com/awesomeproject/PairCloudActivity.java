package com.awesomeproject;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import com.awesomeproject.R;
import uk.co.etiltd.thermalib.Device;
import uk.co.etiltd.thermalib.ThermaLib;

/**
 * Illustrates: 'Pairing' to a Cloud (ThermaQ WiFi, ThermaData WiFi) device.
 */
public class PairCloudActivity extends Activity {

    private static final String TAG = "PairCloudActivity";

    private EditText serialEditText, keyEditText;

    ThermaLib.ClientCallbacksBase callbackBase = new ThermaLib.ClientCallbacksBase() {

        @Override
        public void onDeviceAccessRequestComplete(Device device, boolean succeeded, String errorMessage) {

            if( succeeded ) {
                Log.d(TAG, "WiFi device pairing succeeded: Device " + device.getSerialNumber());
                Toast.makeText(PairCloudActivity.this, "successfully paired device", Toast.LENGTH_SHORT).show();
                PairCloudActivity.this.finish();
            }
            else {
                //Log.e(TAG, String.format("WiFi device %s:, failed to pair - %s", device.getSerialNumber(), errorMessage));
                // TODO replace Strings with string resources
                Toast.makeText(PairCloudActivity.this, "device pairing failed - " + errorMessage, Toast.LENGTH_SHORT).show();

                new android.app.AlertDialog.Builder(PairCloudActivity.this)
                        .setTitle("Device pairing failed")
                        .setMessage("The device was unable to pair this could be because : \n\n " +
                                "- The Serial or Pairing key is wrong. \n " +
                                "- The internet to the phone has become disconnected. \n" +
                                "- Other system error")
                        .setPositiveButton(android.R.string.ok, new DialogInterface.OnClickListener() {
                            @Override
                            public void onClick(DialogInterface dialog, int which) {
                            }
                        })
                        .setOnDismissListener(new DialogInterface.OnDismissListener() {
                            @Override
                            public void onDismiss(DialogInterface dialog) {
                                PairCloudActivity.this.finish();
                            }
                        })
                        .create().show();
            }

        }

    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_pair_cloud);

        serialEditText = (EditText) findViewById(R.id.serialEditText);
        keyEditText = (EditText) findViewById(R.id.keyEditText);

    }

    @Override
    protected void onResume() {
        super.onResume();
        ThermaLib.instance(this).registerCallbacks(callbackBase, TAG);
    }

    @Override
    protected void onPause() {
        super.onPause();
        ThermaLib.instance(this).deregisterCallbacks(callbackBase);
    }

    public void onClick(View view) {

        switch (view.getId()){

            case R.id.requestButton:{

                pairDevice();

                break;

            }

            case R.id.exitButton: {

                finish();
                break;

            }

        }

    }

    private void pairDevice(){

        String key = keyEditText.getText().toString();
        String serial = serialEditText.getText().toString();

        String normalisedPairingKey = normalisePairingKey(key);
        // the device identifier for one of these devices is the serial number but without any
        // leading D/d that might have been entered by the user.

        String identifier = normaliseSerialNumber(serial);
        if( identifier != null && normalisedPairingKey != null) {
            Device device = ThermaLib.instance(this).getDeviceWithIdentifierAndTransport(identifier, ThermaLib.Transport.WS_THERMACLOUD );
            if( device == null ) {
                Log.i(TAG, "Creating new device object for serial: " + identifier);
                device = ThermaLib.instance(this).createDevice(this, identifier, ThermaLib.Transport.WS_THERMACLOUD);
            }
            if (device == null) {
                Log.e(TAG, "Could not create WiFi Device object");

                new AlertDialog.Builder(this)
                        .setMessage(R.string.could_not_pair)
                        .setPositiveButton(android.R.string.ok, null)
                        .create().show();

                finish();
            } else {
                try {
                    ThermaLib.instance(this).requestDeviceAccess(device, normalisedPairingKey);
                    // if this doesn't throw an exception, wait for the callback.
                } catch (Exception x) {
                    Log.e(TAG, "device access request failed", x);
                    new AlertDialog.Builder(this)
                            .setMessage(R.string.device_request_failed)
                            .setPositiveButton(android.R.string.ok, null)
                            .create().show();
                }
            }
        }

    }

    // Converts to upper-case, knock off a leading D if any, test for 8 digit numeric.
    // This will accept and convert the serial number with or without a leading D (either case)
    // but reject all invalid serial numbers.
    private String normaliseSerialNumber(final String rawSerialNumber) {
        String ret = null;
        String norm = rawSerialNumber.toUpperCase();

        if(norm.length() >=8 ){ // can be 8 or 9;

            if( norm.substring(0,1).toUpperCase().equals("D") ) {
                norm = norm.substring(1);
            }

            // must be 8 once the leader, if present, is knocked off.
            if( norm.length() == 8 && android.text.TextUtils.isDigitsOnly(norm)) {
                ret = norm;
            }
            else {
                new AlertDialog.Builder(this)
                        .setMessage(R.string.invalid_serial_number)
                        .setPositiveButton(android.R.string.ok, null)
                        .create().show();
            }

        } else {
            new AlertDialog.Builder(this)
                    .setMessage(R.string.invalid_serial_number)
                    .setPositiveButton(android.R.string.ok, null)
                    .create().show();
        }

        return ret;

    }

    // check that the pairing key is 8 hex digits.

    private String normalisePairingKey(final String pairingKey) {
        String ret = null;
        if( pairingKey.length() == 8) {
            String upper = pairingKey.toUpperCase();
            if( upper.matches("\\p{XDigit}+") ) {
                ret = upper;
            }
        }
        if( ret == null ) {
            new AlertDialog.Builder(this)
                    .setMessage(R.string.invalid_pairing_key)
                    .setPositiveButton(android.R.string.ok, null)
                    .create().show();
        }
        return ret;
    }

}
