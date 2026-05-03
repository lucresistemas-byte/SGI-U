package com.sgiu_group.sgiu.models.audit;

import java.time.LocalDateTime;

public class FixedAuditingProvider implements AuditingDateTimeProvider {

    @Override
    public LocalDateTime now() {
        return LocalDateTime.of(2026, 1, 1, 0, 0);
    }
}
