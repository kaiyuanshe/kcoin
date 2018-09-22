/**
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License. See License.txt in the project root for
 * license information.
 */

package com.kcoin.user;

import com.alibaba.fastjson.JSONArray;
import com.jfinal.plugin.activerecord.Record;
import com.kcoin.fabric.FabricClient;
import com.kcoin.fabric.FabricResponse;

import java.util.function.Function;

/**
 * Created by juniwang on 22/07/2018.
 */
public class FabricController extends BaseController {
    public void index() {
        renderText("Fabric API");
    }

    private String[] getArgsAsArray(Record record) {
        JSONArray array = record.get("args");

        String[] args = new String[array.size()];
        for (int i = 0; i < args.length; i++) {
            args[i] = array.get(i).toString();
        }

        return args;
    }

    public void invoke() {

        // {"fn":"initLedger", "args":["symbol", "name", "owner", "10000"]}
        // {"fn":"transfer", "args":["symbol", "owner", "user1", "5"]}

        Record r = getArgsRecord();
        String finction = r.getStr("fn");
        String[] args = getArgsAsArray(r);
        call_fabric((client) -> {
            try {
                return client.invoke(finction, args);
            } catch (Exception e) {
                return FabricResponse.failure().withMessage(e.getMessage());
            }
        });
    }

    public void query() {

        // {"fn":"balance", "args":["symbol", "owner"]}
        // {"fn":"balance", "args":["symbol", "user1"]}
        // {"fn":"historyQuery", "args":["symbol"]}

        Record r = getArgsRecord();
        String finction = r.getStr("fn");
        String[] args = getArgsAsArray(r);
        call_fabric((client) -> {
            try {
                return client.query(finction, args);
            } catch (Exception e) {
                return FabricResponse.failure().withMessage(e.getMessage());
            }
        });
    }

    private void call_fabric(Function<FabricClient, FabricResponse> func) {
        FabricResponse response;
        try {
            FabricClient client = FabricClient.get();
            response = func.apply(client);
        } catch (Exception e) {
            response = FabricResponse.failure().withMessage(e.getMessage());
        }

        renderJson(response);
        if (response.getCode() / 100 != 2) {
            renderError(response.getCode(), getRender());
        }
    }
}
