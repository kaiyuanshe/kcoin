## Deployment

1. Follow the dev guide to download certificates from cloud
2. create fabric folder and unzip certificates to it
3. replace `fabricAdminPrivateKeyFileName` value by certificates in Dockerfile
4. build image and run container:
  - docker build -t kcoin:0.1 .
  - docker run -ti -p 8080:8080 kcoin:0.1
5. quick validation that it works:
  - `curl -vvv http://localhost:8080/kcoin/user` which should respond "Hello Kcoin"
  - Test fabric API: `curl -vvv -H "Content-Type:application/json"  -X POST --data '{"fn":"balance", "args":["symbol","owner"]}' http://localhost:8080/kcoin/fabric/query`
6. logs can be found at `/var/logs/tomcat/kcoin-server.log`