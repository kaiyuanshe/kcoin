package com.kcoin.user;

import com.jfinal.kit.Ret;
import com.kcoin.common.model.Users;

import java.util.List;


public class UserService {

    public static final UserService me = new UserService();

    public Ret findAll() {
        List<Users> users = Users.dao.find("select * from users");
        return Ret.ok().set("result", users);
    }
}
