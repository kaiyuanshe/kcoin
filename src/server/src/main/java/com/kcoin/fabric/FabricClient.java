/**
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License. See License.txt in the project root for
 * license information.
 */

package com.kcoin.fabric;

import com.jfinal.kit.PropKit;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.hyperledger.fabric.sdk.*;
import org.hyperledger.fabric.sdk.exception.CryptoException;
import org.hyperledger.fabric.sdk.exception.InvalidArgumentException;
import org.hyperledger.fabric.sdk.security.CryptoSuite;
import org.yaml.snakeyaml.Yaml;

import javax.json.Json;
import javax.json.JsonObject;
import javax.json.JsonObjectBuilder;
import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.lang.reflect.InvocationTargetException;
import java.net.URISyntaxException;
import java.net.URL;
import java.nio.file.Paths;
import java.security.Security;
import java.util.*;
import java.util.concurrent.TimeUnit;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import static java.lang.String.format;
import static java.nio.charset.StandardCharsets.UTF_8;

/**
 * Created by juniwang on 28/07/2018.
 */
public class FabricClient {
    private static final Pattern pattern = Pattern.compile("\\$\\{(.+?)\\}");
    private static FabricClient fabricClient;
    private Log logger = LogFactory.getLog(FabricClient.class);

    // Configurations, typically from a yaml file
    private final String configFile;
    private NetworkConfig networkConfig;

    // HyperLedger Fabric Client, inner client that talks to HyperLedger
    private HFClient client = null;
    private Channel channel = null;
    private ChaincodeID chaincodeID = null;

    // configurables
    private long waitSecond = 300;


    static {
        Security.addProvider(new BouncyCastleProvider());
    }

    public FabricClient(String configFile) throws Exception {
        this.configFile = configFile;

        try {
            this.loadConfig();
            this.initClient();
        } catch (Exception e) {
            e.printStackTrace();
            logger.error("Failed to initialize Fabric fabricClient", e);
            throw e;
        }
    }

    /**
     * Get the default fabricClient using default config
     *
     * @return
     */
    public static FabricClient get() throws Exception {
        if (fabricClient != null)
            return fabricClient;

        PropKit.use("configs.properties");
        String path = PropKit.get("fabricSDKConfig", "kcoin-sdk-config.yaml");
        fabricClient = new FabricClient(path);
        return fabricClient;
    }

    public FabricResponse invoke(final String finction, final String[] args) throws Exception {
        ensureChannelReady();

        logger.info(format("begin invoking `%s` with args: %s", finction, Arrays.toString(args)));

        Collection<ProposalResponse> successful = new LinkedList<>();
        Collection<ProposalResponse> failed = new LinkedList<>();

        /// Send transaction proposal to all peers
        TransactionProposalRequest transactionProposalRequest = client.newTransactionProposalRequest();
        transactionProposalRequest.setChaincodeID(chaincodeID);
        transactionProposalRequest.setFcn(finction);
        transactionProposalRequest.setArgs(args);
        Map<String, byte[]> tm2 = new HashMap<>();
        tm2.put("HyperLedgerFabric", "TransactionProposalRequest:JavaSDK".getBytes(UTF_8));
        tm2.put("method", "TransactionProposalRequest".getBytes(UTF_8));
        //tm2.put("result", "{}".getBytes(UTF_8));
        try {
            transactionProposalRequest.setTransientMap(tm2);
        } catch (Exception e) {
            logger.warn("fail to set transient map", e);
        }
        Collection<ProposalResponse> transactionPropResp = channel.sendTransactionProposal(
                transactionProposalRequest,
                channel.getPeers());
        for (ProposalResponse response : transactionPropResp) {
            if (response.getStatus() == ProposalResponse.Status.SUCCESS) {
                successful.add(response);
            } else {
                failed.add(response);
            }
        }

        // Check that all the proposals are consistent with each other. We should have only one set
        // where all the proposals above are consistent.
        Collection<Set<ProposalResponse>> proposalConsistencySets = SDKUtils.getProposalConsistencySets(transactionPropResp);
        if (proposalConsistencySets.size() != 1) {
            logger.warn(format("Expected only one set of consistent proposal responses but got %d",
                    proposalConsistencySets.size()));
            return FabricResponse.failure().withMessage("proposals are not consistent with each other");
        }

        logger.info(format("Received %d transaction proposal responses. Successful+verified: %d . Failed: %d",
                transactionPropResp.size(),
                successful.size(),
                failed.size()));
        if (failed.size() > 0) {
            logger.error(format("Invoke finction `%s` failed", finction));
            Collection<String> messages = new LinkedList<>();
            for (ProposalResponse response : failed) {
                messages.add(response.getMessage());
            }
            logger.error(format("Failure messages: %s", Arrays.toString(messages.toArray())));
            return FabricResponse.failure().withMessage(Arrays.toString(messages.toArray()));
        }

        // Send Transaction Transaction to orderer and wait for the result
        logger.info("Successfully received transaction proposal responses.");
        BlockEvent.TransactionEvent transactionEvent = channel.sendTransaction(successful)
                .get(getWaitSecond(), TimeUnit.SECONDS);

        ProposalResponse proposalResponse = successful.iterator().next();
        return FabricResponse.sunccess()
                .withPayload(new String(proposalResponse.getChaincodeActionResponsePayload()))
                .withTransactionId(proposalResponse.getTransactionID());
    }

