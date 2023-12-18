# Home Assistant Community Add-on: SmartNUT

SmartNUT is a refreshed form-factor of NUT - Network UPS Tools - suited to modern integrations and smart systems, like Home Assistant.

SmartNUT allows you to monitor and manage UPS (battery backup) using a NUT server.
It lets you view their status, receives notifications about important events, and execute commands as device actions.

Conversely to previous NUT Add-on, SmartNUT:

- just uses NUT drivers, and eliminates NUT upsd and client layers, and their configuration complexity
- does not require an additional integration: native support in HA MQTT (hem, todo)
- publishes the data to MQTT (with HA local broker autodetected).
  But can easily be adapted to any other broker/bus/method (HomeKit, ...)
- support the following types of devices:
  - USB: plug and play for (decent) USB device, including multiple ones
  - SNMP, NetXML and NUT client (for remote NUT upsd server, like Synology NAS):
    with manual edits, but will be eased by using nut-scanner too, as for USB

## About NUT

The primary goal of the Network UPS Tools (NUT) project is to provide support
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

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Home Assistant Community add-on.

<!--
https://www.home-assistant.io/common-tasks/os#installing-third-party-add-ons
-->

<!---
1. If you don't have an MQTT broker yet; in Home Assistant go to **[Settings → Add-ons → Add-on store](https://my.home-assistant.io/redirect/supervisor_store/)** and install the **[Mosquitto broker](https://my.home-assistant.io/redirect/supervisor_addon/?addon=core_mosquitto)** addon, then start it.
1. Go back to the **Add-on store**, click **⋮ → Repositories**, fill in</br>  `https://github.com/zigbee2mqtt/hassio-zigbee2mqtt` and click **Add → Close** or click the **Add repository** button below, click **Add → Close** (You might need to enter the **internal IP address** of your Home Assistant instance first).
[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)]
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
- listen on MQTT topic 'homeassistant/nut/#' using MQTT integration (FIXME),
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

* add a UPS that is not automatically detected, such as remote SNMP or serial,
* fix autodetection issues, by disabling the related option (USB for example)
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

* for USB devices: [`usbhid-ups(8)`][usbhid-ups] and [`nutdrv_qx(8)`][nutdrv_qx]
* for SNMP devices: [`snmp-ups(8)`][snmp-ups]
* for remote NUT devices: [`dummy-ups(8)`][dummy-ups]

#### Sub-option: `port`

This is the communication port used by the driver to connect to the UPS, and varies
according to devices:

* for USB devices: use `auto`, and possibly set additional config
* for SNMP devices: use `<ip_address-or_name>`, and possibly set additional config
* for remote NUT devices: use `<device>@<ip_address-or_name>`, and possibly set additional config
* for serial devices: use the port name, usually `/dev/ttyS0` for the first one

#### Sub-option: `config`

A list of additional [options][ups-fields] to configure for this UPS. The common
[`usbhid-ups`][usbhid-ups] driver allows you to distinguish between devices by
using a combination of the `vendor`, `product`, `serial`, `vendorid`, and
`productid` options:


#### Example configuration:

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
  - name: apcups
    driver: usbhid-ups
    port: auto
    config:
      - vendorid = 051d
  - name: SNMP-UPS
    driver: snmp-ups
    port: 192.168.1.142
    config:
      - community = private
  - name: remoteNUT-Synology
    driver: nutclient
    port: smartnut@192.168.1.42
```

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

FIXME

#### Sub-option: `key`

FIXME

#### Sub-option: `cert`

FIXME

#### Example configuration:

```yaml
server: 192.168.1.15:1883
user: my_user
password: "my_password"
```

### Option: `enable_simulated_device`

This option enables the creation of a simulated device, for development and
test purposes.

The device is named `smartnut-dummy`, and includes automatic status changes
(ups.status switches).

For more information, refer to the following links:

* [`dummy-ups(8)`][dummy-ups]
* [`NUT Devices simulation`][nut-simulation]
* [`NUT Devices Dumps Library`][nut-ddl]

### Option: `autoconf_remote_nut_devices`

This option enables the automatic discovery and configuration of remote NUT
devices, including multiple units.

<!--
**Note**: _Remember to restart the add-on when the configuration is changed._

SmartNUT add-on configuration:

```yaml
users:
  - username: nutty
    password: changeme
    instcmds:
      - all
    actions: []
devices:
  - name: myups
    driver: usbhid-ups
    port: auto
    config: []
