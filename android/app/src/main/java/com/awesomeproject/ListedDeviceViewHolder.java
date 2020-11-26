package com.awesomeproject;

/*
 * Created by Julian Symes (ETI Ltd) on 13/12/2016.
 */

import android.annotation.SuppressLint;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.graphics.Color;
import android.view.View;
import android.widget.Button;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.TextView;

import com.awesomeproject.R;
import uk.co.etiltd.thermalib.Device;
import uk.co.etiltd.thermalib.Sensor;

/**
 * Illustrates: several aspects of the use of the ThermaLib API.
 *
 * <ol>
 *     <li>connection states</li>
 *     <li>requesting connection and disconnection</li>
 *     <li>sensor values, fault states and alarm breaches</li>
 *     <li>battery level</li>
 *
 *     <li>device information</li>
 * </ol>
 */
class ListedDeviceViewHolder implements View.OnClickListener {
    private Device mDevice;         // updated when the view is returned from getView(..)
    private final Context mContext;

    // fields relevant whether or not connected

    private final TextView mDeviceNameField;
    private final TextView mConnectionStateField;
    private final Button mConnectButton;

    // fields relevant only if connected

    private final ImageButton mSettingsButton;
    private final ImageButton mInfoButton;
    private final TextView mReading1Field;
    private final TextView mReading2Field;
    private final TextView mSensor1Name;
    private final TextView mSensor2Name;
    private final TextView mBatteryLevelField;
    private final TextView mSensor1DisplayedField;
    private final TextView mSensor2DisplayedField;

    private final ImageView mSensor1DisplayedHighAlarm;
    private final ImageView mSensor1DisplayedLowAlarm;
    private final ImageView mSensor2DisplayedHighAlarm;
    private final ImageView mSensor2DisplayedLowAlarm;

    private final TextView mSensor1NoDisplay;
    private final TextView mSensor2NoDisplay;


