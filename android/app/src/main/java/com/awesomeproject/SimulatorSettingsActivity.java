package com.awesomeproject;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.KeyEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.EditorInfo;
import android.widget.EditText;
import android.widget.SeekBar;
import android.widget.TextView;

import com.awesomeproject.R;
import uk.co.etiltd.thermalib.Device;
import uk.co.etiltd.thermalib.SimulatedDevice;
import uk.co.etiltd.thermalib.ThermaLib;

import static android.view.View.GONE;

/**
 * Illustrates: Changing the characteristics of a simulated device.
 */
public class SimulatorSettingsActivity extends Activity {

    // Thermalib
    private ThermaLib mThermaLib;
    private SimulatedDevice mDevice;

    // device-level field
    private SeekBar mBatteryLevelSetter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        mThermaLib = ThermaLib.instance(this);

        // recover the device object from the intent parameters
        Intent intent = getIntent();

        String deviceAddress = intent.getStringExtra(Defs.PARAM_DEVICE_ADDRESS);

        if (deviceAddress != null) {
            // look for existing device
            Device device = mThermaLib.getDeviceWithIdentifier(deviceAddress);
            // defensive guard
            if (!(device instanceof SimulatedDevice)) {
                Util.toast(this, "not a simulated device");
                finish();
            } else {
                mDevice = (SimulatedDevice) mThermaLib.getDeviceWithIdentifier(deviceAddress);
            }
        }

        if (mDevice == null) {
            Util.toast(this, String.format("device with address %s was not found", deviceAddress));
            finish();
        }

        // at this point mDevice is set correctly.
        setContentView(R.layout.activity_simulator_settings);
        getActionBar().setTitle(mDevice.getDeviceName() + " - Simulation Settings");

        initialiseUI();
    }

    // sensor-specific fields which may be duplicated, within
    // different Sensor groups. In this demo, we just set High and Low alarm values
    // per sensor.

    private class SensorFields implements TextView.OnEditorActionListener {
        private SimulatedDevice.SensorParameters mSensorParameters;
        ViewGroup mGroup;
        EditText mSetReadingField;
        EditText mStepSizeField;
        EditText mRandomAdjustmentField;

        private SensorFields(int groupResId, int sensorIndex) {
            ViewGroup parent = (ViewGroup) findViewById(groupResId);
            mGroup = parent;

            mSetReadingField = (EditText) parent.findViewById(R.id.setCurrentReading);
            mStepSizeField = (EditText) parent.findViewById(R.id.stepSize);
            mRandomAdjustmentField = (EditText) parent.findViewById(R.id.randomAdjustment);

            mSetReadingField.setOnEditorActionListener(this);
            mStepSizeField.setOnEditorActionListener(this);
            mRandomAdjustmentField.setOnEditorActionListener(this);

            if (sensorIndex < mDevice.getSensors().size()) {
                mSensorParameters = mDevice.getSensorParameters(sensorIndex);
                mGroup.setVisibility(View.VISIBLE);
            } else {
                mGroup.setVisibility(GONE);
            }
        }

        // Listen for alarm level setting

        @Override
        public boolean onEditorAction(TextView field, int event, KeyEvent keyEvent) {
            if (event == EditorInfo.IME_ACTION_DONE) {
                try {
                    float value = Float.parseFloat(field.getText().toString());
                    // values are written straight into the simulator memory
                    if (field == mSetReadingField) {
                        mSensorParameters.initialReading = value;
                    } else if (field == mStepSizeField) {
                        mSensorParameters.readingStep = value;
                    } else if (field == mRandomAdjustmentField) {
                        mSensorParameters.randomVariation = value;
                    }
                } catch (NumberFormatException x) {
                    toast("invalid format");
                }
                return true;
            }
            return false;
        }

     }

    ;

    // allocate for 2 groups
    private SensorFields[] mSensorFieldGroups = new SensorFields[2];


    private void initialiseUI() {

        setupBatteryLevelField();
        setupSensorParameters();
        updateFields();

    }

    private void setupBatteryLevelField() {
        mBatteryLevelSetter = (SeekBar) findViewById(R.id.batteryLevelSetter);
        mBatteryLevelSetter.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int level, boolean fromUser) {
                if( fromUser ) {
                    mDevice.setBatteryLevel(level);
                }
            }

            @Override public void onStartTrackingTouch(SeekBar seekBar) { }
            @Override public void onStopTrackingTouch(SeekBar seekBar) { }
        });
    }

    private void updateFields() {

        mBatteryLevelSetter.setProgress(mDevice.getBatteryLevel());


        // Sensor level fields

        int sensorCount = mDevice.getSensors().size();

        if (sensorCount > 0) {
            setSensorFields(0);
        }

        if (sensorCount > 1) {
            setSensorFields(1);
        }
    }

    private void setSensorFields(int sensorIndex) {
        SensorFields fields = mSensorFieldGroups[sensorIndex];
        SimulatedDevice.SensorParameters sensorParameters = mDevice.getSensorParameters(sensorIndex);

        if( sensorParameters != null ) {
            fields.mSetReadingField.setText(String.valueOf(sensorParameters.initialReading));
            fields.mStepSizeField.setText(String.valueOf(sensorParameters.readingStep));
            fields.mRandomAdjustmentField.setText(String.valueOf(sensorParameters.randomVariation));
        }
    }

    private void setupSensorParameters() {
        mSensorFieldGroups[0] = new SensorFields(R.id.sensor1Settings, 0);
        mSensorFieldGroups[1] = new SensorFields(R.id.sensor2Settings, 1);
    }


    private void toast(String s) {
        Util.toast(this, s);
    }
}
