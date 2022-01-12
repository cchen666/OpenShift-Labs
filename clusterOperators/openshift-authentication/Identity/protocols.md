# LDAP Protocols

## activeDirectory

The Active Directory schema requires you to provide an LDAP query definition for user entries, as well as the attributes to represent them with in the internal OpenShift Container Platform group records.

Lookup users first and then use "memberOf" to look for groups.

~~~yaml

kind: LDAPSyncConfig
apiVersion: v1
url: ldap://<IP>:3268
bindDN: cn=rootadmin,CN=Users,DC=mylab,DC=local
bindPassword: <Password>
insecure: true
activeDirectory:
    usersQuery:
        baseDN: "OU=User-UAT,DC=uat,DC=mylab,DC=local"
        scope: sub
        derefAliases: never
        filter: (objectClass=person)
        pageSize: 0
    userNameAttributes: [ sAMAccountName ]
    groupMembershipAttributes: [ memberOf ]

~~~

~~~bash

$ oc adm groups sync --sync-config=adsync.yaml --loglevel=6

I0110 14:15:19.837646   87334 loader.go:372] Config loaded from file:  /Users/cchen/.kube/config
I0110 14:15:19.838228   87334 groupsyncer.go:58] Listing with &{0xc0000a4730 {OU=User-UAT,DC=uat,DC=mylab,DC=local 2 0 0 (objectClass=person) 0} [memberOf] [sAMAccountName] false map[]}
I0110 14:15:20.289521   87334 query.go:232] searching LDAP server with config {Scheme: ldap Host: 3.145.35.225:3268 BindDN: cn=rootadmin,CN=Users,DC=mylab,DC=local len(BbindPassword): 8 Insecure: true} with dn="OU=User-UAT,DC=uat,DC=mylab,DC=local" and scope 2 for (objectClass=person) requesting [memberOf sAMAccountName]
I0110 14:15:20.507156   87334 query.go:249] found dn="CN=Chen Chen,OU=User-UAT,DC=uat,DC=mylab,DC=local"
I0110 14:15:20.507188   87334 query.go:249] found dn="CN=Yao Li,OU=User-UAT,DC=uat,DC=mylab,DC=local"
I0110 14:15:20.507195   87334 query.go:249] found dn="CN=Ying Huang,OU=User-UAT,DC=uat,DC=mylab,DC=local"
I0110 14:15:20.507278   87334 groupsyncer.go:64] Sync ldapGroupUIDs [CN=ocp-users,OU=Groups,DC=bk,DC=mylab,DC=local CN=support,OU=Groups,DC=bk,DC=mylab,DC=local]
I0110 14:15:20.507293   87334 groupsyncer.go:67] Checking LDAP group CN=ocp-users,OU=Groups,DC=bk,DC=mylab,DC=local
I0110 14:15:20.507310   87334 groupsyncer.go:120] Found OpenShift username "cchen" for LDAP user for &{CN=Chen Chen,OU=User-UAT,DC=uat,DC=mylab,DC=local [0xc000d64000 0xc000d64040]}
I0110 14:15:20.507332   87334 groupsyncer.go:84] Has OpenShift users [cchen]
I0110 14:15:21.469792   87334 round_trippers.go:454] GET https://api.mycluster.nancyge.com:6443/apis/user.openshift.io/v1/groups/CN=ocp-users,OU=Groups,DC=bk,DC=mylab,DC=local 404 Not Found in 962 milliseconds
I0110 14:15:21.470369   87334 groupsyncer.go:67] Checking LDAP group CN=support,OU=Groups,DC=bk,DC=mylab,DC=local
I0110 14:15:21.470388   87334 groupsyncer.go:120] Found OpenShift username "yhuang" for LDAP user for &{CN=Ying Huang,OU=User-UAT,DC=uat,DC=mylab,DC=local [0xc000d640c0 0xc000d64100]}
I0110 14:15:21.470406   87334 groupsyncer.go:84] Has OpenShift users [yhuang]
I0110 14:15:21.730069   87334 round_trippers.go:454] GET https://api.mycluster.nancyge.com:6443/apis/user.openshift.io/v1/groups/CN=support,OU=Groups,DC=bk,DC=mylab,DC=local 404 Not Found in 259 milliseconds

