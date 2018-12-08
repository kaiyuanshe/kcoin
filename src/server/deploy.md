## Deployment

1. Follow the dev guide to download certificates from cloud
2. package
  - In Intellij IDEA, Build -> Build Artifacts -> Edit:
    - Add 3rd party libraries to WEB-INF/lib
    - Add kcoin output in classes
    - Add Directory content for /src/main/webapp
  - Build Artifacts
3. upload package to server /usr/share/tomcat/webapps
4. restart tomcat `service tomcat restart`
5. quick validation that it works:
  - `curl -vvv http://localhost:8080/kcoin/user` which should respond "Hello Kcoin"
  - Test fabric API: `curl -vvv -H "Content-Type:application/json"  -X POST --data '{"fn":"balance", "args":["symbol","owner"]}' http://localhost:8080/kcoin/fabric/query`
6. logs can be found at `/var/logs/tomcat/kcoin-server.log`