#!/usr/bin/sed -nrf
# ------------------------------------------------------------------------------------
# Create a SED script based on the configuration from MyLearn Lab
# ------------------------------------------------------------------------------------
/^user/s!.*=(.*)!/^\\s*user/s/"\.\*"/"\1"/!p
/^tenancy/s!.*=(.*)!/^\\s*tenancy/s/"\.\*"/"\1"/!p
/^compartment/s!.*=(.*)!/^\\s*compartment/s/"\.\*"/"\1"/!p
