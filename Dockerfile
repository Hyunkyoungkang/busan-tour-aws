FROM openjdk:17-oracle
ARG JAR_FILE_PATH=./project_DiB/build/libs/project_DiB-0.0.1-SNAPSHOT.jar
RUN  mkdir var/upload
COPY ${JAR_FILE_PATH} busan-tour.jar
ENTRYPOINT ["java", "-jar", "busan-tour.jar"]
