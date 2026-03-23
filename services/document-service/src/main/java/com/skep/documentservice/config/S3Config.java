package com.skep.documentservice.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
public class S3Config {

    @Configuration
    @ConfigurationProperties(prefix = "aws.s3")
    @EnableConfigurationProperties
    public static class S3Properties {
        private String bucketName = "skep-documents";
        private String region = "ap-northeast-2";
        private String endpoint = "";
        private String accessKeyId = "";
        private String secretAccessKey = "";

        public String getBucketName() { return bucketName; }
        public void setBucketName(String v) { this.bucketName = v; }
        public String getRegion() { return region; }
        public void setRegion(String v) { this.region = v; }
        public String getEndpoint() { return endpoint; }
        public void setEndpoint(String v) { this.endpoint = v; }
        public String getAccessKeyId() { return accessKeyId; }
        public void setAccessKeyId(String v) { this.accessKeyId = v; }
        public String getSecretAccessKey() { return secretAccessKey; }
        public void setSecretAccessKey(String v) { this.secretAccessKey = v; }
    }
}
