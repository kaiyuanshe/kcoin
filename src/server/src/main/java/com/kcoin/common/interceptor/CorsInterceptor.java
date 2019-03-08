package com.kcoin.common.interceptor;


import com.jfinal.aop.Interceptor;
import com.jfinal.aop.Invocation;

public class CorsInterceptor implements Interceptor {
    @Override
    public void intercept(Invocation invocation) {
        javax.servlet.http.HttpServletResponse response = invocation.getController().getResponse();
        response.addHeader("Access-Control-Allow-Origin", "*");
        invocation.invoke();
    }
}
