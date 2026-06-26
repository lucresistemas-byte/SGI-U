package com.sgiu_group.sgiu.models.dtos.dashboard;

public class DashboardResponseDTO {
    private DashboardFiltrosDTO filtrosAplicados;
    private DashboardKpisDTO kpis;
    private DashboardGraficosDTO graficos;
    private DashboardMetadataDTO metadata;

    public DashboardResponseDTO(DashboardFiltrosDTO filtrosAplicados,
                                 DashboardKpisDTO kpis,
                                 DashboardGraficosDTO graficos,
                                 DashboardMetadataDTO metadata) {
        this.filtrosAplicados = filtrosAplicados;
        this.kpis = kpis;
        this.graficos = graficos;
        this.metadata = metadata;
    }

    public DashboardFiltrosDTO getFiltrosAplicados() { return filtrosAplicados; }
    public DashboardKpisDTO getKpis() { return kpis; }
    public DashboardGraficosDTO getGraficos() { return graficos; }
    public DashboardMetadataDTO getMetadata() { return metadata; }
}