~~~

## RFC2307

The RFC 2307 schema requires you to provide an LDAP query definition for both user and group entries, as well as the attributes with which to represent them in the internal OpenShift Container Platform records.

RFC 2307 will first lookup the groups and then use `member` attribute to find out users.

~~~yaml

kind: LDAPSyncConfig
apiVersion: v1
url: ldap://<IP>:3268
bindDN: cn=rootadmin,CN=Users,DC=mylab,DC=local
bindPassword: <Password>
insecure: true
rfc2307:
    groupsQuery:
        baseDN: "OU=Groups,DC=bk,DC=mylab,DC=local"
        scope: sub
        derefAliases: never
        pageSize: 0
        filter: (|(cn=support)(cn=ocp-users))
    groupUIDAttribute: dn
    groupNameAttributes: [ cn ]
    groupMembershipAttributes: [ member ]
    usersQuery:
        baseDN: "OU=User-UAT,DC=uat,DC=mylab,DC=local"
        scope: sub
        derefAliases: never
        pageSize: 0
    userNameAttributes: [ sAMAccountName ]
    userUIDAttribute: dn
    tolerateMemberNotFoundErrors: true
    tolerateMemberOutOfScopeErrors: true
~~~

~~~bash

$ oc adm groups sync --sync-config=rfc2307.yaml --loglevel=6

