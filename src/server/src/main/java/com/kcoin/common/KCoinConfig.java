package com.kcoin.common;

import com.jfinal.config.*;
import com.jfinal.json.MixedJsonFactory;
import com.jfinal.kit.Prop;
import com.jfinal.kit.PropKit;
import com.jfinal.template.Engine;
import com.kcoin.common.interceptor.CorsInterceptor;

/**
 * KCoin Config
 */
public class KCoinConfig extends JFinalConfig {

    static Prop p;

    public static void main(String[] args) {
    }

    static void loadConfig() {
        if (p == null) {
            p = PropKit.use("configs.properties");
        }
    }

    /**
     * Constant val
     * <p>
     * Get value by PropKit.get(...)
     */
    public void configConstant(Constants constants) {
        loadConfig();
        constants.setDevMode(p.getBoolean("devMode", false));
        constants.setJsonFactory(MixedJsonFactory.me());
    }

    /**
     * Route config
     */
    public void configRoute(Routes routes) {
        routes.add(new FrontRoutes());
    }

    public void configEngine(Engine engine) {
    }

    /**
     * Plugin config
     */
    public void configPlugin(Plugins plugins) {

    }

    /**
     * Global Interceptor
     */
    public void configInterceptor(Interceptors interceptors) {
        interceptors.addGlobalActionInterceptor(new CorsInterceptor());
    }

    /**
     * Global Handler
     */
    public void configHandler(Handlers handlers) {

    }
}
