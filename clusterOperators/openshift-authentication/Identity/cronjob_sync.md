# Cronjob Sync

## Create SA

~~~bash
cat << EOF > sa.yaml
kind: ServiceAccount
apiVersion: v1
metadata:
  name: ldap-group-syncer
  namespace: openshift-authentication
  labels:
    app: cronjob-ldap-group-sync

EOF
~~~

~~~bash
cat << EOF > cr.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: ldap-group-syncer
  labels:
    app: cronjob-ldap-group-sync
rules:
  - apiGroups:
      - ''
      - user.openshift.io
    resources:
      - groups
    verbs:
      - get
      - list
      - create
      - update

EOF
~~~

~~~bash
cat << EOF > crb.yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ldap-group-syncer
  labels:
    app: cronjob-ldap-group-sync
subjects:
  - kind: ServiceAccount
    name: ldap-group-syncer
    namespace: openshift-authentication
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: ldap-group-syncer

EOF
~~~

## Create ConfigMap

~~~bash
cat << EOF > cm_syncer.yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: ldap-group-syncer
  namespace: openshift-authentication
  labels:
    app: cronjob-ldap-group-sync
data:
  ldap-group-sync.yaml: |
    kind: LDAPSyncConfig
    apiVersion: v1
    url: ldap://18.117.72.87:389
    bindDN: uid=binduser,cn=users,cn=accounts,dc=mycluster,dc=nancyge,dc=com
    bindPassword:
      file: "/etc/secrets/bindPassword"
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
cat << EOF > cm_whitelist.yaml

kind: ConfigMap
apiVersion: v1
metadata:
  name: ldap-group-syncer-whitelist
  namespace: openshift-authentication
  labels:
    app: cronjob-ldap-group-sync
data:
  whitelist.txt: |
    cn=ocp_support,cn=groups,cn=accounts,dc=mycluster,dc=nancyge,dc=com
    cn=ocp_admin,cn=groups,cn=accounts,dc=mycluster,dc=nancyge,dc=com
    cn=ocp_users,cn=groups,cn=accounts,dc=mycluster,dc=nancyge,dc=com
EOF
~~~

## Create CronJob

~~~bash
cat << EOF > cronjob.yaml

kind: CronJob
apiVersion: batch/v1beta1
metadata:
  name: ldap-group-syncer
  namespace: openshift-authentication
  labels:
    app: cronjob-ldap-group-sync
spec:
  schedule: "*/1 * * * *"
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 5
  failedJobsHistoryLimit: 5
  jobTemplate:
    metadata:
      labels:
        app: cronjob-ldap-group-sync
    spec:
      backoffLimit: 0
      template:
        metadata:
          labels:
            app: cronjob-ldap-group-sync
        spec:
          containers:
            - name: ldap-group-sync
              image: "registry.redhat.io/openshift4/ose-cli:v4.8"
              command:
                - "/bin/bash"
                - "-c"
                - oc adm groups sync --whitelist=/etc/whitelist/whitelist.txt --sync-config=/etc/config/ldap-group-sync.yaml --confirm
              volumeMounts:
                - mountPath: "/etc/config"
                  name: "ldap-sync-volume"
                - mountPath: "/etc/whitelist"
                  name: "ldap-sync-volume-whitelist"
                - mountPath: "/etc/secrets"
                  name: "ldap-bind-password"
          volumes:
            - name: "ldap-sync-volume"
              configMap:
                name: "ldap-group-syncer"
            - name: "ldap-sync-volume-whitelist"
              configMap:
                name: "ldap-group-syncer-whitelist"
            - name: "ldap-bind-password"
              secret:
                secretName: "v4-0-config-user-idp-0-bind-password"
          restartPolicy: "Never"
          terminationGracePeriodSeconds: 30
          activeDeadlineSeconds: 500
          dnsPolicy: "ClusterFirst"
          serviceAccountName: "ldap-group-syncer"
          serviceAccount: "ldap-group-syncer"
EOF
~~~
