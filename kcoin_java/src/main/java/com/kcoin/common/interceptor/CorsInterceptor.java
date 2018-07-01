package com.kcoin.common.interceptor;


import com.jfinal.aop.Interceptor;
import com.jfinal.aop.Invocation;

public class CorsInterceptor implements Interceptor {
    @Override
    public void intercept(Invocation invocation) {
        invocation.getController().getResponse().addHeader("Access-Control-Allow-Origin", "*");
        invocation.invoke();
    }
}
