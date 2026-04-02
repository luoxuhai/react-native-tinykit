import { useEffect, useState, useCallback } from 'react';
import {
  Text,
  View,
  StyleSheet,
  TouchableOpacity,
  SafeAreaView,
  StatusBar,
} from 'react-native';
import {
  getThermalState,
  onThermalStateChange,
  restart,
  requestReview,
  activate,
  deactivate,
  type ThermalState,
} from 'react-native-tinykit';

export default function App() {
  const [thermalState, setThermalState] = useState<ThermalState>(() =>
    getThermalState()
  );
  const [keepAwake, setKeepAwake] = useState(false);

  const handleToggleKeepAwake = useCallback(() => {
    if (keepAwake) {
      deactivate();
    } else {
      activate();
    }
    setKeepAwake((prev) => !prev);
  }, [keepAwake]);

  useEffect(() => {
    const subscription = onThermalStateChange((state) => {
      console.log('Thermal state changed:', state);
      setThermalState(state);
    });

    return () => {
      subscription.remove();
    };
  }, []);

  const handleRestart = () => {
    restart();
  };

  const handleGetThermalState = () => {
    const state = getThermalState();
    console.log('Manual get thermal state:', state);
    setThermalState(state);
  };

  const handleRequestReview = async () => {
    try {
      console.log('Requesting review...');
      await requestReview();
      console.log('Review request completed');
    } catch (error) {
      console.error('Review request failed:', error);
    }
  };

  const thermalColors: Record<ThermalState, string> = {
    nominal: '#4CAF50',
    fair: '#FFC107',
    serious: '#FF9800',
    critical: '#F44336',
  };

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" />
      <View style={styles.header}>
        <Text style={styles.title}>Tinykit Example</Text>
      </View>

      <View style={styles.content}>
        <View style={styles.section}>
          <Text style={styles.label}>Thermal State API</Text>
          <View
            style={[
              styles.stateBadge,
              { backgroundColor: thermalColors[thermalState] },
            ]}
          >
            <Text style={styles.stateText}>{thermalState.toUpperCase()}</Text>
          </View>
          <Text style={styles.description}>
            The thermal state indicates the current thermal condition of the
            device.
          </Text>
          <TouchableOpacity
            style={[styles.button, { marginTop: 16 }]}
            onPress={handleGetThermalState}
            activeOpacity={0.7}
          >
            <Text style={styles.buttonText}>Get Thermal State</Text>
          </TouchableOpacity>
        </View>

        <View style={styles.section}>
          <Text style={styles.label}>Restart API</Text>
          <TouchableOpacity
            style={[styles.button, { backgroundColor: '#FF3B30' }]}
            onPress={handleRestart}
            activeOpacity={0.7}
          >
            <Text style={styles.buttonText}>Restart Application</Text>
          </TouchableOpacity>
          <Text style={styles.hint}>
            This will trigger a bundle reload of the React Native application.
          </Text>
        </View>

        <View style={styles.section}>
          <Text style={styles.label}>Keep Awake API</Text>
          <View
            style={[
              styles.stateBadge,
              { backgroundColor: keepAwake ? '#4CAF50' : '#9E9E9E' },
            ]}
          >
            <Text style={styles.stateText}>{keepAwake ? 'ON' : 'OFF'}</Text>
          </View>
          <TouchableOpacity
            style={[
              styles.button,
              { backgroundColor: keepAwake ? '#FF3B30' : '#34C759' },
            ]}
            onPress={handleToggleKeepAwake}
            activeOpacity={0.7}
          >
            <Text style={styles.buttonText}>
              {keepAwake ? 'Disable Keep Awake' : 'Enable Keep Awake'}
            </Text>
          </TouchableOpacity>
          <Text style={styles.hint}>
            Prevents the screen from auto-locking when enabled.
          </Text>
        </View>

        <View style={styles.section}>
          <Text style={styles.label}>Review API</Text>
          <TouchableOpacity
            style={[styles.button, { backgroundColor: '#007AFF' }]}
            onPress={handleRequestReview}
            activeOpacity={0.7}
          >
            <Text style={styles.buttonText}>Request Review</Text>
          </TouchableOpacity>
        </View>
      </View>

      <View style={styles.footer}>
        <Text style={styles.version}>react-native-tinykit v0.1.0</Text>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8F9FA',
  },
  header: {
    paddingVertical: 20,
    backgroundColor: '#FFF',
    borderBottomWidth: 1,
    borderBottomColor: '#EEEEEE',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 2,
  },
  title: {
    fontSize: 20,
    fontWeight: '700',
    color: '#1A1A1A',
  },
  content: {
    flex: 1,
    padding: 20,
  },
  section: {
    marginBottom: 24,
    padding: 24,
    backgroundColor: '#FFF',
    borderRadius: 16,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 3,
  },
  label: {
    fontSize: 14,
    fontWeight: '600',
    color: '#666',
    textTransform: 'uppercase',
    letterSpacing: 1,
    marginBottom: 16,
  },
  stateBadge: {
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 12,
    marginBottom: 16,
  },
  stateText: {
    color: '#FFF',
    fontSize: 24,
    fontWeight: '800',
  },
  description: {
    fontSize: 14,
    color: '#8E8E93',
    textAlign: 'center',
    lineHeight: 20,
  },
  button: {
    backgroundColor: '#007AFF',
    paddingHorizontal: 24,
    paddingVertical: 16,
    borderRadius: 12,
    width: '100%',
    alignItems: 'center',
    marginBottom: 12,
  },
  buttonText: {
    color: '#FFF',
    fontSize: 16,
    fontWeight: '600',
  },
  hint: {
    fontSize: 12,
    color: '#AEAEB2',
    textAlign: 'center',
  },
  footer: {
    padding: 20,
    alignItems: 'center',
  },
  version: {
    fontSize: 12,
    color: '#C7C7CC',
  },
});
