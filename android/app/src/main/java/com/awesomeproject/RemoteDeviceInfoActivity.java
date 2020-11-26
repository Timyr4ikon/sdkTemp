package com.awesomeproject;

import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.widget.TextView;

import com.awesomeproject.R;
import uk.co.etiltd.thermalib.Device;
import uk.co.etiltd.thermalib.RemoteSettings;
import uk.co.etiltd.thermalib.ThermaLib;

/**
 * Illustrates: Remote settings (Cloud devices only)
 */

public class RemoteDeviceInfoActivity extends Activity {

    private Device mDevice;
    private static final String TAG = "CDeviceSettingsActivity";

    private ThermaLib.ClientCallbacks mCallbacks = new ThermaLib.ClientCallbacksBase() {
        @Override
        public void onRemoteSettingsReceived(Device device) {
            setFields();
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_cloud_device_settings);

        mDevice = ThermaLib.instance(getApplicationContext()).getDeviceWithIdentifier(getIntent().getStringExtra(Defs.PARAM_DEVICE_ADDRESS));
        ThermaLib.instance(getApplicationContext()).registerCallbacks(mCallbacks, TAG);

        setFields();

    }

    private void setFields(){

        RemoteSettings settings = mDevice.getRemoteSettings();

        setText(R.id.measurementInterval, String.valueOf(settings.getMeasurementInterval()));
        setText(R.id.transmissionInterval, String.valueOf(settings.getTransmissionInterval()));
        setText(R.id.startDate, settings.getStartDate().toString());
        setText(R.id.samplesInMemory, String.valueOf(settings.getSampleCount()));
        setText(R.id.tempratureDisplayUnit, settings.getTemperatureDisplayUnit().getDesc());
        setText(R.id.auditEnabled, String.valueOf(settings.isAuditEnabled()));
        setText(R.id.signal, String.valueOf(settings.getSignalStrength()));

        setText(R.id.sensor1Name, settings.getSensorName(0));
        setText(R.id.sensor1Enabled, String.valueOf(settings.isSensorEnabled(0)));
        setText(R.id.sensor1AlarmDelay, String.valueOf(settings.getSensorAlarmDelay(0)));
        setText(R.id.sensor1HighAlarm, String.valueOf(settings.getSensorHighLimit(0)));
        setText(R.id.sensor1LowAlarm, String.valueOf(settings.getSensorLowLimit(0)));
        setText(R.id.sensor1HighEnabled, String.valueOf(settings.isSensorHighAlarmEnabled(0)));
        setText(R.id.sensor1LowEnabled, String.valueOf(settings.isSensorLowAlarmEnabled(0)));
        setText(R.id.sensor1TrimValue, String.valueOf(settings.getSensorTrimValue(0)));
        setText(R.id.sensor1TrimDate, String.valueOf(settings.getSensorTrimDate(0)));

        if(mDevice.getSensors().size() == 2){

            findViewById(R.id.sensor2).setVisibility(View.VISIBLE);

            setText(R.id.sensor2Name, settings.getSensorName(1));
            setText(R.id.sensor2Enabled, String.valueOf(settings.isSensorEnabled(1)));
            setText(R.id.sensor2AlarmDelay, String.valueOf(settings.getSensorAlarmDelay(1)));
            setText(R.id.sensor2HighAlarm, String.valueOf(settings.getSensorHighLimit(1)));
            setText(R.id.sensor2LowAlarm, String.valueOf(settings.getSensorLowLimit(1)));
            setText(R.id.sensor2HighEnabled, String.valueOf(settings.isSensorHighAlarmEnabled(1)));
            setText(R.id.sensor2LowEnabled, String.valueOf(settings.isSensorLowAlarmEnabled(1)));
            setText(R.id.sensor2TrimValue, String.valueOf(settings.getSensorTrimValue(1)));
            setText(R.id.sensor2TrimDate, String.valueOf(settings.getSensorTrimDate(1)));

        } else {

            findViewById(R.id.sensor2).setVisibility(View.GONE);

        }

    }

    private void setText(int id, String text){
        TextView textView = (TextView) findViewById(id);
        if( textView != null ) {
            textView.setText(text);
        }
    }


}
