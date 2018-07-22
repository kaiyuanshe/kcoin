/**
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License. See License.txt in the project root for
 * license information.
 */

package com.kcoin.fabric.model;

import io.netty.util.internal.StringUtil;
import org.bouncycastle.util.encoders.Hex;
import org.hyperledger.fabric.sdk.Enrollment;
import org.hyperledger.fabric.sdk.User;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.ObjectOutputStream;
import java.io.Serializable;
import java.util.Set;

/**
 * Created by juniwang on 22/07/2018.
 */
public class KCoinUser implements User, Serializable {
    private static final long serialVersionUID = 8077132186383604355L;

    private String name;
    private Set<String> roles;
    private String account;
    private String affiliation;
    private String organization;
    private String enrollmentSecret;
    Enrollment enrollment = null; //need access in test env.

    private transient KCoinStore keyValStore;
    private String keyValStoreName;

    KCoinUser(String name, String org, KCoinStore fs) {
        this.name = name;

        this.keyValStore = fs;
        this.organization = org;
        this.keyValStoreName = toKeyValStoreName(this.name, org);
        saveState();
        /*
        String memberStr = keyValStore.getValue(keyValStoreName);
        if (null == memberStr) {
            saveState();
        } else {
            restoreState();
        }
        */
    }


    public String getName() {
        return this.name;
    }


    public Set<String> getRoles() {
        return this.roles;
    }

    public void setRoles(Set<String> roles) {

        this.roles = roles;
        saveState();
    }


    public String getAccount() {
        return this.account;
    }

    /**
     * Set the account.
     *
     * @param account The account.
     */
    public void setAccount(String account) {

        this.account = account;
        saveState();
    }


    public String getAffiliation() {
        return this.affiliation;
    }

    /**
     * Set the affiliation.
     *
     * @param affiliation the affiliation.
     */
    public void setAffiliation(String affiliation) {
        this.affiliation = affiliation;
        saveState();
    }


    public Enrollment getEnrollment() {
        return this.enrollment;
    }

    /**
     * Determine if this name has been registered.
     *
     * @return {@code true} if registered; otherwise {@code false}.
     */
    public boolean isRegistered() {
        return !StringUtil.isNullOrEmpty(enrollmentSecret);
    }

    /**
     * Determine if this name has been enrolled.
     *
     * @return {@code true} if enrolled; otherwise {@code false}.
     */
    public boolean isEnrolled() {
        return this.enrollment != null;
    }

    /**
     * Save the state of this user to the key value store.
     */
    void saveState() {
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        try {
            ObjectOutputStream oos = new ObjectOutputStream(bos);
            oos.writeObject(this);
            oos.flush();
            keyValStore.setValue(keyValStoreName, Hex.toHexString(bos.toByteArray()));
            bos.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    /**
     * Restore the state of this user from the key value store (if found).  If not found, do nothing.
     */
    /*
    KCoinUser restoreState() {
        String memberStr = keyValStore.getValue(keyValStoreName);
        if (null != memberStr) {
            // The user was found in the key value store, so restore the
            // state.
            byte[] serialized = Hex.decode(memberStr);
            ByteArrayInputStream bis = new ByteArrayInputStream(serialized);
            try {
                ObjectInputStream ois = new ObjectInputStream(bis);
                KCoinUser state = (KCoinUser) ois.readObject();
                if (state != null) {
                    this.name = state.name;
                    this.roles = state.roles;
                    this.account = state.account;
                    this.affiliation = state.affiliation;
                    this.organization = state.organization;
                    this.enrollmentSecret = state.enrollmentSecret;
                    this.enrollment = state.enrollment;
                    this.mspId = state.mspId;
                    return this;
                }
            } catch (Exception e) {
                throw new RuntimeException(String.format("Could not restore state of member %s", this.name), e);
            }
        }
        return null;
    }
    */
    public String getEnrollmentSecret() {
        return enrollmentSecret;
    }

    public void setEnrollmentSecret(String enrollmentSecret) {
        this.enrollmentSecret = enrollmentSecret;
        saveState();
    }

    public void setEnrollment(Enrollment enrollment) {

        this.enrollment = enrollment;
        saveState();

    }

    public static String toKeyValStoreName(String name, String org) {
        return "user." + name + org;
    }

    public String getMspId() {
        return mspId;
    }

    String mspId;

    public void setMspId(String mspID) {
        this.mspId = mspID;
        saveState();

    }

}