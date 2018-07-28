/**
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License. See License.txt in the project root for
 * license information.
 */

package com.kcoin.user;

import com.alibaba.fastjson.JSONArray;
import com.jfinal.core.Controller;
import com.jfinal.kit.PropKit;
import com.jfinal.kit.Ret;
import com.jfinal.plugin.activerecord.Record;
import com.kcoin.fabric.FabricClient;
import com.kcoin.fabric.FabricManager;
import com.kcoin.fabric.FabricResponse;
import org.hyperledger.fabric.sdk.NetworkConfig;
import org.hyperledger.fabric.sdk.exception.InvalidArgumentException;
import org.hyperledger.fabric.sdk.exception.NetworkConfigurationException;
import org.yaml.snakeyaml.Yaml;
import org.yaml.snakeyaml.constructor.Constructor;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.stream.Collectors;

/**
 * Created by juniwang on 22/07/2018.
 */
public class FabricController extends BaseController {
    public void index() {
        renderText("Fabric API");
    }

    public void query() {
        String id = getPara(0);
        String payload = FabricManager.get().query("query", new String[]{id});
        Ret ret = Ret.ok()
                .set("id", id)
                .set("balance", payload);

        renderJson(ret);
    }

    public void invoke() {
        Record r = getArgsRecord();
        String from = r.getStr("from");
        String to = r.getStr("to");
        Integer amount = r.getInt("amount");

        Boolean result = FabricManager.get().invoke("invoke", new String[]{from, to, amount.toString()});
        Ret ret = result ? Ret.ok() : Ret.fail();
        ret.set("from", from)
                .set("to", to)
                .set("amount", amount)
                .set("status", result);
        renderJson(ret);
    }

    public void proxy() {
        Record r = getArgsRecord();
        String finction = r.getStr("fn");
        JSONArray array = r.get("args");

        // {"fn":"initLedger", "args":["aaa", "aaa", 10000]}
        // {"fn":"balance", "args":["aaa", "coinbase"]}
        // {"fn":"balance", "args":["aaa", "user1"]}
        // {"fn":"transfer", "args":["aaa", "coinbase", "user1", 5]}
        // {"fn":"balance", "args":["aaa", "user1"]}

        String[] args = new String[array.size()];
        for (int i = 0; i < args.length; i++) {
            args[i] = array.get(i).toString();
        }

//        Boolean result = FabricManager.get().invoke(finction, args);
//        Ret ret = result ? Ret.ok() : Ret.fail();
//        renderJson(ret);

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
