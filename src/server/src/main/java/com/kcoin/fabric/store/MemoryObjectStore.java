/**
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License. See License.txt in the project root for
 * license information.
 */

package com.kcoin.fabric.store;

import com.kcoin.fabric.model.KCoinUser;

import java.util.HashMap;
import java.util.Map;

/**
 * A local file-based key value store.
 * <p>
 * Created by juniwang on 22/07/2018.
 */
public class MemoryObjectStore implements ObjectStore<KCoinUser> {

    private static final Map<String, KCoinUser> storedUsers = new HashMap<String, KCoinUser>();

    public void saveObject(String key, KCoinUser value) {
        storedUsers.put(key, value);
    }

    public KCoinUser loadObject(String key) {
        return storedUsers.get(key);
    }

}
