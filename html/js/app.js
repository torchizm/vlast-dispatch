IsOpen = false;

let ShowNotifications = true;
let ShowGps = true;
let ShowEditRadioCode = false;

let Self = [];
let NotificationHistory = [];
let Cache = [];
// let NotificationHtmls = [];

Notifications = []

$(document).ready(function() {
    // Notifications.forEach(notify => {
    //     createNotification(notify).appendTo('#app-contents');
    // });

    document.onkeyup = function(data) {
        if (data.which == 27) {
            close();
        }
    }

    window.addEventListener('message', (event) => {
        switch (event.data.type) {
            case "open":
                $("#app-container").css("display", "block");

                $("#app-container").animate({
                    margin: "16px"
                }, 300, "easeOutBounce");

                Self = event.data.user;
                $("#self-radio-code").html(Self.radioCode);
                $("#self-name").html(Self.name);
                $("#self-job").html(Self.job);

                break;
            case "notification":
                var audio = new Audio('https://cdn.discordapp.com/attachments/767392265773383761/862301178519224340/bipbip.ogg');
                audio.play();

                Notifications.push(event.data.data);
                var notifElement = createNotification(event.data.data);
                var staticElement = createNotification(event.data.data);
                staticElement.appendTo('#app-contents');
                $(`#app-contents .notification-item[data-notification-id='${event.data.data.id}'] #shortcut`).remove();
                pushNotification(event.data.data);
                break;
            case "update":
                switch (event.data.content) {
                    case "self":
                        Self = event.data.data;
                        break;
                    case "notifications":
                        Notifications = event.data.data;
                        break;
                    case "add-active-unit":
                        addActiveUnit(event.data.data.notifid, event.data.data.radioid, false);
                        break;
                    case "remove-active-unit":
                        removeActiveUnit(event.data.data.notifid, event.data.data.radioid, false);
                        break;
                    default:
                        break;
                }
            default:
                break;
        }
    })
});

function close() {
    $("#app-container").animate({
        "margin": "16px -110% 16px 16px"
    }, 400);

    setTimeout(() => {
        $("#app-container").css("display", "none");
    }, 500);

    $.post('http://vlast-dispatch/close', JSON.stringify({}));
}

function pushNotification(data) {
    if (!IsOpen && ShowNotifications) {
        var element = createNotification(data);

        element.css('margin-left', '110%');
        element.appendTo('.notification-container');

        element.animate({
            "margin-left": "0"
        }, 400);

        $("#notification-container").css('background', '#000000');

        setTimeout(() => {
            element.animate({
                "margin-left": "110%"
            }, 400);
        }, 4000);

        setTimeout(() => {
            element.remove();
        }, 5000);
    }
}

function createNotification(data) {
    let activeUnits = "";

    if (data.activeUnits != undefined) {
        data.activeUnits.forEach(element => {
            activeUnits += `<span class="unit-radio-code" id="unit-radio-code" data-radio-ids="${element}">${element}</span>`
        });
    }

    let elem = $('<div/>', {
        'class': 'notification-item',
        'html': `
        <div class="notification-header">
            <div>
                <span>#${data.code}</span>
                <span>${getDate()}</span>
            </div>
            <span></span>
        </div>

        <div class="notification-details">
            <span>${data.description}</span>
        </div>

        ${data.coords != undefined ? `
            <div class="location-field">
                <span id="shortcut">[ALT]</span>
                <i id="set-waypoint" data-coords-x=${data.coords.x.toFixed(2)} data-coords-y=${data.coords.y.toFixed(2)} class="fas fa-map shortcut"></i>
                <span id="location-text">${data.location}</span>
            </div>
            ` : ""
        }

        ${activeUnits == undefined || activeUnits.length == 0 ? `
            <div class="notification-footer">
                <div class="notification-footer-field">
                    <span class="title">İntikal eden birimler</span>
                    <i id="button-icon" class="fas fa-plus-circle"></i>
                </div>
                <div id="active-units" class="active-units">
                </div>
            </div>
        ` : `
            <div class="notification-footer">
                <div class="notification-footer-field">
                    <span class="title">İntikal eden birimler</span>
                    <i id="button-icon" class="fas fa-plus-circle"></i>
                </div>
                <div id="active-units" class="active-units">
                    ${activeUnits}
                </div>
            </div>`}
        `
    }).attr({
        'data-notification-id': `${data.id}`
    });

    $(elem).find('#set-waypoint').click(function() {
       $.post('http://vlast-dispatch/set-waypoint', JSON.stringify({x: $(this).attr('data-coords-x'), y: $(this).attr('data-coords-y')})); 
    });

    $(elem).find('#button-icon').click(function() {
        if ($(elem).find('#button-icon').hasClass("fa-plus-circle")) {
            $.post('http://vlast-dispatch/addActiveUnit', JSON.stringify({citizenid: Self.citizenId, notifid: data.id, radioid: Self.radioCode}));
        } else {
            $.post('http://vlast-dispatch/removeActiveUnit', JSON.stringify({citizenid: Self.citizenId, notifid: data.id, radioid: Self.radioCode}));
        }
    });

    return elem;
}

