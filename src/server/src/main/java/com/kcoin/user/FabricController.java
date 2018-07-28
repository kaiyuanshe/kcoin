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

    public void proxy() {

        // {"fn":"initLedger", "args":["symbol", "name", "owner", "10000"]}
        // {"fn":"balance", "args":["symbol", "owner"]}
        // {"fn":"balance", "args":["symbol", "user1"]}
        // {"fn":"transfer", "args":["symbol", "owner", "user1", "5"]}
        // {"fn":"balance", "args":["symbol", "user1"]}

        Record r = getArgsRecord();
        String finction = r.getStr("fn");
        String[] args = getArgsAsArray(r);

        FabricResponse response;
        try {
            FabricClient client = FabricClient.get();
            response = client.invoke(finction, args);
        } catch (Exception e) {
            response = FabricResponse.failure().withMessage(e.getMessage());
        }
        renderJson(response);
    }

}
