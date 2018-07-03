package com.kcoin.common;

import javax.sql.DataSource;

import com.jfinal.plugin.activerecord.dialect.Sqlite3Dialect;
import com.kcoin.common.KCoinConfig;
import com.jfinal.kit.PathKit;
import com.jfinal.plugin.activerecord.generator.Generator;
import com.jfinal.plugin.druid.DruidPlugin;

/**
 * Run this main function will sync change BaseModel,Model,_MappingKit if table changed or created.
 */
public class _Generator {

    private static String[] excludedTable = {"sqlite_sequence", "sqlite_master", "migrations"};

    public static DataSource getDataSource() {
        DruidPlugin druidPlugin = KCoinConfig.getDruidPlugin();
        druidPlugin.start();
        return druidPlugin.getDataSource();
    }

    public static void main(String[] args) {
        // base model package name
        String baseModelPackageName = "com.kcoin.common.model.base";
        // base model file path
        String baseModelOutputDir = PathKit.getWebRootPath() + "/src/main/java/com/kcoin/common/model/base";

        // model package name
        String modelPackageName = "com.kcoin.common.model";
        // model file path
        String modelOutputDir = baseModelOutputDir + "/..";

        // create generator
        Generator generator = new Generator(getDataSource(), baseModelPackageName, baseModelOutputDir, modelPackageName, modelOutputDir);
        // set DB dialect
        generator.setDialect(new Sqlite3Dialect());
        // add exclude tables
        for (String table: excludedTable) {
            generator.addExcludedTable(table.trim());
        }
        // set setter chain
        generator.setGenerateChainSetter(true);
        // set dao object in model
        generator.setGenerateDaoInModel(true);
        // generate
        generator.generate();
    }
}
