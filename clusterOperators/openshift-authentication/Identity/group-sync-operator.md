# group-sync-operator

## Create Secret

~~~bash
$ oc create secret generic ldap-group-sync --from-literal=username='uid=binduser,cn=users,cn=accounts,dc=mycluster,dc=nancyge,dc=com' --from-literal=password='<password>'
~~~

## Create GroupSync CR

~~~bash

apiVersion: redhatcop.redhat.io/v1alpha1
kind: GroupSync
metadata:
  name: ldap-groupsync
spec:
  providers:
  - ldap:
      credentialsSecret:
        name: ldap-group-sync
        namespace: group-sync-operator
      insecure: true
      rfc2307:
        groupMembershipAttributes:
        - memberOf
        groupNameAttributes:
        - cn
        groupUIDAttribute: dn
        groupsQuery:
          baseDN: dc=mycluster,dc=nancyge,dc=com
          derefAliases: never
          filter: (objectClass=groupofnames)
          scope: sub
        tolerateMemberNotFoundErrors: true
        tolerateMemberOutOfScopeErrors: true
        userNameAttributes:
        - uid
        userUIDAttribute: dn
        usersQuery:
          baseDN: "cn=users,cn=accounts,dc=mycluster,dc=nancyge,dc=com"
          derefAliases: never
          scope: sub
      url: ldap://18.117.72.87:389
    name: ldap

$ oc apply -f 

~~~

## Check the logs

~~~bash

$ oc logs -c manager group-sync-operator-controller-manager-74fb99df47-wz59t -n group-sync-operator

2021-10-19T13:54:38.441Z INFO controllers.GroupSync Sync Completed Successfully {"groupsync": "group-sync-operator/ldap-groupsync", "Provider": "ldap", "Groups Created or Updated": 7}
~~~
