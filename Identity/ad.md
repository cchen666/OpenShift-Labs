#### Test AD
~~~
# ldapsearch -h 10.0.95.91 -b "dc=titamu,dc=com" -D "CN=Chen Chen, CN=Users, DC=titamu, DC=com" -w 'RedHat1!' -x
~~~
#### Get AD's CA
~~~
https://docs.microsoft.com/en-us/troubleshoot/windows-server/identity/export-root-certification-authority-certificate
~~~
#### Download a useful ldap browser
~~~
https://directory.apache.org/studio/download/download-macosx.html
~~~
#### Create bind user's secret file
~~~
$ oc create secret generic ldap-secret --from-literal=bindPassword='RedHat1!' -n openshift-config
~~~
#### Create OAuth yaml file
~~~


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
        - name
        email:
        - mail
        name:
        - cn
        preferredUsername:
        - givenName
      bindDN: "CN=BindUser,OU=openshift,OU=cloud, DC=titamu, DC=com"
      bindPassword:
        name: ldap-secret
      insecure: true
      url: "ldap://10.0.95.91/ou=openshift,ou=cloud,dc=titamu,dc=com?userPrincipalName"
~~~

#### Group Sync
~~~
# cat active_directory_config.yaml
kind: LDAPSyncConfig
apiVersion: v1
url: ldap://10.0.95.91:389
bindDN: cn=BindUser,ou=openshift,ou=cloud, dc=titamu, dc=com
bindPassword: 'RedHat1!'
insecure: true
activeDirectory:
    usersQuery:
        baseDN: "ou=openshift,ou=cloud,dc=titamu,dc=com"
        scope: sub
        derefAliases: never
        filter: (objectClass=person)
        pageSize: 0
    userNameAttributes: [ sAMAccountName ] # <---- https://access.redhat.com/solutions/4338081
    groupMembershipAttributes: [ memberOf ]

# oc adm groups sync --sync-config=active_directory_config.yaml # This is dry-run

$ oc adm groups sync --sync-config=active_directory_config.yaml --confirm
group/CN=admin,OU=openshift,OU=cloud,DC=titamu,DC=com
group/CN=qe,OU=openshift,OU=cloud,DC=titamu,DC=com
group/CN=support,OU=openshift,OU=cloud,DC=titamu,DC=com

$ oc get group
NAME                                                USERS
CN=admin,OU=openshift,OU=cloud,DC=titamu,DC=com     yaoli, yhuang
CN=qe,OU=openshift,OU=cloud,DC=titamu,DC=com        wsun
CN=support,OU=openshift,OU=cloud,DC=titamu,DC=com   yaoli, yhuang

===================
Local Group Mapping
===================


# cat active_directory_config.yaml
kind: LDAPSyncConfig
apiVersion: v1
url: ldap://10.0.95.91:389
bindDN: cn=BindUser,ou=openshift,ou=cloud, dc=titamu, dc=com
bindPassword: 'RedHat1!'
insecure: true
activeDirectory:
    usersQuery:
        baseDN: "ou=openshift,ou=cloud,dc=titamu,dc=com"
        scope: sub
        derefAliases: never
        filter: (objectClass=person)
        pageSize: 0
    userNameAttributes: [ sAMAccountName ]
    groupMembershipAttributes: [ memberOf ]
groupUIDNameMapping:
    "CN=support,OU=openshift,OU=cloud,DC=titamu,DC=com": ocp_support

$ oc adm groups sync --sync-config=active_directory_config.yaml --confirm

$ oc get groups
NAME                                                USERS
CN=admin,OU=openshift,OU=cloud,DC=titamu,DC=com     yaoli, yhuang
CN=qe,OU=openshift,OU=cloud,DC=titamu,DC=com        wsun
CN=support,OU=openshift,OU=cloud,DC=titamu,DC=com   yaoli, yhuang
ocp_support                                         yaoli, yhuang  <--- Created automatically
~~~
