import { useState, useEffect } from 'react';
import { Text, View, StyleSheet, Button, Alert } from 'react-native';
import {
  restart,
  getBatteryLevel,
  isLowPowerModeEnabled,
} from 'react-native-tinykit';

export default function App() {
  const [batteryLevel, setBatteryLevel] = useState<number | null>(null);
  const [lowPowerMode, setLowPowerMode] = useState<boolean | null>(null);

  const fetchBatteryInfo = () => {
    try {
      const level = getBatteryLevel();
      setBatteryLevel(level);

      const isLowPower = isLowPowerModeEnabled();
      setLowPowerMode(isLowPower);
    } catch (error) {
      Alert.alert('Error', `Failed to get battery info: ${error}`);
    }
  };

  useEffect(() => {
    fetchBatteryInfo();
  }, []);

  const handleRestart = () => {
    Alert.alert(
      'Restart App',
      'Are you sure you want to restart the application?',
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Restart', onPress: () => restart() },
      ]
    );
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>React Native Tinykit</Text>

      <View style={styles.infoContainer}>
        <Text style={styles.label}>Battery Level:</Text>
        <Text style={styles.value}>
          {batteryLevel !== null ? `${batteryLevel.toFixed(0)}%` : 'Loading...'}
        </Text>
      </View>

      <View style={styles.infoContainer}>
        <Text style={styles.label}>Low Power Mode:</Text>
        <Text style={styles.value}>
          {lowPowerMode !== null
            ? lowPowerMode
              ? '✓ Enabled'
              : '✗ Disabled'
            : 'Loading...'}
        </Text>
      </View>

      <View style={styles.buttonContainer}>
        <Button title="Refresh Battery Info" onPress={fetchBatteryInfo} />
      </View>

      <View style={styles.buttonContainer}>
        <Button title="Restart App" onPress={handleRestart} color="#FF6B6B" />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
    backgroundColor: '#f5f5f5',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 30,
  },
  infoContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: 10,
    width: '100%',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
  },
  label: {
    fontSize: 16,
    fontWeight: '600',
  },
  value: {
    fontSize: 16,
    color: '#666',
  },
  buttonContainer: {
    marginTop: 20,
    width: '100%',
    paddingHorizontal: 20,
  },
});
