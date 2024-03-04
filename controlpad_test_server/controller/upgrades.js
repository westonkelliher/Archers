import { send_controlpad_message } from "./controlpad.js";
////////////////////////////// Upgrades //////////////////////////////

const BORDER = "0px solid #111111";


export function layoutUpgrades() {
    var upgradesDiv = document.getElementById("upgrades");
    upgradesDiv.style.display = "block";
    upgradesDiv.style.position = "absolute";
    upgradesDiv.style.top = "50%";
    upgradesDiv.style.left = "50%";
    upgradesDiv.style.transform = "translate(-50%, -50%)";
    upgradesDiv.style.width = "130vh";
    upgradesDiv.style.height = "85vh";
    //
    upgradesDiv.style.border = BORDER;
    upgradesDiv.style.borderRadius = "30px";
    
    //// Bow Upgrade ////
    var upDiv1 = document.getElementById("up1");
    upDiv1.style.top = "2%";
    upDiv1.style.left = "1%";
    //
    populateUpDiv(upDiv1);
    
    //// Arrow Upgrade ////
    var upDiv2 = document.getElementById("up2");
    upDiv2.style.top = "2%";
    upDiv2.style.left = "50%";
    upDiv2.style.transform = "translate(-50%, 0%)";
    //
    populateUpDiv(upDiv2);

    //// Armor Upgrade ////
    var upDiv3 = document.getElementById("up3");
    upDiv3.style.top = "2%";
    upDiv3.style.right = "1%";
    //
    populateUpDiv(upDiv3);
}


function populateUpDiv(upDiv) {
    // remove any old children
    while (upDiv.firstChild) {
        upDiv.removeChild(upDiv.firstChild);
    }
    // size it
    upDiv.style.position = "absolute";
    upDiv.style.width = "29%";
    upDiv.style.height = "96%";
    //
    upDiv.style.border = BORDER;
    upDiv.style.borderRadius = "30px";
    ////
    var old_square = document.createElement('img');
    old_square.src = "./resources/equipment_box_inactive.png";
    old_square.style.position = "absolute";
    old_square.style.top = "0vh";
    old_square.style.left = "50%";
    old_square.style.transform = "translate(-50%, 0%)";
    old_square.style.width = "36vh";
    old_square.style.height = "36vh";
    upDiv.appendChild(old_square);
    ////
    var arrow = document.createElement('img');
    arrow.src = "./resources/arrow_down.png";
    arrow.style.position = "absolute";
    arrow.style.top = "49.5%";
    arrow.style.left = "50%";
    arrow.style.transform = "translate(-50%, -50%)";
    arrow.style.width = "16vh";
    arrow.style.height = "16vh";
    upDiv.appendChild(arrow);
    ////
    var new_square = document.createElement('img');
    new_square.src = "./resources/equipment_box_active.png";
    new_square.style.position = "absolute";
    new_square.style.bottom = "0vh";
    new_square.style.left = "50%";
    new_square.style.transform = "translate(-50%, 0%)";
    new_square.style.width = "36vh";
    new_square.style.height = "36vh";
    upDiv.appendChild(new_square);
}


