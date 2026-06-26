package com.sgiu_group.sgiu.exceptions;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.BAD_REQUEST)
public class FechasInvalidasException extends RuntimeException {
    public FechasInvalidasException(String message) {
        super(message);
    }
}
