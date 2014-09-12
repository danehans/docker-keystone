#!/bin/sh
#

# Database definitions
DB_USER=keystone
DATABASE_NAME=keystone
DB_HOST=%DB_HOST%
DB_PASSWORD=%DB_PASSWORD%

# Keystone definitions
KEYSTONE_REGION=RegionOne
SERVICE_TOKEN=%ADMIN_TOKEN%
SERVICE_ENDPOINT='http://%KEYSTONE_HOST%:35357/v2.0'
export SERVICE_TOKEN="${SERVICE_TOKEN:-%ADMIN_TOKEN%}"
export SERVICE_ENDPOINT="${SERVICE_ENDPOINT:-http://%KEYSTONE_HOST%:35357/v2.0}"

# API Endpoint Definitions
GLANCE_API_HOST=${GLANCE_API_HOST:-%GLANCE_API_HOST%}
SWIFT_PROXY_HOST=${SWIFT_PROXY_HOST:-%SWIFT_PROXY_HOST%}
KEYSTONE_API_HOST=${KEYSTONE_API_HOST:-%KEYSTONE_API_HOST%}
NOVA_API_HOST=${NOVA_API_HOST:-%NOVA_API_HOST%}
CINDER_API_HOST=${CINDER_API_HOST:-%CINDER_API_HOST%}
NEUTRON_API_HOST=${NEUTRON_API_HOST:-%NEUTRON_API_HOST%}
HEAT_API_HOST=${HEAT_API_HOST:-%HEAT_API_HOST%}
CEILOMETER_API_HOST=${CEILOMETER_API_HOST:-%CEILOMETER_API_HOST%}
TROVE_API_HOST=${TROVE_API_HOST:-%TROVE_API_HOST%}

# Enable/Disable Services
CONFIG_KEYSTONE=${CONFIG_KEYSTONE:-true}
CONFIG_GLANCE=${CONFIG_GLANCE:-true}
CONFIG_NOVA=${CONFIG_NOVA:-true}
CONFIG_CINDER=${CONFIG_CINDER:-true}
CONFIG_NEUTRON=${CONFIG_NEUTRON:-true}
CONFIG_SWIFT=${CONFIG_SWIFT:-true}
CONFIG_HEAT=${CONFIG_HEAT:-true}
CONFIG_CEILOMETER=${CONFIG_CEILOMETER:-true}
CONFIG_TROVE=${CONFIG_TROVE:-true}

while getopts "u:D:p:m:K:R:E:S:T:vh" opt; do
  case $opt in
    u)
      DB_USER=$OPTARG
      ;;
    D)
      DATABASE_NAME=$OPTARG
      ;;
    p)
      DB_PASSWORD=$OPTARG
      ;;
    m)
      DB_HOST=$OPTARG
      ;;
    C)
      CONTROLLER=$OPTARG
      ;;
    R)
      KEYSTONE_REGION=$OPTARG
      ;;
    E)
      export SERVICE_ENDPOINT=$OPTARG
      ;;
    S)
      SWIFT_PROXY=$OPTARG
      ;;
    T)
      export SERVICE_TOKEN=$OPTARG
      ;;
    v)
      set -x
      ;;
    h)
      cat <<EOF
Usage: $0 [-m db_hostname] [-u db_username] [-D db_database] [-p db_password]
       [-C controller ] [ -R keystone_region ] [ -E keystone_endpoint_url ] 
       [ -S swift_proxy ] [ -T keystone_token ]
          
Add -v for verbose mode, -h to display this message.
EOF
      exit 0
      ;;
    \?)
      echo "Unknown option -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument" >&2
      exit 1
      ;;
  esac
done  

if [ -z "$KEYSTONE_REGION" ]; then
  echo "Keystone region not set. Please set with -R option or set KEYSTONE_REGION variable." >&2
  missing_args="true"
fi

if [ -z "$SERVICE_TOKEN" ]; then
  echo "Keystone service token not set. Please set with -T option or set SERVICE_TOKEN variable." >&2
  missing_args="true"
fi

if [ -z "$SERVICE_ENDPOINT" ]; then
  echo "Keystone service endpoint not set. Please set with -E option or set SERVICE_ENDPOINT variable." >&2
  missing_args="true"
fi

if [ -z "$DB_PASSWORD" ]; then
  echo "MySQL password not set. Please set with -p option or set DB_PASSWORD variable." >&2
  missing_args="true"
fi

if [ -n "$missing_args" ]; then
  exit 1
fi

if [ "${CONFIG_KEYSTONE}" = true ] ; then
keystone service-create --name keystone --type identity --description 'OpenStack Identity'
fi

if [ "${CONFIG_GLANCE}" = true  ] ; then
  keystone service-create --name glance --type image --description 'OpenStack Image Service'
fi

if [ "${CONFIG_NOVA}" = true ] ; then
  keystone service-create --name nova --type compute --description 'OpenStack Compute Service'
  keystone service-create --name ec2 --type ec2 --description 'OpenStack EC2 service'
fi

if [ "${CONFIG_CINDER}" = true ] ; then
  keystone service-create --name cinder --type volume --description 'OpenStack Volume Service'
fi

if [ "${CONFIG_SWIFT}" = true ] ; then
keystone service-create --name swift --type object-store --description 'OpenStack Storage Service'
fi

if [ "${CONFIG_NEUTRON}" = true ] ; then
  keystone service-create --name neutron --type network --description 'OpenStack Networking Service'
fi

if [ "${CONFIG_HEAT}" = true ] ; then
  keystone service-create --name heat-cfn --type cloudformation --description 'Heat CloudFormation API'
  keystone service-create --name heat --type orchestration --description 'Heat Orchestration API'
