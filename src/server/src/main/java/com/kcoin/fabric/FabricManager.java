/**
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License. See License.txt in the project root for
 * license information.
 */

package com.kcoin.fabric;

import com.kcoin.fabric.model.KCoinUser;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.hyperledger.fabric.sdk.*;
import org.hyperledger.fabric.sdk.security.CryptoSuite;

import java.io.File;
import java.nio.file.Paths;
import java.security.Security;
import java.util.*;
import java.util.concurrent.TimeUnit;

import static java.lang.String.format;
import static java.nio.charset.StandardCharsets.UTF_8;

/**
 * Created by juniwang on 21/07/2018.
 */
public class FabricManager {
    private static FabricConfigV0 fabricConfigV0 = null;
    //private static InitConfig fabricConfig = InitConfig.getConfig("/src/main/resources/fixture/config/hdrNoDelete-sdk-config.sm.yaml");
    //private static TestConfig testConfig = TestConfig.getConfig();

    private HFClient client = null;
    private Channel channel = null;
    private ChaincodeID chaincodeID = null;

    private final static FabricManager me = new FabricManager();
    private static boolean isReady = false;


    public static FabricManager get() {
        if (!isReady) {
            try {
                //TODO handle exception in initialization
                me.init();
                isReady = true;
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        return me;
    }

    private CryptoSuite initCryptoSuite() throws Exception {
        fabricConfigV0 = FabricConfigV0.getConfig();
        return CryptoSuite.Factory.getCryptoSuite();
    }

    public void init() throws Exception {
        //Create instance of client.
        client = HFClient.createNewInstance();
        try {
            // client.setCryptoSuite(CryptoSuite.Factory.getCryptoSuite(fabricConfig.getSMProperties()));
            CryptoSuite cs = initCryptoSuite();
            client.setCryptoSuite(cs);
        } catch (Exception e) {
            e.printStackTrace();
        }
        //Set up USERS

        final UserManager userManager = UserManager.get();
        // get users for all orgs
        Collection<KCoinOrg> testKCoinOrgs = fabricConfigV0.getIntegrationKCoinOrgs();
        for (KCoinOrg kcoinOrg : testKCoinOrgs) {
            final String orgName = kcoinOrg.getName();
            KCoinUser admin = userManager.getEnrolledUser(fabricConfigV0.TEST_ADMIN_NAME, orgName);
            kcoinOrg.setAdmin(admin); // The admin of this org.
            // No need to enroll or register all done in End2endIt !
            KCoinUser user = userManager.getEnrolledUser(fabricConfigV0.TESTUSER_1_NAME, orgName);
            kcoinOrg.addUser(user);  //Remember user belongs to this Org

            final String kcoinOrgName = kcoinOrg.getName();
            try {
                System.out.println(Paths.get(kcoinOrg.getKeystorePath()).toFile());
                KCoinUser peerOrgAdmin = userManager.getEnrolledUser(kcoinOrgName + "Admin", kcoinOrgName, kcoinOrg.getMSPID(),
                        findFileSk(Paths.get(kcoinOrg.getKeystorePath()).toFile()),
                        Paths.get(kcoinOrg.getSigncertsPath()).toFile());
                kcoinOrg.setPeerAdmin(peerOrgAdmin); //A special user that can create channels, join peers and install chaincode
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        chaincodeID = ChaincodeID.newBuilder().setName(fabricConfigV0.getChainCodeName()).setVersion(fabricConfigV0.getChainCodeVersion()).build();

        newChannel();
    }

    public void newChannel() throws Exception {
        KCoinOrg kcoinOrg = fabricConfigV0.getIntegrationKCoinOrg(fabricConfigV0.getOrgName());
        client.setUserContext(kcoinOrg.getPeerAdmin());

        channel = client.newChannel(fabricConfigV0.getChannelName());
        for (String orderName : kcoinOrg.getOrdererNames()) {
            channel.addOrderer(client.newOrderer(orderName, kcoinOrg.getOrdererLocation(orderName),
                    kcoinOrg.getOrdererProperties(orderName)));
        }

        for (String peerName : kcoinOrg.getPeerNames()) {
            String peerLocation = kcoinOrg.getPeerLocation(peerName);
            Peer peer = client.newPeer(peerName, peerLocation, kcoinOrg.getPeerProperties(peerName));

            //Query the actual peer for which channels it belongs to and check it belongs to this channel
            Set<String> channels = client.queryChannels(peer);
            if (!channels.contains(fabricConfigV0.getChannelName())) {
                throw new AssertionError(format("Peer %s does not appear to belong to channel %s",
                        peerName, fabricConfigV0.getChannelName()));
            }

            channel.addPeer(peer);
            kcoinOrg.addPeer(peer);
        }

        for (String eventHubName : kcoinOrg.getEventHubNames()) {
            EventHub eventHub = client.newEventHub(eventHubName, kcoinOrg.getEventHubLocation(eventHubName),
                    kcoinOrg.getPeerProperties(eventHubName));
            channel.addEventHub(eventHub);
        }

        channel.initialize();
        //channel.setTransactionWaitTime(testConfig.getTransactionWaitTime());
        //channel.setDeployWaitTime(testConfig.getDeployWaitTime());
    }

    public boolean invoke(String finction, String[] args) {
        Collection<ProposalResponse> successful = new LinkedList<>();
        Collection<ProposalResponse> failed = new LinkedList<>();
        try {
            /// Send transaction proposal to all peers
            TransactionProposalRequest transactionProposalRequest = client.newTransactionProposalRequest();
            transactionProposalRequest.setChaincodeID(chaincodeID);
            transactionProposalRequest.setFcn(finction);
            //transactionProposalRequest.setProposalWaitTime(testConfig.getProposalWaitTime());
            transactionProposalRequest.setArgs(args);

            Map<String, byte[]> tm2 = new HashMap<>();
            tm2.put("HyperLedgerFabric", "TransactionProposalRequest:JavaSDK".getBytes(UTF_8));
            tm2.put("method", "TransactionProposalRequest".getBytes(UTF_8));
            tm2.put("result", ":)".getBytes(UTF_8));  /// This should be returned see chaincode.
            try {
                transactionProposalRequest.setTransientMap(tm2);
            } catch (Exception e) {
            }

            Collection<ProposalResponse> transactionPropResp = channel.sendTransactionProposal(transactionProposalRequest, channel.getPeers());
            for (ProposalResponse response : transactionPropResp) {
                if (response.getStatus() == ProposalResponse.Status.SUCCESS) {
                    // out("Successful transaction proposal response Txid: %s from peer %s", response.getTransactionID(), response.getPeer().getName());
                    successful.add(response);
                } else {
                    failed.add(response);
                }
            }

            // Check that all the proposals are consistent with each other. We should have only one set
            // where all the proposals above are consistent.
            Collection<Set<ProposalResponse>> proposalConsistencySets = SDKUtils.getProposalConsistencySets(transactionPropResp);
            if (proposalConsistencySets.size() != 1) {
                out(format("Expected only one set of consistent proposal responses but got %d", proposalConsistencySets.size()));
            }

            //out("Received %d transaction proposal responses. Successful+verified: %d . Failed: %d",
            //        transactionPropResp.size(), successful.size(), failed.size());
            if (failed.size() > 0) {
                ProposalResponse firstTransactionProposalResponse = failed.iterator().next();
                out("Invoke:" + failed.size() + " endorser error: " +
                        firstTransactionProposalResponse.getMessage() +
                        ". Was verified: " + firstTransactionProposalResponse.isVerified());
            }
            //out("Successfully received transaction proposal responses.");

            // Send Transaction Transaction to orderer
            //BlockEvent.TransactionEvent transactionEvent = channel.sendTransaction(successful).get(testConfig.getTransactionWaitTime(), TimeUnit.SECONDS);
            BlockEvent.TransactionEvent transactionEvent = channel.sendTransaction(successful).get(fabricConfigV0.getWaiteTime(), TimeUnit.SECONDS);

            if (transactionEvent.isValid()) {
                //ut("Finished transaction with transaction id %s", transactionEvent.getTransactionID());
                return true;
            } else {
                return false;
            }
        } catch (Exception e) {
            //out("Caught an exception while invoking chaincode");
            e.printStackTrace();
            return false;
            //fail("Failed invoking chaincode with error : " + e.getMessage());
        }
    }

    public String query(String finction, String[] args) {
        try {
            //out("Now query chaincode for the value of b.");
            QueryByChaincodeRequest queryByChaincodeRequest = client.newQueryProposalRequest();
            queryByChaincodeRequest.setArgs(args);
            queryByChaincodeRequest.setFcn(finction);
            queryByChaincodeRequest.setChaincodeID(chaincodeID);

            Map<String, byte[]> tm2 = new HashMap<>();
            tm2.put("HyperLedgerFabric", "QueryByChaincodeRequest:JavaSDK".getBytes(UTF_8));
            tm2.put("method", "QueryByChaincodeRequest".getBytes(UTF_8));
            queryByChaincodeRequest.setTransientMap(tm2);

            Collection<ProposalResponse> queryProposals = channel.queryByChaincode(queryByChaincodeRequest, channel.getPeers());
            for (ProposalResponse proposalResponse : queryProposals) {
                if (!proposalResponse.isVerified() || proposalResponse.getStatus() != ProposalResponse.Status.SUCCESS) {
                    out("Failed query proposal from peer " + proposalResponse.getPeer().getName() + " status: " + proposalResponse.getStatus() +
                            ". Messages: " + proposalResponse.getMessage()
                            + ". Was verified : " + proposalResponse.isVerified());
                } else {
                    String payload = proposalResponse.getProposalResponse().getResponse().getPayload().toStringUtf8();
                    out("Query payload from peer %s returned %s", proposalResponse.getPeer().getName(), payload);
                    return payload;
                }
            }
        } catch (Exception e) {
            out("Caught exception while running query");
            e.printStackTrace();
            out("Failed during chaincode query with error : " + e.getMessage());
        }
        return null;
    }

    public void close() {
        channel.shutdown(true);
    }

    static void out(String format, Object... args) {
        System.err.flush();
        System.out.flush();

        System.out.println(format(format, args));
        System.err.flush();
        System.out.flush();

    }

    private static File findFileSk(File directory) {

        File[] matches = directory.listFiles((dir, name) -> name.endsWith("_sk"));

        if (null == matches) {
            throw new RuntimeException(format("Matches returned null does %s directory exist?", directory.getAbsoluteFile().getName()));
        }

        if (matches.length != 1) {
            throw new RuntimeException(format("Expected in %s only 1 sk file but found %d", directory.getAbsoluteFile().getName(), matches.length));
        }

        return matches[0];

    }
}
