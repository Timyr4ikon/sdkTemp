import React, {useEffect} from 'react';
import {Text} from 'react-native';
import {NativeModules} from 'react-native';
import {createStackNavigator} from '@react-navigation/stack';
import {NavigationContainer} from '@react-navigation/native';
import firstScreen from './screens/firstScreen';
import secondScreen from './screens/secondScreen';

const ReactBridge = NativeModules.ReactBridge;
const AuthStack = createStackNavigator();

export default function App() {
  return (
    <NavigationContainer>
      <AuthStack.Navigator>
        <AuthStack.Screen
          options={{
            headerShown: false,
          }}
          name="First"
          component={firstScreen}
        />
        <AuthStack.Screen
          options={{
            headerShown: false,
          }}
          name="Second"
          component={secondScreen}
        />
      </AuthStack.Navigator>
    </NavigationContainer>
  );
}
