FROM jupyter/pyspark-notebook:latest
USER root

RUN apt-get update && \
    apt-get install -y procps curl && \
    rm -rf /var/lib/apt/lists/*

ENV SPARK_HOME=/usr/local/spark
ENV SPARK_JARS_DIR=${SPARK_HOME}/jars

# Versions that MATCH Spark 3.5.0
ENV HADOOP_AWS_VERSION=3.3.4
ENV AWS_SDK_BUNDLE_VERSION=1.11.1026
ENV ICEBERG_VERSION=1.4.2
ENV SPARK_SCALA_VERSION=2.12

# Add ONLY required jars
ADD https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_AWS_VERSION}/hadoop-aws-${HADOOP_AWS_VERSION}.jar ${SPARK_JARS_DIR}/
ADD https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/${AWS_SDK_BUNDLE_VERSION}/aws-java-sdk-bundle-${AWS_SDK_BUNDLE_VERSION}.jar ${SPARK_JARS_DIR}/
ADD https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.5_${SPARK_SCALA_VERSION}/${ICEBERG_VERSION}/iceberg-spark-runtime-3.5_${SPARK_SCALA_VERSION}-${ICEBERG_VERSION}.jar ${SPARK_JARS_DIR}/

RUN chmod 644 ${SPARK_JARS_DIR}/*.jar

# Spark config
RUN echo "spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
    echo "spark.sql.catalog.local=org.apache.iceberg.spark.SparkCatalog" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
    echo "spark.sql.catalog.local.type=hadoop" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
    echo "spark.sql.catalog.local.warehouse=s3a://local-datalake/warehouse" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
    echo "spark.hadoop.fs.s3a.endpoint=http://minio-service:9000" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
    echo "spark.hadoop.fs.s3a.path.style.access=true" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
    echo "spark.hadoop.fs.s3a.connection.ssl.enabled=false" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
    echo "spark.hadoop.fs.s3a.aws.credentials.provider=org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider" >> ${SPARK_HOME}/conf/spark-defaults.conf

USER jovyan
