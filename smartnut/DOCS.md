# Home Assistant Community Add-on: SmartNUT

SmartNUT is a refreshed form-factor of NUT - [Network UPS Tools][nut] - suited to modern integrations and smart systems, like Home Assistant.

SmartNUT allows you to monitor and manage UPS (battery backup) using NUT drivers.
It lets you view their status, receives notifications about important events, and execute commands as device actions.

Conversely to the historic NUT Add-on, SmartNUT:

- just uses NUT drivers, and eliminates NUT upsd and client layers, and their configuration complexity
- does not require an additional integration: native support in HA MQTT (hem, todo)
- publishes the data to MQTT (with HA local broker autodetected).
  But can easily be adapted to any other broker/bus/method (HomeKit, ...)
- supports the following types of devices:
  - USB: plug and play for (decent) USB device, including multiple ones
  - SNMP, NetXML and NUT client (for remote NUT upsd server, like Synology NAS):
    with manual edits, but will be eased by using nut-scanner too, as for USB

## About NUT

The primary goal of the [Network UPS Tools (NUT)][nut] project is to provide support
for Power Devices, such as Uninterruptible Power Supplies, Power Distribution
Units, Automatic Transfer Switch, Power Supply Units and Solar Controllers.

NUT provides many control and monitoring [features][nut-features], with a
uniform control and management interface.

More than 140 different manufacturers, and several thousands models
are [compatible][nut-compatible].

The Network UPS Tools (NUT) project is the combined effort of
many [individuals and companies][nut-acknowledgements].

## Installation

| WARNING: This is an early development version! It is subject to change and may require advanced Home Assistant knowledges |
| ------------------------------------------------------------------------------------------------------------------------- |

<!-- FIXME: alpha notice §## + call to test / translation / feedback -->

<!--
**Note**: _Remember to restart the add-on when the configuration is changed._
-->

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Home Assistant Community add-on.

<!-- FIXME
https://www.home-assistant.io/common-tasks/os#installing-third-party-add-ons
-->

