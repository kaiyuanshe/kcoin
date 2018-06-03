module EmailAppHelpers
  require 'net/smtp'

  def send_email(_user)
    email = _user.email
    name = _user.email.split('@')[0]
    activeUrl = request.base_url + '/user/activeUser?' + URI.encode(_user.id)

    message = <<MESSAGE_END
From: kcoin@163.com
To: #{email}
MIME-Version: 1.0
Content-type: text/html
Subject: kcoin 帐号激活

<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <html>
    <head>
        <meta content="text/html;charset=UTF-8" http-equiv="Content-Type">
        <style media="all" type="text/css">
            td, p, h1, h3, a {
                font-family: Microsoft YaHei, sans-serif;
            }
        </style>
    </head>

<body LINK="#c6d4df" ALINK="#c6d4df" VLINK="#c6d4df" TEXT="#c6d4df"
      style="font-family: Microsoft YaHei, sans-serif; font-size: 14px; color: #c6d4df;">
<table style="width: 600px; background-color: #393836;" align="center" cellspacing="0" cellpadding="0">
    <tr>
        <td style=" height: 65px; background-color: #000000; border-bottom: 1px solid #4d4b48;">
            <a style="text-decoration: none;" href="http://kcoin.kaiyuanshe.cn/">
            <span style="font-size: 36px;color: #66c0f4;font-family: Microsoft YaHei, sans-serif;font-weight: bold;padding-left: 10px;padding-left: 10px;">
                <span style="color: #00a3d9;">K</span>coin
            </span>
            </a>
        </td>
    </tr>
    <tr>
        <td bgcolor="#17212e">
            <table width="470" border="0" align="center" cellpadding="0" cellspacing="0"
                   style="padding-left: 5px; padding-right: 5px; padding-bottom: 10px;">

                <tr bgcolor="#17212e">
                    <td style="padding-top: 32px;">
					<span style="padding-top: 16px; padding-bottom: 16px; font-size: 24px; color: #66c0f4; font-family: Microsoft YaHei, sans-serif; font-weight: bold;">
						尊敬的 #{name}：
					</span><br>
                    </td>
                </tr>

                <tr>
                    <td style="padding-top: 12px;">
					<span style="font-size: 17px; color: #c6d4df; font-family: Microsoft YaHei, sans-serif; font-weight: bold;">
						<p>您在 kcoin 上注册了一个新用户，帐号为：#{email}</p>
                        <p>请点下面链接以激活您的账号：</p>
                        <p><a style="color: #8f98a0;"
                              href="#{activeUrl}">#{activeUrl}</a>
                        </p>
					</span>
                    </td>
                </tr>


                <tr>
                    <td>
                        <br>
                    </td>
                </tr>


                <tr bgcolor="#121a25">
                    <td style="padding: 20px; font-size: 12px; line-height: 17px; color: #c6d4df; font-family: Microsoft YaHei, sans-serif;">
                        Kcion 是一个开源项目激励平台，结合区块链技术......
                    </td>

                </tr>
            </table>
        </td>
    </tr>

    <td bgcolor="#000000">
        <table width="460" height="55" border="0" align="center" cellpadding="0" cellspacing="0">
            <tr valign="top">
                <td width="350" valign="top">
                    <span style="color: #999999; font-size: 12px; font-family: Microsoft YaHei, sans-serif;">本邮件由系统发出，请勿直接回复。</span>
                </td>
            </tr>
        </table>
    </td>
    </tr>
</table>

</body>
</html>


MESSAGE_END

    Net::SMTP.start('smtp.163.com',
                    25,
                    '163.com',
                    '13993143738', 'a19924141', :plain) do |smtp|
      smtp.send_message message, '13993143738@163.com',
                        email
    end
  end
end