/*
//////////////////// MovePad ////////////////////
var MOVE_BASE_IMG;
var MOVE_STICK_IMG;

let moveTouchActive = false;
let moveTouchStart = {x: 0, y: 0};
var movePad = document.getElementById('movePad');
movePad.style.zIndex = "1";
let moveStickPosition = {x: 0, y: 0};

export function layoutMovePad() {
    var movePad = document.getElementById('movePad');
    movePad.style.zIndex = "1";
    movePad.style.position = "absolute";
    movePad.style.bottom = "12px";
    movePad.style.left = "12px";
    //movePad.style.transform = "translate(-50%, -50%)";
    movePad.style.width = "250px";
    movePad.style.height = "250px";
    //movePad.style.border = "1px solid #bbbbbb";
    movePad.style.borderRadius = "140px";
    //
    var pad_img = document.createElement('img');
    pad_img.style.zIndex = "2";
    pad_img.style.position = "absolute";
    pad_img.style.bottom = "8px";
    pad_img.style.left = "8px";
    pad_img.style.width = "250px";
    pad_img.style.height = "250px";
    pad_img.style.pointerEvents = "none";
    pad_img.src = "./resources/joystick_pad_move.png";
    //
    var base_img = document.createElement('img');
    base_img.style.zIndex = "3";
    base_img.style.position = "absolute";
    base_img.style.width = "140px";
    base_img.style.height = "140px";
    base_img.style.transform = "translate(-50%, -50%)";
    base_img.style.pointerEvents = "none";
    base_img.src = "./resources/joystick_base.png";
    base_img.style.display = "none";
    MOVE_BASE_IMG = base_img;
    //
    var stick_img = document.createElement('img');
    stick_img.style.zIndex = "4";
    stick_img.style.position = "absolute";
    stick_img.style.width = "110px";
    stick_img.style.height = "110px";
    stick_img.style.transform = "translate(-50%, -50%)";
    stick_img.style.pointerEvents = "none";
    stick_img.src = "./resources/joystick_stick.png";
    stick_img.style.display = "none";
    MOVE_STICK_IMG = stick_img;
    //
    while (movePad.firstChild) {
        movePad.removeChild(movePad.firstChild);
    }
    var mainDiv = document.getElementById('mainDi');
    mainDiv.appendChild(pad_img);
    mainDiv.appendChild(base_img);
    mainDiv.appendChild(stick_img);
}

movePad.addEventListener('touchstart', function(e) {
    // Prevent the default highlighting behavior
    e.preventDefault();

    if (moveTouchActive) { return; }

    // check for correct touch
    var touch = null;
    for (let aTouch of e.changedTouches) {
        if (aTouch.target.id == "movePad") {
            touch = aTouch;
        }
    }
    if (touch == null) {
        return;
    }

    moveTouchActive = true;

    // Get the touch position
    var touchX = touch.clientX;
    var touchY = touch.clientY;
    moveTouchStart.x = touchX;
    moveTouchStart.y = touchY;
    
    // Show joystick
    MOVE_BASE_IMG.style.display = "block";
    MOVE_BASE_IMG.style.left = String(touchX) + "px";
    MOVE_BASE_IMG.style.top = String(touchY) + "px";
    MOVE_STICK_IMG.style.display = "block";
    MOVE_STICK_IMG.style.left = String(touchX) + "px";
    MOVE_STICK_IMG.style.top = String(touchY) + "px";
    
}, false);


movePad.addEventListener('touchend', function(e) {
    moveTouchActive = false;
    MOVE_BASE_IMG.style.display = "none";
    MOVE_STICK_IMG.style.display = "none";
    send_controlpad_message("move:0,0");
}, false);

movePad.addEventListener('touchcancel', function(e) {
    moveTouchActive = false;
    MOVE_BASE_IMG.style.display = "none";
    MOVE_STICK_IMG.style.display = "none";
    send_controlpad_message("move:0,0");
}, false);


function setMoveStickPosition(x, y) {
    const dx = x - moveTouchStart.x;
    const dy = y - moveTouchStart.y;
    const distance = Math.sqrt(dx*dx + dy*dy);
    if (distance < MAX_STICK_DIST) {
        moveStickPosition.x = x;
        moveStickPosition.y = y;
    } else {
        const unitX = dx / distance;
        const unitY = dy / distance;
        moveStickPosition.x = moveTouchStart.x + unitX * MAX_STICK_DIST;
        moveStickPosition.y = moveTouchStart.y + unitY * MAX_STICK_DIST;
    }
    MOVE_STICK_IMG.style.left = String(moveStickPosition.x) + "px";
    MOVE_STICK_IMG.style.top = String(moveStickPosition.y) + "px";
}

var moveThrottledDragEvent = throttle(function(e) {
    // check for correct touch
    var touch = null;
    for (let aTouch of e.changedTouches) {
        if (aTouch.target.id == "movePad") {
            touch = aTouch;
        }
    }
    if (touch == null) {
        return;
    }
    // Get the touch position
    var touchX = touch.clientX;
    var touchY = touch.clientY;

    // Set stick position
    setMoveStickPosition(touchX, touchY);

    
    if (moveTouchActive) {
        const moveX = Math.round((moveStickPosition.x - moveTouchStart.x)*255/MAX_STICK_DIST);
        const moveY = Math.round((moveStickPosition.y - moveTouchStart.y)*255/MAX_STICK_DIST);
        let datum = "move:" + String(moveX) + "," + String(moveY);
        send_controlpad_message(datum);
        //console.log(datum);
    }
}, 33); // Throttle to 30 times per second (33.33 milliseconds)

// Add the throttled touchmove event listener to the element
movePad.addEventListener('touchmove', moveThrottledDragEvent, false);




//////////////////// BowPad ////////////////////
var BOW_BASE_IMG;
var BOW_STICK_IMG;

let bowTouchActive = false;
let bowTouchStart = {x: 0, y: 0};
var bowPad = document.getElementById('bowPad');
let bowStickPosition = {x: 0, y: 0};

export function layoutBowPad() {
    var bowPad = document.getElementById('bowPad');
    bowPad.style.zIndex = "1";
    bowPad.style.position = "absolute";
    bowPad.style.bottom = "12px";
    bowPad.style.right = "12px";
    //bowPad.style.transform = "translate(-50%, -50%)";
    bowPad.style.width = "250px";
    bowPad.style.height = "250px";
    //bowPad.style.border = "1px solid #bbbbbb";
    bowPad.style.borderRadius = "140px";
    //
    var pad_img = document.createElement('img');
    pad_img.style.zIndex = "2";
    pad_img.style.position = "absolute";
    pad_img.style.bottom = "8px";
    pad_img.style.right = "8px";
    pad_img.style.width = "250px";
    pad_img.style.height = "250px";
    pad_img.style.pointerEvents = "none";
    pad_img.src = "./resources/joystick_pad_bow.png";
    //
    var base_img = document.createElement('img');
    base_img.style.zIndex = "3";
    base_img.style.position = "absolute";
    base_img.style.width = "140px";
    base_img.style.height = "140px";
    base_img.style.transform = "translate(-50%, -50%)";
    base_img.style.pointerEvents = "none";
    base_img.src = "./resources/joystick_base.png";
    base_img.style.display = "none";
    BOW_BASE_IMG = base_img;
    //
    var stick_img = document.createElement('img');
    stick_img.style.zIndex = "4";
    stick_img.style.position = "absolute";
    stick_img.style.width = "110px";
    stick_img.style.height = "110px";
    stick_img.style.transform = "translate(-50%, -50%)";
    stick_img.style.pointerEvents = "none";
    stick_img.src = "./resources/joystick_stick.png";
    stick_img.style.display = "none";
    BOW_STICK_IMG = stick_img;
    //
    while (bowPad.firstChild) {
        bowPad.removeChild(bowPad.firstChild);
    }
    var mainDiv = document.getElementById('mainDi');
    mainDiv.appendChild(pad_img);
    mainDiv.appendChild(base_img);
    mainDiv.appendChild(stick_img);
}

bowPad.addEventListener('touchstart', function(e) {
    // Prevent the default highlighting behavior
    e.preventDefault();

    if (bowTouchActive) { return; }

    // check for correct touch
    var touch = null;
    for (let aTouch of e.changedTouches) {
        if (aTouch.target.id == "bowPad") {
            touch = aTouch;
        }
    }
    if (touch == null) {
        return;
    }

    bowTouchActive = true;

    // Get the touch position
    var touchX = touch.clientX;
    var touchY = touch.clientY;
    bowTouchStart.x = touchX;
    bowTouchStart.y = touchY;
    
    // Show joystick
    BOW_BASE_IMG.style.display = "block";
    BOW_BASE_IMG.style.left = String(touchX) + "px";
    BOW_BASE_IMG.style.top = String(touchY) + "px";
    BOW_STICK_IMG.style.display = "block";
    BOW_STICK_IMG.style.left = String(touchX) + "px";
    BOW_STICK_IMG.style.top = String(touchY) + "px";
    
}, false);


bowPad.addEventListener('touchend', function(e) {
    bowTouchActive = false;
    BOW_BASE_IMG.style.display = "none";
    BOW_STICK_IMG.style.display = "none";
    send_controlpad_message("bow:0,0");
}, false);

bowPad.addEventListener('touchcancel', function(e) {
    bowTouchActive = false;
    BOW_BASE_IMG.style.display = "none";
    BOW_STICK_IMG.style.display = "none";
    send_controlpad_message("bow:0,0");
}, false);


function setBowStickPosition(x, y) {
    const dx = x - bowTouchStart.x;
    const dy = y - bowTouchStart.y;
    const distance = Math.sqrt(dx*dx + dy*dy);
    if (distance < MAX_STICK_DIST) {
        bowStickPosition.x = x;
        bowStickPosition.y = y;
    } else {
        const unitX = dx / distance;
        const unitY = dy / distance;
        bowStickPosition.x = bowTouchStart.x + unitX * MAX_STICK_DIST;
        bowStickPosition.y = bowTouchStart.y + unitY * MAX_STICK_DIST;
    }
    BOW_STICK_IMG.style.left = String(bowStickPosition.x) + "px";
    BOW_STICK_IMG.style.top = String(bowStickPosition.y) + "px";
}

var bowThrottledDragEvent = throttle(function(e) {
    // check for correct touch
    var touch = null;
    for (let aTouch of e.changedTouches) {
        if (aTouch.target.id == "bowPad") {
            touch = aTouch;
        }
    }
    if (touch == null) {
        return;
    }
    // Get the touch position
    var touchX = touch.clientX;
    var touchY = touch.clientY;

    // Set stick position
    setBowStickPosition(touchX, touchY);

    
    if (bowTouchActive) {
        const bowX = Math.round((bowStickPosition.x - bowTouchStart.x)*255/MAX_STICK_DIST);
        const bowY = Math.round((bowStickPosition.y - bowTouchStart.y)*255/MAX_STICK_DIST);
        let datum = "bow:" + String(bowX) + "," + String(bowY);
        send_controlpad_message(datum);
        //console.log(datum);
    }
}, 33); // Throttle to 30 times per second (33.33 milliseconds)

// Add the throttled touchbow event listener to the element
bowPad.addEventListener('touchmove', bowThrottledDragEvent, false);




////////////////////////////////////////////////////////////////////////////////

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
    };
}

*/
