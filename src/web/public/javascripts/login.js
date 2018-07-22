$(function () {
    if (location.search.length > 0) {
        $("#auth_login")[0].href = $("#auth_login")[0].href + location.search
    }
});

// validate uesr
function validateEmailAndPwd(el) {
    var flag = false;
    $.ajax({
        type: "post",
        url: "/user/validate/user",
        data: $("form").serialize(),
        async: false,
        success: function (msg) {
            flag = JSON.parse(msg).flag;
        }
    });
    return flag;
}
