# Active Directory Integration

## Test AD connection command

~~~bash
$ ldapsearch -h 10.0.95.91 -b "dc=titamu,dc=com" -D "CN=Chen Chen, CN=Users, DC=titamu, DC=com" -w '<password>' -x
~~~

## Get AD's CA

<https://docs.microsoft.com/en-us/troubleshoot/windows-server/identity/export-root-certification-authority-certificate>

## Download a useful ldap browser

<https://mail.google.com/mail/u/0/#label/3_cee-info%2F002_pek-list>

## Create bind user's secret file

~~~bash
$ oc create secret generic ldap-secret --from-literal=bindPassword='<password>' -n openshift-config
~~~

## Create OAuth yaml file

~~~yaml

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

## Group Sync

~~~bash
$ cat << EOF > active_directory_config.yaml
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

EOF

$ oc adm groups sync --sync-config=active_directory_config.yaml # This is dry-run

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

$ cat active_directory_config.yaml
kind: LDAPSyncConfig
apiVersion: v1
url: ldap://10.0.95.91:389
bindDN: cn=BindUser,ou=openshift,ou=cloud, dc=titamu, dc=com
bindPassword: '<password>'
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

## AD subdomain configurations

Check this series of AD tutorials

<https://www.youtube.com/channel/UCWTAzBlHWOf17F8zN8HNJXg>

1. Setup a Root Forest with DNS

<https://www.youtube.com/watch?v=h3sxduUt5a8>
2. Setup another two ADs to connect to existing Forest

<https://www.youtube.com/watch?v=1vWSKLX0Xrk>
3. Configure Domain Trusts

<https://www.youtube.com/watch?v=Cud41sE2KHI>
4. Make sure DNS is correctly set
5. Static IP and disable IPv6
6. In Cloud env, make sure the SG allows traffic between these Ads
7. Group needs to be set universal
<https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2003/cc755692(v=ws.10)?redirectedfrom=MSDN>
<http://vcloud-lab.com/entries/active-directory/adding-user-to-administrators-from-another-cross-domain-part-1>

## AD Subdomains & Domain Trusts

【测试环境】

User:  CN=Chen Chen,OU=User-UAT,DC=uat,DC=mylab,DC=local
       CN=Yao Li,OU=User-UAT,DC=uat,DC=mylab,DC=local

Group: CN=ocp-users,OU=Groups,DC=bk,DC=mylab,DC=local

Global Catalog: $GC-IP:3268

ldapsearch 可以查询到 user cchen 属于 ocp-users 这个 group（memberOf 这一行），
但是 yaoli 没有 memberOf 这一行，即 yaoli 不属于 ocp-users 这个组

~~~bash
$ ldapsearch -h GC-IP -p 3268 -b "OU=user-uat,dc=uat,dc=mylab,dc=local" -D "CN=rootadmin,CN=Users,DC=mylab,DC=local" -w '<password>' -x

<Snip>

# Chen Chen, User-UAT, uat.mylab.local
dn: CN=Chen Chen,OU=User-UAT,DC=uat,DC=mylab,DC=local
cn: Chen Chen
sn: Chen
givenName: Chen
distinguishedName: CN=Chen Chen,OU=User-UAT,DC=uat,DC=mylab,DC=local
memberOf: CN=ocp-users,OU=Groups,DC=bk,DC=mylab,DC=local     <==================
sAMAccountName: cchen

<Snip>

# 尧帝没有 memberOf: CN=ocp-users,OU=Groups,DC=bk,DC=mylab,DC=local

# Yao Li, User-UAT, uat.mylab.local
dn: CN=Yao Li,OU=User-UAT,DC=uat,DC=mylab,DC=local
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: user
cn: Yao Li
sn: Li
givenName: Yao
distinguishedName: CN=Yao Li,OU=User-UAT,DC=uat,DC=mylab,DC=local
instanceType: 0
whenCreated: 20211114054319.0Z
whenChanged: 20211114054337.0Z
displayName: Yao Li
uSNCreated: 61235
uSNChanged: 61261
name: Yao Li
objectGUID:: 9hLU/W6K60aJQY82ZSp7OQ==
userAccountControl: 66048
primaryGroupID: 513
objectSid:: AQUAAAAAAAUVAAAADkV4DwmLnPT1K3t3WgQAAA==
sAMAccountName: yaoli
sAMAccountType: 805306368
userPrincipalName: yaoli@uat.mylab.local
objectCategory: CN=Person,CN=Schema,CN=Configuration,DC=mylab,DC=local
dSCorePropagationData: 16010101000000.0Z
lastLogonTimestamp: 132813422140541297
~~~

【1. Login 部分】

如果指定 url: ldap://$GC-IP:3268/dc=bk,dc=mylab,dc=local?sAMAccountName，cchen 是无法登陆的，因为 cchen 用户在 uat 域

~~~yaml
  identityProviders:
  - ldap:
      attributes:
        email:
        - mail
        id:
        - sAMAccountName
        name:
        - cn
        preferredUsername:
        - sAMAccountName
      bindDN: cn=rootadmin,cn=users,dc=mylab,dc=local
      bindPassword:
        name: ldap-secret
      insecure: true
      url: ldap://3.145.35.225:3268/dc=bk,dc=mylab,dc=local?sAMAccountName
    mappingMethod: claim
    name: ldapidp
    type: LDAP
~~~

~~~bash
$ oc login -u cchen -p 'RedHat1!'
Login failed (401 Unauthorized)
Verify you have provided correct credentials.

更改 ldap url 至 url: ldap://$GC-IP:3268/dc=uat,dc=mylab,dc=local?sAMAccountName，cchen 可以登陆

oc login -u cchen -p 'RedHat1!'
Login successful.

【2. Group Sync 部分】

