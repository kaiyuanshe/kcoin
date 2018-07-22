// load project list view
$(function () {
    initProjectList();
});

function initProjectList() {
    $.ajax({
        type: "GET",
        url: "/project/projectLists",
        success: function (res) {
            var res = JSON.parse(res);
            var list = res.projectList;
            console.log(list);
            if (res.projectList.length > 0) {
                let template = $("#listTemplate").html();
                while (template.match(/\&gt;/) || template.match(/\&lt;/)) {
                    template = template.replace(/\&gt;/, '>');
                    template = template.replace(/\&lt;/, '<')
                }
                $("#listContainer").html(Metro.template(template, {list}));
            }
        }
    });
}
