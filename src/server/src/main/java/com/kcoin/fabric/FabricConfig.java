/**
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License. See License.txt in the project root for
 * license information.
 */

package com.kcoin.fabric;

import com.jfinal.kit.PropKit;
import com.kcoin.fabric.model.KCoinOrg;
import org.yaml.snakeyaml.Yaml;

import java.io.*;
import java.net.URISyntaxException;
import java.net.URL;
import java.nio.file.Paths;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * Created by juniwang on 22/07/2018.
 */
public class FabricConfig {
    private long waiteTime = 1000000;
    private static final Properties sdkProperties = new Properties();
    private static final HashMap<String, KCoinOrg> kcoinOrgs = new HashMap<>();
    private static final Pattern pattern = Pattern.compile("\\$\\{(.+?)\\}");

    private static FabricConfig fabricConfig;
    private HashMap configMap;

    public static String orgName = null;
    public static String CHANNEL_NAME = null;

    // TODO should be a list for multiple projects
    public static String CHAIN_CODE_NAME = null;
    public static String CHAIN_CODE_VERSION = null;

    public static String TEST_ADMIN_NAME = "Admin";
    public static String TESTUSER_1_NAME = "User1";
    static String sslProvider = "openSSL";
    static String negotiationType = "TLS";

    private FabricConfig() {
        // read configs
        PropKit.use("configs.properties");


        // read YAML file and replace placeholders
        try {
            String fabricConfig = readAndFormatYaml();
            System.out.printf("Fabric Config : %s\n", fabricConfig);
            Yaml yaml = new Yaml();
            configMap = (HashMap) yaml.load(fabricConfig);
        } catch (URISyntaxException e) {
            e.printStackTrace();
        }

        String userName = PropKit.get("fabricUserName");
        setKCoinOrg(userName);
    }

    private String readAndFormatYaml() throws URISyntaxException {
        // read YAML content
        String yamlFilePath = PropKit.get("fabricSDKConfig", "kcoin-sdk-config.yaml");
        ClassLoader classloader = Thread.currentThread().getContextClassLoader();
        URL yaml = classloader.getResource(yamlFilePath);
        InputStream is = classloader.getResourceAsStream(yamlFilePath);
        String content = new BufferedReader(new InputStreamReader(is)).lines().collect(Collectors.joining("\n"));

        // placeholders
        String resourcesPath = Paths.get(yaml.toURI()).getParent().toAbsolutePath().toString();
        String certPath = Paths.get(resourcesPath, "fabric").toAbsolutePath().toString();
        final Map<String, String> replacements = new HashMap<>();
        replacements.put("fabricCertificatesPath", certPath);
        replacements.put("ordererEIP", PropKit.get("fabricOrdererEIP"));
        replacements.put("peerEIP", PropKit.get("fabricPeerEIP"));

        // replace
        Matcher m = pattern.matcher(content);
        StringBuffer sb = new StringBuffer();
        while (m.find()) {
            String var = m.group(1);
            String replacement = replacements.get(var);
            m.appendReplacement(sb, replacement);
        }
        m.appendTail(sb);
        return sb.toString();
    }

