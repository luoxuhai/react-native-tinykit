# Contributing

Contributions are always welcome, no matter how large or small!

We want this community to be friendly and respectful to each other. Please follow it in all your interactions with the project. Before contributing, please read the [code of conduct](./CODE_OF_CONDUCT.md).

## Development workflow

This project is a monorepo managed using [Yarn workspaces](https://yarnpkg.com/features/workspaces). It contains the following packages:

- The library package in the root directory.
- An example app in the `example/` directory.

To get started with the project, make sure you have the correct version of [Node.js](https://nodejs.org/) installed. See the [`.nvmrc`](./.nvmrc) file for the version used in this project.

Run `yarn` in the root directory to install the required dependencies for each package:

```sh
yarn
```

> Since the project relies on Yarn workspaces, you cannot use [`npm`](https://github.com/npm/cli) for development without manually migrating.

The [example app](/example/) demonstrates usage of the library. You need to run it to test any changes you make.

It is configured to use the local version of the library, so any changes you make to the library's source code will be reflected in the example app. Changes to the library's JavaScript code will be reflected in the example app without a rebuild, but native code changes will require a rebuild of the example app.

If you want to use Android Studio or Xcode to edit the native code, you can open the `example/android` or `example/ios` directories respectively in those editors. To edit the Objective-C or Swift files, open `example/ios/TinykitExample.xcworkspace` in Xcode and find the source files at `Pods > Development Pods > react-native-tinykit`.

To edit the Java or Kotlin files, open `example/android` in Android studio and find the source files at `react-native-tinykit` under `Android`.

You can use various commands from the root directory to work with the project.

To start the packager:

```sh
yarn example start
```

To run the example app on Android:

```sh
yarn example android
```

To run the example app on iOS:

```sh
yarn example ios
```

To confirm that the app is running with the new architecture, you can check the Metro logs for a message like this:

```sh
Running "TinykitExample" with {"fabric":true,"initialProps":{"concurrentRoot":true},"rootTag":1}
```

Note the `"fabric":true` and `"concurrentRoot":true` properties.

Make sure your code passes TypeScript:

```sh
yarn typecheck
```

To check for linting errors, run the following:

```sh
yarn lint
```

To fix formatting errors, run the following:

```sh
yarn lint --fix
```

### Source layout

Each native feature has its own directory in `src`, named to match the feature
in `ios` and the `react-native-tinykit.features` configuration:

```text
src/
  index.ts
  Alert/index.ts
  ColorPicker/index.ts
  Confetti/index.ts
  Haptics/index.ts
  KeepAwake/index.tsx
  Mail/index.ts
  Restart/index.ts
  Review/index.ts
  ThermalState/index.ts
  Toast/index.ts
  Translation/index.ts
  utils/
    NativeTinykit.ts
    getNativeTinykit.ts
```

`index.ts` contains the root public exports. Feature directories contain their
JavaScript API wrappers, hooks and components. `utils/NativeTinykit.ts` keeps
the TurboModule specification and its Codegen types together;
`utils/getNativeTinykit.ts` handles lazy module access and feature availability.
Codegen scans only `src/utils`.

Public subpath imports remain lowercase and use hyphens, such as
`react-native-tinykit/color-picker`. When adding or moving a feature, update all
three `package.json` export targets (`source`, `types`, `default`) as well as
the root exports.

### Overlay validation

Run the public API regression checks with `yarn test:overlays`. To check optional
Pod selection and the upstream Git release pins, run
`ruby tests/overlay_pods_test.rb` using the same Ruby environment as CocoaPods
(for example, `rbenv exec ruby tests/overlay_pods_test.rb`).

For the example app, run `pod install` from `example/ios`, then
`yarn example start` and `yarn example ios` from the repository root. The Metro
configuration uses the standard port and watches the library through
`react-native-monorepo-config`. `yarn example build:ios` builds in Debug mode.

For a simulator-only build without launching Metro or signing:

```sh
xcodebuild -workspace example/ios/TinykitExample.xcworkspace \
  -scheme TinykitExample -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
```


### Publishing to npm

We use [release-it](https://github.com/release-it/release-it) to make it easier to publish new versions. It handles common tasks like bumping version based on semver, creating tags and releases etc.

To publish new versions, run the following:

```sh
yarn release
```


### Scripts

The `package.json` file contains various scripts for common tasks:

- `yarn`: setup project by installing dependencies.
- `yarn typecheck`: type-check files with TypeScript.
- `yarn lint`: lint files with [ESLint](https://eslint.org/).
- `yarn example start`: start the Metro server for the example app.
- `yarn example android`: run the example app on Android.
- `yarn example ios`: run the example app on iOS.

### Sending a pull request

> **Working on your first pull request?** You can learn how from this _free_ series: [How to Contribute to an Open Source Project on GitHub](https://app.egghead.io/playlists/how-to-contribute-to-an-open-source-project-on-github).

When you're sending a pull request:

- Prefer small pull requests focused on one change.
- Verify that linters and tests are passing.
- Review the documentation to make sure it looks good.
- Follow the pull request template when opening a pull request.
- For pull requests that change the API or implementation, discuss with maintainers first by opening an issue.
