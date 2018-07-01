// validate uesr
function validateEmailAndPwd(el) {
    var flag = false;
    $.ajax({
        type: "GET",
        url: "/user/validate/user",
        data: $("form").serialize(),
        async: false,
        success: function (msg) {
            flag = JSON.parse(msg).flag;
        }
    });
    return flag;
}