fi

if [ "${CONFIG_CEILOMETER}" = true ] ; then
  keystone service-create --name ceilometer --type metering --description 'OpenStack Telemetry Service'
fi

if [ "${CONFIG_TROVE}" = true ] ; then
  keystone service-create --name trove --type database --description 'OpenStack Database Service'
fi

create_endpoint () {
  case $1 in
    compute)
    if [ $CONFIG_NOVA = true ]; then
    keystone endpoint-create --region $KEYSTONE_REGION --service-id $2 --publicurl 'http://'"$NOVA_API_HOST"':8774/v2/$(tenant_id)s' --adminurl 'http://'"$NOVA_API_HOST"':8774/v2/$(tenant_id)s' --internalurl 'http://'"$NOVA_API_HOST"':8774/v2/$(tenant_id)s'
    fi
    ;;
    volume)
    if [ $CONFIG_CINDER = true ]; then
    keystone endpoint-create --region $KEYSTONE_REGION --service-id $2 --publicurl 'http://'"$CINDER_API_HOST"':8776/v1/$(tenant_id)s' --adminurl 'http://'"$CINDER_API_HOST"':8776/v1/$(tenant_id)s' --internalurl 'http://'"$CINDER_API_HOST"':8776/v1/$(tenant_id)s'
    fi
    ;;
    image)
    if [ $CONFIG_GLANCE = true ]; then
    keystone endpoint-create --region $KEYSTONE_REGION --service-id $2 --publicurl 'http://'"$GLANCE_API_HOST"':9292/v2' --adminurl 'http://'"$GLANCE_API_HOST"':9292/v2' --internalurl 'http://'"$GLANCE_API_HOST"':9292/v2'
    fi
    ;;
    object-store)
    if [ $CONFIG_SWIFT = true ]; then
      keystone endpoint-create --region $KEYSTONE_REGION --service-id $2 --publicurl 'http://'"$SWIFT_PROXY_HOST"':8080/v1/AUTH_$(tenant_id)s' --adminurl 'http://'"$SWIFT_PROXY_HOST"':8080/v1' --internalurl 'http://'"$SWIFT_PROXY_HOST"':8080/v1/AUTH_$(tenant_id)s'
    fi
    ;;
    identity)
    if [ $CONFIG_KEYSTONE = true ]; then
    keystone endpoint-create --region $KEYSTONE_REGION --service-id $2 --publicurl 'http://'"$KEYSTONE_API_HOST"':5000/v2.0' --adminurl 'http://'"$KEYSTONE_API_HOST"':35357/v2.0' --internalurl 'http://'"$KEYSTONE_API_HOST"':5000/v2.0'
    fi
    ;;
    ec2)
    if [ $CONFIG_NOVA = true ]; then
    keystone endpoint-create --region $KEYSTONE_REGION --service-id $2 --publicurl 'http://'"$NOVA_API_HOST"':8773/services/Cloud' --adminurl 'http://'"$NOVA_API_HOST"':8773/services/Admin' --internalurl 'http://'"$NOVA_API_HOST"':8773/services/Cloud'
    fi
    ;;
    cloudformation)
    if [ $CONFIG_HEAT = true ]; then
    keystone endpoint-create --region $KEYSTONE_REGION --service-id $2 --publicurl 'http://'"$HEAT_API_HOST"':8000/v1' --adminurl 'http://'"$HEAT_API_HOST"':8000/v1' --internalurl 'http://'"$HEAT_API_HOST"':8000/v1'
    fi
    ;;
    orchestration)
    if [ $CONFIG_HEAT = true ]; then
    keystone endpoint-create --region $KEYSTONE_REGION --service-id $2 --publicurl 'http://'"$HEAT_API_HOST"':8004/v1/%(tenant_id)s' --adminurl 'http://'"$HEAT_API_HOST"':8004/v1/%(tenant_id)s' --internalurl 'http://'"$HEAT_API_HOST"':8004/v1/%(tenant_id)s'
    fi
    ;;
    network)
    if [ $CONFIG_NEUTRON = true ]; then
    keystone endpoint-create --region $KEYSTONE_REGION --service-id $2 --publicurl 'http://'"$NEUTRON_API_HOST"':9696/' --adminurl 'http://'"$NEUTRON_API_HOST"':9696/' --internalurl 'http://'"$NEUTRON_API_HOST"':9696/'
    fi
    ;;
    metering)
    if [ $CONFIG_CEILOMETER = true ]; then
    keystone endpoint-create --region $KEYSTONE_REGION --service-id $2 --publicurl 'http://'"$CEILOMETER_API_HOST"':8777/'  --adminurl 'http://'"$CEILOMETER_API_HOST"':8777/' --internalurl 'http://'"$CEILOMETER_API_HOST"':8777/'
    fi
    ;;
    database)
    if [ $CONFIG_TROVE = true ]; then
    keystone endpoint-create --region $KEYSTONE_REGION --service-id $2 --publicurl 'http://'"$TROVE_API_HOST"':8779/v1.0/\$(tenant_id)s' --adminurl 'http://'"$TROVE_API_HOST"':8779/v1.0/\$(tenant_id)s' --internalurl 'http://'"$TROVE_API_HOST"':8779/v1.0/\$(tenant_id)s'
    fi
    ;;
  esac
}

for i in compute volume image object-store identity ec2 cloudformation orchestration network metering database; do
  id=`mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DATABASE_NAME" -ss -e "SELECT id FROM service WHERE type='"$i"';"` || exit 1
  create_endpoint $i $id
done