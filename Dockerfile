# Keystone
# VERSION               0.0.1
# Tested on RHEL7 and OSP5 (i.e. Icehouse)

FROM       systemd_rhel7
MAINTAINER Daneyon Hansen "daneyonhansen@gmail.com"

WORKDIR /root

# Uses Cisco Internal Mirror. Follow the OSP 5 Repo documentation if you are using subscription manager.
RUN curl --url http://173.39.232.144/repo/redhat.repo --output /etc/yum.repos.d/redhat.repo
RUN yum -y update; yum clean all

# Required Utilities. Note: Mariadb is required for data and endpoint scripts.
RUN yum -y install openssl ntp mariadb

# Keystone
RUN yum install -y openstack-keystone python-keystoneclient
RUN mv /etc/keystone/keystone.conf /etc/keystone/keystone.conf.save
ADD keystone.conf /etc/keystone/keystone.conf
RUN chown keystone:keystone /etc/keystone/keystone.conf
RUN mkdir -p /var/log/keystone && touch /var/log/keystone/keystone.log
RUN chown keystone:keystone /var/log/keystone/keystone.log
RUN systemctl enable openstack-keystone

# Initialize the Keystone MySQL DB
RUN keystone-manage db_sync

# By default, Keystone uses PKI tokens. 
# Create the signing keys and certificates and restrict access to the generated data
RUN keystone-manage pki_setup --keystone-user keystone --keystone-group keystone
RUN chown -R keystone:keystone /etc/keystone/ssl
RUN chmod -R o-rwx /etc/keystone/ssl

# Populate the Keystone DB
ADD keystone-data.sh /root/keystone-data.sh
RUN chmod +x /root/keystone-data.sh
#RUN . keystone-data.sh
ADD keystone-endpoints.sh /root/keystone-endpoints.sh
RUN chmod +x /root/keystone-endpoints.sh
#RUN . keystone-endpoints.sh

# Copy Keystone Credential Files
ADD admin-openrc.sh /root/admin-openrc.sh
ADD demo-openrc.sh /root/demo-openrc.sh

# Expose Keystone TCP ports
EXPOSE 5000 35357

CMD ["/usr/sbin/init"]