    private void setKCoinOrg(String UserName) {
        orgName = (String) ((HashMap) configMap.get("client")).get("organization");
        System.out.println("Organization:" + orgName);

        for (String str : (Set<String>) ((HashMap) configMap.get("channels")).keySet()) {
            CHANNEL_NAME = str;
            for (String s : ((ArrayList<String>) ((HashMap) ((HashMap) configMap.get("channels")).get(str)).get("chaincodes"))) {
                String[] slist = s.split(":");
                CHAIN_CODE_NAME = slist[0];
                CHAIN_CODE_VERSION = slist[1];
                break;
            }
            break;
        }
        System.out.println("Channel Name:" + CHANNEL_NAME);
        System.out.println("Chain Code Name:" + CHAIN_CODE_NAME);
        System.out.println("Chain Code Version:" + CHAIN_CODE_VERSION);


        HashMap orgMap = (HashMap) configMap.get("organizations");
        HashMap peersMap = (HashMap) configMap.get("peers");
        HashMap orderersMap = (HashMap) configMap.get("orderers");

        for (Object object : orgMap.entrySet()) {
            Map.Entry eachOrgMap = (Map.Entry) object;
            HashMap eachOrgMapValue = (HashMap) eachOrgMap.getValue();
            KCoinOrg kcoinOrg = new KCoinOrg(eachOrgMap.getKey().toString(), eachOrgMapValue.get("mspid").toString());

            String cryptoPath = eachOrgMapValue.get("cryptoPath").toString();
            String clientKeyFile = eachOrgMapValue.get("tlsCryptoKeyPath").toString();
            String clientCertFile = eachOrgMapValue.get("tlsCryptoCertPath").toString();
            System.out.println("Crypto Path:" + cryptoPath);
            System.out.println("Client Cert File:" + clientKeyFile);
            System.out.println("Client Cert File:" + clientCertFile);

            kcoinOrg.setKeystorePath(cryptoPath + "/keystore/");
            kcoinOrg.setSigncertsPath(cryptoPath + "/signcerts/" + UserName + "@" + orgName + ".peer-" + orgName + ".default.svc.cluster.local-cert.pem");

            ArrayList orgPeersArrary = (ArrayList) eachOrgMapValue.get("peers");
            for (Object eachPeer : orgPeersArrary) {
                HashMap eachPeerMap = (HashMap) peersMap.get(eachPeer.toString());
                System.out.println("Peer Name:" + eachPeer.toString());

                kcoinOrg.addPeerLocation(eachPeer.toString(), eachPeerMap.get("url").toString());
                System.out.println("	Peer Location:" + eachPeerMap.get("url").toString());

                kcoinOrg.addEventHubLocation(eachPeer.toString(), eachPeerMap.get("eventUrl").toString());
                System.out.println("	Event Hub Location:" + eachPeerMap.get("eventUrl").toString());


                Properties pro = getProperties(eachPeerMap);

                pro.setProperty("hostnameOverride", eachPeer.toString());
                System.out.println("	Host Name Override:" + eachPeer.toString());

                pro.put("clientKeyFile", clientKeyFile);
                System.out.println("	Client Key File:" + cryptoPath);

                pro.put("clientCertFile", clientCertFile);
                System.out.println("	Client Cert File:" + cryptoPath);


                kcoinOrg.addPeerProperties(eachPeer.toString(), pro);
            }

            for (Object eachOrderer : orderersMap.entrySet()) {
                Map.Entry eachOrdererEntry = (Map.Entry) eachOrderer;
                HashMap eachOrdererMap = (HashMap) eachOrdererEntry.getValue();
                String url = eachOrdererMap.get("url").toString();
                kcoinOrg.addOrdererLocation(eachOrdererEntry.getKey().toString(), url);
                System.out.println("Orderer Name:" + eachOrdererEntry.getKey().toString());

                Properties pro = getProperties(eachOrdererMap);

                pro.setProperty("hostnameOverride", eachOrdererEntry.getKey().toString());
                System.out.println("	Host Name Override:" + eachOrdererMap.toString());
                //pro.put("clientKeyFile",clientKeyFile);
                //pro.put("clientCertFile",clientCertFile);

                kcoinOrg.addOrdererProperties(eachOrdererEntry.getKey().toString(), pro);
            }

            kcoinOrgs.put(eachOrgMap.getKey().toString(), kcoinOrg);

            break;
        }
    }

    private Properties getProperties(HashMap nodeMap) {
        Properties properties = new Properties();
        HashMap grpcMap = (HashMap) nodeMap.get("grpcOptions");
        properties.setProperty("pemFile", ((HashMap) nodeMap.get("tlsCACerts")).get("path").toString());
        System.out.println("	Pem File:" + ((HashMap) nodeMap.get("tlsCACerts")).get("path").toString());

        properties.setProperty("sslProvider", sslProvider);
        System.out.println("	SSL Provider:" + sslProvider);

        properties.setProperty("negotiationType", negotiationType);
        System.out.println("	Negotiation Type:" + negotiationType);
        return properties;
    }


    public Properties getSMProperties() {
        Properties properties = new Properties();
        properties.setProperty("org.hyperledger.fabric.sdk.hash_algorithm", "SM3");
        properties.setProperty("org.hyperledger.fabric.sdk.crypto.default_signature_userid", "1234567812345678");
        return properties;
    }


    public void setWaiteTime(long waiteTime) {
        this.waiteTime = waiteTime;
    }

    public static FabricConfig getConfig() {
        if (fabricConfig == null) {
            fabricConfig = new FabricConfig();
        }
        return fabricConfig;
    }

    public Collection<KCoinOrg> getIntegrationKCoinOrgs() {
        return Collections.unmodifiableCollection(kcoinOrgs.values());
    }

    public KCoinOrg getIntegrationKCoinOrg(String name) {
        return kcoinOrgs.get(name);
    }

    public long getWaiteTime() {
        return waiteTime;
    }

    /*
    public static void main(String[] args) throws FileNotFoundException {
        new FabricConfig("/src/main/fixture/config/network-config.yaml");
    }
    */

    private static void setProperty(String key, String value) {
        String ret = System.getProperty(key);
        if (ret != null) {
            sdkProperties.put(key, ret);
        } else {
            String envKey = key.toUpperCase().replaceAll("\\.", "_");
            ret = System.getenv(envKey);
            if (null != ret) {
                sdkProperties.put(key, ret);
            } else {
                if (null == sdkProperties.getProperty(key) && value != null) {
                    sdkProperties.put(key, value);
                }

            }

        }
    }
}
