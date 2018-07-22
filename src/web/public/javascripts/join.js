$.ajaxSetup({cache:false});

// validate email for kcoin
function validateExistEmail(val) {
    var flag = true;
    $.ajax({
        type: "post",
        url: "/user/validate/email",
        data: $("form").serialize(),
        async: false,
        success: function (msg) {
            flag = JSON.parse(msg).flag;
        }
    });
    return flag;

}
