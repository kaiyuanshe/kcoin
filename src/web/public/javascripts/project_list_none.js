// load project list view
$(function () {
    $("#btn_import").on("click", function () {
        openImportWin();
    });
    $(".btn_prev").on("click", function () {
        showPrevPage();
    });
    $(".btn_next").on("click", function () {
        showNextPage();
    });
    $("#btn_submit").on("click", function () {
        saveForm();
    });
    $("#search_input").on("change", function () {
        var fullName = $("#search_input").val();
        fullName = fullName.match(/github\.com[\:/]?(\S*)(\.git)?/);

        if (fullName === undefined || fullName == null) {
            Metro.toast.create("无法解析该URL，请重新输入!", null, 3000, "alert");
            return
        }
        fullName = fullName[1].replace(".git", "");

        if (fullName.split("/").length !== 2) {
            Metro.toast.create("URL格式不正确，请重新输入!", null, 3000, "alert");
            return
        }

        $.ajax({
            type: "GET",
            url: "/project/search_github?repo=" + fullName,
            success: function (res) {
                $("#github_project_id").data({});
                data = JSON.parse(res);
                if (data.error) {
                    Metro.toast.create(data.error.message, null, 3000, "alert");
                    return
                }

                if (data.permissions.admin) {
                    $("#project_title").html(data.name);
                    $(".project_name").val(data.name);
                    $("#github_project_id").val(data.id);
                    $("#github_project_id").data(data);

                    $("#kcoin_stepper").data('stepper')['next']();
                    $("#kcoin_master").data('master').next();

                    bindingContributors(fullName);
                } else {
                    Metro.toast.create("您无权导入该项目，请尝试联系项目管理员", null, 3000, "alert");
                }
            },
            error: function (res) {
                Metro.toast.create(res.responseText, null, 3000, "alert");
            }
        });
    });
    bindProjectPanel();
});

var list = [];
var contributors;
var projectListRenderFlag = false;
var import_activity;

function bindProjectPanel() {
    // get project List from other platform like github and render template
    $.ajax({
        type: "GET",
        url: "/project/fetchList",
        success: function (res) {
            // initPager();
            list = JSON.parse(res);
            if (list.login) {
                window.location.href = list.login;
                return;
            }
            let map = new Map();
            list.forEach(function (item) {
                if (map.has(item.owner.id)) {
                    map.get(item.owner.id).push(item);
                } else {
                    map.set(item.owner.id, [item]);
                }
            });

            renderTemplate($("#projectListTemplate").html(), $("#projectList"), map);
            if (import_activity) {
                Metro.window.toggle("#win_import");
                Metro.activity.close(import_activity);
            }
            projectListRenderFlag = true;
        }
    });
}

function openImportWin() {
    if (!projectListRenderFlag) {
        import_activity = Metro.activity.open({
            type: 'ring',
            overlayColor: '#fff',
            overlayAlpha: 0,
            text: '<div class=\'mt-2 text-small\'>请稍候, 正在加载项目列表...</div>',
            overlayClickClose: false
        });
    }

    if (projectListRenderFlag) {
        Metro.window.toggle("#win_import");
    }
}

function renderTemplate(template, target, data) {
    template = unescapeForMetro(template);
    target.html(Metro.template(template, {data}));
}

// replace &gt; and &lt; to >,<
function unescapeForMetro(str) {
    if (str === undefined || str === null) {
        return
    }
    return str.replace(/\&gt;/g, '>').replace(/\&lt;/g, '<');
}

// set disabled to input element
function toggleElementDisabled(source, flag) {
    source.each(function () {
        let target = $(this);
        if (target[0].value === undefined || target[0].value === null || target[0].value === '') {
            target.prop("disabled", flag);
        }
    });
}