1. If you don't have an MQTT broker yet, follow these steps to get the Mosquitto add-on installed on your system:
   1. Navigate in your Home Assistant frontend to **Settings** -> **Add-ons** -> **Add-on store**.
   2. Find the "Mosquitto broker" add-on and click it.
   3. Click on the "INSTALL" button, then start it.
   <!--[![Open Mosquitto add-on in your Home Assistant instance.][addon-badge]][addon-mosquitto]-->

   For more information, refer to **[Mosquitto broker](https://my.home-assistant.io/redirect/supervisor_addon/?addon=core_mosquitto)** addon.

2. Click the Home Assistant My button below to open the SmartNUT add-on on your Home
   Assistant instance.
   [![Open this add-on in your Home Assistant instance.][addon-badge]][addon]
3. Click the "Install" button to install the add-on.
4. Configure SmartNUT if needed, as described belows.
5. Start the "SmartNUT" add-on.
6. Check the logs of the "SmartNUT" add-on to see if everything went well.
7. Check the _How to use_ below for integrating into Home Assistant MQTT.

## How to use

For now:

- just start SmartNUT (for USB) and/or use enable enable_simulated_device,
- check the Journal tab for the startup sequence,
- listen on MQTT topic 'homeassistant/nut/#' using MQTT integration
<!-- FIXME: provide procedure and more info -->
- and have fun :smile:

## Configuration

The add-on can be used with the basic configuration, with other options for more
advanced users.

### Option: `log_level`

The `log_level` option controls the level of log output by the add-on and can
be changed to be more or less verbose, which might be useful when you are
dealing with an unknown issue. Possible values are:

- `trace`: Show every detail, like all called internal functions.
- `debug`: Shows detailed debug information.
- `info`: Normal (usually) interesting events.
- `warning`: Exceptional occurrences that are not errors.
- `error`: Runtime errors that do not require immediate action.
- `fatal`: Something went terribly wrong. Add-on becomes unusable.

Please note that each level automatically includes log messages from a
more severe level, e.g., `debug` also shows `info` messages. By default,
the `log_level` is set to `info`, which is the recommended setting unless
you are troubleshooting.

### Option: `autoconf_usb_devices`

This option enables the automatic discovery and configuration of USB devices,
including multiple units.

### Option: `manually_edit_devices`

This option allows you to edit the `devices` configuration, in order to:

- add a UPS that is not automatically detected, such as remote SNMP or serial,
- fix autodetection issues, by disabling the related option (USB for example)
  and adding entries to the `devices` section.

### Option: `devices`

This option allows you to specify a list of UPS devices attached to your
system.

_Refer to the [`ups.conf(5)`][ups-conf] documentation for more information._

#### Sub-option: `name`

The name of the UPS. The name `default` is used internally, so you can’t use
it in this file.

#### Sub-option: `driver`

This specifies which program will be monitoring this UPS. You need to specify
the one that is compatible with your hardware. See [`nutupsdrv(8)`][nutupsdrv]
for more information on drivers in general and pointers to the man pages of
specific drivers.

While the SmartNUT Add-on comes with all drivers supported by NUT, the following
are probably the most interesting:

- for USB devices: [`usbhid-ups(8)`][usbhid-ups] and [`nutdrv_qx(8)`][nutdrv_qx]
- for SNMP devices: [`snmp-ups(8)`][snmp-ups]
- for remote NUT devices: [`dummy-ups(8)`][dummy-ups]
  Note that `dummy-ups` replaces the `netclient` option, from the historic NUT Add-on,
  by repeating the remote device data as if it was connected locally.

#### Sub-option: `port`

This is the communication port used by the driver to connect to the UPS, and varies
according to devices:

- for USB devices: use `auto`, and possibly set additional config
- for SNMP devices: use `<ip_address-or_name>`, and possibly set additional config
- for remote NUT devices: use `<device>@<ip_address-or_name>`, and possibly set additional config
- for serial devices: use the port name, usually `/dev/ttyS0` for the first one

#### Sub-option: `config`

A list of additional [options][ups-fields] to configure for this UPS.

Note:

- The generic [`usbhid-ups`][usbhid-ups] driver allows you to distinguish
  between devices by using a combination of the `vendorid`, `productid` and `serial` options.

- The generic [`snmp-ups`][snmp-ups] driver may need additional information to
  connect to the SNMP agent, such as the `snmp_version`, `community`, `secName` or others
  SNMPv3 options.

#### Example configuration:

<!-- FIXME: desc field... + split into multiple examples -->

```yaml
devices:
  - name: Eaton-3S
    driver: usbhid-ups
    port: auto
    config:
      - vendorid = 0463
      - productid = FFFF
      - serial = XXXXXXXXXXXXX
  - name: Eaton-5PX
    driver: usbhid-ups
    port: auto
    config:
      - vendorid = 0463
      - productid = FFFF
      - serial = YYYYYYYYYYYYY
  - name: APCUPS
    driver: usbhid-ups
    port: auto
    config:
      - vendorid = 051d
  - name: SNMP-UPSv1
    driver: snmp-ups
    port: 192.168.1.142
    config:
      - snmp_version = v1
      - community = private
  - name: SNMP-UPSv3
    driver: snmp-ups
    port: 192.168.1.142
    config:
      - snmp_version = v3
      - community = private
      - secName = mysecname
      - authPassword = "@123456"
  - name: remoteNUT-Synology
    driver: nutclient
    port: smartnut@192.168.1.42
```

Note: If password values, such as `authPassword`, include certain special
characters (reserved by yaml specification), the enclosing quotes are required.
So it is recommended to always quote it when in doubt.

### Option: `mqtt`

This option allows you to specify the configuration to connect to an MQTT broker.
Leave empty when using the Mosquitto broker addon, since it is automatically
detected.

#### Sub-option: `server`

The hostname of the MQTT broker.

#### Sub-option: `port`

The port of the MQTT broker.

#### Sub-option: `user`

The username to connect to the MQTT broker.

#### Sub-option: `password`

The password to connect to the MQTT broker.

Note: If the `password` includes certain special characters (reserved by yaml
specification), the enclosing quotes are required. So it is recommended to
always quote it when in doubt.

#### Sub-option: `ca`

Not yet implemented!

#### Sub-option: `key`

Not yet implemented!

#### Sub-option: `cert`

Not yet implemented!

#### Example configuration:

```yaml
server: 192.168.1.15:1883
user: my_user
password: "my_password"
```

### Option: `enable_simulated_device`

This option enables the creation of a simulated device, for development and
test purposes.

The device is named `smartnut-dummy`, includes automatic status changes
(ups.status switches) and uses the following [`simulation file`][smartnut-dummy.seq].

For more information, refer to the following links:

- [`dummy-ups(8)`][dummy-ups]
- [`NUT Devices simulation`][nut-simulation]
- [`NUT Devices Dumps Library`][nut-ddl]

### Option: `autoconf_remote_nut_devices`

This option enables the automatic discovery and configuration of remote NUT
devices, including multiple units.

It replaces the `netclient` option, from the historic NUT Add-on, by repeating
the remote device data as if it was connected locally.

<!--
```yaml
automations:
  - alias: "UPS changed state"
    trigger:
      - platform: event
        event_type: nut.ups_event
    action:
      - service: notify.mobile_app_<your_device_id_here>
        data_template:
          title: "UPS changed state"
          message: "{{ trigger.event.data.notify_msg }}"
          data:
            push:
              sound:
                name: default
                critical: 1
                volume: 1.0
```

For more information, see the NUT docs [here][nut-notif-doc-1] and
[here][nut-notif-doc-2].
-->

## Example automations

FIXME

Note that it is currently not possible to send commands to the UPS, nor
to apply settings.

It is however already possibly to react through the values published on
MQTT.

## Changelog & Releases

This repository keeps a change log using [GitHub's releases][releases]
functionality.

Releases are based on [Semantic Versioning][semver], and use the format
of `MAJOR.MINOR.PATCH`. In a nutshell, the version will be incremented
based on the following:

- `MAJOR`: Incompatible or major changes.
- `MINOR`: Backwards-compatible new features and enhancements.
- `PATCH`: Backwards-compatible bugfixes and package updates.

## Support

Got questions?

You have several options to get them answered:

- The [Home Assistant Community Add-ons Discord chat server][discord] for add-on
  support and feature requests.
- The [Home Assistant Discord chat server][discord-ha] for general Home
  Assistant discussions and questions.
- The Home Assistant [Community Forum][forum].
- Join the [Reddit subreddit][reddit] in [/r/homeassistant][reddit]

You could also [open an issue here][issue] GitHub.

## Authors & contributors

The original setup of this repository is by [Arnaud Quette][aquette].

[Arnaud Quette][aquette] is the retired former NUT project leader, and its main developer / Debian packager / author of many drivers (usbhid-ups, snmp-ups, dummy-ups, ...) / author of WMNUT and lot more (...)

For a full list of all authors and contributors,
check [the contributor's page][contributors].

## License

Copyright 2023 Arnaud Quette

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

[addon-badge]: https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg
[addon]: https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Faquette%2Faddon-smartnut
[addon-mosquitto]: https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fhome-assistant%2Faddons%2Ftree%2Fmaster%2Fmosquitto
[aquette]: https://github.com/aquette
[contributors]: https://github.com/aquette/addon-smartnut/graphs/contributors
[critical-notif]: https://companion.home-assistant.io/docs/notifications/critical-notifications
[dale3h]: https://github.com/dale3h
[discord-ha]: https://discord.gg/c5DvZ4e
[discord]: https://discord.me/hassioaddons
[dummy-ups]: https://networkupstools.org/docs/man/dummy-ups.html
[forum]: https://community.home-assistant.io/t/community-hass-io-add-on-network-ups-tools/68516
[issue]: https://github.com/aquette/addon-smartnut/issues
[nut]: https://networkupstools.org
[nut-acknowledgements]: https://networkupstools.org/acknowledgements.html
[nut-compatible]: https://networkupstools.org/stable-hcl.html
[nut-conf]: https://networkupstools.org/docs/man/nut.conf.html
[nut-ddl]: https://networkupstools.org/ddl/index.html#_supported_devices
[nut-features]: https://networkupstools.org/features.html
[nut-notif-doc-1]: https://networkupstools.org/docs/user-manual.chunked/ar01s07.html
[nut-notif-doc-2]: https://networkupstools.org/docs/man/upsmon.conf.html
[nut-simulation]: https://networkupstools.org/docs/developer-guide.chunked/dev-tools.html#dev-simu
[nutdrv_qx]: https://networkupstools.org/docs/man/nutdrv_qx.html
[nutupsdrv]: https://networkupstools.org/docs/man/nutupsdrv.html
[reddit]: https://reddit.com/r/homeassistant
[releases]: https://github.com/hassio-addons/addon-nut/releases
[semver]: https://semver.org/spec/v2.0.0
[smartnut-dummy.seq]: https://github.com/aquette/addon-smartnut/blob/main/smartnut/rootfs/etc/nut/smartnut-dummy.seq
[sleep]: https://linux.die.net/man/1/sleep
[snmp-ups]: https://networkupstools.org/docs/man/snmp-ups.html
[ups-conf]: https://networkupstools.org/docs/man/ups.conf.html
[ups-fields]: https://networkupstools.org/docs/man/ups.conf.html#_ups_fields
[upsd-conf]: https://networkupstools.org/docs/man/upsd.conf.html
[upsd-users]: https://networkupstools.org/docs/man/upsd.users.html
[upsd]: https://networkupstools.org/docs/man/upsd.html
[upsmon]: https://networkupstools.org/docs/man/upsmon.html
[usbhid-ups]: https://networkupstools.org/docs/man/usbhid-ups.html