    public FabricResponse query(final String finction, String[] args) throws Exception {
        ensureChannelReady();

        try {
            QueryByChaincodeRequest queryByChaincodeRequest = client.newQueryProposalRequest();
            queryByChaincodeRequest.setArgs(args);
            queryByChaincodeRequest.setFcn(finction);
            queryByChaincodeRequest.setChaincodeID(chaincodeID);

            Map<String, byte[]> tm2 = new HashMap<>();
            tm2.put("HyperLedgerFabric", "QueryByChaincodeRequest:JavaSDK".getBytes(UTF_8));
            tm2.put("method", "QueryByChaincodeRequest".getBytes(UTF_8));
            queryByChaincodeRequest.setTransientMap(tm2);

            Collection<ProposalResponse> queryProposals = channel.queryByChaincode(queryByChaincodeRequest, channel.getPeers());
            ProposalResponse proposalResponse = queryProposals.iterator().next();
            if (!proposalResponse.isVerified() || proposalResponse.getStatus() != ProposalResponse.Status.SUCCESS) {
                logger.info("Failed query proposal from peer " + proposalResponse.getPeer().getName() + " status: " + proposalResponse.getStatus() +
                        ". Messages: " + proposalResponse.getMessage()
                        + ". Was verified : " + proposalResponse.isVerified());
                return FabricResponse.failure().withMessage(proposalResponse.getMessage());
            } else {
                String payload = proposalResponse.getProposalResponse().getResponse().getPayload().toStringUtf8();
                logger.info(format("Query payload from peer %s returned %s", proposalResponse.getPeer().getName(), payload));
                return FabricResponse.sunccess().withMessage(payload);
            }
        } catch (Exception e) {
            logger.error("Caught exception while running query", e);
            e.printStackTrace();
            return FabricResponse.failure().withMessage(e.getMessage());
        }
    }

    private void loadConfig() throws Exception {
        String content = readYamlAsString();

        // we add some placeholders in the yaml file such as the file location
        // so that the YAML file can be used in different folder by different developer.

        // placeholders
        String json = handlePlaceHolders(content);

        // load as JsonConfig
        Yaml yaml = new Yaml();
        @SuppressWarnings("unchecked")
        Map<String, Object> map = yaml.load(json);
        JsonObjectBuilder builder = Json.createObjectBuilder(map);
        JsonObject jsonConfig = builder.build();
        this.networkConfig = NetworkConfig.fromJsonObject(jsonConfig);
    }

    private void initClient() throws Exception {
        // Create instance of client.
        client = HFClient.createNewInstance();
        initCryptoSuite();
        initUserContext();
        initChannel();
    }

    private void initCryptoSuite() throws IllegalAccessException, InstantiationException, ClassNotFoundException, CryptoException, InvalidArgumentException, NoSuchMethodException, InvocationTargetException {
        CryptoSuite cryptoSuite = CryptoSuite.Factory.getCryptoSuite();
        client.setCryptoSuite(cryptoSuite);
    }

    private void initChannel() throws Exception {
        String channelName = networkConfig.getChannelNames().iterator().next();
        //Channel ch = networkConfig.loadChannel(client, channelName);
        Channel ch = client.loadChannelFromConfig(channelName, networkConfig);
        ch.initialize();
        this.channel = ch;
    }

    private void initUserContext() throws Exception {
        NetworkConfig.OrgInfo clientOrg = networkConfig.getClientOrganization();
        client.setUserContext(clientOrg.getPeerAdmin());
    }

    private void throwIfChannelNotReady() throws Exception {
        if (!channel.isInitialized())
            throw new Exception("channel is not initialized yet.");
    }

    private void ensureChannelReady() throws Exception {
        if (this.channel == null || this.channel.isShutdown()) {
            initChannel();
        }

        throwIfChannelNotReady();
    }

    /**
     * Replace the placeholders in the yaml file
     *
     * @return
     * @throws URISyntaxException
     */
    private String handlePlaceHolders(String content) throws Exception {
        ClassLoader classloader = Thread.currentThread().getContextClassLoader();
        URL yaml = classloader.getResource(configFile);
        String resourcesPath = Paths.get(yaml.toURI()).getParent().toAbsolutePath().toString();
        String certPath = Paths.get(resourcesPath, "fabric").toAbsolutePath().toString();

        final Map<String, String> replacements = new HashMap<>();
        replacements.put("fabricCertificatesPath", certPath);
        replacements.put("ordererEIP", PropKit.get("fabricOrdererEIP"));
        replacements.put("peerEIP", PropKit.get("fabricPeerEIP"));
        replacements.put("adminPrivateKeyFile", PropKit.get("fabricAdminPrivateKeyFileName"));

        final String ccName = PropKit.get("fabricChainCodeName");
        final String ccVersion = PropKit.get("fabricChainCodeVersion");
        replacements.put("fabricChainCodeId", String.format("%s:%s", ccName, ccVersion));
        this.chaincodeID = ChaincodeID.newBuilder().setName(ccName).setVersion(ccVersion).build();

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

    /**
     * Read string content from HyperLedger YAML config file
     *
     * @return
     */
    private String readYamlAsString() {
        ClassLoader classloader = Thread.currentThread().getContextClassLoader();
        InputStream is = classloader.getResourceAsStream(configFile);
        return new BufferedReader(new InputStreamReader(is)).lines().collect(Collectors.joining("\n"));
    }

    public long getWaitSecond() {
        return waitSecond;
    }

    public void setWaitSecond(long waitSecond) {
        this.waitSecond = waitSecond;
    }
}

