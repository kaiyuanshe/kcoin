// load project list view
$(function () {
    $("#btn_import").on("click", function () {
        openImportWin();
    });
    $("#btn_prev").on("click", function () {
        showPrevPage();
    });
    $("#btn_submit").on("click", function () {
        saveForm();
    });
});

var list = [];

function openImportWin() {
    let import_activity = Metro.activity.open({
        type: 'square',
        overlayColor: '#fff',
        overlayAlpha: 0,
        text: '<div class=\'mt-2 text-small\'>请稍候, 正在加载项目列表...</div>',
        overlayClickClose: false
    });

    // if user does not oauth other account,show dialog for binding accounts

    // get project List from other platform like github and render template
    $.ajax({
        type: "GET",
        url: "/project/fetchList",
        success: function (res) {
            // initPager();
            list = JSON.parse(res);
            let map = new Map();
            list.forEach(function (item) {
                if (map.has(item.owner.id)) {
                    map.get(item.owner.id).push(item);
                } else {
                    map.set(item.owner.id, [item]);
                }
            });
            var template = $("#projectListTemplate").html();
            while (template.match(/\&gt;/) || template.match(/\&lt;/)) {
                template = template.replace(/\&gt;/, '>');
                template = template.replace(/\&lt;/, '<')
            }
            $("#projectList").html(Metro.template(template, {map}));
            Metro.activity.close(import_activity);
            Metro.window.toggle("#win_import");
        }
    });
}

function initPager() {
    $("#kcoin_stepper").data('stepper').first();
    $("#kcoin_master").data('master').toPage(0);
    $("#import_form")[0].reset()
}

function showNextPage(project_id) {
    $("#kcoin_stepper").data('stepper')['next']();
    $("#kcoin_master").data('master').next();
    let index = findElem(list, "id", project_id);
    $("#project_title").html(list[index].name);
    $("#project_name").val(list[index].name);
    $("#project_id").val(project_id);
}

function showPrevPage() {
    $("#kcoin_stepper").data('stepper').prev();
    $("#kcoin_master").data('master').prev();
}

function validateFileSize() {
    if ($("#img")[0].files[0].size < (1024 * 1024 * 2)) {
        return true;
    } else {
        return false;
    }
}

function saveForm() {
    if (!Metro.validator.validate($("#project_name"))) {
        return;
    }
    if (!Metro.validator.validate($("#img"))) {
        Metro.toast.create("上传的图片不能超过 2 M", null, 3000, "alert");
        return;
    }
    var project_id = $("#project_id").val();
    var index = findElem(list, "id", project_id);
    var formData = new FormData($("#import_form")[0]);
    formData.append("project", list[index]);
    debugger
    $.ajax({
        type: "POST",
        data: formData,
        processData: false,
        contentType: false,
        url: "/project/saveProject",
        success: function (res) {
            res = JSON.parse(res);
            if (res.code === 601) {
                $("#container").load("/project/projectListsView");
            } else if (res.code === 602) {
                Metro.toast.create(res.msg, null, 3000, "alert");
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
