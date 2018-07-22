/**
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License. See License.txt in the project root for
 * license information.
 */

package com.kcoin.user;

import com.jfinal.core.Controller;
import com.jfinal.json.FastJson;
import com.jfinal.kit.HttpKit;
import com.jfinal.kit.StrKit;
import com.jfinal.plugin.activerecord.Record;

/**
 * Created by juniwang on 22/07/2018.
 */
public class BaseController extends Controller {

    public Record getArgsRecord() {
        String jsonStr = HttpKit.readData(getRequest());
        System.out.println("received json：" + jsonStr);

        if (StrKit.notBlank(jsonStr)) {
            @SuppressWarnings("unchecked")
            java.util.Map<String, Object> ls = FastJson.getJson().parse(jsonStr, java.util.Map.class);
            Record r = new Record().setColumns(ls);
            System.out.println("Record as json：" + r.toJson());
            return r;
        } else {
            return new Record();
        }
    }
}
