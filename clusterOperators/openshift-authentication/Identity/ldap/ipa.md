# IPA

## Installation

~~~bash

$ cat inventory/hosts

[ipaserver]
ipa.mycluster.nancyge.com
[ipaserver:vars]
ipaserver_domain=mycluster.nancyge.com
ipaserver_realm=MYCLUSTER.NANCYGE.COM
#ipaserver_setup_dns=yes
#ipaserver_auto_forwarders=yes
ipaadmin_password="redhat123"
ipadm_password="redhat123"

$ cat install.yaml
---
- name: Playbook to configure IPA server
  hosts: ipaserver
  become: true

  roles:
  - role: ipaserver
    state: present

$ subscription-manager config --rhsm.manage_repos=1
$ subscription-manager repos --enable ansible-2.8-for-rhel-8-x86_64-rpms
$ yum install ansible ansible-freeipa -y

$ ansible-playbook -i inventory/hosts install.yaml
~~~

## Configure OAuth

~~~bash
cat << EOF > oauth.yaml

apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: ldapidp
    mappingMethod: claim
    type: LDAP
    ldap:
      attributes:
        id:
        - dn
        email:
        - mail
        name:
        - cn
        preferredUsername:
        - uid
      bindDN: "uid=binduser,cn=users,cn=accounts,dc=mycluster,dc=nancyge,dc=com"
      bindPassword:
        name: ldap-secret
      insecure: true
      url: "ldap://18.117.72.87/cn=users,cn=accounts,dc=mycluster,dc=nancyge,dc=com?uid"

EOF

~~~

~~~bash
$ oc create secret generic ldap-secret --from-literal=bindPassword='<password>' -n openshift-config
$ oc apply -f oauth.yaml
~~~

## Sync the group

~~~bash
$ cat << EOF > sync.yaml

kind: LDAPSyncConfig
apiVersion: v1
url: ldap://18.117.72.87:389
bindDN: uid=binduser,cn=users,cn=accounts,dc=mycluster,dc=nancyge,dc=com
bindPassword: 'RedHat1!'
insecure: true
activeDirectory:
    usersQuery:
        baseDN: "cn=users,cn=accounts,dc=mycluster,dc=nancyge,dc=com"
        scope: sub
        derefAliases: never
        filter: (objectClass=Person)
        pageSize: 0
    userNameAttributes: [ uid ]
    groupMembershipAttributes: [ memberOf ]
groupUIDNameMapping:
    cn=ocp_support,cn=groups,cn=accounts,dc=mycluster,dc=nancyge,dc=com: ocp_support
    cn=ocp_admin,cn=groups,cn=accounts,dc=mycluster,dc=nancyge,dc=com: ocp_admin
    cn=ocp_users,cn=groups,cn=accounts,dc=mycluster,dc=nancyge,dc=com: ocp_users

EOF
~~~

~~~bash
$ cat << EOF > whitelist.txt
cn=ocp_support,cn=groups,cn=accounts,dc=mycluster,dc=nancyge,dc=com
cn=ocp_admin,cn=groups,cn=accounts,dc=mycluster,dc=nancyge,dc=com
cn=ocp_users,cn=groups,cn=accounts,dc=mycluster,dc=nancyge,dc=com
EOF
~~~

~~~bash

$ oc adm groups sync --whitelist=whitelist.txt --sync-config=sync.yaml
$ oc adm groups sync --whitelist=whitelist.txt --sync-config=sync.yaml --confirm
$ oc adm policy add-cluster-role-to-group cluster-admin ocp_admin
~~~

## Configure LDAPS

~~~bash
#The location of IPA's CAcert is located in /etc/ipa/ca.crt; Copy it out
#Create a configmap based on the ca.crt we copied from IPA server.

$ oc create configmap ca-config-map --from-file=ca.crt=ca.crt -n openshift-config

#Verify the CA is working. Be aware that MacOS doesn't know LDAPTLS_CACERT. https://stackoverflow.com/questions/27835019/ldap-search-user-based-on-certificate-in-linux-command-line

$ LDAPTLS_CACERT=ca.crt ldapsearch  -Z -H ldaps://ipa.mycluster.nancyge.com:636 -D "uid=binduser,cn=users,cn=accounts,dc=mycluster,dc=nancyge,dc=com" -w '<password>' -b "cn=users,cn=accounts,dc=mycluster,dc=nancyge,dc=com" uid

$ oc edit oauth cluster

spec:
  identityProviders:
  - ldap:
      attributes:
        email:
        - mail
        id:
        - dn
        name:
        - cn
        preferredUsername:
        - uid
      bindDN: uid=binduser,cn=users,cn=accounts,dc=mycluster,dc=nancyge,dc=com
      bindPassword:
        name: ldap-secret
      ca:                        <=========
        name: ca-config-map      <=========
      insecure: false            <=========
      url: ldaps://ipa.mycluster.nancyge.com:636/cn=users,cn=accounts,dc=mycluster,dc=nancyge,dc=com?uid <=========
    mappingMethod: claim
    name: ldapidp
    type: LDAP
~~~

## HAProxy + LDAPs

1. fullchain.pem includes certificate and key, pem formatted
2. mode needs to be tcp
3. In backend, use either ca-file <IPA's CA file> or "verify none" to skip the CA check
4. Point the DNS to haproxy server

~~~bash

$ cat /etc/haproxy/haproxy.cfg # in lb.apps.mycluster.nancyge.com

frontend ldap-server-636
    mode tcp
    bind *:636 ssl crt /etc/ssl/certs/fullchain.pem
    default_backend ldaps_servers

backend ldaps_servers
    mode tcp
    option ldap-check
    server ipa1 ipa1.mycluster.nancyge.com:636 check ssl verify none
    server ipa2 ipa2.mycluster.nancyge.com:636 check ssl verify none backup

frontend ldap-server-389
    mode tcp
    bind *:389
    default_backend ldap_servers

backend ldap_servers
    mode tcp
    option ldap-check
    server ipa1 ipa1.mycluster.nancyge.com:389 check
    server ipa2 ipa2.mycluster.nancyge.com:389 check backup

$ cat /etc/hosts

<public IP> lb.apps.mycluster.nancyge.com

$ ldapsearch  -H ldaps://lb.apps.mycluster.nancyge.com:636  -b "cn=users,cn=accounts,dc=mycluster,dc=nancyge,dc=com" -D "uid=binduser,cn=users,cn=accounts,dc=mycluster,dc=nancyge,dc=com" -w '<password>' uid
# extended LDIF
#
# LDAPv3
# base <cn=users,cn=accounts,dc=mycluster,dc=nancyge,dc=com> with scope subtree
# filter: (objectclass=*)
# requesting: uid
#

# users, accounts, mycluster.nancyge.com
dn: cn=users,cn=accounts,dc=mycluster,dc=nancyge,dc=com
<Snip>

~~~
