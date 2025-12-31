# react-native-tinykit

[![npm version](https://img.shields.io/npm/v/react-native-tinykit.svg)](https://www.npmjs.com/package/react-native-tinykit)
[![license](https://img.shields.io/npm/l/react-native-tinykit.svg)](https://github.com/luoxuhai/react-native-tinykit/blob/master/LICENSE)

A lightweight React Native toolkit for iOS, providing essential native utilities.

## Features

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

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

- [Development workflow](CONTRIBUTING.md#development-workflow)
- [Sending a pull request](CONTRIBUTING.md#sending-a-pull-request)
- [Code of conduct](CODE_OF_CONDUCT.md)

## License

MIT © [Darkce](https://github.com/luoxuhai)

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
