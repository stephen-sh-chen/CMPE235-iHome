// Youtube API
// 2. This code loads the IFrame Player API code asynchronously.
var tag = document.createElement('script');

tag.src = "https://www.youtube.com/iframe_api";
var firstScriptTag = document.getElementsByTagName('script')[0];
firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

// 3. This function creates an <iframe> (and YouTube player)
//    after the API code downloads.
var player;
function onYouTubeIframeAPIReady() {
    player = new YT.Player('youtube-iframe', {
        height: '390',
        width: '640',
        videoId: 'ybPzXEAAhXE',
        events: {
            'onReady': onPlayerReady,
            'onStateChange': onPlayerStateChange
        }
    });
}

// 4. The API will call this function when the video player is ready.
function onPlayerReady(event) {
    //event.target.playVideo();
}

// 5. The API calls this function when the player's state changes.
//    The function indicates that when playing a video (state=1),
//    the player should play for six seconds and then stop.
var done = false;
function onPlayerStateChange(event) {
    // if (event.data == YT.PlayerState.PLAYING && !done) {
    //     setTimeout(stopVideo, 6000);
    //     done = true;
    // }
}

// 6. stop the video
function stopVideo() {
    player.stopVideo();
}

$(document).ready(function(){
    var pubnub = PUBNUB({
        subscribe_key : 'sub-c-ac319e2e-ee4c-11e6-b325-02ee2ddab7fe'
    });

    // bulb
    var bulb_tracker = 'off';
    var bulb = document.getElementById('imgBulb');

    var door_tracker = 'close';
    var door = document.getElementById('imgDoor');
    //drawInactive(iProgressCTX);

    var fan = document.getElementById('imgFan');
    var temp_status = 'normal';

    pubnub.subscribe({
        channel: "my_channel",
        message: function(message){
            // door: open/close
            console.log(message.door);
            // bulb: on/off
            if (message[0].Types == 'Light' && message[0].Action == 'ON') {
                bulb.src='img/pic_bulbon.gif';
                bulb_tracker = 'on';
            } else if (message[0].Types == 'Light' && message[0].Action == 'OFF') {
                bulb.src='img/pic_bulboff.gif';
                bulb_tracker = 'off';
            }

            // Door
            if (message[0].Types == 'Door' && message[0].Action == 'ON') {
                door.src='img/door_open.gif';
                door_tracker = 'open';
            } else if (message[0].Types == 'Door' && message[0].Action == 'OFF') {
                door.src='img/door_close.png';
                door_tracker = 'close';
            }

            // Fan
            if (message[0].Types == 'Fan' && message[0].Action == 'ON') {
                fan.src='img/giphy_on.gif';
            } else if (message[0].Types == 'Fan' && message[0].Action == 'OFF') {
                fan.src='img/giphy_off.jpg';
            }

            // TV
            if (message[0].Types == 'TV' && message[0].Action == 'ON') {
                player.playVideo();
            } else if (message[0].Types == 'TV' && message[0].Action == 'OFF') {
                player.stopVideo();
            } else if (message[0].Types == 'TV' && message[0].Action == 'PAUSE') {
                player.pauseVideo();
            }

            // AC
            if (message[0].Types == 'AC' && message[0].Action == 'ON') {
                temp_status = 'cold';
            } else if (message[0].Types == 'AC' && message[0].Action == 'OFF') {
                temp_status = 'normal';
            }
        }
    });

    // temperature chart
    var dps = []; // dataPoints
    var chart = new CanvasJS.Chart("chartContainer", {
        title :{
            text: "Temperature Data"
        },
        axisX:{
            title: "second",
            gridThickness: 2
        },
        axisY: {
            title: "temperature(°F)",
            includeZero: false
        },
        data: [{
            type: "line",
            dataPoints: dps
        }]
    });

    var xVal = 5;
    var yVal = 60;
    var updateInterval = 5000;
    var dataLength = 20; // number of dataPoints visible at any point

    var updateChart = function (count) {
        count = count || 1;
        for (var j = 0; j < count; j++) {
            //normal, heater on, ac on
            if (temp_status == 'normal') {
                yVal = Math.round(65 + Math.random() * (66 - 65));
            } else if (temp_status == 'cold') {
                yVal = Math.round(55 + Math.random() * (56 - 55));
            } else if (temp_status == 'hot') {
                yVal = Math.round(75 + Math.random() * (76 - 5));
            }
            dps.push({
                x: xVal,
                y: yVal
            });
            xVal += 5;
        }

        if (dps.length > dataLength) {
            dps.shift();
        }

        chart.render();
    };
    updateChart(dataLength);
    setInterval(function(){updateChart()}, updateInterval);

});