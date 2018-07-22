package com.kcoin.user;

import com.jfinal.core.Controller;
import com.jfinal.kit.Ret;

public class UserController extends BaseController {

    // 渲染文本
    public void index() {
        renderText("Hello Kcoin");
    }

    // 返回 Json 数据
    public void getUserList() {
        Ret ret = UserService.me.findAll();
        renderJson(ret);
    }
}
