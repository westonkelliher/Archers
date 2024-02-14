import { send_datum } from "./controlpad.js";


document.addEventListener("controlpad-message", (event) => {
    
    var msg = event.detail;
    console.log("recv: " + msg)
    let movePad = document.getElementById("movePad");
    let bowPad = document.getElementById("bowPad");
    movePad.style.background = msg;
    bowPad.style.background = msg;
    
});


function addUpgradeButtons() {
    const container = document.createElement('div');
    container.style.position = 'fixed'; // Use fixed positioning
    container.style.top = '15%'; // Center vertically
    container.style.left = '50%'; // Center horizontally
    container.style.transform = 'translate(-50%, -50%)'; // Adjust the exact center
    container.style.display = 'flex'; // Use flexbox for alignment
    container.style.gap = '20px'; // Gap between buttons

    const buttonData = [
        { name: 'Bow Upgrade', imageSrc: 'resources/bowUpgrade.png', msg: 'bow' },
        { name: 'Arrow Upgrade', imageSrc: 'resources/arrowUpgrade.png', msg: 'arrow' },
        { name: 'Ability Upgrade', imageSrc: 'resources/abilityUpgrade.png', msg: 'ability' }
    ];


    // Create and append buttons to the container
    for (let i = 0; i < 3; i++) {
      const button = document.createElement('button');
      button.textContent = buttonData[i].name; // Set button text
      button.style.border = '3px solid #000000';
      button.style.width = '120px'; // Set width
      button.style.height ='120px'; // Set height
      button.style.borderRadius = '10px'; // Make corners rounded
      // Create and append image element to the button
      const img = document.createElement('img');
      img.src = buttonData[i].imageSrc;
      img.style.width = '60px'; // Set image width (adjust as needed)
      img.style.height = '60px'; // Set image height (adjust as needed)
      img.style.display = 'block'; // Ensure the image is block-level
      img.style.margin = 'auto'; // Center the image within the button
      button.appendChild(img)

      // Add event listener to button
        button.addEventListener('click', function() {
            // Perform action on button click
            //console.log(`Button ${i + 1} clicked`);
            console.log(`upgrade:` + buttonData[i].msg);
            send_datum(`upgrade:` + buttonData[i].msg)
        });

      container.appendChild(button); // Add button to container
    }

    // Append the container to the body of the document
    document.body.appendChild(container);
}



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
    // Prevent the default highlighting behavior
    e.preventDefault();

    if (isTouchActive) { return; }

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

    isTouchActive = true;

    // Get the touch position
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
    // Prevent the default highlighting behavior
    e.preventDefault();

    if (isBowTouchActive) { console.log("tried while active"); return; }

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

    isBowTouchActive = true;

    // Get the touch position
    var touchX = touch.clientX;
    var touchY = touch.clientY;

    // Print "touch start" and the x,y position
    console.log("touch start: " + touchX + ", " + touchY);
    bowTouchStart.x = touchX;
    bowTouchStart.y = touchY;
}, false);


bowPad.addEventListener('touchend', function(e) {
    isBowTouchActive = false;
    send_datum("bow:0,0");
}, false);

bowPad.addEventListener('touchcancel', function(e) {
    isBowTouchActive = false;
    send_datum("bow:0,0");
}, false);


var bowDrag = throttle(function(e) {
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
    var touchX = touch.clientX;
    var touchY = touch.clientY;

    if (isBowTouchActive) {
        let datum = "bow:" + String(touchX - bowTouchStart.x) + "," + String(touchY - bowTouchStart.y);
        send_datum(datum);
    }
}, 33); // Throttle to 30 times per second (33.33 milliseconds)

// Add the throttled touchmove event listener to the element
bowPad.addEventListener('touchmove', bowDrag, false);

//console.log("sanity");
addUpgradeButtons();