I0110 14:10:55.054072   87291 loader.go:372] Config loaded from file:  /Users/cchen/.kube/config
I0110 14:10:55.054663   87291 groupsyncer.go:58] Listing with &{0xc000924140 {{OU=Groups,DC=bk,DC=mylab,DC=local 2 0 0 (|(cn=support)(cn=ocp-users)) 0} dn} [cn] [member] {{OU=User-UAT,DC=uat,DC=mylab,DC=local 2 0 0  0} dn} [sAMAccountName] map[] map[] 0xc000d71020}
I0110 14:10:55.486944   87291 query.go:232] searching LDAP server with config {Scheme: ldap Host: 3.145.35.225:3268 BindDN: cn=rootadmin,CN=Users,DC=mylab,DC=local len(BbindPassword): 8 Insecure: true} with dn="OU=Groups,DC=bk,DC=mylab,DC=local" and scope 2 for (|(cn=support)(cn=ocp-users)) requesting [cn dn member]
I0110 14:10:55.704049   87291 query.go:249] found dn="CN=support,OU=Groups,DC=bk,DC=mylab,DC=local"
I0110 14:10:55.704092   87291 query.go:249] found dn="CN=ocp-users,OU=Groups,DC=bk,DC=mylab,DC=local"
I0110 14:10:55.704189   87291 groupsyncer.go:64] Sync ldapGroupUIDs [CN=support,OU=Groups,DC=bk,DC=mylab,DC=local CN=ocp-users,OU=Groups,DC=bk,DC=mylab,DC=local]
I0110 14:10:55.704213   87291 groupsyncer.go:67] Checking LDAP group CN=support,OU=Groups,DC=bk,DC=mylab,DC=local
I0110 14:10:56.148971   87291 query.go:232] searching LDAP server with config {Scheme: ldap Host: 3.145.35.225:3268 BindDN: cn=rootadmin,CN=Users,DC=mylab,DC=local len(BbindPassword): 8 Insecure: true} with dn="CN=Ying Huang,OU=User-UAT,DC=uat,DC=mylab,DC=local" and scope 0 for (objectClass=*) requesting [dn sAMAccountName]
I0110 14:10:56.364841   87291 query.go:249] found dn="CN=Ying Huang,OU=User-UAT,DC=uat,DC=mylab,DC=local"
I0110 14:10:56.364985   87291 query.go:198] found dn="CN=Ying Huang,OU=User-UAT,DC=uat,DC=mylab,DC=local" for (objectClass=*)
I0110 14:10:56.365026   87291 groupsyncer.go:120] Found OpenShift username "yhuang" for LDAP user for &{CN=Ying Huang,OU=User-UAT,DC=uat,DC=mylab,DC=local [0xc000a34100]}
I0110 14:10:56.365071   87291 groupsyncer.go:84] Has OpenShift users [yhuang]
I0110 14:10:57.204396   87291 round_trippers.go:454] GET https://api.mycluster.nancyge.com:6443/apis/user.openshift.io/v1/groups/support 404 Not Found in 838 milliseconds
I0110 14:10:57.204964   87291 groupsyncer.go:67] Checking LDAP group CN=ocp-users,OU=Groups,DC=bk,DC=mylab,DC=local
I0110 14:10:57.684406   87291 query.go:232] searching LDAP server with config {Scheme: ldap Host: 3.145.35.225:3268 BindDN: cn=rootadmin,CN=Users,DC=mylab,DC=local len(BbindPassword): 8 Insecure: true} with dn="CN=Chen Chen,OU=User-UAT,DC=uat,DC=mylab,DC=local" and scope 0 for (objectClass=*) requesting [dn sAMAccountName]
I0110 14:10:57.900550   87291 query.go:249] found dn="CN=Chen Chen,OU=User-UAT,DC=uat,DC=mylab,DC=local"
I0110 14:10:57.900690   87291 query.go:198] found dn="CN=Chen Chen,OU=User-UAT,DC=uat,DC=mylab,DC=local" for (objectClass=*)
I0110 14:10:57.900756   87291 ldapinterface.go:100] membership lookup for user "CN=ocp-users,OU=Groups,DC=bk,DC=mylab,DC=local" in group "CN=Read-only Domain Controllers,CN=Users,DC=uat,DC=mylab,DC=local" skipped because of "search for entry with dn=\"CN=Read-only Domain Controllers,CN=Users,DC=uat,DC=mylab,DC=local\" would search outside of the base dn specified (dn=\"OU=User-UAT,DC=uat,DC=mylab,DC=local\")"
I0110 14:10:57.900790   87291 groupsyncer.go:120] Found OpenShift username "cchen" for LDAP user for &{CN=Chen Chen,OU=User-UAT,DC=uat,DC=mylab,DC=local [0xc000cc2000]}
I0110 14:10:57.900844   87291 groupsyncer.go:84] Has OpenShift users [cchen]
I0110 14:10:58.143453   87291 round_trippers.go:454] GET https://api.mycluster.nancyge.com:6443/apis/user.openshift.io/v1/groups/ocp-users 404 Not Found in 242 milliseconds
~~~

## AugmentedActiveDirectory

The augmented Active Directory schema requires you to provide an LDAP query definition for both user entries and group entries, as well as the attributes with which to represent them in the internal OpenShift Container Platform group records.

Lookup users first and then use `memberOf` attribute to look for groups.

~~~yaml

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

~~~

~~~bash

$ oc adm groups sync --sync-config=augmentedad.yaml --loglevel=6

