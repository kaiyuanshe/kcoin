/**
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License. See License.txt in the project root for
 * license information.
 */

package com.kcoin.fabric.model;

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
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;

/**
 * A local file-based key value store.
 * <p>
 * Created by juniwang on 22/07/2018.
 */
public class KCoinStore {
    private String file;
    private Log logger = LogFactory.getLog(KCoinStore.class);

    public KCoinStore(File file) {

        this.file = file.getAbsolutePath();
    }

    /**
     * Get the value associated with name.
     *
     * @param name
     * @return value associated with the name
     */
    /*
    public String getValue(String name) {
        Properties properties = loadProperties();
        return properties.getProperty(name);
    }

    private Properties loadProperties() {
        Properties properties = new Properties();

        try {
            InputStream input = new FileInputStream(file);
            properties.load(input);
            input.close();
        } catch (FileNotFoundException e) {
            logger.warn(String.format("Could not find the file \"%s\"", file));
        } catch (IOException e) {
            logger.warn(String.format("Could not load keyvalue store from file \"%s\", reason:%s",
                    file, e.getMessage()));
        }

        return properties;
    }
*/

    /**
     * Set the value associated with name.
     *
     * @param name  The name of the parameter
     * @param value Value for the parameter
     */
    public void setValue(String name, String value) {
        //Properties properties = loadProperties();
        Properties properties = new Properties();
        try {
            OutputStream output = new FileOutputStream(file);
            properties.setProperty(name, value);
            properties.store(output, "");
            output.close();

        } catch (IOException e) {
            logger.warn(String.format("Could not save the keyvalue store, reason:%s", e.getMessage()));
        }
    }

    private final Map<String, KCoinUser> members = new HashMap<String, KCoinUser>();

    /**
     * Get the user with a given name
     *
     * @param name
     * @param org
     * @return user
     */
    public KCoinUser getMember(String name, String org) {

        // Try to get the KCoinUser state from the cache
        KCoinUser kcoinUser = members.get(KCoinUser.toKeyValStoreName(name, org));
        if (null != kcoinUser) {
            return kcoinUser;
        }

        // Create the KCoinUser and try to restore it's state from the key value store (if found).
        kcoinUser = new KCoinUser(name, org, this);

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
    public KCoinUser getMember(String name, String org, String mspId, File privateKeyFile,
                               File certificateFile) throws IOException, NoSuchAlgorithmException, NoSuchProviderException, InvalidKeySpecException {

        try {
            // Try to get the KCoinUser state from the cache
            KCoinUser kcoinUser = members.get(KCoinUser.toKeyValStoreName(name, org));
            if (null != kcoinUser) {
                return kcoinUser;
            }

            // Create the KCoinUser and try to restore it's state from the key value store (if found).
            kcoinUser = new KCoinUser(name, org, this);
            kcoinUser.setMspId(mspId);

            String certificate = new String(IOUtils.toByteArray(new FileInputStream(certificateFile)), "UTF-8");

            PrivateKey privateKey = getPrivateKeyFromBytes(IOUtils.toByteArray(new FileInputStream(privateKeyFile)));

            kcoinUser.setEnrollment(new KCoinStoreEnrollement(privateKey, certificate));

            kcoinUser.saveState();

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

    static final class KCoinStoreEnrollement implements Enrollment, Serializable {

        private static final long serialVersionUID = -2784835212445309006L;
        private final PrivateKey privateKey;
        private final String certificate;


        KCoinStoreEnrollement(PrivateKey privateKey, String certificate) {


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
