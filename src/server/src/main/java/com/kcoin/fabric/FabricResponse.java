/**
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License. See License.txt in the project root for
 * license information.
 */

package com.kcoin.fabric;

/**
 * Created by juniwang on 28/07/2018.
 */
public class FabricResponse {
    private String payload;
    private String message;
    private int code;
    private String transactionId;

    public static final FabricResponse sunccess() {
        return new FabricResponse().withCode(200);
    }

    public static final FabricResponse failure() {
        return new FabricResponse().withCode(500);
    }

    public static final FabricResponse undefined() {
        return new FabricResponse().withCode(0);
    }

    public String getPayload() {
        return payload;
    }


    public String getMessage() {
        return message;
    }

    /**
     * UNDEFINED(0),
     * SUCCESS(200),
     * FAILURE(500)
     */
    public int getCode() {
        return code;
    }

    public String getTransactionId() {
        return transactionId;
    }

    public FabricResponse withPayload(String payload) {
        this.payload = payload;
        return this;
    }

    public FabricResponse withMessage(String message) {
        this.message = message;
        return this;
    }

    public FabricResponse withCode(int code) {
        this.code = code;
        return this;
    }

    public FabricResponse withTransactionId(String transactionId) {
        this.transactionId = transactionId;
        return this;
    }
}
