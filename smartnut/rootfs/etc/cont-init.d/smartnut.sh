#!/command/with-contenv bashio
# ==============================================================================
# Home Assistant Community Add-on: SmartNUT - Network UPS Tools
# Configures SmartNUT - Network UPS Tools
# ==============================================================================

readonly UPS_CONF=/etc/nut/ups.conf

# FIXME: check if root is really needed? simple 'nut' should do
chown root:root /var/run/nut
chmod 0770 /var/run/nut

chown -R root:root /etc/nut
find /etc/nut -not -perm 0660 -type f -exec chmod 0660 {} \;
find /etc/nut -not -perm 0660 -type d -exec chmod 0660 {} \;

# Init configuration, to be able to append
touch "${UPS_CONF}"

# Check for USB devices first
if bashio::config.true 'autoconf_usb_devices' ;then

    bashio::log.info "Autodetecting and configuring USB devices"
    nut-scanner -U >>  "${UPS_CONF}"
    bashio::log.info "=> OK"
fi

# Process manual edits
if bashio::config.true 'manually_edit_devices' ;then

    bashio::log.info "Applying manual devices configuration"

    for device in $(bashio::config "devices|keys"); do
        upsname=$(bashio::config "devices[${device}].name")
        upsdriver=$(bashio::config "devices[${device}].driver")
        upsport=$(bashio::config "devices[${device}].port")
        if bashio::config.has_value "devices[${device}].powervalue"; then
            upspowervalue=$(bashio::config "devices[${device}].powervalue")
        else
            upspowervalue="1"
        fi
        # FIXME: not useful anymore (?)

        bashio::log.info "Configuring Device named ${upsname}..."
        {
            echo "[${upsname}]"
            echo -e "\tdriver = ${upsdriver}"
            echo -e "\tport = ${upsport}"
        } >> "${UPS_CONF}"

        OIFS=$IFS
        IFS=$'\n'
        for configitem in $(bashio::config "devices[${device}].config"); do
            echo "  ${configitem}" >> "${UPS_CONF}"
        done
        IFS="$OIFS"
    done
    bashio::log.info "=> OK"
fi

if bashio::config.true 'enable_simulated_device' ;then
    # https://networkupstools.org/docs/developer-guide.chunked/dev-tools.html

    bashio::log.info "Configuring Simulation Device 'smartnut-dummy'..."
    {
        echo "[smartnut-dummy]"
        echo -e "\tdriver = dummy-ups"
        echo -e "\tport = smartnut-dummy.seq"
    } >>  "${UPS_CONF}"

    bashio::log.info "=> OK"
fi


if bashio::config.true 'autoconf_remote_nut_devices' ;then

    bashio::log.info "Autodetecting and configuring remote NUT devices"

    # NUT discovery through Avahi
    #nut-scanner -A

    # Or using classic method...
    # FIXME: requires network params
    nut-scanner -O -m 192.168.1.1/24
fi

# FIXME:
# autoconf_snmp_devices
# nut-scanner -S -m 192.168.1.1/24
#
# autoconf_netxml_devices
# nut-scanner -M -m 192.168.1.1/24

# MQTT config
bashio::log.info "Configuring MQTT..."

MQTT_HOST=""
MQTT_USER=""
MQTT_PASSWORD=""

for mqtt_key in $(bashio::config "mqtt|keys"); do
    if bashio::config.has_value "mqtt[${mqtt_key}].server"; then
        bashio::log.info "From user configuration"
        MQTT_HOST=$(bashio::config "mqtt.server")
    fi
    if bashio::config.has_value "mqtt[${mqtt_key}].user"; then
        MQTT_USER=$(bashio::config "mqtt.user")
    fi
    if bashio::config.has_value "mqtt[${mqtt_key}].password"; then
        MQTT_PASSWORD=$(bashio::config "mqtt.password")
    fi
done
if [ -z "$MQTT_HOST"]; then
    bashio::log.info "From Home Assistant service"
        MQTT_HOST=$(bashio::services mqtt "host")
        MQTT_USER=$(bashio::services mqtt "username")
        MQTT_PASSWORD=$(bashio::services mqtt "password")
fi

# FIXME
#  - ca: str?
#  - key: str?
#  - cert: str?

# FIXME: MQTT sanity check (-n MQTT_HOST MQTT_USER MQTT_PASSWORD) and error catching
bashio::log.info "=> OK"

# FIXME: get config...
{
    echo "MQTT_HOST=$MQTT_HOST"
    echo "MQTT_USER=$MQTT_USER"
    echo "MQTT_PASSWORD=$MQTT_PASSWORD"
} > /etc/nut/libnutdrv_mqtt.conf

bashio::log.info "---------------------"
bashio::log.info "Checking configuration:"
bashio::log.info  "${UPS_CONF}"
cat "${UPS_CONF}"
bashio::log.info "/etc/nut/libnutdrv_mqtt.conf"
cat /etc/nut/libnutdrv_mqtt.conf
# FIXME: -s sanity check for status
bashio::log.info "=> OK"

bashio::log.info "---------------------"
bashio::log.info "Starting the SmartNUT Driver(s)..."
upsdrvctl -u root start
bashio::log.info "=> OK"

bashio::log.info "---------------------"
bashio::log.info "Starting the SmartNUT2MQTT Adapter..."
/usr/bin/dstate-nut2mqtt