mode: netserver
shutdown_host: "false"
```

**Note**: _This is just an example, don't copy and paste it! Create your own!_





### Option: `users`

This option allows you to specify a list of one or more users. Each user can
have its own privileges like defined in the sub-options below.

_Refer to the [`upsd.users(5)`][upsd-users] documentation for more information._

#### Sub-option: `username`

The username the user needs to use to login to the NUT server. A valid username
contains only `a-z`, `A-Z`, `0-9` and underscore characters (`_`).

#### Sub-option: `password`

Set the password for this user.

#### Sub-option: `instcmds`

A list of instant commands that a user is allowed to initiate. Use `all` to
grant all commands automatically.

#### Sub-option: `actions`

A list of actions that a user is allowed to perform. Valid actions are:

- `set`: change the value of certain variables in the UPS.
- `fsd`: set the forced shutdown flag in the UPS. This is equivalent to an
  "on battery + low battery" situation for the purposes of monitoring.

The list of actions is expected to grow in the future.

#### Sub-option: `upsmon`

Add the necessary actions for a `upsmon` process to work. This is either set to
`master` or `slave`. If creating an account for a `netclient` setup to connect
this should be set to `slave`.



### Option: `mode`

Recognized values are `netserver` and `netclient`.

- `netserver`: Runs the components needed to manage a locally connected UPS and
  allow other clients to connect (either as slaves or for management).
- `netclient`: Only runs `upsmon` to connect to a remote system running as
  `netserver`.

### Option: `shutdown_host`

When this option is set to `true` on a UPS shutdown command, the host system
will be shutdown. When set to `false` only the add-on will be stopped. This is to
allow testing without impact to the system.

### Option: `list_usb_devices`

When this option is set to `true`, a list of connected USB devices will be
displayed in the add-on log when the add-on starts up. This option can be used
to help identify different UPS devices when multiple UPS devices are connected
to the system.

### Option: `remote_ups_name`

When running in `netclient` mode, the name of the remote UPS.

### Option: `remote_ups_host`

When running in `netclient` mode, the host of the remote UPS.

### Option: `remote_ups_user`

When running in `netclient` mode, the user of the remote UPS.

### Option: `remote_ups_password`

When running in `netclient` mode, the password of the remote UPS.

**Note**: _When using the remote option, the user and device options must still
be present, however they will have no effect_

### Option: `upsd_maxage`

Allows setting the MAXAGE value in upsd.conf to increase the timeout for
specific drivers, should not be changed for the majority of users.

### Option: `upsmon_deadtime`

Allows setting the DEADTIME value in upsmon.conf to adjust the stale time for
the monitor process, should not be changed for the majority of users.

### Option: `i_like_to_be_pwned`

Adding this option to the add-on configuration allows to you bypass the
HaveIBeenPwned password requirement by setting it to `true`.

**Note**: _We STRONGLY suggest picking a stronger/safer password instead of
using this option! USE AT YOUR OWN RISK!_

### Option: `leave_front_door_open`

Adding this option to the add-on configuration allows you to disable
authentication on the NUT server by setting it to `true` and leaving the
username and password empty.

**Note**: _We STRONGLY suggest, not to use this, even if this add-on is
only exposed to your internal network. USE AT YOUR OWN RISK!_

## Event Notifications

Whenever your UPS changes state, an event named `nut.ups_event` will be fired.
It's payload looks like this:

| Key           | Value                                        |
| ------------- | -------------------------------------------- |
| `ups_name`    | The name of the UPS as you configured it     |
| `notify_type` | The type of notification                     |
| `notify_msg`  | The NUT default message for the notification |

`notify_type` signifies what kind of notification it is.
See the below table for more information as well as the message that will be in
`notify_msg`. `%s` is automatically replaced by NUT with your UPS name.

| Type       | Cause                                                                 | Default Message                                    |
| ---------- | --------------------------------------------------------------------- | -------------------------------------------------- |
| `ONLINE`   | UPS is back online                                                    | "UPS %s on line power"                             |
| `ONBATT`   | UPS is on battery                                                     | "UPS %s on battery"                                |
| `LOWBATT`  | UPS has a low battery (if also on battery, it's "critical")           | "UPS %s battery is low"                            |
| `FSD`      | UPS is being shutdown by the master (FSD = "Forced Shutdown")         | "UPS %s: forced shutdown in progress"              |
| `COMMOK`   | Communications established with the UPS                               | "Communications with UPS %s established"           |
| `COMMBAD`  | Communications lost to the UPS                                        | "Communications with UPS %s lost"                  |
| `SHUTDOWN` | The system is being shutdown                                          | "Auto logout and shutdown proceeding"              |
| `REPLBATT` | The UPS battery is bad and needs to be replaced                       | "UPS %s battery needs to be replaced"              |
| `NOCOMM`   | A UPS is unavailable (can't be contacted for monitoring)              | "UPS %s is unavailable"                            |
| `NOPARENT` | The process that shuts down the system has died (shutdown impossible) | "upsmon parent process died - shutdown impossible" |

This event allows you to create automations to do things like send a
[critical notification][critical-notif] to your phone:
-->


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
[sleep]: https://linux.die.net/man/1/sleep
[snmp-ups]: https://networkupstools.org/docs/man/snmp-ups.html
[ups-conf]: https://networkupstools.org/docs/man/ups.conf.html
[ups-fields]: https://networkupstools.org/docs/man/ups.conf.html#_ups_fields
[upsd-conf]: https://networkupstools.org/docs/man/upsd.conf.html
[upsd-users]: https://networkupstools.org/docs/man/upsd.users.html
[upsd]: https://networkupstools.org/docs/man/upsd.html
[upsmon]: https://networkupstools.org/docs/man/upsmon.html
[usbhid-ups]: https://networkupstools.org/docs/man/usbhid-ups.html
