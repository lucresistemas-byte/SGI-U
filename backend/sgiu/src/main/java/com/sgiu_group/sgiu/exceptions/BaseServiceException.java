package com.sgiu_group.sgiu.exceptions;

public class BaseServiceException extends RuntimeException {
    public BaseServiceException(String message) {
        super(message);
    }
}