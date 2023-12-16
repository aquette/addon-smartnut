#!/command/with-contenv bashio
# ==============================================================================
# Home Assistant Community Add-on: SmartNUT - Network UPS Tools
# Configures SmartNUT - Network UPS Tools
# ==============================================================================
set -x

readonly UPS_CONF=/etc/nut/ups.conf

# FIXME: check if root is really needed? simple 'nut' should do
chown root:root /var/run/nut
chmod 0770 /var/run/nut

chown -R root:root /etc/nut
find /etc/nut -not -perm 0660 -type f -exec chmod 0660 {} \;
find /etc/nut -not -perm 0660 -type d -exec chmod 0660 {} \;

# Clear configuration
echo "" > "${UPS_CONF}"

# NUT discovery through Avahi
nut-scanner -A

# Check for USB devices first
if bashio::config.true 'autoconf_usb_devices' ;then

    bashio::log.info "Autodetecting and configuring USB devices"
    nut-scanner -U >  "${UPS_CONF}"
fi

if bashio::config.true 'manual_edit_devices' ;then

    bashio::log.info "manual_edit_devices"
    # FIXME: process manual edits
fi


if bashio::config.true 'enable_simulated_device' ;then
    # https://networkupstools.org/docs/developer-guide.chunked/dev-tools.html

    bashio::log.info "Configuring Simulation Device 'smartnut-dummy'..."
    {
        echo
        echo "[smartnut-dummy]"
        echo -e "\tdriver = dummy-ups"
        echo -e "\tport = smartnut-dummy.seq"
    } >>  "${UPS_CONF}"

fi

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

# FIXME: sanity check (-n MQTT_HOST MQTT_USER MQTT_PASSWORD) and error catching
# FIXME
#  - ca: str?
#  - key: str?
#  - cert: str?

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

bashio::log.info "---------------------"
bashio::log.info "Starting the SmartNUT Driver(s)..."
upsdrvctl -u root start
#/usr/lib/nut/usbhid-ups -u root -a nutdev1
sleep 5
bashio::log.info "Driver(s) started..."

bashio::log.info "---------------------"
bashio::log.info "Starting the SmartNUT2MQTT Adapter..."
/usr/bin/dstate-nut2mqtt
