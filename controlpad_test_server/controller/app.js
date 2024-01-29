import { send_datum } from "./controlpad.js";


// Throttle function to limit the rate of execution
function throttle(func, limit) {
    var lastFunc;
    var lastRan;
    return function() {
        const context = this;
        const args = arguments;
        if (!lastRan) {
            func.apply(context, args);
            lastRan = Date.now();
        } else {
            clearTimeout(lastFunc);
            lastFunc = setTimeout(function() {
                if ((Date.now() - lastRan) >= limit) {
                    func.apply(context, args);
                    lastRan = Date.now();
                }
            }, limit - (Date.now() - lastRan));
        }
    }
}


// Movement
let isTouchActive = false;
let touchStart = {x: 0, y: 0};

var touchPad = document.getElementById('movePad');

touchPad.addEventListener('touchstart', function(e) {
    isTouchActive = true;

    // Prevent the default highlighting behavior
    e.preventDefault();

    // Get the touch position
    var touch = e.touches[0];
    var touchX = touch.clientX;
    var touchY = touch.clientY;

    touchStart.x = touchX;
    touchStart.y = touchY;
}, false);


touchPad.addEventListener('touchend', function(e) {
    isTouchActive = false;
    send_datum("move:0,0");
}, false);

touchPad.addEventListener('touchcancel', function(e) {
    isTouchActive = false;
    send_datum("move:0,0");
}, false);

var throttledDragEvent = throttle(function(e) {
    // Get the touch position
    var touch = e.touches[0];
    var touchX = touch.clientX;
    var touchY = touch.clientY;

    if (isTouchActive) {
        let datum = "move:" + String(touchX - touchStart.x) + "," + String(touchY - touchStart.y);
        send_datum(datum);
        //console.log(datum);
    }
}, 33); // Throttle to 30 times per second (33.33 milliseconds)

// Add the throttled touchmove event listener to the element
touchPad.addEventListener('touchmove', throttledDragEvent, false);



// Movement
let isBowTouchActive = false;
let bowTouchStart = {x: 0, y: 0};

var bowPad = document.getElementById('bowPad');

bowPad.addEventListener('touchstart', function(e) {
    isTouchActive = true;

    // Prevent the default highlighting behavior
    e.preventDefault();

    // Get the touch position
    var touch = e.touches[0];
    var touchX = touch.clientX;
    var touchY = touch.clientY;

    // Print "touch start" and the x,y position
    console.log("touch start: " + touchX + ", " + touchY);
    touchStart.x = touchX;
    touchStart.y = touchY;
}, false);


bowPad.addEventListener('touchend', function(e) {
    isTouchActive = false;
    send_datum("bow:0,0");
}, false);

bowPad.addEventListener('touchcancel', function(e) {
    isTouchActive = false;
    send_datum("bow:0,0");
}, false);


var bowDrag = throttle(function(e) {
    // Get the touch position
    var touch = e.touches[0];
    var touchX = touch.clientX;
    var touchY = touch.clientY;

    if (isTouchActive) {
        let datum = "bow:" + String(touchX - touchStart.x) + "," + String(touchY - touchStart.y);
        send_datum(datum);
    }
}, 33); // Throttle to 30 times per second (33.33 milliseconds)

// Add the throttled touchmove event listener to the element
bowPad.addEventListener('touchmove', bowDrag, false);
