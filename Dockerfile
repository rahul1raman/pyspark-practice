FROM jupyter/pyspark-notebook:latest
USER root

# Install required system dependencies
RUN apt-get update && \
    apt-get install -y procps curl && \
    rm -rf /var/lib/apt/lists/*

# Set versions
ENV HADOOP_VERSION=3.3.4
ENV ICEBERG_VERSION=1.4.2
ENV SPARK_SCALA_VERSION=2.12
ENV AWS_SDK_BUNDLE_VERSION=1.11.1026
ENV SPARK_HOME=/usr/local/spark
ENV SPARK_JARS_DIR=${SPARK_HOME}/jars

# AWS Credentials (MinIO Access)
ENV AWS_ACCESS_KEY_ID=fakesecret
ENV AWS_SECRET_ACCESS_KEY=fakesecret
ENV AWS_REGION=us-east-1

# Copy the Hadoop distribution, Iceberg JAR, and AWS SDK Bundle
COPY downloads/hadoop-${HADOOP_VERSION}.tar.gz /tmp/
COPY downloads/iceberg-spark-runtime-3.4_${SPARK_SCALA_VERSION}-${ICEBERG_VERSION}.jar ${SPARK_JARS_DIR}/
COPY downloads/aws-java-sdk-bundle-${AWS_SDK_BUNDLE_VERSION}.jar ${SPARK_JARS_DIR}/

# Extract Hadoop and copy relevant JARs to Spark classpath
RUN tar -xzf /tmp/hadoop-${HADOOP_VERSION}.tar.gz -C /tmp && \
    # Copy Hadoop common JARs
    cp /tmp/hadoop-${HADOOP_VERSION}/share/hadoop/common/lib/*.jar ${SPARK_JARS_DIR}/ && \
    cp /tmp/hadoop-${HADOOP_VERSION}/share/hadoop/common/*.jar ${SPARK_JARS_DIR}/ && \
    # Copy HDFS JARs
    cp /tmp/hadoop-${HADOOP_VERSION}/share/hadoop/hdfs/lib/*.jar ${SPARK_JARS_DIR}/ && \
    cp /tmp/hadoop-${HADOOP_VERSION}/share/hadoop/hdfs/*.jar ${SPARK_JARS_DIR}/ && \
    # Copy MapReduce JARs - with directory checks
    if [ -d "/tmp/hadoop-${HADOOP_VERSION}/share/hadoop/mapreduce/lib" ]; then \
      cp /tmp/hadoop-${HADOOP_VERSION}/share/hadoop/mapreduce/lib/*.jar ${SPARK_JARS_DIR}/ || true; \
    fi && \
    cp /tmp/hadoop-${HADOOP_VERSION}/share/hadoop/mapreduce/*.jar ${SPARK_JARS_DIR}/ && \
    # Copy YARN JARs - with directory checks
    if [ -d "/tmp/hadoop-${HADOOP_VERSION}/share/hadoop/yarn/lib" ]; then \
      cp /tmp/hadoop-${HADOOP_VERSION}/share/hadoop/yarn/lib/*.jar ${SPARK_JARS_DIR}/ || true; \
    fi && \
    cp /tmp/hadoop-${HADOOP_VERSION}/share/hadoop/yarn/*.jar ${SPARK_JARS_DIR}/ && \
    # Copy AWS S3 support JARs
    mkdir -p /tmp/hadoop-tools && \
    tar -xzf /tmp/hadoop-${HADOOP_VERSION}.tar.gz -C /tmp/hadoop-tools hadoop-${HADOOP_VERSION}/share/hadoop/tools --strip-components=1 && \
    find /tmp/hadoop-tools -name "hadoop-aws-${HADOOP_VERSION}.jar" -exec cp {} ${SPARK_JARS_DIR}/ \; && \
    # Clean up
    rm -rf /tmp/hadoop-${HADOOP_VERSION} /tmp/hadoop-${HADOOP_VERSION}.tar.gz /tmp/hadoop-tools

# Install PyIceberg (for Python Iceberg interaction)
RUN pip install pyiceberg==0.6.0 pandas==2.0.0

# Set proper permissions
RUN chmod 644 ${SPARK_JARS_DIR}/*.jar && mkdir -p /opt/spark/logs && chmod 777 /opt/spark/logs

# Configure Spark defaults for Iceberg + MinIO
RUN echo "spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
    echo "spark.hadoop.fs.s3a.access.key=fakesecret" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
    echo "spark.hadoop.fs.s3a.secret.key=fakesecret" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
    echo "spark.hadoop.fs.s3a.endpoint=http://minio-service:9000" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
    echo "spark.hadoop.fs.s3a.path.style.access=true" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
    echo "spark.hadoop.fs.s3a.connection.ssl.enabled=false" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
    echo "spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
    echo "spark.hadoop.fs.s3a.aws.credentials.provider=org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
    echo "spark.sql.catalog.local=org.apache.iceberg.spark.SparkCatalog" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
    echo "spark.sql.catalog.local.type=hadoop" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
    echo "spark.sql.catalog.local.warehouse=s3a://local-datalake/warehouse" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
    echo "spark.hadoop.fs.s3a.impl.disable.cache=true" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
    echo "spark.hadoop.fs.s3a.connection.establish.timeout=5000" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
    echo "spark.hadoop.fs.s3a.attempts.maximum=20" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
    echo "spark.hadoop.fs.s3a.connection.timeout=10000" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
    echo "spark.hadoop.fs.s3a.multipart.size=5242880" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
    echo "spark.hadoop.fs.s3a.acl.default=PublicReadWrite" >> ${SPARK_HOME}/conf/spark-defaults.conf

# Expose necessary ports
EXPOSE 7077 8080 4040 8888

# Change back to jovyan user
USER jovyan

# Entrypoint to start Spark Master, Worker, and Jupyter Notebook
CMD /usr/local/spark/sbin/start-master.sh && \
    /usr/local/spark/sbin/start-worker.sh spark://localhost:7077 && \
    start-notebook.sh --NotebookApp.token='' --NotebookApp.password=''