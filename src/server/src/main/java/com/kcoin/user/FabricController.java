/**
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License. See License.txt in the project root for
 * license information.
 */

package com.kcoin.user;

import com.jfinal.core.Controller;
import com.jfinal.kit.Ret;
import com.jfinal.plugin.activerecord.Record;
import com.kcoin.fabric.FabricManager;

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
}
