docker-keystone
===========

0.0.1 - 2014.1.2-1 - Icehouse

Overview
--------

Run OpenStack Keystone in a Docker container.

Introduction
------------

This guide assumes you have Docker installed on your host system. Use the [Get Started with Docker Containers in RHEL 7](https://access.redhat.com/articles/881893] to install Docker on RHEL 7) to setup your Docker on your RHEL 7 host if needed. Reference the [Getting images from outside Docker registries](https://access.redhat.com/articles/881893#images) section of the the guide to pull your base rhel7 image from Red Hat's private registry. This is required to build the rhel7-systemd base image used by the Keystone container.

Make sure your Docker host has been configured with the required [OSP 5 channels and repositories](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux_OpenStack_Platform/5/html/Installation_and_Configuration_Guide/chap-Prerequisites.html#sect-Software_Repository_Configuration)

After following the [Get Started with Docker Containers in RHEL 7](https://access.redhat.com/articles/881893) guide, verify your Docker Registry is running:
```
# systemctl status docker-registry
docker-registry.service - Registry server for Docker
   Loaded: loaded (/usr/lib/systemd/system/docker-registry.service; enabled)
   Active: active (running) since Mon 2014-05-05 13:42:56 EDT; 601ms ago
 Main PID: 21031 (gunicorn)
   CGroup: /system.slice/docker-registry.service
           ├─21031 /usr/bin/python /usr/bin/gunicorn --access-logfile - --debug ...
            ...
```
Now that you have the rhel7 base image, follow the instructions in the [docker-rhel7-systemd project](https://github.com/danehans/docker-rhel7-systemd/blob/master/README.md) to build your rhel7-systemd image.

Although the container does initialize the database used by Keystone, it does not create the database, permissions, etc.. These are responsibilities of the database service.

Installation
------------

From your Docker Registry, set the environment variables used to automate the image building process

Required. Name of the Github repo. Change danehans to your Github repo name if you forked this project. Otherwise set REPO_NAME to danehans.
```
export REPO_NAME=danehans
```
Required. The branch from the REPO_NAME repo. Unless you are using a different branch, set the REPO_BRANCH to master.
```
export REPO_BRANCH=master
```
Optional. Name of the Docker base image in your Docker Registry. This should be the image that includes systemd. Defaults to rhel7-systemd.
```
export BASE_IMAGE=ouruser/rhel7-systemd
```
Optional. Name to use for the Keystone Docker image. Defaults to keystone.
```
export IMAGE_NAME=ouruser/keystone
```
Optional. Hostname to use when running the Keystone container. Defaults to $HOSTNAME
```
export KEYSTONE_HOSTNAME=keystone.example.com
```
Required. IP address/hostname of the Database server.
```
export DB_HOST=10.10.10.200
```
Optional. Password used to connect to the Keystone database on the DB_HOST server. Defaults to changeme.
```
export DB_PASSWORD=changeme
```
Required. IP address/hostname of the RabbitMQ server.
```
export RABBIT_HOST=10.10.10.200
```
Required. IP address/hostname of Keystone. This address should resolve to the IP used by the Host and not the container.
```
export KEYSTONE_HOST=10.10.10.100
```
Optional. admin_token flag used in keystone.conf to bootstrap Keystone. Defaults to changeme.
```
export KEYSTONE_ADMIN_TOKEN=changeme
```
Optional. TCP Port used by the Docker host to listen on for the Keystone Admin API. Defaults to 35357.
```
export KEYSTONE_ADMIN_HOST_PORT=35357
```
Optional. TCP Port used by the Docker host to listen on for the Keystone Public API. Note: The Docker Registry listens on port 5000. Defaults to 5000
```
export KEYSTONE_PUBLIC_HOST_PORT=5001
```
Optional. The name and password of the service tenant within the Keystone service catalog. Defaults to service/changeme
```
export SERVICE_TENANT=services
export SERVICE_PASSWORD=changeme
```
Optional. Credentials used in the Keystone RC files. Defaults to changeme.
```
export ADMIN_USER_PASSWORD=changeme
export DEMO_USER_PASSWORD=changeme
```
Optional. Domain name used within the Keystone service catalog. Defaults to localhost.
```
export DOMAIN=example.com
```
Optional. Region name used within the Keystone service catalog. Defaults to RegionOne
```
export REGION=RegionOne
```
Optional. Set the IP address to use for the OS service in the Keystone endpoint-create. Defaults to 127.0.0.1.Leave at default if you do not set CONFIG_* to true
```
export GLANCE_API_HOST=10.10.10.100
export SWIFT_PROXY_HOST=10.10.10.200
export CINDER_API_HOST=10.10.10.100
export NOVA_API_HOST=10.10.10.100
export NEUTRON_API_HOST=10.10.10.100
export HEAT_API_HOST=10.10.10.100
```
Optional. Set which services to configure within the Keystone service catalog. Defaults to false.
```
export CONFIG_CEILOMETER=false
export CONFIG_TROVE=false
export CONFIG_KEYSTONE=true
export CONFIG_GLANCE=true
export CONFIG_NOVA=true
export CONFIG_SWIFT=true
export CONFIG_NEUTRON=true
export CONFIG_HEAT=true
export CONFIG_CINDER=true
```
Additional environment variables can be set as needed. You can reference the [build script](https://github.com/danehans/docker-keystone/blob/master/data/scripts/build#L14-L99) to review all the available environment variables options and their default settings.

Refer to the OpenStack [Icehouse installation guide](http://docs.openstack.org/icehouse/install-guide/install/yum/content/keystone-install.html) for more details on the .conf configuration parameters.

Run the build script.
```
bash <(curl \-fsS https://raw.githubusercontent.com/$REPO_NAME/docker-keystone/$REPO_BRANCH/data/scripts/build)
```
The image should now appear in your image list:
```
# docker images
REPOSITORY                TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
keystone                  latest              d75185a8e696        3 minutes ago       555 MB
```
Now you can run a Keystone container from the newly created image. You can use the run script or run the container manually.

First, set your environment variables:
```
export IMAGE_NAME=ouruser/keystone
export KEYSTONE_HOSTNAME=keystone.example.com
```
Keystone and the Docker registry service both listen on port 5000. Change the port the Docker host will listen on for Keystone if you are running the Keystone container on a Docker registry server.
```
export KEYSTONE_PUBLIC_HOST_PORT=5001
export DNS_SEARCH=example.com
```
Additional environment variables can be set as needed. You can reference the [run script](https://github.com/danehans/docker-keystone/blob/master/data/scripts/run#L14-L36) to review all the available environment variables options and their default settings.

**Option 1-** Use the run script:
```
# . $HOME/docker-keystone/data/scripts/run
```
**Option 2-** Manually:
Run the Keystone container. The example below uses the -h flag to configure the hostame as keystone within the container, exposes TCP ports 5000 and 35357 on the Docker host, names the container keystone, uses -d to run the container as a daemon.
```
# docker run --privileged -d -h keystone -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
-p 5000:5000 -p 35357:35357 --name="keystone" keystone
```
**Note:** SystemD requires CAP_SYS_ADMIN capability and access to the cgroup file system within a container. Therefore, --privileged and -v /sys/fs/cgroup:/sys/fs/cgroup:ro are required flags.

Verification
------------

Verify your Keystone container is running:
```
# docker ps
CONTAINER ID  IMAGE         COMMAND          CREATED             STATUS              PORTS                                          NAMES
96173898fa16  keystone:latest   /usr/sbin/init   About an hour ago   Up 51 minutes       0.0.0.0:5000->5000/tcp 0.0.0.0:35357->35357/tcp  keystone
```
Access the shell from your container:
```
# docker inspect --format='{{.State.Pid}}' keystone
```
The command above will provide a process ID of the Keystone container that is used in the following command:
```
# nsenter -m -u -n -i -p -t <PROCESS_ID> /bin/bash
bash-4.2#
```
From here you can perform limited functions such as viewing installed RPMs, the keystone.conf file, etc..

Configuration
-------------

Run the keystone-data.sh and keystone-endpoints.sh scripts to populate Keystone with the necessary users, tenants, services, endpoints, etc.. Your container should be configured with the CONF_* environment variables. The scripts will only configure OS services that are set to CONF_*=true.
```
# ./usr/local/bin/keystone-data.sh
# ./usr/local/bin/keystone-endpoints.sh
```
Source your Keystone credential file:
```
# source /root/admin-openrc.sh
```
Verify the Keystone configuration.
```
# keystone user-list
+----------------------------------+------------+---------+----------------------+
|                id                |    name    | enabled |        email         |
+----------------------------------+------------+---------+----------------------+
| e343c55f856541fa960aee223bad5d79 |   admin    |   True  |   admin@localhost    |
| db8ce1c348b6473b930446828ec4594d | ceilometer |   True  | ceilometer@localhost |
| 93eed2f266854880ac69e581ed8936ef |   cinder   |   True  |   cinder@localhost   |
| 3084389e225845ad9c19251beb7db8f4 |    demo    |   True  |    demo@localhost    |
| d8cb2670a3a04898b2d737b28896c132 |   glance   |   True  |   glance@localhost   |
| ac82a1eb77644e45909ab59361ba7aa9 |  keystone  |   True  |  keystone@localhost  |
| 52a169ef86cb4d25af5c81776d905a66 |  neutron   |   True  |  neutron@localhost   |
| d3b17613fe6449e39e4a85df2cdc2ea3 |    nova    |   True  |    nova@localhost    |
| f3e5da44c69842e99ca542eda8348da2 |   swift    |   True  |   swift@localhost    |
| 12edd14e389a428d897eb627733a3f79 |   trove    |   True  |   trove@localhost    |
+----------------------------------+------------+---------+----------------------+
# keystone tenant-list
+----------------------------------+----------+---------+
|                id                |   name   | enabled |
+----------------------------------+----------+---------+
| 527e84e38b964357adc1de01f151b3da |  admin   |   True  |
| c8fdd62a304a497a9dcbb492f87179b1 |   demo   |   True  |
| 5ae49e7dbdd94b728d25935b6df06be8 | services |   True  |
+----------------------------------+----------+---------+
# keystone service-list
+----------------------------------+------------+----------------+------------------------------+
|                id                |    name    |      type      |         description          |
+----------------------------------+------------+----------------+------------------------------+
| 3d539e82ecde4d2fae2df5d03bbebbff | ceilometer |    metering    | OpenStack Telemetry Service  |
| 39b45e204b6641b6b0d02f7180d3d6e0 |   cinder   |     volume     |   OpenStack Volume Service   |
| cbe045310df4475f97664563b6da81c4 |    ec2     |      ec2       |    OpenStack EC2 service     |
| e0e541a23ff64d52829559a6f9ce187d |   glance   |     image      |   OpenStack Image Service    |
| 03ea2d10a6cf403a842dbf36eec94f27 | keystone   | orchestration  |  Keystone Orchestration API  |
| 2db4fad42e4f4c50884d60adbb3b92da | keystone   | orchestration  |  Keystone Orchestration API  |
| 5e50490b38e140cebe3461b0673b888e |keystone-cfn| cloudformation | Keystone CloudFormation API  |
| e99f65a04cea44dba7df488749c42fbd |keystone-cfn| cloudformation | Keystone CloudFormation API  |
| b7d37c90b74340e9b1ebf82023bf7053 |  keystone  |    identity    |      OpenStack Identity      |
| ad9b4f5dd793411594a69aae2cfdad52 |  neutron   |    network     | OpenStack Networking Service |
| 202db1aa66ca463bbc315aacb0a61a71 |    nova    |    compute     |  OpenStack Compute Service   |
| 68b4bfd4a90249f19bad3e4ddbeb4b77 |   swift    |  object-store  |  OpenStack Storage Service   |
| 59ead4b627d6465dab06394f4f5ea47a |   trove    |    database    |  OpenStack Database Service  |
+----------------------------------+------------+----------------+------------------------------+
# keystone endpoint-list
+----------------------------------+-----------+------------------------------------------------+------------------------------------------------+----------------------------------------------+----------------------------------+
|                id                |   region  |                   publicurl                    |                  internalurl                   |                   adminurl                   |            service_id            |
+----------------------------------+-----------+------------------------------------------------+------------------------------------------------+----------------------------------------------+----------------------------------+
| 04e7181792df41d79ff3fae9ed9c5d8e | RegionOne |          http://10.10.10.100:8000/v1           |          http://10.10.10.100:8000/v1           |         http://10.10.10.100:8000/v1          | 5e50490b38e140cebe3461b0673b888e |
| 2288d896389f43e39d54c51eb4c4ab77 | RegionOne |         http://10.10.10.100:5000/v2.0          |         http://10.10.10.100:5000/v2.0          |        http://10.10.10.100:35357/v2.0        | b7d37c90b74340e9b1ebf82023bf7053 |
| 29b877b62a804b2c9e5dfd4e9d1517b9 | RegionOne |          http://10.10.10.100:8000/v1           |          http://10.10.10.100:8000/v1           |         http://10.10.10.100:8000/v1          | 5e50490b38e140cebe3461b0673b888e |
| 33721d024a494328ae301d579bb761dd | RegionOne |           http://10.10.10.200:9696/            |           http://10.10.10.200:9696/            |          http://10.10.10.200:9696/           | ad9b4f5dd793411594a69aae2cfdad52 |
| 446377d275bb404b94c50144ad7b264c | RegionOne |   http://10.10.10.100:8776/v1/$(tenant_id)s    |   http://10.10.10.100:8776/v1/$(tenant_id)s    |  http://10.10.10.100:8776/v1/$(tenant_id)s   | 39b45e204b6641b6b0d02f7180d3d6e0 |
| 51bf840d21934ff096954cd2d57ba23f | RegionOne |          http://10.10.10.100:9292/v2           |          http://10.10.10.100:9292/v2           |         http://10.10.10.100:9292/v2          | e0e541a23ff64d52829559a6f9ce187d |
| 52575efa3bcd4cc187e2e34b92cc80cd | RegionOne |   http://10.10.10.100:8774/v2/$(tenant_id)s    |   http://10.10.10.100:8774/v2/$(tenant_id)s    |  http://10.10.10.100:8774/v2/$(tenant_id)s   | 202db1aa66ca463bbc315aacb0a61a71 |
| 728c1fc708da42a88ccd8020548653b3 | RegionOne |  http://10.10.10.200:8779/v1.0/\$(tenant_id)s  |  http://10.10.10.200:8779/v1.0/\$(tenant_id)s  | http://10.10.10.200:8779/v1.0/\$(tenant_id)s | 59ead4b627d6465dab06394f4f5ea47a |
| b9074b09447f461a8ed643acd65368c4 | RegionOne | http://10.10.10.200:8080/v1/AUTH_$(tenant_id)s | http://10.10.10.200:8080/v1/AUTH_$(tenant_id)s |         http://10.10.10.200:8080/v1          | 68b4bfd4a90249f19bad3e4ddbeb4b77 |
| c2f5116a396c4408b569a2ba21a4bfef | RegionOne |    http://10.10.10.100:8773/services/Cloud     |    http://10.10.10.100:8773/services/Cloud     |   http://10.10.10.100:8773/services/Admin    | cbe045310df4475f97664563b6da81c4 |
| ceb0494b7e0447c5b4e9e8a896c8671b | RegionOne |   http://10.10.10.100:8004/v1/%(tenant_id)s    |   http://10.10.10.100:8004/v1/%(tenant_id)s    |  http://10.10.10.100:8004/v1/%(tenant_id)s   | 2db4fad42e4f4c50884d60adbb3b92da |
| e45f6595572c4713927bf52774a2fa8b | RegionOne |   http://10.10.10.100:8004/v1/%(tenant_id)s    |   http://10.10.10.100:8004/v1/%(tenant_id)s    |  http://10.10.10.100:8004/v1/%(tenant_id)s   | 03ea2d10a6cf403a842dbf36eec94f27 |
| fc7632d87ca84904b74123c344863e08 | RegionOne |           http://10.10.10.200:8777/            |           http://10.10.10.200:8777/            |          http://10.10.10.200:8777/           | 3d539e82ecde4d2fae2df5d03bbebbff |
+----------------------------------+-----------+------------------------------------------------+------------------------------------------------+----------------------------------------------+----------------------------------+
```

Troubleshooting
---------------

Can you connect to the OpenStack API endpints from your Docker host and container? Verify connectivity with tools such as ping and curl.
```
# yum install -y curl
# curl -d '{"auth": {"tenantName": "admin", "passwordCredentials":{"username": "admin", "password": "%ADMIN_TOKEN%"}}}' -H "Content-type: application/json" http://%KEYSTONE_HOST%:35357/v2.0/tokens | python -mjson.tool
```
IPtables may be blocking you. Check IPtables rules on the host(s) running the other OpenStack services:
```
# iptables -L
```
To change iptables rules:
```
# vi /etc/sysconfig/iptables
# systemctl restart iptables.service
```
If the Keystone container is being added to an existing OpenStack deployment, you must restart the existing services to obtain updated Keystone certificates. If you had an existing Neutron service, you will need to update the nova_admin_tenant_id in neutron.conf to reflect the new tenant-id of the services tenant. You will also need to update any existing Neutron networks to reflect the correct admin/tenant tenant-id. If you have an existing Keystone deployment, you will need to remove/rename the /tmp/keystone-signing-keystone/ for Keystone to recreate the correct .pem files.

Contributing
------------

The [keystone.conf](https://github.com/danehans/docker-keystone/blob/master/data/tiller/templates/keystone.conf.erb) file is managed by a tool called [Tiller](https://github.com/markround/tiller/blob/master/README.md).

If you require setting additional keystone.conf configuration flags, please fork the docker-keystone project, hack, test and submit a pull request to get your changes back upstream.
