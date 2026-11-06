package com.sgiu_group.sgiu.models.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO que representa el estado de salud de los respaldos de la base de datos (R-11).
 * Consumido por el Shell del Frontend (H-SHELL-05) para renderizar el banner de estado.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BackupEstadoDTO {

    /**
     * Estado semántico para el banner en UI: "AL_DIA", "DESACTUALIZADO", "CRITICO".
     */
    private String estado;

    /**
     * Marca temporal ISO-8601 del último respaldo completado (o null si no existen).
     */
    private String ultimoBackupTimestamp;

    /**
     * Cantidad de horas transcurridas desde el último respaldo (o null si no existen).
     */
    private Long horasDesdeUltimo;

    /**
     * Nombre del archivo del último respaldo (o null si no existen).
     */
    private String ultimoArchivo;

    /**
     * Estado del almacenamiento remoto: "CONFIGURADO", "LOCAL_ONLY", "NO_CONFIGURADO".
     */
    private String almacenamientoRemoto;

    /**
     * Mensaje amigable y legible para el usuario final en español.
     */
    private String mensaje;
}