// binding change event for member input to calculator token value
function bindingEventOnMemberInput() {
    $("[name='member_token']").on("change", function (event) {
        let total = 0;

        $("[name='member_token']").each(function () {
            total += Number($(this)[0].value);
        });
        let result = Number($("#init_supply")[0].value) - total;
        if (result < 0) {
            Metro.toast.create("预分配值大于当前剩余值，请重新分配！", null, 3000, "alert");
            event.target.value = '';
        } else if (result == 0) {
            toggleElementDisabled($("[name='member_token']"), true);
            $("#tokenNum").html(result)
        } else {
            toggleElementDisabled($("[name='member_token']"), false);
            $("#tokenNum").html(result)
        }
    });
}

// render contributors to page
function bindingContributors(full_name) {
    let uri = 'https://api.github.com/repos/' + full_name + '/contributors';

    $.ajax({
        type: "GET",
        url: uri,
        success: function (res) {
            contributors = res;
            renderTemplate($("#memberListTemplate").html(), $("#memberList"), res);
            bindingEventOnMemberInput()
        }
    });
}

// set to first page
function initPager() {
    $("#kcoin_stepper").data('stepper').first();
    $("#kcoin_master").data('master').toPage(0);
    $("#import_form")[0].reset()
}

function showNextPage(github_project_id) {
    if (github_project_id !== undefined) {
        let index = findElem(list, "id", github_project_id);
        $("#project_title").html(list[index].name);
        $(".project_name").val(list[index].name);
        $("#github_project_id").val(github_project_id);
        bindingContributors(list[index].full_name);
    } else {
        if (!validateForm()) {
            return
        }
        $(".tokenName").html($("#token_name").val());
        $("#tokenNum").html($("#init_supply").val());
    }

    $("#kcoin_stepper").data('stepper')['next']();
    $("#kcoin_master").data('master').next();
}

function showPrevPage() {
    if ($("#kcoin_stepper").data('stepper').current === 2) {
        initPager();
    } else {
        $("[name='member_token']").each(function () {
            $(this)[0].value = '';
        });
        toggleElementDisabled($("[name='member_token']"), false);
        $("#kcoin_stepper").data('stepper').prev();
        $("#kcoin_master").data('master').prev();
    }
}

// validate upload file size
function validateFileSize() {
    if ($("#img")[0].files[0].size < (1024 * 1024 * 2)) {
        return true;
    } else {
        return false;
    }
}

// validate form data
function validateForm() {
    let flag = true;
    if (!Metro.validator.validate($(".project_name"))) {
        flag = false;
    }
    if (!Metro.validator.validate($("#token_name"))) {
        flag = false;
    }
    if (!Metro.validator.validate($("#init_supply"))) {
        flag = false;
    }
    if (!Metro.validator.validate($("#img"))) {
        Metro.toast.create("上传的图片不能超过 2 M", null, 3000, "alert");
        flag = false;
    }
    return flag;
}

function saveForm() {
    if (!validateForm()) {
        return;
    }
    var github_project_id = $("#github_project_id").val();
    var index = findElem(list, "id", github_project_id);
    var formData = new FormData($("#import_form")[0]);
    var repo = index >= 0 ? list[index] : $("#github_project_id").data();
    formData.append("owner", repo.owner.login);

    $("[name='member_token']").each(function () {
        var id = $(this).attr('data-member-id');
        var tmp = contributors.find(x => x.id === Number(id));
        tmp["init_supply"] = $(this)[0].value
    });
    formData.append("contributors", JSON.stringify([...contributors]));

    $.ajax({
        type: "POST",
        data: formData,
        processData: false,
        contentType: false,
        url: "/project/saveProject",
        beforeSend: function () {
            $('#btn_submit').prop("disabled", "disabled");
        },
        success: function (res) {
            res = JSON.parse(res);
            console.log(res);
            if (res.code === 601) {
                // $("#container").load("/project/projectListsView");
                window.location.href = "/project";
            } else if (res.code === 602) {
                Metro.toast.create(res.msg, null, 3000, "alert");
                $('#btn_submit').prop("disabled", false);
            }
        }
    });
}

function closeWin() {
    initPager();
}

function findElem(arrayToSearch, attr, val) {
    for (var i = 0; i < arrayToSearch.length; i++) {
        if (arrayToSearch[i][attr] == val) {
            return i;
        }
    }
    return -1;
}
