#!/bin/sh

# DPS Enrollment Group Key
KEY=
DPS_SCOPE_ID=

# Get the hostname
HOSTNAME=$(hostname)

# Specify the Registration ID
REG_ID=$HOSTNAME

# Compute a Derived key
keybytes=$(echo $KEY | base64 --decode | xxd -p -u -c 1000)
DERIVED_KEY=$(echo -n $REG_ID | openssl sha256 -mac HMAC -macopt hexkey:$keybytes -binary | base64)

# Install IoT Edge

wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# Install a container engine

sudo apt-get update
sudo apt-get install moby-engine

# Set the default logging driver

sudo tee /etc/docker/daemon.json << END

{
      "log-driver": "local"
}
END

# Install the IoT Edge runtime

sudo apt-get update
sudo apt-get install aziot-edge

# Restart the container engine for the changes to take effect

sudo systemctl restart docker

# Add storage access permissions here

sudo mkdir -p /data/iotedge/databases
sudo chmod 755 /data/iotedge/databases

# Provision the device with its cloud identity

sudo cp /etc/aziot/config.toml.edge.template /etc/aziot/config.toml

# DPS provisioning with symmetric key

sudo tee /etc/aziot/config.toml << END


[provisioning]
source = "dps"
global_endpoint = "https://global.azure-devices-provisioning.net"
id_scope = "$DPS_SCOPE_ID"

# Uncomment to send a custom payload during DPS registration
# payload = { uri = "PATH_TO_JSON_FILE" }

[provisioning.attestation]
method = "symmetric_key"
registration_id = "$REG_ID"

symmetric_key = { value = "$DERIVED_KEY" }

# auto_reprovisioning_mode = Dynamic
END
# Apply the configuration changes

sudo iotedge config apply