$ cat sync.yaml

kind: LDAPSyncConfig
apiVersion: v1
url: ldap://$GC-IP:3268
bindDN: cn=rootadmin,CN=Users,DC=mylab,DC=local
bindPassword: <password>
insecure: true
augmentedActiveDirectory:
    groupsQuery:
        baseDN: "OU=Groups,dc=bk,dc=mylab,dc=local"
        scope: sub
        derefAliases: never
        pageSize: 0
    groupUIDAttribute: dn
    groupNameAttributes: [ cn ]
    usersQuery:
        baseDN: "ou=User-UAT,dc=uat,dc=mylab,dc=local"
        scope: sub
        derefAliases: never
        filter: (objectClass=person)
        pageSize: 0
    userNameAttributes: [ sAMAccountName ]
    groupMembershipAttributes: [ memberOf ]

$ oc adm groups sync --sync-config=sync.yaml --loglevel=6
I1114 15:17:25.204934   62203 loader.go:372] Config loaded from file:  ../kubeconfig
I1114 15:17:25.205760   62203 groupsyncer.go:58] Listing with &{0xc000b4b170 {{OU=Groups,dc=bk,dc=mylab,dc=local 2 0 0  0} dn} [cn] map[]}
I1114 15:17:25.656182   62203 query.go:232] searching LDAP server with config {Scheme: ldap Host: 3.145.35.225:3268 BindDN: cn=rootadmin,CN=Users,DC=mylab,DC=local len(BbindPassword): 8 Insecure: true} with dn="ou=User-UAT,dc=uat,dc=mylab,dc=local" and scope 2 for (objectClass=person) requesting [memberOf sAMAccountName]
I1114 15:17:25.974508   62203 query.go:249] found dn="CN=Chen Chen,OU=User-UAT,DC=uat,DC=mylab,DC=local"
I1114 15:17:25.974542   62203 query.go:249] found dn="CN=Yao Li,OU=User-UAT,DC=uat,DC=mylab,DC=local"
I1114 15:17:25.974621   62203 groupsyncer.go:64] Sync ldapGroupUIDs [CN=ocp-users,OU=Groups,DC=bk,DC=mylab,DC=local]
I1114 15:17:25.974643   62203 groupsyncer.go:67] Checking LDAP group CN=ocp-users,OU=Groups,DC=bk,DC=mylab,DC=local
I1114 15:17:25.974674   62203 groupsyncer.go:120] Found OpenShift username "cchen" for LDAP user for &{CN=Chen Chen,OU=User-UAT,DC=uat,DC=mylab,DC=local [0xc000e90000 0xc000e90040]}
I1114 15:17:25.974693   62203 groupsyncer.go:84] Has OpenShift users [cchen]
I1114 15:17:26.415307   62203 query.go:232] searching LDAP server with config {Scheme: ldap Host: 3.145.35.225:3268 BindDN: cn=rootadmin,CN=Users,DC=mylab,DC=local len(BbindPassword): 8 Insecure: true} with dn="CN=ocp-users,OU=Groups,DC=bk,DC=mylab,DC=local" and scope 0 for (objectClass=*) requesting [cn dn]
I1114 15:17:26.635748   62203 query.go:249] found dn="CN=ocp-users,OU=Groups,DC=bk,DC=mylab,DC=local"
I1114 15:17:26.635855   62203 query.go:198] found dn="CN=ocp-users,OU=Groups,DC=bk,DC=mylab,DC=local" for (objectClass=*)
I1114 15:17:27.504879   62203 round_trippers.go:454] GET https://api.mycluster.nancyge.com:6443/apis/user.openshift.io/v1/groups/ocp-users 200 OK in 868 milliseconds
apiVersion: user.openshift.io/v1
items:
- metadata:
    creationTimestamp: null
  users: null
- apiVersion: user.openshift.io/v1
  kind: Group
  metadata:
    annotations:
      openshift.io/ldap.sync-time: 2021-11-14T15:17:2700800
      openshift.io/ldap.uid: CN=ocp-users,OU=Groups,DC=bk,DC=mylab,DC=local
      openshift.io/ldap.url: 3.145.35.225:3268
    creationTimestamp: "2021-11-14T05:42:01Z"
    labels:
      openshift.io/ldap.host: 3.145.35.225
    name: ocp-users
    resourceVersion: "5258648"
    uid: 094c195e-3162-4c84-8681-1782760332c1
  users:
  - cchen
kind: GroupList

$ oc adm groups sync --sync-config=sync.yaml --confirm
group/ocp-users

可以看到 group sync 的结果，cchen 被加入到了 ocp-users 组里

$ oc get group

NAME          USERS
ocp-users     cchen
~~~

【3. 限制特定 group 人员登陆】

~~~bash
url: ldap://$GC-IP:3268/dc=uat,dc=mylab,dc=local?sAMAccountName，尧帝是可以登陆的

$ oc login -u yaoli -p <password>

Login successful.

更改 ldap url 为

url: ldap://$GC-IP:3268/dc=uat,dc=mylab,dc=local?sAMAccountName?sub?(&(objectclass=*)(|(memberOf=CN=ocp-users,OU=Groups,DC=bk,DC=mylab,DC=local)))

cchen 仍然可以登陆因为 cchen 属于 ocp-users 组，但是 yaoli 无法登陆

$ oc login -u cchen -p '<password>'
Login successful.

$ oc login -u yaoli -p <password>

Login failed (401 Unauthorized)
Verify you have provided correct credentials.
~~~

【4. 注意点】

变更 OAuth Cluster CR 之后一定要观察 oc get co | grep auth，有一个 Progressing 的过程。如果没有，强制重启 oauth PODs。

~~~bash
$ oc delete pods -l app=oauth-openshift
~~~
