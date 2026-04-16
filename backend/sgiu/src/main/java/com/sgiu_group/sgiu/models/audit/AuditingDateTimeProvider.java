package com.sgiu_group.sgiu.models.audit;

import java.time.LocalDateTime;

public interface AuditingDateTimeProvider {
    LocalDateTime now();
}