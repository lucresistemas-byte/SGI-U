package com.sgiu_group.sgiu.models.dtos.dashboard;

public class ProductoStockCriticoDTO {
    private Long productoId;
    private String nombre;
    private Integer stockActual;
    private Integer stockMinimo;
    private String estado;

    public ProductoStockCriticoDTO(Long productoId, String nombre,
                                    Integer stockActual, Integer stockMinimo,
                                    String estado) {
        this.productoId = productoId;
        this.nombre = nombre;
        this.stockActual = stockActual;
        this.stockMinimo = stockMinimo;
        this.estado = estado;
    }

    public Long getProductoId() { return productoId; }
    public String getNombre() { return nombre; }
    public Integer getStockActual() { return stockActual; }
    public Integer getStockMinimo() { return stockMinimo; }
    public String getEstado() { return estado; }
}
