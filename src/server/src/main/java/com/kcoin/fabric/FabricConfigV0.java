/**
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License. See License.txt in the project root for
 * license information.
 */

package com.kcoin.fabric;

import com.jfinal.kit.PropKit;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.yaml.snakeyaml.Yaml;

import javax.json.*;
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
public class FabricConfigV0 {
    private String yamlFilePath = null;
    private JsonObject jsonConfig = null;
    private Log logger = LogFactory.getLog(FabricConfigV0.class);

    private HashMap configMap;
    private long waiteTime = 1000000;
    private String orgName;
    private String chainCodeName;
    private String chainCodeVersion;
    private String channelName;

    private static final Properties sdkProperties = new Properties();
    private static final HashMap<String, KCoinOrg> kcoinOrgs = new HashMap<>();
    private static final Pattern pattern = Pattern.compile("\\$\\{(.+?)\\}");

    public static String TEST_ADMIN_NAME = "Admin";
    public static String TESTUSER_1_NAME = "User1";
    static String sslProvider = "openSSL";
    static String negotiationType = "TLS";

    public static FabricConfigV0 getConfig() throws Exception {
        PropKit.use("configs.properties");
        String path = PropKit.get("fabricSDKConfig", "kcoin-sdk-config.yaml");
        return new FabricConfigV0(path);
    }

    public FabricConfigV0(String configFilePath) throws Exception {
        this.yamlFilePath = configFilePath;

        // read YAML file and replace placeholders
        loadConfig();
        System.out.printf("Fabric Config : %s\n", jsonConfig.toString());

        String userName = PropKit.get("fabricUserName");
        initKCoinOrgs(userName);
    }

    private void loadConfig() throws URISyntaxException {
        String content = readYamlAsString();

        // we add some placeholders in the yaml file such as the file location
        // so that the YAML file can be used in different folder by different developer.

        // placeholders
        final Map<String, String> replacements = getReplacements();

        // replace
        Matcher m = pattern.matcher(content);
        StringBuffer sb = new StringBuffer();
        while (m.find()) {
            String var = m.group(1);
            String replacement = replacements.get(var);
            m.appendReplacement(sb, replacement);
        }
        m.appendTail(sb);
        String json = sb.toString();

        // load as JsonConfig
        Yaml yaml = new Yaml();
        configMap = yaml.load(json);
        JsonObjectBuilder builder = Json.createObjectBuilder(configMap);
        this.jsonConfig = builder.build();
    }

    /**
     * Get the replacement for the placeholders in the yaml file
     *
     * @return
     * @throws URISyntaxException
     */
    private Map<String, String> getReplacements() throws URISyntaxException {
        ClassLoader classloader = Thread.currentThread().getContextClassLoader();
        URL yaml = classloader.getResource(yamlFilePath);
        String resourcesPath = Paths.get(yaml.toURI()).getParent().toAbsolutePath().toString();
        String certPath = Paths.get(resourcesPath, "fabric").toAbsolutePath().toString();
        final Map<String, String> replacements = new HashMap<>();
        replacements.put("fabricCertificatesPath", certPath);
        replacements.put("ordererEIP", PropKit.get("fabricOrdererEIP"));
        replacements.put("peerEIP", PropKit.get("fabricPeerEIP"));
        replacements.put("fabricChainCodeId", "jtokena:1.0.7");
        return replacements;
    }

    /**
     * Read string content from HyperLedger YAML config file
     *
     * @return
     */
    private String readYamlAsString() {
        ClassLoader classloader = Thread.currentThread().getContextClassLoader();
        InputStream is = classloader.getResourceAsStream(yamlFilePath);
        return new BufferedReader(new InputStreamReader(is)).lines().collect(Collectors.joining("\n"));
    }

    private void initKCoinOrgs(String UserName) {
        orgName = (String) ((HashMap) configMap.get("client")).get("organization");
        logger.debug("Organization:" + orgName);

        initChainCodeId();


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

    private void initChainCodeId() {
        for (String str : (Set<String>) ((HashMap) configMap.get("channels")).keySet()) {
            channelName = str;
            for (String s : ((ArrayList<String>) ((HashMap) ((HashMap) configMap.get("channels")).get(str)).get("chaincodes"))) {
                String[] slist = s.split(":");
                chainCodeName = slist[0];
                chainCodeVersion = slist[1];
                break;
            }
            break;
        }

        // Override the ChainCode name and version with the one in configs.properties
        chainCodeName = PropKit.get("fabricChainCodeName");
        chainCodeVersion = PropKit.get("fabricChainCodeVersion");

        System.out.println("Channel Name:" + channelName);
        System.out.println("Chain Code Name:" + chainCodeName);
        System.out.println("Chain Code Version:" + chainCodeVersion);
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

    public Collection<KCoinOrg> getIntegrationKCoinOrgs() {
        return Collections.unmodifiableCollection(kcoinOrgs.values());
    }

    public KCoinOrg getIntegrationKCoinOrg(String name) {
        return kcoinOrgs.get(name);
    }

    public long getWaiteTime() {
        return waiteTime;
    }

    public String getOrgName() {
        return orgName;
    }

    public String getChainCodeName() {
        return chainCodeName;
    }

    public String getChainCodeVersion() {
        return chainCodeVersion;
    }

    public String getChannelName() {
        return channelName;
    }

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
