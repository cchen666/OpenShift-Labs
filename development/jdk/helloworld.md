# OpenJDK Helloworld

## Build

1. Download a helloworld java source code

    ~~~bash
    $ git clone https://github.com/donschenck/path-to-kubernetes
    ~~~

2. Switch to the correct directory

    ~~~bash
    $ cd path-to-kubernetes/src/java/helloworld
    ~~~

3. Backup the Dockerfile and create a new one like following:

    ~~~bash
    $ mv Dockerfile Dockerfile.bak
    $ cp files/helloworld.dockerfile .

    ~~~

4. Build the Image and push it to Quay

    ~~~bash
    $ podman build -t quay.io/chenchen/jdk-helloworld:v1.0 .

    $ podman push quay.io/chenchen/jdk-helloworld:v1.0
    ~~~

## Create Pod in OpenShift

~~~bash
$ oc apply -f files/pod.yaml
~~~

## Verify

1. Check the Log and test the Java app is running

    ~~~bash
    $ oc logs java

    .   ____          _            __ _ _
    /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
    ( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
    \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
    '  |____| .__|_| |_|_| |_\__, | / / / /
    =========|_|==============|___/=/_/_/_/
    :: Spring Boot ::        (v2.1.2.RELEASE)

    2022-12-09 02:06:15.681  INFO 1 --- [           main] c.e.helloWorld.HelloWorldApplication     : Starting HelloWorldApplication v1.0.0 on java with PID 1 (/helloWorld.jar started by jboss in /home/jboss)
    2022-12-09 02:06:15.684  INFO 1 --- [           main] c.e.helloWorld.HelloWorldApplication     : No active profile set, falling back to default profiles: default
    2022-12-09 02:06:16.477  INFO 1 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat initialized with port(s): 3333 (http)
    2022-12-09 02:06:16.497  INFO 1 --- [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
    2022-12-09 02:06:16.497  INFO 1 --- [           main] org.apache.catalina.core.StandardEngine  : Starting Servlet engine: [Apache Tomcat/9.0.14]
    2022-12-09 02:06:16.506  INFO 1 --- [           main] o.a.catalina.core.AprLifecycleListener   : The APR based Apache Tomcat Native library which allows optimal performance in production environments was not found on the java.library.path: [/usr/java/packages/lib:/usr/lib64:/lib64:/lib:/usr/lib]
    2022-12-09 02:06:16.573  INFO 1 --- [           main] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext
    2022-12-09 02:06:16.573  INFO 1 --- [           main] o.s.web.context.ContextLoader            : Root WebApplicationContext: initialization completed in 854 ms
    2022-12-09 02:06:16.729  INFO 1 --- [           main] o.s.s.concurrent.ThreadPoolTaskExecutor  : Initializing ExecutorService 'applicationTaskExecutor'
    2022-12-09 02:06:16.866  INFO 1 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port(s): 3333 (http) with context path ''
    2022-12-09 02:06:16.869  INFO 1 --- [           main] c.e.helloWorld.HelloWorldApplication     : Started HelloWorldApplication in 1.461 seconds (JVM running for 1.69)
    2022-12-09 02:06:22.873  INFO 1 --- [nio-3333-exec-1] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring DispatcherServlet 'dispatcherServlet'
    2022-12-09 02:06:22.873  INFO 1 --- [nio-3333-exec-1] o.s.web.servlet.DispatcherServlet        : Initializing Servlet 'dispatcherServlet'
    2022-12-09 02:06:22.877  INFO 1 --- [nio-3333-exec-1] o.s.web.servlet.DispatcherServlet        : Completed initialization in 4 ms

    $ oc exec -it java -- curl localhost:3333
    Hello World!
    ~~~
