/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 * @flow strict-local
 */

import React, {Component} from 'react';
import {
  Platform,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
  Button
} from 'react-native';

// We are importing the native Java module here
import {NativeModules} from 'react-native';
var ReactBridge = NativeModules.ReactBridge;

export default class App extends Component {
 constructor(){
    super()
    this.useCallback = this.useCallback.bind(this);
    this.useCallbackAndroid = this.useCallbackAndroid.bind(this);
    this.useCallbackiOS = this.useCallbackiOS.bind(this);
    ReactBridge.setupBridge();
  }

    // async function to call the Java native method
    async usePromise() {
        try {
            var msg = await ReactBridge.promise();
            console.log(msg);
            // this.setState(videoLoaded: videoLoaded)
        } catch (e) {
            console.error(e);
        }
    }

    async addDevice() {
        try {
            var {
                timestamp,
                device,
            } = await ReactBridge.addDevice();
            console.log(device + ':' + timestamp);
        } catch (e) {
            console.error(e);
        }
    }

    async startScan(){
        const timeout = 2000;
        try {
            var numDevices = await ReactBridge.startScan(timeout);
            console.log(numDevices);
        } catch (e) {
            console.error(e);
        }
    }

    async startScanSimulated(){
        const timeout = 2000;
        try {
            var numDevices = await ReactBridge.startScanSimulated(timeout);
            console.log(numDevices);
        } catch (e) {
            console.error(e);
        }
    }


    useCallbackAndroid() {
        ReactBridge.callback(0.1,
            (msg) => {
                console.error(msg);
            },
            (someData) => {
                console.log(someData);
            });
    }


    useCallbackiOS() {
        ReactBridge.callback(0.1, (error, someData) => {
            if (error) {
                console.error(error);
            } else {
                console.log(someData);
            }
        });
    }

    async useCallback() {
        if (Platform.OS === 'ios') {
            this.useCallbackiOS();
        } else {
            this.useCallbackAndroid();
        }
    }

//  /// Bluetooth Low Energy connection
//  TLTransportBluetoothLE, --- 0
//  /// Indirect connection to an instrument via ETI Web Service
//  TLTransportCloudService, --- 1
//  /// Simulated device - not in current use
//  TLTransportSimulated --- 2

  render() {
    return (
      <View style={styles.container}>
        <TouchableOpacity onPress={ this.usePromise }>
              <Text>Invoke promise</Text>
         </TouchableOpacity>
         <Text />
        <TouchableOpacity onPress={ this.useCallback }>
              <Text>Invoke callback</Text>
         </TouchableOpacity>
         <Button
            onPress = {() => {
                scanBLE();
            }}
            title = "Scan BLE Test"
         />
      </View>
    );
  }
}

const scanBLE = async () => {
    try {
        var results = await ReactBridge.scanBLE();
    } catch (e) {
        console.error(e);
    }
};

const styles = StyleSheet.create({
    container: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: '#F5FCFF',
    },
});
