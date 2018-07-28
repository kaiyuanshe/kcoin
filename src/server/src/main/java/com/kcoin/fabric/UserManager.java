/**
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License. See License.txt in the project root for
 * license information.
 */

package com.kcoin.fabric;

import com.kcoin.fabric.model.KCoinUser;
import com.kcoin.fabric.store.MemoryObjectStore;
import com.kcoin.fabric.store.ObjectStore;
import org.apache.commons.io.IOUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.bouncycastle.asn1.pkcs.PrivateKeyInfo;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.bouncycastle.openssl.PEMParser;
import org.bouncycastle.openssl.jcajce.JcaPEMKeyConverter;
import org.hyperledger.fabric.sdk.Enrollment;

import java.io.*;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.security.PrivateKey;
import java.security.Security;
import java.security.spec.InvalidKeySpecException;

/**
 * Created by juniwang on 27/07/2018.
 */
public class UserManager {
    private Log logger = LogFactory.getLog(UserManager.class);
    private static final ObjectStore<KCoinUser> store = new MemoryObjectStore();
    private static final UserManager userManager = new UserManager();

    private UserManager() {
    }

    public static UserManager get(){
        return userManager;
    }

    private void addUser(KCoinUser user) {
        String key = getUserStoreKey(user.getName(), user.getOrganization());
        logger.info("save object with key: " + key);
        store.saveObject(key, user);
    }

    /**
     * Get or create User with a given name and organization
     *
     * @param name
     * @param org
     * @return user
     */
    public KCoinUser getEnrolledUser(String name, String org) {

        // Try to get the KCoinUser state from the cache
        KCoinUser kcoinUser = store.loadObject(getUserStoreKey(name, org));
        if (null != kcoinUser) {
            return kcoinUser;
        }

        // Create the KCoinUser and try to restore it's state from the key value store (if found).
        kcoinUser = new KCoinUser(name, org);
        addUser(kcoinUser);
        return kcoinUser;
    }

    /**
     * Get the user with a given name
     *
     * @param name
     * @param org
     * @param mspId
     * @param privateKeyFile
     * @param certificateFile
     * @return user
     * @throws IOException
     * @throws NoSuchAlgorithmException
     * @throws NoSuchProviderException
     * @throws InvalidKeySpecException
     */
    public KCoinUser getEnrolledUser(String name, String org, String mspId, File privateKeyFile, File certificateFile)
            throws IOException, NoSuchAlgorithmException, NoSuchProviderException, InvalidKeySpecException {

        try {
            // Try to get the KCoinUser state from the cache
            KCoinUser kcoinUser = store.loadObject(getUserStoreKey(name, org));
            if (null != kcoinUser) {
                return kcoinUser;
            }

            // Create the KCoinUser and try to restore it's state from the key value store (if found).
            kcoinUser = new KCoinUser(name, org);
            kcoinUser.setMspId(mspId);

            String certificate = new String(IOUtils.toByteArray(new FileInputStream(certificateFile)), "UTF-8");
            PrivateKey privateKey = getPrivateKeyFromBytes(IOUtils.toByteArray(new FileInputStream(privateKeyFile)));
            kcoinUser.setEnrollment(new UserStoreEnrollment(privateKey, certificate));

            addUser(kcoinUser);
            return kcoinUser;
        } catch (IOException e) {
            e.printStackTrace();
            throw e;

        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
            throw e;
        } catch (NoSuchProviderException e) {
            e.printStackTrace();
            throw e;
        } catch (InvalidKeySpecException e) {
            e.printStackTrace();
            throw e;
        } catch (ClassCastException e) {
            e.printStackTrace();
            throw e;
        }

    }


    /**
     * Get cache key for user
     *
     * @param name
     * @param org
     * @return
     */
    private static String getUserStoreKey(String name, String org) {
        return String.format("org.%s.user.%s", org, name);
    }

    static {
        Security.addProvider(new BouncyCastleProvider());
    }

    static PrivateKey getPrivateKeyFromBytes(byte[] data) throws IOException, NoSuchProviderException, NoSuchAlgorithmException, InvalidKeySpecException {
        final Reader pemReader = new StringReader(new String(data));

        final PrivateKeyInfo pemPair;

        PEMParser pemParser = new PEMParser(pemReader);
        pemPair = (PrivateKeyInfo) pemParser.readObject();


        PrivateKey privateKey = new JcaPEMKeyConverter().setProvider(BouncyCastleProvider.PROVIDER_NAME).getPrivateKey(pemPair);

        return privateKey;
    }

    static final class UserStoreEnrollment implements Enrollment, Serializable {
        private static final long serialVersionUID = -2784835212445309006L;
        private final PrivateKey privateKey;
        private final String certificate;

        UserStoreEnrollment(PrivateKey privateKey, String certificate) {
            this.certificate = certificate;
            this.privateKey = privateKey;
        }

        public PrivateKey getKey() {
            return privateKey;
        }

        public String getCert() {
            return certificate;
        }
    }
}
