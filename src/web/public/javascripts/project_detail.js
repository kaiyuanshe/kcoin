$(document).ready(function () {
    $("#btn_submit").on("click", function () {
        saveForm();
    });
    initCharts();
});


var kcoinChart = echarts.init($('#kcoin-chart')[0], 'macarons');
var tokenChart = echarts.init($('#token-chart')[0], 'macarons');

function initCharts() {

    genData();

    window.onresize = function () {
        kcoinChart.resize();
        tokenChart.resize();
    }
}

function genOption(title, seriesData) {
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
            data: seriesData,
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


function genData() {
    let url = "/project/getProjectState";
    $.ajax({
        type: "get",
        url: url,
        data: {
            "repo_name": $("#repo_name").val(),
            "repo_id": $("#repo_id").val(),
            "repo_owner": $("#repo_owner").val()
        },
        success: function (res) {
            let data = JSON.parse(res);
            let seriesData = [];

            for (let i = 0; i < data.stats.length; i++) {
                seriesData.push({
                    name: data.stats[i][0],
                    value: data.stats[i][1]
                });
            }

            // init KCoin state
            kcoinChart.setOption(genOption('KCoin 分配情况', seriesData));


            // init Token state
            tokenChart.setOption(genOption('Token 贡献分布', seriesData));

            // regist resize event
            window.onresize = function () {
                kcoinChart.resize();
                tokenChart.resize();
            }
        }
    });
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