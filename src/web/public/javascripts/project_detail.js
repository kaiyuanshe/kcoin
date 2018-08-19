$(document).ready(function () {
    $("#btn_submit").on("click", function () {
        saveForm();
    });

    initCharts();
});

function initCharts() {
    var kcoinChart = echarts.init($('#kcoin-chart')[0], 'macarons');
    var tokenChart = echarts.init($('#token-chart')[0], 'macarons');

    var option = genOption('KCoin 分配情况', genData("kcoin"));
    kcoinChart.setOption(option);
    var option2 = genOption('Token 贡献分布', genData("token"));
    tokenChart.setOption(option2);
    window.onresize = function () {
        kcoinChart.resize();
        tokenChart.resize();
    }
}

function genOption(title, data) {
    return {
        title: {
            text: title,
            x: 'center'
        },
        tooltip: {
            trigger: 'item',
            formatter: "{a} <br/>{b} : {c} ({d}%)"
        },
        legend: {
            type: 'scroll',
            orient: 'horizontal',
            bottom: 20
        },
        series: [{
            type: 'pie',
            radius: '55%',
            center: ['50%', '50%'],
            data: data.seriesData,
            itemStyle: {
                emphasis: {
                    shadowBlur: 10,
                    shadowOffsetX: 0,
                    shadowColor: 'rgba(0, 0, 0, 0.5)'
                }
            }
        }]
    };
}

function genData(key) {
    let url = "/project/getProjectState";
    let data;
    if (key === "kcoin") {
        // url = "";
    } else if (key === "token") {
        // url = ""
    } else {
        return {
            seriesData: [],
        };
    }

    $.ajax({
        type: "get",
        url: url,
        data: {
            "repo_name": $("#repo_name").val(),
            "repo_owner": $("#repo_owner").val()
        },
        async: false,
        success: function (res) {
            data = JSON.parse(res);
        }
    });

    var seriesData = [];
    for (let i = 0; i < data.length; i++) {
        seriesData.push({
            name: data[i].author.login,
            value: data[i].total
        });
    }

    return {
        seriesData: seriesData,
    };

}

function saveForm() {
    if (!Metro.validator.validate($("#project_name"))) {
        return;
    }
    if (!Metro.validator.validate($("#img"))) {
        Metro.toast.create("上传的图片不能超过 2 M", null, 3000, "alert");
        return;
    }
    var formData = new FormData($("#form")[0]);
    $.ajax({
        type: "POST",
        data: formData,
        processData: false,
        contentType: false,
        url: "/project/updateProject",
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

function validateFileSize() {
    if ($("#img")[0].files[0].size < (1024 * 1024 * 2)) {
        return true;
    } else {
        return false;
    }
}