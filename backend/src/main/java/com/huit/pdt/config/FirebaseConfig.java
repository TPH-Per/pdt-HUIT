// config/FirebaseConfig.java

package com.huit.pdt.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.IOException;
import java.io.InputStream;

@Slf4j
@Configuration
public class FirebaseConfig {

    @Bean
    @ConditionalOnProperty(name = "firebase.enabled", havingValue = "true")
    public FirebaseMessaging firebaseMessaging() throws IOException {
        if (FirebaseApp.getApps().isEmpty()) {
            InputStream serviceAccount = getClass().getClassLoader()
                .getResourceAsStream("firebase-service-account.json");

            if (serviceAccount == null) {
                log.warn("firebase-service-account.json not found. FCM notifications disabled.");
                return null;
            }

            FirebaseOptions options = FirebaseOptions.builder()
                .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                .build();

            FirebaseApp.initializeApp(options);
            log.info("Firebase initialized successfully");
        }

        return FirebaseMessaging.getInstance();
    }

    @Bean
    @ConditionalOnProperty(name = "firebase.enabled", havingValue = "false")
    public FirebaseMessaging firebaseMessagingDisabled() {
        log.warn("Firebase is disabled (firebase.enabled=false)");
        return null;
    }
}
