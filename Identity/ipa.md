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

$ subscription-manager repos --enable ansible-2.8-for-rhel-8-x86_64-rpms
$ yum install ansible
$ yum install ansible-freeipa

ansible-playbook -i inventory/hosts install.yaml
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

#Verify the CA is working

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
