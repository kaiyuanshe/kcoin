/**
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License. See License.txt in the project root for
 * license information.
 */

package com.kcoin.fabric;

import com.kcoin.fabric.model.KCoinUser;
import org.hyperledger.fabric.sdk.Peer;
import org.hyperledger.fabric.sdk.User;
import org.hyperledger.fabric_ca.sdk.HFCAClient;

import java.util.*;

/**
 * Created by juniwang on 22/07/2018.
 */
public class KCoinOrg {
    final String name;
    final String mspid;
    HFCAClient caClient;

    Map<String, User> userMap = new HashMap<>();
    Map<String, String> peerLocations = new HashMap<>();
    Map<String, String> ordererLocations = new HashMap<>();
    Map<String, String> eventHubLocations = new HashMap<>();
    Set<Peer> peers = new HashSet<>();

    Map<String, Properties> peerProperties = new HashMap<>();
    Map<String, Properties> ordererProperties = new HashMap<>();

    private KCoinUser admin;
    private String caLocation;
    private Properties caProperties = null;

    private KCoinUser peerAdmin;
    private String domainName;
    private String keystorePath;
    private String signcertsPath;

    public KCoinOrg(String name, String mspid) {
        this.name = name;
        this.mspid = mspid;
    }

    public KCoinUser getAdmin() {
        return admin;
    }

    public void setAdmin(KCoinUser admin) {
        this.admin = admin;
    }

    public String getMSPID() {
        return mspid;
    }

    public String getCALocation() {
        return this.caLocation;
    }

    public void setCALocation(String caLocation) {
        this.caLocation = caLocation;
    }

    public void addPeerLocation(String name, String location) {

        peerLocations.put(name, location);
    }

    public void addOrdererLocation(String name, String location) {

        ordererLocations.put(name, location);
    }

    public void addPeerProperties(String name, Properties properties) {

        peerProperties.put(name, properties);
    }

    public void addOrdererProperties(String name, Properties properties) {

        ordererProperties.put(name, properties);
    }

    public void addEventHubLocation(String name, String location) {

        eventHubLocations.put(name, location);
    }

    public String getPeerLocation(String name) {
        return peerLocations.get(name);

    }

    public String getOrdererLocation(String name) {
        return ordererLocations.get(name);

    }

    public Properties getPeerProperties(String name) {
        return peerProperties.get(name);

    }

    public Properties getOrdererProperties(String name) {
        return ordererProperties.get(name);

    }

    public String getEventHubLocation(String name) {
        return eventHubLocations.get(name);

    }

    public Set<String> getPeerNames() {

        return Collections.unmodifiableSet(peerLocations.keySet());
    }


    public Set<String> getOrdererNames() {

        return Collections.unmodifiableSet(ordererLocations.keySet());
    }

    public Set<String> getEventHubNames() {

        return Collections.unmodifiableSet(eventHubLocations.keySet());
    }

    public HFCAClient getCAClient() {

        return caClient;
    }

    public void setCAClient(HFCAClient caClient) {

        this.caClient = caClient;
    }

    public String getName() {
        return name;
    }

    public void addUser(KCoinUser user) {
        userMap.put(user.getName(), user);
    }

    public User getUser(String name) {
        return userMap.get(name);
    }

    public Collection<String> getOrdererLocations() {
        return Collections.unmodifiableCollection(ordererLocations.values());
    }

    public Collection<String> getEventHubLocations() {
        return Collections.unmodifiableCollection(eventHubLocations.values());
    }

    public Set<Peer> getPeers() {
        return Collections.unmodifiableSet(peers);
    }

    public void addPeer(Peer peer) {
        peers.add(peer);
    }

    public void setCAProperties(Properties caProperties) {
        this.caProperties = caProperties;
    }

    public Properties getCAProperties() {
        return caProperties;
    }


    public KCoinUser getPeerAdmin() {
        return peerAdmin;
    }

    public void setPeerAdmin(KCoinUser peerAdmin) {
        this.peerAdmin = peerAdmin;
    }

    public void setDomainName(String domainName) {
        this.domainName = domainName;
    }

    public String getDomainName() {
        return domainName;
    }

    public void setKeystorePath(String keystorePath) {
        this.keystorePath = keystorePath;
        System.out.println("KeystorePath:" + keystorePath);
    }

    public String getKeystorePath() {
        return keystorePath;
    }

    public void setSigncertsPath(String signcertsPath) {
        this.signcertsPath = signcertsPath;
        System.out.println("Signcerts Path:" + signcertsPath);
    }

    public String getSigncertsPath() {
        return signcertsPath;
    }
}
