package com.awesomeproject;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.KeyEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.EditorInfo;
import android.widget.CompoundButton;
import android.widget.EditText;
import android.widget.RadioGroup;
import android.widget.Switch;
import android.widget.TextView;

import java.text.SimpleDateFormat;
import java.util.Date;

import com.awesomeproject.R;
import uk.co.etiltd.thermalib.Device;
import uk.co.etiltd.thermalib.DeviceType;
import uk.co.etiltd.thermalib.Sensor;
import uk.co.etiltd.thermalib.SimulatedDevice;
import uk.co.etiltd.thermalib.ThermaLib;
import uk.co.etiltd.thermalib.ThermaLibException;

import static android.view.View.GONE;
import static uk.co.etiltd.thermalib.Device.CommandType.FACTORY_RESET;

/**
 * Illustrates how to alter settings on the ETI device. The activity is passed the device address in the
 * invoking Intent.
 */
public class DeviceSettingsActivity extends Activity implements View.OnClickListener {
    private static final String TAG = "DeviceSettings";

    // Thermalib
    private ThermaLib mThermaLib;
    private Device mDevice;
    private Object mThermaLibCallbackHandle;    // set when mCallbacks are registered, and used to deregister while the activity is paused.

    // ThermaLib mCallbacks.

    private ThermaLib.ClientCallbacks mThermalibCallbacks = new ThermaLib.ClientCallbacksBase() {
        @Override
        public void onDeviceConnectionStateChanged(Device device, Device.ConnectionState newState, long timestamp) {
            if (device == mDevice && device.getConnectionState() != Device.ConnectionState.CONNECTED) {
                toast("Device is no longer connected");
                finish();
            }
        }

        // will be called whenever there's an update to the Device object. All changes generate this callback,
        // whether the stimulus was local (e.g. settings change) or remote (e.g. new reading data)

        // Note: Currently Bluetooth LE devices that have 2 sensors will cause this callback to be invoked
        // twice in quick succession, every time the device transmits, since each sensor's reading data is
        // stored on it's own characteristic, which results in 2 notifications from the Bluetooth
        // infrastructure.

        @Override
        public void onDeviceUpdated(Device device, long timestamp) {
            Log.d(TAG, device.getDeviceName() + " update received");
            updateFields();
        }

        @Override
        public void onRefreshComplete(Device device, boolean userRefresh, long timestamp) {
            updateFields();
            toast("remote device resync complete");
        }

        /**
         * Illustrates: handling protocol notifications sent from the device. Currently Bluetooth LE only.
         */
        @Override
        public void onDeviceNotificationReceived(Device device, int notificationType, byte[] payload, long timestamp) {
            // See the hardware technical specification for the device type in question to determine
            // what type of notifications may be sent, and the payload contents, which will in general
            // be specific to notification type.

            // Note that the notification type parameter should be accessed by symbolic name
            // (Device.NotificationType.BUTTON_PRESSED etc) since the raw numeric value does not
            // necessarily correspond to the integer delivered by the low-level protocol.
            if (device == mDevice) {   // this device only
                switch (notificationType) {
                    case Device.NotificationType.BUTTON_PRESSED:
                        toast("device button pressed");
                        break;
                    case Device.NotificationType.COMMUNICATION_ERROR:
                        toast("communication error");
                        break;
                    case Device.NotificationType.INVALID_COMMAND:
                        toast("invalid command");
                        break;
                    case Device.NotificationType.INVALID_SETTING:
                        toast("device rejected setting");
                        // in this case the library will automatically re-sync all data with the
                        // remote device, and then call onRefreshComplete above.
                        break;
                    case Device.NotificationType.SHUTDOWN:
                        toast("device shutdown");
                        break;
                    case Device.NotificationType.CHECKPOINT:
                        toast("Checkpoint");
                        break;
                    default:
                    case Device.NotificationType.UNKNOWN:
                        toast("unknown notification type");
                        break;
                }
            }
        }

        // called to indicate completion of revoke access (== deregistration == "unpairing") of a Cloud device
        @Override
        public void onDeviceRevokeRequestComplete(Device device, boolean succeeded, String errorMessage) {
            toast(device.getDeviceName() + " was deregistered");
            finish();
        }
    };

    /**
     * Illustrates: obtaining the ThermaLib singleton; finding a device by identifier; reading the device name
     */
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        mThermaLib = ThermaLib.instance(this);

