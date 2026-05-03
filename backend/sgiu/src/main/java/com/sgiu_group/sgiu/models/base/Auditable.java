package com.sgiu_group.sgiu.models.base;

import java.time.LocalDateTime;

// Responsabilidad 2: ser auditable

public interface Auditable {
    LocalDateTime getCreatedAt();
    LocalDateTime getUpdatedAt();
}