    ListedDeviceViewHolder(View view) {
        mContext = view.getContext();
        mDeviceNameField = (TextView) view.findViewById(R.id.deviceName);
        mConnectionStateField = (TextView) view.findViewById(R.id.connectionState);
        mConnectButton = (Button) view.findViewById(R.id.connectButton);

        mSettingsButton = (ImageButton) view.findViewById(R.id.settingsButton);
        mInfoButton = (ImageButton) view.findViewById(R.id.infoButton);

        mReading1Field = (TextView) view.findViewById(R.id.sensor1Reading);
        mReading2Field = (TextView) view.findViewById(R.id.sensor2Reading);
        mSensor1Name = (TextView) view.findViewById(R.id.sensor1Name);
        mSensor2Name = (TextView) view.findViewById(R.id.sensor2Name);
        mBatteryLevelField = (TextView) view.findViewById(R.id.batteryLevel);

        mSensor1DisplayedField = (TextView) view.findViewById(R.id.sensor1DispalyedValue);
        mSensor2DisplayedField = (TextView) view.findViewById(R.id.sensor2DispalyedValue);

        mSensor1DisplayedHighAlarm = (ImageView) view.findViewById(R.id.sensor1HighAlarm);
        mSensor1DisplayedLowAlarm = (ImageView) view.findViewById(R.id.sensor1LowAlarm);
        mSensor2DisplayedHighAlarm = (ImageView) view.findViewById(R.id.sensor2HighAlarm);
        mSensor2DisplayedLowAlarm = (ImageView) view.findViewById(R.id.sensor2LowAlarm);

        mSensor1NoDisplay = (TextView)view.findViewById(R.id.sensor1NoDisplay);
        mSensor2NoDisplay = (TextView)view.findViewById(R.id.sensor2NoDisplay);

        mSettingsButton.setOnClickListener(this);
        mInfoButton.setOnClickListener(this);
        mConnectButton.setOnClickListener(this);
    }
    // Button Handler...
    /**
     * Illustrates: connection state testing; requesting connection and disconnection
     */
    @Override
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.connectButton:
                // ThermaLib will throw an exception if a connection request is made when
                // already connected, and vice versa
                try {
                    if (!mDevice.isConnected()) {
                        mDevice.requestConnection();
                    } else {
                        mDevice.requestDisconnection();
                    }
                } catch (Exception x) {
                    Util.toast(mContext, x.getMessage());
                }
                break;
            case R.id.settingsButton:
                startSettingsActivity(mDevice);
                break;
            case R.id.infoButton:
                showDeviceInfo(mDevice);
                break;

        }
    }

    /**
     * Illustrates: connection states; ready state
     */
    void setConnectButton() {
        switch (mDevice.getConnectionState()) {
            case CONNECTED:
                if (mDevice.isReady()) {
                    Util.setButton(mConnectButton, "disconnect", true);
                } else {
                    Util.setButton(mConnectButton, "reading..", false);
                }
                break;
            case DISCONNECTED:
            case UNKNOWN:
            default:
                Util.setButton(mConnectButton, "connect", true);
                break;
            case CONNECTING:
            case DISCONNECTING:
                Util.setButton(mConnectButton, "wait..", false);
                break;
            case UNSUPPORTED:
                Util.setButton(mConnectButton, "unsupported", false);
                break;
            case UNAVAILABLE:
                Util.setButton(mConnectButton, "unavailable", false);
                break;

        }
    }
    /**
     * Illustrates: sensor values, alarm and fault states
     */
    void setReadingFields(int sensorIndex) {
        TextView readingField, noDisplayField, displayedReadingField;
        View highAlarmIndicatorField, lowAlarmIndicatorField;
        // get the fields for this sensor
        if( sensorIndex == 0 ) {
            readingField = mReading1Field;
            noDisplayField = mSensor1NoDisplay;
            displayedReadingField = mSensor1DisplayedField;
            highAlarmIndicatorField = mSensor1DisplayedHighAlarm;
            lowAlarmIndicatorField = mSensor1DisplayedLowAlarm;
        }
        else {
            readingField = mReading2Field;
            noDisplayField = mSensor2NoDisplay;
            displayedReadingField = mSensor2DisplayedField;
            highAlarmIndicatorField = mSensor2DisplayedHighAlarm;
            lowAlarmIndicatorField = mSensor2DisplayedLowAlarm;
        }
        String name = "Sensor " + (sensorIndex + 1);
        int color = Color.BLACK;

        String readingString = "?";
        String displayedReadingString = "?";
        if (sensorIndex >= mDevice.getMaxSensorCount()) {
            // not applicable - device doesn't have that many sensors
            readingString = "n/a";
            displayedReadingString = "n/a";
        } else {
            Sensor sensor = mDevice.getSensor(sensorIndex);

            // alarm indicators reflect the real device.
            // isHigh/LowAlarmSignalled() will return false if the device doesn't have
            // alarm signalling itself.

            highAlarmIndicatorField.setVisibility(sensor.isHighAlarmSignalled() ? View.VISIBLE : View.INVISIBLE);
            lowAlarmIndicatorField.setVisibility(sensor.isLowAlarmSignalled() ? View.VISIBLE : View.INVISIBLE);


            // always show the raw reading string
            readingField.setVisibility(View.VISIBLE);

            // compute the strings to use as the reading and displayed reading
            if (!sensor.isEnabled()) {
                readingString = "dis";
                displayedReadingString = "dis";
            } else if (sensor.isFault()) {
                readingString = "err";
                displayedReadingString = "err";
            } else {
                // neither disabled nor in error
                // color-code against the sensor status
                color = getColorForReading(sensor);
                float reading = sensor.getReading();
                readingString = Util.formatReadingValue(reading) + sensor.getReadingUnit().getUnitString();

                // if the device has its own display, compute and show the displayed reading,
                // otherwise show the No Display indicator.
                if (sensor.getDevice().hasFeature(Device.Feature.DISPLAY)) {
                    displayedReadingString = sensor.getReadingAsDisplayed() + sensor.getDisplayUnit().getUnitString();
                    displayedReadingField.setVisibility(View.VISIBLE);
                    noDisplayField.setVisibility(View.INVISIBLE);
                } else {
                    displayedReadingField.setVisibility(View.INVISIBLE);
                    noDisplayField.setVisibility(View.VISIBLE);
                }
            }
        }

        // show the reading and displayed reading fields
        readingField.setTextColor(color);
        readingField.setText(readingString);

        displayedReadingField.setTextColor(color);
        displayedReadingField.setText(displayedReadingString);
     }

    /**
     * Illustrates: testing sensor alarm conditions
     */
    int getColorForReading(Sensor sensor) {
        int color = Color.BLACK;
        if( sensor.isFault() ) {
            color = getColor(android.R.color.holo_red_dark);
        }
        else if (mDevice.isReady()) {
            if (sensor.isHighAlarmBreached()) {
                color = getColor(android.R.color.holo_red_dark);
            } else if (sensor.isLowAlarmBreached()) {
                color = getColor(android.R.color.holo_blue_dark);
            } else {
                color = getColor(android.R.color.holo_green_dark);
            }
        }
        return color;
    }

    private int getColor(int colorRes) {
        return mContext.getResources().getColor(colorRes);
    }

    private int getColorForBattery() {
        int color = Color.BLACK;
        if(mDevice.isReady()){
            if(mDevice.getBatteryWarningLevel() == Device.BatteryWarningLevel.LOW || mDevice.getBatteryWarningLevel() == Device.BatteryWarningLevel.CRITICAL){
                color = getColor(android.R.color.holo_red_dark);
            } else if(mDevice.getBatteryWarningLevel() == Device.BatteryWarningLevel.HALF){
                color = getColor(android.R.color.holo_orange_dark);
            } else {
                color = getColor(android.R.color.holo_green_dark);
            }
        }
        return color;
    }

    /**
     * Illustrates: battery level; device ready state
     */
    @SuppressLint("SetTextI18n")
    void setFields() {
        // scan fields, set regardless of connection state
        mDeviceNameField.setText(mDevice.getDeviceName());
        Device.ConnectionState connectionState = mDevice.getConnectionState();
        mConnectionStateField.setText(connectionState.toString());

        setConnectButton();

        if(mDevice.getConnectionState() == Device.ConnectionState.DISCONNECTED){
            mSensor1Name.setText("Sensor 1");
            mSensor2Name.setText("Sensor 2");
        }

        // set or clear fields depending on whether the device ready (which implies
        // connected).

        // isReady() doesn't return true until the device's values at connection
        // have been read.

        if (mDevice.isReady()) {
            // only show settings/info buttons if connected
            mSettingsButton.setVisibility(View.VISIBLE);
            mInfoButton.setVisibility(View.VISIBLE);
            setReadingFields(0);
            setReadingFields(1);
            mBatteryLevelField.setText(String.format("%d%%", mDevice.getBatteryLevel()));
            mBatteryLevelField.setTextColor(getColorForBattery());
        } else {
            mSettingsButton.setVisibility(View.GONE);
            mInfoButton.setVisibility(View.INVISIBLE);
            mReading1Field.setTextColor(Color.BLACK);
            mReading1Field.setText("-");
            mReading2Field.setTextColor(Color.BLACK);
            mReading2Field.setText("-");
            mBatteryLevelField.setTextColor(Color.BLACK);
            mBatteryLevelField.setText("-");
            mSensor2DisplayedField.setText("-");
            mSensor1DisplayedField.setText("-");
            mSensor2DisplayedField.setVisibility(View.VISIBLE);
            mSensor1DisplayedField.setVisibility(View.VISIBLE);
            mSensor1NoDisplay.setVisibility(View.INVISIBLE);
            mSensor2NoDisplay.setVisibility(View.INVISIBLE);
            mSensor1DisplayedHighAlarm.setVisibility(View.INVISIBLE);
            mSensor2DisplayedHighAlarm.setVisibility(View.INVISIBLE);
            mSensor1DisplayedLowAlarm.setVisibility(View.INVISIBLE);
            mSensor2DisplayedLowAlarm.setVisibility(View.INVISIBLE);
        }
    }
    /**
     * Illustrates: getting device information
     */
    private String makeDeviceInfo(Device device) {
        StringBuilder builder = new StringBuilder();
        builder.append( "Manufacturer: ").append(device.getManufacturerName()).append("\n")
                .append("Model: ").append(device.getModelNumber()).append("\n")
                .append("Serial Number: ").append(device.getSerialNumber()).append("\n")
                .append("Address: ").append(device.getIdentifier()).append("\n")
                .append("Hardware Version: ").append(device.getHardwareRevision()).append("\n")
                .append("Firmware Version: ").append(device.getFirmwareRevision()).append("\n")
                .append("Software Version: ").append(device.getSoftwareRevision()).append("\n")
                .append("Device Type: ").append(device.getDeviceType().toString()).append("\n")
                .append("Features: ").append(makeFeatureString(device)).append("\n").append("\n")
                ;

        for(int i = 0; i < device.getSensors().size(); i++){
            builder.append("Sensor " + i + ":").append("\n");
            builder.append("Sensor " + i +" type: ").append(device.getSensor(i).getType().toString()).append("\n");
            builder.append("Sensor " + i +" name: ").append(device.getSensor(i).getName()).append("\n").append("\n");

        }

        return builder.toString();
    }

    private String makeFeatureString(Device device) {
        int features = device.getFeatures();
        StringBuilder b = new StringBuilder("");
        addFeatureComponentToString(b, features, Device.Feature.ALARM, "Alarm");
        addFeatureComponentToString(b, features, Device.Feature.DISPLAY, "Display");
        addFeatureComponentToString(b, features, Device.Feature.POLLED_DEVICE, "Polled");
        addFeatureComponentToString(b, features, Device.Feature.ASYNCHRONOUS_SETTINGS, "Asynch. Settings");
        addFeatureComponentToString(b, features, Device.Feature.AUTO_OFF, "Auto Off");
        addFeatureComponentToString(b, features, Device.Feature.EMISSIVITY, "Emissivity");
        return b.toString();
    }

    private void addFeatureComponentToString(StringBuilder b, int features, int feature, String featureString) {
        if( (features & feature) != 0 ) {
            if( b.length() != 0 ) {
                b.append(",");
            }
            b.append(featureString);
        }
    }

    private void showDeviceInfo(Device device) {
        AlertDialog.Builder dialog = new AlertDialog.Builder(mContext)
                .setTitle("Device Info")
                .setMessage(makeDeviceInfo(device))
                .setPositiveButton(android.R.string.ok, null);

        if(mDevice.hasFeature(Device.Feature.ASYNCHRONOUS_SETTINGS)){
            dialog.setNegativeButton("Remote Settings", new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int which) {

                    Intent i = new Intent(mContext, RemoteDeviceInfoActivity.class);
                    i.putExtra(Defs.PARAM_DEVICE_ADDRESS, mDevice.getIdentifier());

                    mContext.startActivity(i);
                }
            });
        }

        dialog.create().show();
    }


    void setDevice(Device device) {
        mDevice = device;
    }

    Device getDevice() {
        return mDevice;
    }

    private void startSettingsActivity(Device device) {
        // place the device details in the intent
        Intent intent = new Intent(mContext, DeviceSettingsActivity.class);
        intent.putExtra(Defs.PARAM_DEVICE_ADDRESS, device.getIdentifier());
        mContext.startActivity(intent);
    }
}