        // recover the device object from the intent parameters
        Intent intent = getIntent();
        String deviceIdentifier = intent.getStringExtra(Defs.PARAM_DEVICE_ADDRESS);
        if (deviceIdentifier != null) {
            // look for existing device
            mDevice = mThermaLib.getDeviceWithIdentifier(deviceIdentifier);
        }
        if (mDevice == null) {
            Util.toast(this, String.format("device with identifier %s was not found", deviceIdentifier));
            finish();
        }
        // at this point mDevice is set correctly.
        setContentView(R.layout.activity_device_settings);
        getActionBar().setTitle(mDevice.getDeviceName() + " - Device Settings");
        initialiseUI();
    }

    /**
     * Illustrates: registering mCallbacks. Try to have mCallbacks registered only while they
     * are required.
     */

    @Override
    protected void onResume() {
        super.onResume();
        // the second parameter is a tag that will be used in Android logging.
        mThermaLibCallbackHandle = mThermaLib.registerCallbacks(mThermalibCallbacks, TAG);
    }

    /**
     * Illustrates: deregistering mCallbacks
     */
    @Override
    protected void onPause() {
        if (mThermaLibCallbackHandle != null) {
            mThermaLib.deregisterCallbacks(mThermaLibCallbackHandle);
            mThermaLibCallbackHandle = null;
        }
        super.onPause();
    }

    ///
    /// ---------- User Interface handling below here


    // device-level fields
    private EditText mMeasurementIntervalField;
    private EditText mTransmissionIntervalField;
    private EditText mPollrateField;
    private EditText mEmissivityField;
    private EditText mAutoOffField;
    private RadioGroup mUnitSelector;

    // Button click handler.

    @Override
    public void onClick(View view) {
        if (!mDevice.isReady()) {
            toast("Device not ready");
        } else {
            switch (view.getId()) {
                case R.id.cmdDefaults:
                    // this will set default values on the device for most settings, though
                    // not necessarily all. See the low-level protocol spec. for a
                    // description of which.
                    mDevice.sendCommand(Device.CommandType.SET_DEFAULTS, null);
                    break;
                case R.id.cmdMeasure:
                    // this will request that the device immediately
                    // send a reading for all sensors.
                    mDevice.sendCommand(Device.CommandType.MEASURE, null);
                    break;
                case R.id.cmdIdentify:
                    // this requests the device in question to identify itself,
                    // typically by flashing its lights in a distinctive way
                    mDevice.sendCommand(Device.CommandType.IDENTIFY, null);
                    break;
                case R.id.cmdReset:
                    // this requests a full factory reset of the device
                    mDevice.sendCommand(FACTORY_RESET, null);
                    break;
                case R.id.refresh:
                    mDevice.refresh();
                    break;
                case R.id.forgetDevice:
                    try {
                        mThermaLib.revokeDeviceAccess(mDevice);
                    } catch (ThermaLibException e) {
                        e.printStackTrace();
                    }
                    break;
                default:
                    break;
            }
        }
    }
    ////////////
    //
    // per-sensor fields. In this demo, we just set High and Low alarms,
    // and the name to be used for the sensor.

    private class SensorFields {
        private Sensor sensor;
        private ViewGroup mViewGroup;
        private EditText highAlarmField;
        private EditText lowAlarmField;
        private EditText sensorNameField;
        private Switch highAlarmEnabledSwitch;
        private Switch lowAlarmEnabledSwitch;

        /**
         * Per-sensor settings fields.
         * <p>
         * Illustrates: setting high alarm
         */

        private SensorFields(int groupResId, int sensorIndex) {
            // resource layout ids are only unique per sensor, so need to know the id of the per-sensor parent.
            ViewGroup parent = (ViewGroup) findViewById(groupResId);
            mViewGroup = parent;

            // remove the per-sensor section if there aren't that many sensors.
            if (sensorIndex >= mDevice.getSensors().size()) {
                mViewGroup.setVisibility(GONE);
            } else {
                sensor = mDevice.getSensor(sensorIndex);
                mViewGroup.setVisibility(View.VISIBLE);

                // Alarm fields
                // NOTE. A real application may well want to set limits on the alarm level,
                // according to real-world considerations.  Additionally, the device itself
                // may impose a range validation base on the physical limitations of the
                // sensors.

                // NOTE. Real-world apps would certainly want to be checking that the high
                // alarm is higher than the low alarm, if they are both set.
                //
                // If the device-level validation fails, the device will deliver an Invalid
                // Setting notification which the app must be able to handle. In general, this
                // will require re-reading of the device data, to establish what value the
                // device has actually set in reaction to the invalid setting from the app.

                // high alarm

                highAlarmField = setupEditableField(parent.findViewById(R.id.highAlarm), new Setter() {
                    @Override
                    void setFromTextView(TextView textView) {
                        try {
                            sensor.setHighAlarm(Float.parseFloat(textView.getText().toString()));
                        } catch (NumberFormatException x) {
                            toast("Invalid high alarm");
                        }
                    }
                });

                // low alarm

                lowAlarmField = setupEditableField(parent.findViewById(R.id.lowAlarm), new Setter() {
                    @Override
                    void setFromTextView(TextView textView) {
                        try {
                            sensor.setLowAlarm(Float.parseFloat(textView.getText().toString()));
                        } catch (NumberFormatException x) {
                            toast("Invalid low alarm");
                        }
                    }
                });

                // sensor name

                sensorNameField = setupEditableField(parent.findViewById(R.id.sensorName), new Setter() {
                            @Override
                            void setFromTextView(TextView textView) {
                                sensor.setName(textView.getText().toString());
                            }
                        }
                );

                sensorNameField.setSingleLine(true);

                // high alarm switch

                highAlarmEnabledSwitch = (Switch) parent.findViewById(R.id.highAlarmSwitch);
                highAlarmEnabledSwitch.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
                    @Override
                    public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                        // only submit new setting if there's a change.
                        if (isChecked != sensor.isHighAlarmEnabled()) {
                            if (!isChecked) {
                                sensor.disableHighAlarm();
                            } else {
                                sensor.setHighAlarm(40f);   // default
                            }
                        }
                    }
                });

                // low alarm switch

                lowAlarmEnabledSwitch = (Switch) parent.findViewById(R.id.lowAlarmSwitch);
                lowAlarmEnabledSwitch.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
                    @Override
                    public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                        // only submit new setting if there's a change.
                        if (isChecked != sensor.isLowAlarmEnabled()) {
                            if (!isChecked) {
                                sensor.disableLowAlarm();
                            } else {
                                sensor.setLowAlarm(0);      // default
                            }
                        }
                    }
                });
            }
        }
    }

    // allocate 2 groups of sensor fields. setup must be done after setContentView
    private SensorFields[] mSensorFieldGroups;

    private void initialiseUI() {

        // set up 2 groups of sensor fields
        mSensorFieldGroups = new SensorFields[]{
                new SensorFields(R.id.sensor1Settings, 0),
                new SensorFields(R.id.sensor2Settings, 1)
        };

        // set up button handler
        for (int buttonId : new int[]{
                R.id.cmdMeasure,
                R.id.cmdIdentify,
                R.id.cmdDefaults,
                R.id.cmdReset,
                R.id.refresh,
                R.id.forgetDevice
        }) {
            View view = findViewById(buttonId);
            if (view != null) {
                view.setOnClickListener(this);
            }
        }

        // set up settings controls

        mMeasurementIntervalField = setupEditableField(R.id.measurementInterval, new Setter() {
            @Override
            void setFromTextView(TextView textView) {
                try {
                    int measurementInterval = Integer.parseInt(textView.getText().toString());
                    if (0 > measurementInterval) {
                        toast("measurement interval must be > 0");
                    } else {
                        mDevice.setMeasurementInterval(measurementInterval);
                        toast("measurement interval set");
                    }
                } catch (NumberFormatException x) {
                    toast("invalid measurement interval");
                }
            }
        });


        mTransmissionIntervalField = setupEditableField(findViewById(R.id.transmissionInterval), new Setter() {
            @Override
            void setFromTextView(TextView textView) {
                try {
                    int transmissionInterval = Integer.parseInt(textView.getText().toString());
                    if (0 > transmissionInterval) {
                        toast("transmission interval must be > 0");
                    } else {
                        mDevice.setMeasurementInterval(transmissionInterval);
                        toast("transmission interval set");
                    }
                } catch (NumberFormatException x) {
                    toast("invalid measurement interval");
                }
            }
        });

        mPollrateField = setupEditableField(R.id.pollRate, new Setter() {
            @Override
            void setFromTextView(TextView textView) {
                try {
                    int pollrate = Integer.parseInt(textView.getText().toString());
                    if (pollrate < 0) {
                        toast("poll rate must be >= 0");
                    } else {
                        mDevice.setPollInterval(pollrate);
                        toast("poll rate set");
                    }
                } catch (NumberFormatException x) {
                    toast("invalid poll rate");
                } catch (ThermaLibException tlx) {
                    tlx.printStackTrace();
                    toast("poll rate could not be set. see logcat");
                }
            }
        });

        mEmissivityField = setupEditableField(R.id.emissivityValue, new Setter() {
            @Override
            void setFromTextView(TextView textView) {
                try {
                    float emissivity = Float.parseFloat(textView.getText().toString());
                    if (!(0.1 <= emissivity && emissivity <= 1)) {
                        toast("emissivity must be between 0.1 and 1");
                    } else {
                        mDevice.setEmissivity(emissivity);
                        toast("emissivity set");
                    }

                } catch (NumberFormatException x) {
                    toast("invalid input");
                } catch (ThermaLibException tlx) {
                    tlx.printStackTrace();
                    toast("failed to set emissivity. See logcat");
                }
            }
        });

        mAutoOffField = setupEditableField(R.id.autoOffValue, new Setter() {
            @Override
            void setFromTextView(TextView textView) {
                try {
                    int autoOffTime = Integer.parseInt(textView.getText().toString());
                    if (autoOffTime < 0) {
                        toast("auto off time must be >= 0");
                    } else {
                        mDevice.setAutoOffInterval(autoOffTime);
                        toast("auto off time set");
                    }

                } catch (NumberFormatException x) {
                    toast("invalid auto off time");
                }
            }
        });

        mUnitSelector = (RadioGroup) findViewById(R.id.unitSelector);
        mUnitSelector.setOnCheckedChangeListener(new RadioGroup.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(RadioGroup radioGroup, int setId) {
                Device.Unit selectedUnit = null;
                switch (setId) {
                    case R.id.celsiusSelected:
                        selectedUnit = Device.Unit.CELSIUS;
                        break;
                    case R.id.fahrenheitSelected:
                        selectedUnit = Device.Unit.FAHRENHEIT;
                        break;
                }
                if (selectedUnit != null && selectedUnit != mDevice.getDisplayedUnitForGenericSensorType(Sensor.GenericType.TEMPERATURE)) {
                    mDevice.setDisplayedUnitForGenericSensorType(Sensor.GenericType.TEMPERATURE, selectedUnit);
                }
            }
        });

        View simulatorSettingsButton = findViewById(R.id.simulatorSettingsButton);
        if (simulatorSettingsButton != null) {
            if (mDevice instanceof SimulatedDevice) {
                simulatorSettingsButton.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View view) {
                        startSimulatorSettingsActivity();

                    }
                });
            } else {
                simulatorSettingsButton.setVisibility(GONE);
            }
        }

        View forgetDeviceButton = findViewById(R.id.forgetDevice);
        if (forgetDeviceButton != null) {
            forgetDeviceButton.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    try {
                        mThermaLib.revokeDeviceAccess(mDevice);
                    } catch (ThermaLibException e) {
                        e.printStackTrace();
                    }
                }
            });
        }

        if (mDevice.getTransportType() == ThermaLib.Transport.WS_THERMACLOUD) {
            setupWiFiSettings();
        } else {
            findViewById(R.id.nextTransGroup).setVisibility(View.GONE);
        }

        updateFields();

    }

    private void setupWiFiSettings() {

        findViewById(R.id.deviceCommands).setVisibility(GONE);
        findViewById(R.id.nextTransGroup).setVisibility(View.VISIBLE);

        if (mDevice.getDeviceType() == DeviceType.WIFI_TD) {
            findViewById(R.id.transmissionIntervalGroup).setVisibility(View.VISIBLE);
        }

    }

    // update fields from the device.

    private void updateFields() {

        // setText() will only update the field if it's not currently focussed
        setText(mMeasurementIntervalField, "" + mDevice.getMeasurementInterval());
        setText(mTransmissionIntervalField, "" + mDevice.getTransmissionInterval());
        setText(mPollrateField, "" + mDevice.getPollInterval());
        setText(mEmissivityField, "" + mDevice.getEmissivity());
        setText(mAutoOffField, "" + mDevice.getAutoOffInterval());

        Date date = new Date(mDevice.getNextTransmissionTime());
        SimpleDateFormat fmtOut = new SimpleDateFormat("HH:mm:ss");

        ((TextView) findViewById(R.id.nextTransText)).setText(fmtOut.format(date));

        Device.Unit unit = mDevice.getDisplayedUnitForGenericSensorType(Sensor.GenericType.TEMPERATURE);
        switch (unit) {
            case CELSIUS:
                mUnitSelector.check(R.id.celsiusSelected);
                break;
            case FAHRENHEIT:
                mUnitSelector.check(R.id.fahrenheitSelected);
                break;
        }

        setVisibilityFromFeature(R.id.emissivityGroup, Device.Feature.EMISSIVITY);
        setVisibilityFromFeature(R.id.pollIntervalGroup, Device.Feature.POLLED_DEVICE);
        setVisibilityFromFeature(R.id.autoOffGroup, Device.Feature.AUTO_OFF);

        // set sensor level fields for the sensors the device actually has.

        int sensorCount = mDevice.getSensors().size();

        if (sensorCount > 0) {
            setSensorFields(0);
        }

        if (sensorCount > 1) {
            setSensorFields(1);
        }
    }

    /**
     * Illustrates: use of hasFeature
     */
    void setVisibilityFromFeature(int viewId, int feature) {
        View view = findViewById(viewId);
        if (view != null) {
            view.setVisibility(mDevice.hasFeature(feature) ? View.VISIBLE : View.GONE);
        }
    }

    /**
     * Illustrates: adjusting the high and low alarm
     */
    void setSensorFields(int sensorIndex) {
        Sensor sensor = mDevice.getSensor(sensorIndex);
        SensorFields fields = mSensorFieldGroups[sensorIndex];

        // alarm fields
        float highAlarm = sensor.getHighAlarm();
        float lowAlarm = sensor.getLowAlarm();

        setText(fields.highAlarmField, Util.formatReadingValue(highAlarm, 2));
        setText(fields.lowAlarmField, Util.formatReadingValue(lowAlarm, 2));

        setText(fields.sensorNameField, sensor.getName());

        fields.highAlarmEnabledSwitch.setChecked(sensor.isHighAlarmEnabled());
        fields.lowAlarmEnabledSwitch.setChecked(sensor.isLowAlarmEnabled());
    }

    private void startSimulatorSettingsActivity() {
        Intent intent = new Intent(this, SimulatorSettingsActivity.class);
        intent.putExtra(Defs.PARAM_DEVICE_ADDRESS, mDevice.getIdentifier());
        startActivity(intent);
    }

    // util
    private void toast(String s) {
        Util.toast(this, s);
    }

    // standardised handling of editable fields.

    // support writing to a field only if it's not currently being edited.
    private View mFieldBeingEdited = null;


    private void setText(TextView textView, CharSequence text) {
        if (textView != mFieldBeingEdited) {
            textView.setText(text);
        }
    }

    private abstract class Setter {
        abstract void setFromTextView(TextView textView);
    }

    private EditText setupEditableField(final View view, final Setter setter) {
        EditText editText = null;
        if (view instanceof EditText) {
            editText = (EditText) view;
            editText.setOnFocusChangeListener(new View.OnFocusChangeListener() {
                // update mFieldBeingEdited on gaining/losing focus. Used by setText()
                // to avoid updating fields that are in the middle of being edited.
                @Override
                public void onFocusChange(View v, boolean hasFocus) {
                    if (hasFocus) {
                        mFieldBeingEdited = v;
                    } else if (v == mFieldBeingEdited) {
                        mFieldBeingEdited = null;
                    }
                }
            });
            if (setter != null) {
                editText.setOnEditorActionListener(new TextView.OnEditorActionListener() {
                    @Override
                    public boolean onEditorAction(TextView v, int action, KeyEvent event) {
                        boolean done = (action == EditorInfo.IME_ACTION_DONE);
                        if (done) {
                            setter.setFromTextView(v);
                        }
                        return done;
                    }
                });
            }
        }
        return editText;
    }

    private EditText setupEditableField(final int fieldId, final Setter setter) {
        return setupEditableField(findViewById(fieldId), setter);
    }
}
