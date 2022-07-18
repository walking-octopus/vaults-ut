<img height="128" src="https://raw.githubusercontent.com/walking-octopus/vaults-ut/main/assets/logo.png" align="left"/>

# Vaults

Keep your private files safe.
It's an Ubuntu Touch wrapper around `gocryptfs`. Inspired by https://github.com/mpobaschnig/Vaults.
_____________________________________________

## Installing

Since the app depends on and automatically installs Fuse, it might not get an OpenStore listing until it's shipped by default. Until then, get a build from the Release page or GitHub Actions, and install the `.click` file.

## Building

### Dependencies
- Docker
- Android tools (for ADB)
- Python3 / pip3
- Clickable (get it from [here](https://clickable-ut.dev/en/latest/index.html))

Use Clickable to build and package Vaults as a Click package ready to be installed on Ubuntu Touch

### Build instructions

Make sure you clone the project with
`git clone https://github.com/walking-octopus/vaults-ut.git; cd vaults-ut`.

Compile the `gocryptfs` for the target arch with
`clickable build --libs --arch {amd64, armhf, arm64}`

To build the app for the target arch, use
`clickable build --arch {amd64, armhf, arm64}`

To run on a device over SSH:
`clickable --ssh [device IP address]`

Use `clickable desktop` to quickly test it on your desktop.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

### Translations

You can help translate the app by following [these instructions](https://github.com/walking-octopus/vaults-ut/tree/main/po/README.md).

## Licenses
 - `walking-octopus/vaults-ut` is licensed under the GNU GPLv3
 - `rfjakob/gocryptfs` is licensed under the MIT License
 - The current logo is a modified `passwords-app.png` from `snwh/suru-icon-theme`, licensed under the Creative Commons Attribution-ShareAlike 4.0
