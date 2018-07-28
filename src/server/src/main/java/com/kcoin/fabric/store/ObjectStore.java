/**
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License. See License.txt in the project root for
 * license information.
 */

package com.kcoin.fabric.store;

/**
 * Created by juniwang on 27/07/2018.
 */
public interface ObjectStore<T> {
    void saveObject(String key, T value);

    T loadObject(String key);
}