function addActiveUnit(notifid, radioid, post) {
    if (Self.radioCode == "YOK") return;

    const mainDispatch = $(`.notification-item[data-notification-id='${notifid}']`);
    let unitElements = $(`.notification-item[data-notification-id='${notifid}']`);

    if (unitElements.find(`.unit[data-radio-id=${radioid}]`).length >= 1) return;

    if (unitElements.find('.unit-radio-code').length !== 0) {
        unitElements = unitElements.find('.unit-radio-code');
    }
    
    if (Cache[radioid] != undefined) {
        removeActiveUnit(Cache[radioid], radioid, true);
    }

    if (unitElements.length != 0) {
        var unitElem = $('<span/>', {
            class: "unit",
            html: radioid
        }).appendTo(mainDispatch.find("#active-units")).attr({
            'data-radio-id': radioid
        });

        Cache[radioid] = notifid;
    };
    
    if (radioid == Self.radioCode) {
        mainDispatch[0].querySelector("#button-icon").classList = "fas fa-minus-circle";
    }
}

function removeActiveUnit(notifid, radioid, post) {
    const mainDispatch = $(`.unit[data-radio-id='${radioid}']`);
    const unitElements = $(`.notification-item[data-notification-id='${notifid}']`);

    Cache[radioid] = undefined;
    mainDispatch[0].parentNode.parentNode.querySelector("#active-units").querySelector(`span[data-radio-id=${radioid}]`).remove();
    
    if (radioid == Self.radioCode) {
        unitElements[0].querySelector("#button-icon").classList = "fas fa-plus-circle";
    }
}


function getDate() {
    return new Date().toLocaleTimeString().replace(/([\d]+:[\d]{2})(:[\d]{2})(.*)/, "$1$3");
}

$('#toggle-notifications').click(function() {
    ShowNotifications = !ShowNotifications;
    
    if (ShowNotifications) {
        $(this).addClass("fa-bell");
        $(this).removeClass("fa-bell-slash");
    } else {
        $(this).removeClass("fa-bell");
        $(this).addClass("fa-bell-slash");
    }
});

$('#toggle-gps').click(function() {
    ShowGps = !ShowGps;
    
    if (ShowGps) {
        $(this).addClass("fa-eye");
        $(this).removeClass("fa-eye-slash");
    } else {
        $(this).removeClass("fa-eye");
        $(this).addClass("fa-eye-slash");
    }
});

$('#toggle-radio-code-input').click(function() {
    ToggleEditRadioCode();
});

function ToggleEditRadioCode() {
    ShowEditRadioCode = !ShowEditRadioCode;

    if (ShowEditRadioCode) {
        $("#radio-code").css("height", "auto");
        $(".app-header-field").css("margin-bottom", "8px");

        $("#radio-code").css("display", "inline-block");
    } else {
        $("#radio-code").css("height", "0px");
        $(".app-header-field").css("margin-bottom", "0px");

        setTimeout(() => {
            $("#radio-code").css("display", "none");
        }, 400);
    }
}

$("#radio-code").keyup(function(event) { 
    if (event.which == 13) {
        radiocode = $("#radio-code").val();
        $.post("http://vlast-dispatch/set-radio-code", JSON.stringify({radiocode}), (data) => {
            if (data) {
                if (data) {
                    Self.radioCode = radiocode;
                    $("#self-radio-code").html(radiocode);
                }

                $('.notification-item span.unit').each(function() {
                    if ($(this).html() == Self.radioCode) {
                        $(this).html(radiocode);
                        $(this).attr("data-radio-id", radiocode);
                    }
                });

                Self.radioCode = radiocode;
                ToggleEditRadioCode();
            }
        });
    }
})