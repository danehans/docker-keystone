#!/bin/sh
#

ADMIN_USER=${ADMIN_USER:-admin}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-%ADMIN_PASSWORD%}
DEMO_PASSWORD=${DEMO_PASSWORD:-%DEMO_PASSWORD%}
DOMAIN=${DOMAIN:-localhost}
export SERVICE_TOKEN="%ADMIN_TOKEN%"
export SERVICE_ENDPOINT="http://%KEYSTONE_HOST%:35357/v2.0"
SERVICE_TENANT=${SERVICE_TENANT:-%SERVICE_TENANT%}
SERVICE_PASSWORD=${SERVICE_PASSWORD:-$ADMIN_PASSWORD}
# Enable/Disable which services to configure
CONFIG_KEYSTONE=${CONFIG_KEYSTONE:-true}
CONFIG_GLANCE=${CONFIG_GLANCE:-true}
CONFIG_NOVA=${CONFIG_NOVA:-true}
CONFIG_NEUTRON=${CONFIG_NEUTRON:-true}
CONFIG_CINDER=${CONFIG_CINDER:-true}
CONFIG_SWIFT=${CONFIG_SWIFT:-true}
CONFIG_CEILOMETER=${CONFIG_CEILOMETER:-true}
CONFIG_HEAT=${CONFIG_HEAT:-true}
CONFIG_TROVE=${CONFIG_TROVE:-true}

if [ "${CONFIG_KEYSTONE}" = true ] ; then
  # Users
  keystone user-create --name=$ADMIN_USER --pass=$ADMIN_PASSWORD --email=admin@$DOMAIN
  keystone user-create --name=demo --pass=$DEMO_PASSWORD --email=demo@$DOMAIN
  # Roles
  keystone role-create --name=admin
  # Tenants
  keystone tenant-create --name=admin --description="Admin Tenant"
  keystone tenant-create --name=demo --description="Demo Tenant"
  keystone tenant-create --name=$SERVICE_TENANT --description="Service Tenant"
  # Add Roles to Users in Tenants
  keystone user-role-add --user=$ADMIN_USER --role=admin --tenant=admin
  keystone user-role-add --user=$ADMIN_USER --role=_member_ --tenant=admin
  keystone user-role-add --user=demo --role=_member_ --tenant=demo
fi

if [ "${CONFIG_GLANCE}" = true ] ; then
  keystone user-create --name=glance --pass=$SERVICE_PASSWORD --email=glance@$DOMAIN
  keystone user-role-add --user=glance --tenant=$SERVICE_TENANT --role=admin
fi

if [ "${CONFIG_NOVA}" = true ] ; then
  keystone user-create --name=nova --pass=$SERVICE_PASSWORD --email=nova@$DOMAIN
  keystone user-role-add --user=nova --tenant=$SERVICE_TENANT --role=admin
fi

if [ "${CONFIG_NEUTRON}" = true ] ; then
  keystone user-create --name=neutron --pass=$SERVICE_PASSWORD --email=neutron@$DOMAIN
  keystone user-role-add --user=neutron --tenant=$SERVICE_TENANT --role=admin
fi

if [ "${CONFIG_CINDER}" = true ] ; then
  keystone user-create --name=cinder --pass=$SERVICE_PASSWORD --email=cinder@$DOMAIN
  keystone user-role-add --user=cinder --tenant=$SERVICE_TENANT --role=admin
fi

if [ "${CONFIG_SWIFT}" = true ] ; then
  keystone user-create --name=swift --pass=$SERVICE_PASSWORD --email=swift@$DOMAIN
  keystone user-role-add --user=swift --tenant=$SERVICE_TENANT --role=admin
fi

if [ "${CONFIG_HEAT}" = true ] ; then
  keystone role-create --name=heat_stack_user
  keystone role-create --name=heat_stack_owner
  keystone user-create --name=heat --pass=$SERVICE_PASSWORD --email=heat@$DOMAIN
  keystone user-role-add --user=heat --tenant=$SERVICE_TENANT --role=admin
fi

if [ "${CONFIG_CEILOMETER}" = true ] ; then
  keystone user-create --name=ceilometer --pass=$SERVICE_PASSWORD --email=ceilometer@$DOMAIN
  keystone user-role-add --user=ceilometer --tenant=$SERVICE_TENANT --role=admin
fi

if [ "${CONFIG_TROVE}" = true ] ; then
  keystone user-create --name=trove --pass=$SERVICE_PASSWORD --email=trove@$DOMAIN
  keystone user-role-add --user=trove --tenant=$SERVICE_TENANT --role=admin
fi
