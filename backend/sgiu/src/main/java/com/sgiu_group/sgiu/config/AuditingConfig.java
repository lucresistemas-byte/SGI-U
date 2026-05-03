package com.sgiu_group.sgiu.config;

import com.sgiu_group.sgiu.models.audit.AuditingDateTimeProvider;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.auditing.DateTimeProvider;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

import java.util.Optional;

@Configuration
@EnableJpaAuditing(dateTimeProviderRef = "auditingDateTimeProvider")
public class AuditingConfig {

    @Bean
    public DateTimeProvider auditingDateTimeProvider(AuditingDateTimeProvider provider) {
        return () -> Optional.of(provider.now());
    }
}
