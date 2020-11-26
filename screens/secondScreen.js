import React, {useEffect} from 'react';
import {
  Text,
  View,
  TouchableOpacity,
  ScrollView,
  StyleSheet,
} from 'react-native';

export default function Second() {
  return (
    <ScrollView style={styles.container}>
      <View style={styles.titleBlock}>
        <TouchableOpacity style={styles.scanBlock}>
          <Text>Stop Scan</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.scanBlock}>
          <Text>Scan</Text>
        </TouchableOpacity>
      </View>

      <View
        style={{
          flexDirection: 'row',
          height: 100,
          borderBottomColor: '#000',
          borderBottomWidth: 2,
          padding: 15,
          justifyContent: 'center',
          alignItems: 'center',
        }}>
        <View
          style={{
            width: '33%',

            justifyContent: 'space-evenly',
          }}>
          <Text>Device Name</Text>
          <Text>Temp</Text>
        </View>
        <View
          style={{
            width: '33%',
            alignSelf: 'flex-end',
            justifyContent: 'space-evenly',
            paddingBottom: 14,
          }}>
          <Text>Battery:</Text>
        </View>
        <TouchableOpacity
          style={{
            backgroundColor: 'pink',
            height: 50,
            justifyContent: 'center',
            alignItems: 'center',
            borderWidth: 2,
            borderColor: '#000',
            padding: 10,
          }}>
          <Text>Connect</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
}
const styles = StyleSheet.create({
  container: {
    backgroundColor: '#F5FCFF',
    paddingTop: 20,
  },
  titleBlock: {
    flexDirection: 'row',
    justifyContent: 'space-evenly',
    padding: 20,
    borderBottomColor: '#000',
    borderBottomWidth: 2,
  },
  scanBlock: {
    backgroundColor: 'pink',
    width: '33%',
    height: 50,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#000',
  },
});
