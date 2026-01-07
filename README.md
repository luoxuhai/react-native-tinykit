# react-native-tinykit

[![npm version](https://img.shields.io/npm/v/react-native-tinykit.svg)](https://www.npmjs.com/package/react-native-tinykit)
[![license](https://img.shields.io/npm/l/react-native-tinykit.svg)](https://github.com/luoxuhai/react-native-tinykit/blob/master/LICENSE)

A lightweight React Native toolkit for iOS, providing essential native utilities.

## Features

- 🔄 **App Restart** - Programmatically restart your React Native application
- 🌡️ **Thermal State** - Get and monitor the device's thermal state
- ⚡ **Turbo Module** - Built with the new architecture for optimal performance
- 📦 **Lightweight** - Minimal footprint with zero dependencies

## Requirements

- React Native >= 0.76
- iOS only (for now)

## Installation

```sh
# Using npm
npm install react-native-tinykit

# Using yarn
yarn add react-native-tinykit
```

### iOS Setup

```sh
cd ios && pod install
```

## Usage

### Restart Application

Restart the React Native application programmatically:

```tsx
import { restart } from 'react-native-tinykit';

// Restart the app
restart();
```

#### Example Use Cases

- Force reload after language/locale change
- Reset app state after logout
- Apply configuration changes that require a restart

### Thermal State

Get the current thermal state and monitor for changes:

```tsx
import { getThermalState, addThermalStateListener } from 'react-native-tinykit';

// Get current thermal state
const state = getThermalState();
console.log('Current thermal state:', state);

// Listen for thermal state changes
const subscription = addThermalStateListener((state) => {
  console.log('Thermal state changed:', state);
  
  switch (state) {
    case 'nominal':
      // Normal operating conditions
      break;
    case 'fair':
      // Slightly elevated thermal state
      break;
    case 'serious':
      // High thermal state - consider reducing activity
      break;
    case 'critical':
      // Critical thermal state - reduce activity immediately
      break;
  }
});

// Clean up the listener when done
subscription.remove();
```

#### Example Use Cases

- Reduce graphics quality or frame rate when device is overheating
- Pause background tasks during high thermal states
- Show warnings to users when thermal state is critical

## API Reference

### `restart()`

Triggers a reload of the React Native application.

```tsx
restart(): void
```

**Example:**

```tsx
import { restart } from 'react-native-tinykit';

const handleLogout = async () => {
  await clearUserData();
  restart(); // Restart app to reset state
};
```

### `getThermalState()`

Returns the current thermal state of the device.

```tsx
getThermalState(): ThermalState
```

**Returns:** `'nominal' | 'fair' | 'serious' | 'critical'`

| State | Description |
|-------|-------------|
| `nominal` | The thermal state is within normal limits |
| `fair` | The thermal state is slightly elevated |
| `serious` | The thermal state is high |
| `critical` | The thermal state is critically high |

**Example:**

```tsx
import { getThermalState } from 'react-native-tinykit';

const state = getThermalState();
if (state === 'critical') {
  // Reduce app activity to help cool down the device
}
```

### `addThermalStateListener()`

Adds a listener for thermal state changes.

```tsx
addThermalStateListener(listener: (state: ThermalState) => void): { remove: () => void }
```

**Parameters:**
- `listener` - Callback function that receives the new thermal state

**Returns:** A subscription object with a `remove()` method to stop listening

**Example:**

```tsx
import { addThermalStateListener } from 'react-native-tinykit';

const subscription = addThermalStateListener((state) => {
  console.log('Thermal state changed to:', state);
});

// Later, when you want to stop listening:
subscription.remove();
```

## Apps Using This Library

- [Night Vision - LiDAR Camera](https://apps.apple.com/app/id1668629667)

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

- [Development workflow](CONTRIBUTING.md#development-workflow)
- [Sending a pull request](CONTRIBUTING.md#sending-a-pull-request)
- [Code of conduct](CODE_OF_CONDUCT.md)

## License

MIT © [Darkce](https://github.com/luoxuhai)

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
