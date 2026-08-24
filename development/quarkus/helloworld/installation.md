# Installation

## Install maven

```bash
$ dnf install maven
```

## Intialize the project

```bash
$ mvn io.quarkus.platform:quarkus-maven-plugin:3.38.2:create \
    -DprojectGroupId=org.acme \
    -DprojectArtifactId=getting-started \
    -Dextensions='rest'
cd getting-started


[SUCCESS] ✅  quarkus project has been successfully generated in:
--> /root/getting-started
-----------
[INFO]
[INFO] ========================================================================================
[INFO] Your new application has been created in /root/getting-started
[INFO]
[INFO]
[INFO] ========================================================================================
[INFO]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  23.692 s
[INFO] Finished at: 2026-08-18T03:21:55-04:00
[INFO] ------------------------------------------------------------------------
```

## Build in dev mode

```
$ mvn wrapper:wrapper
$ ./mvnw quarkus:dev -Dquarkus.http.host=0.0.0.0
__  ____  __  _____   ___  __ ____  ______
 --/ __ \/ / / / _ | / _ \/ //_/ / / / __/
 -/ /_/ / /_/ / __ |/ , _/ ,< / /_/ /\ \
--\___\_\____/_/ |_/_/|_/_/|_|\____/___/
2026-08-18 04:00:32,340 INFO  [io.quarkus] (Quarkus Main Thread) getting-started 1.0.0-SNAPSHOT on JVM (powered by Quarkus 3.38.2) started in 4.275s. Listening on: http://0.0.0.0:8080
```

## Test

```
$ curl XXXX:8080/hello
Hello from Quarkus REST%
$ curl XXXX:8080/hello/greeting/1234
hello 1234%
$ curl XXXX:8080/hello/greeting/

404 - Resource Not Found
------------------------

Resource Endpoints
	- /hello
		- GET (produces:text/plain;charset=UTF-8)
	- /hello/greeting/{name}
		- GET (produces:text/plain;charset=UTF-8)

Additional endpoints
	- http://0.0.0.0:8080/q/arc
		- CDI Overview
	- http://0.0.0.0:8080/q/arc/beans
		- Active CDI Beans
	- http://0.0.0.0:8080/q/arc/observers
		- Active CDI Observers
	- http://0.0.0.0:8080/q/arc/removed-beans
		- Removed CDI Beans
	- http://0.0.0.0:8080/q/dev-ui
		- Dev UI

```

