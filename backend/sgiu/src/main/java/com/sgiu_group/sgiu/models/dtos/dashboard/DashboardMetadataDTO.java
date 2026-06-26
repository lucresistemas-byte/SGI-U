package com.sgiu_group.sgiu.models.dtos.dashboard;

public class DashboardMetadataDTO {
    private boolean hayDatos;
    private String mensaje;

    public DashboardMetadataDTO(boolean hayDatos, String mensaje) {
        this.hayDatos = hayDatos;
        this.mensaje = mensaje;
    }

    public boolean isHayDatos() { return hayDatos; }
    public String getMensaje() { return mensaje; }
}
