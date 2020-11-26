import React, {useEffect} from 'react';
import {
  Text,
  ScrollView,
  StyleSheet,
  View,
  Image,
  TouchableOpacity,
} from 'react-native';
import {NativeModules} from 'react-native';
const ReactBridge = NativeModules.ReactBridge;

const list = [
  {
    id: '1',
    deg: '36,6',
  },
  {
    id: '12',
    deg: '39,6',
  },
  {
    id: '41',
    deg: '40,6',
  },
  {
    id: '15',
    deg: '10,6',
  },
];
export default function First({navigation}) {
  useEffect(() => {
    const start = ReactBridge.startScan();
    console.log(start);
  }, []);
  return (
    <ScrollView style={styles.container}>
      <TouchableOpacity
        onPress={() => navigation.navigate('Second')}
        style={{
          alignSelf: 'flex-end',
          width: 50,
          height: 50,
          backgroundColor: 'red',
          marginBottom: 20,
        }}></TouchableOpacity>
      {list.map((el) => (
        <TouchableOpacity key={el.id} style={styles.block}>
          <Text style={styles.temp}>{el.deg}</Text>
          <Image
            source={require('../images/wireless.png')}
            style={styles.imgLow}
          />
        </TouchableOpacity>
      ))}
    </ScrollView>
  );
}
const styles = StyleSheet.create({
  container: {
    backgroundColor: '#F5FCFF',
    padding: 40,
  },
  block: {
    borderColor: '#000',
    borderWidth: 2,
    height: 50,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 30,
    marginBottom: 30,
  },
  temp: {
    lineHeight: 50,
    color: 'grey',
  },
  imgLow: {
    width: 30,
    height: 30,
    resizeMode: 'center',
  },
});
