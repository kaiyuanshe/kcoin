## 目录结构

```text
|-- src
|   |-- main
|   |   |-- java
|   |   |   `-- com
|   |   |       `-- kcoin
|   |   |           |-- user    业务模块
|   |   |           |   |-- UserController.java     Controller 控制层
|   |   |           |   |-- UserInterceptor.java    Interceptor 类级别拦截器
|   |   |           |   |-- UserService.java        Service 层
|   |   |           |   `-- UserValidator.java      后台校验器，可用于方法级拦截器
|   |   |           `-- common  基础模块,涉及Jfianl的基础配置，路由，全局拦截器等
|   |   |               |-- FrontRoutes.java        路由配置，url 与 controller 之间的映射
|   |   |               |-- KCoinConfig.java        设置 JFinal 运行环境，数据库连接池，模板引擎，缓存插件等
|   |   |               |-- _Generator.java         Model 生成器，根据数据库生产 model，新增/修改表后执行该类的 main 方法
|   |   |               |-- controller
|   |   |               |   `-- BaseController.java 基础 Controller，业务模块的 Controller 需要继承该类
|   |   |               |-- handler                 用于扩展 web 请求
|   |   |               |-- interceptor             用于存放全局拦截器
|   |   |               |-- kit                     用于存放工具类
|   |   |               `-- model
|   |   |                   |-- User.java           Model，由 Model 生成器生成，涉及 dao 层操作。也可追加自定义字段和方法，方便前端交互。
|   |   |                   |-- _MappingKit.java    Model 与 数据库表, id 的映射关系，由 Model 生成器生成
|   |   |                   `-- base
|   |   |                       `-- BaseUser.java   BaseModel,由 Model 生成器生成，对应数据库表字段，不可修改
|   |   |-- resources   资源文件
|   |   |   |-- configs.properties  存放配置信息，如：数据库配置，邮箱配置等
|   |   |   |-- log4j.properties    日志配置
|   |   |   `-- sql     用于存放业务 sql 文件
|   |   |       |-- All.sql     存放业务 sql 语句和配置子 sql 语句文件
|   |   |       `-- User.sql    存放业务 sql 语句，方便和其他模块区分，需要在 All.sql 中申明
|   |   `-- webapp
|   |       |-- META-INF
|   |       |   `-- MANIFEST.MF
|   |       |-- WEB-INF
|   |       |   `-- web.xml
|   |       `-- favicon.ico
|   `-- test    存放单元测试文件
|       `-- java
|-- KCoin.log       程序输出的日志文件
|-- README.md       开发文档
|-- kcoin.sqlite    数据库文件
|-- package.xml
`-- pom.xml         maven 配置文件
```

## 如何运行

在集成开发环境（Eclipse，IDEA）中 导入 Maven 项目，运行 `KCoinConfig` 类中的 `main` 方法即可。
在 IDEA 开发工具中， JFianl 集成的 jetty 无法直接热部署，可以部署到 tomcat 中(请同步修改 `configs.properties`中数据库的地址，以免找不到数据库)。

## 如何新增一个业务模块

新增业务模块的基本步骤如下：

1. 在 `src` 的 `com.kcoin` 包下，新增业务模块包： `com.kcoin.user`
2. 新建 `Controller` 文件： `com.kcoin.user.UserController`
```java
package com.kcoin.user;

import com.jfinal.core.Controller;

public class UserController extends Controller {
    public void index() {
        renderText("Hello kcoin");
    }
}
```
3. 配置 url， 在 `com.kcoin.common.FrontRoutes` 路由类中配置增加路由规则：`add("/user", UserController.class);`
4. 重启容器(新增/删除类，修改方法参数列表，注解等需要重启容器使修改生效)，访问 localhost:8089/user/index

在数据库中新增/修改表后，运行 `com.kcoin.common._Generator` 类中的 `main` 方法，将会生成对应表的 Model 和 BaseModel 类。
上面是新增一个业务模块的最简单的过程，实际开发过程需要要 Interceptor,Validator,Service等，请参考 [JFinal 官方文档](http://www.jfinal.com/doc)


## 参考资料

[JFinal 官方文档](http://www.jfinal.com/doc)

[JFinal API](https://apidoc.gitee.com/jfinal/jfinal/index.html?overview-summary.html)
