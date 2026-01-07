# react-native-tinykit

[![npm version](https://img.shields.io/npm/v/react-native-tinykit.svg)](https://www.npmjs.com/package/react-native-tinykit)
[![license](https://img.shields.io/npm/l/react-native-tinykit.svg)](https://github.com/luoxuhai/react-native-tinykit/blob/master/LICENSE)

A lightweight React Native toolkit for iOS, providing essential native utilities.

## Features

- 🔋 **Battery Level** - Get the current battery level as a percentage
- ⚡ **Low Power Mode** - Detect if Low Power Mode is enabled
- 🔄 **App Restart** - Programmatically restart your React Native application
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

### Get Battery Level

Get the current battery level as a percentage (0-100):

```tsx
import { getBatteryLevel } from 'react-native-tinykit';

const level = await getBatteryLevel();
console.log(`Battery level: ${level}%`);
```

### Check Low Power Mode

Check if Low Power Mode is currently enabled:

```tsx
import { isLowPowerModeEnabled } from 'react-native-tinykit';

const isEnabled = await isLowPowerModeEnabled();
console.log(`Low Power Mode: ${isEnabled ? 'Enabled' : 'Disabled'}`);
```

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

## API Reference

### `getBatteryLevel()`

Gets the current battery level as a percentage.

```tsx
getBatteryLevel(): Promise<number>
```

**Returns:** A promise that resolves to the battery level percentage (0-100).

**Throws:** Error if battery level is unavailable.

**Example:**

```tsx
import { getBatteryLevel } from 'react-native-tinykit';

try {
  const level = await getBatteryLevel();
  if (level < 20) {
    console.log('Battery is low!');
  }
} catch (error) {
  console.error('Failed to get battery level:', error);
}
```

### `isLowPowerModeEnabled()`

Checks if Low Power Mode is currently enabled.

```tsx
isLowPowerModeEnabled(): Promise<boolean>
```

**Returns:** A promise that resolves to `true` if Low Power Mode is enabled, `false` otherwise.

**Example:**

```tsx
import { isLowPowerModeEnabled } from 'react-native-tinykit';

const isLowPower = await isLowPowerModeEnabled();
if (isLowPower) {
  // Reduce app functionality to save battery
  console.log('Low Power Mode is enabled');
}
```

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
