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
    private Enrollment enrollment = null; //need access in test env.

    public KCoinUser(String name, String org) {
        this.name = name;
        this.organization = org;
    }

    public String getName() {
        return this.name;
    }

    public Set<String> getRoles() {
        return this.roles;
    }

    public void setRoles(Set<String> roles) {
        this.roles = roles;
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

    public String getEnrollmentSecret() {
        return enrollmentSecret;
    }

    public void setEnrollmentSecret(String enrollmentSecret) {
        this.enrollmentSecret = enrollmentSecret;
    }

    public void setEnrollment(Enrollment enrollment) {
        this.enrollment = enrollment;
    }


    public String getMspId() {
        return mspId;
    }

    String mspId;

    public void setMspId(String mspID) {
        this.mspId = mspID;
    }

    public String getOrganization() {
        return organization;
    }

    public void setOrganization(String organization) {
        this.organization = organization;
    }
}