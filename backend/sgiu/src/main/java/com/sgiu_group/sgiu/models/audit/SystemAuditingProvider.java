package com.sgiu_group.sgiu.models.audit;

import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

@Component
public class SystemAuditingProvider implements AuditingDateTimeProvider {

    @Override
    public LocalDateTime now() {
        return LocalDateTime.now();
    }
}