I0110 14:18:33.434099   87379 loader.go:372] Config loaded from file:  /Users/cchen/.kube/config
I0110 14:18:33.435267   87379 groupsyncer.go:58] Listing with &{0xc000a8ef30 {{OU=Groups,dc=bk,dc=mylab,dc=local 2 0 0  0} dn} [cn] map[]}
I0110 14:18:33.872698   87379 query.go:232] searching LDAP server with config {Scheme: ldap Host: 3.145.35.225:3268 BindDN: cn=rootadmin,CN=Users,DC=mylab,DC=local len(BbindPassword): 8 Insecure: true} with dn="ou=User-UAT,dc=uat,dc=mylab,dc=local" and scope 2 for (objectClass=person) requesting [memberOf sAMAccountName]
I0110 14:18:34.091476   87379 query.go:249] found dn="CN=Chen Chen,OU=User-UAT,DC=uat,DC=mylab,DC=local"
I0110 14:18:34.091520   87379 query.go:249] found dn="CN=Yao Li,OU=User-UAT,DC=uat,DC=mylab,DC=local"
I0110 14:18:34.091528   87379 query.go:249] found dn="CN=Ying Huang,OU=User-UAT,DC=uat,DC=mylab,DC=local"
I0110 14:18:34.091622   87379 groupsyncer.go:64] Sync ldapGroupUIDs [CN=ocp-users,OU=Groups,DC=bk,DC=mylab,DC=local CN=support,OU=Groups,DC=bk,DC=mylab,DC=local]
I0110 14:18:34.091636   87379 groupsyncer.go:67] Checking LDAP group CN=ocp-users,OU=Groups,DC=bk,DC=mylab,DC=local
I0110 14:18:34.091656   87379 groupsyncer.go:120] Found OpenShift username "cchen" for LDAP user for &{CN=Chen Chen,OU=User-UAT,DC=uat,DC=mylab,DC=local [0xc000b40000 0xc000b40040]}
I0110 14:18:34.091683   87379 groupsyncer.go:84] Has OpenShift users [cchen]
I0110 14:18:34.525990   87379 query.go:232] searching LDAP server with config {Scheme: ldap Host: 3.145.35.225:3268 BindDN: cn=rootadmin,CN=Users,DC=mylab,DC=local len(BbindPassword): 8 Insecure: true} with dn="CN=ocp-users,OU=Groups,DC=bk,DC=mylab,DC=local" and scope 0 for (objectClass=*) requesting [cn dn]
I0110 14:18:34.742260   87379 query.go:249] found dn="CN=ocp-users,OU=Groups,DC=bk,DC=mylab,DC=local"
I0110 14:18:34.742413   87379 query.go:198] found dn="CN=ocp-users,OU=Groups,DC=bk,DC=mylab,DC=local" for (objectClass=*)
I0110 14:18:35.656572   87379 round_trippers.go:454] GET https://api.mycluster.nancyge.com:6443/apis/user.openshift.io/v1/groups/ocp-users 404 Not Found in 912 milliseconds
I0110 14:18:35.657728   87379 groupsyncer.go:67] Checking LDAP group CN=support,OU=Groups,DC=bk,DC=mylab,DC=local
I0110 14:18:35.657762   87379 groupsyncer.go:120] Found OpenShift username "yhuang" for LDAP user for &{CN=Ying Huang,OU=User-UAT,DC=uat,DC=mylab,DC=local [0xc0009b8040 0xc0009b8080]}
I0110 14:18:35.657807   87379 groupsyncer.go:84] Has OpenShift users [yhuang]
I0110 14:18:36.090719   87379 query.go:232] searching LDAP server with config {Scheme: ldap Host: 3.145.35.225:3268 BindDN: cn=rootadmin,CN=Users,DC=mylab,DC=local len(BbindPassword): 8 Insecure: true} with dn="CN=support,OU=Groups,DC=bk,DC=mylab,DC=local" and scope 0 for (objectClass=*) requesting [cn dn]
I0110 14:18:36.305887   87379 query.go:249] found dn="CN=support,OU=Groups,DC=bk,DC=mylab,DC=local"
I0110 14:18:36.306021   87379 query.go:198] found dn="CN=support,OU=Groups,DC=bk,DC=mylab,DC=local" for (objectClass=*)
I0110 14:18:36.558650   87379 round_trippers.go:454] GET https://api.mycluster.nancyge.com:6443/apis/user.openshift.io/v1/groups/support 404 Not Found in 252 milliseconds

~~~