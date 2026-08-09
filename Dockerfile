FROM eclipse-temurin:21-jre
ADD target/*.jar app.jar 
ENTRYPOINT [ "java", "-jar", "/app.jar" ]
