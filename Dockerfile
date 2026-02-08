FROM maxpain62/maven-3.9:jre11
ADD target/user-0.0.1-RELEASE.jar eos-user-api.jar
CMD ["java","-jar","eos-user-api.jar"]
