import { send_controlpad_message } from "./controlpad.js";
import { layoutMovePad, layoutBowPad } from "./joysticks.js";
import { layoutUpgrades } from "./upgrades.js";

export const DEBUG = true;

var STATE = "none";
var COLOR = "#eeeeee";

let upgradePoints = 2;

document.addEventListener("viewport-change", (event) => {
    clearElements();
    if (event.detail.isPortrait) {
        document.getElementById("turn-text").style.display = "block";
        return;
    }
    layoutElements(event.detail.viewWidth, event.detail.viewHeight);
});

function clearElements() {
    document.getElementById("turn-text").style.display = "none";
    document.getElementById("wait-text").style.display = "none";
    document.getElementById("movePad").style.display = "none";
    document.getElementById("bowPad").style.display = "none";
    document.getElementById("upgrades").style.display = "none";
    //
    var mainDiv = document.getElementById("mainDi");
    while (mainDiv.firstChild) {
        mainDiv.removeChild(mainDiv.firstChild);
    }
}

function layoutElements(viewWidth, viewHeight) {
    if (STATE == "none") {
        document.getElementById("wait-text").style.display = "block";
    } else if (STATE == "joining") {
        layoutMovePad();
        layoutBowPad();
        document.getElementById("mainDi").style.background = "#eeeeee";
    } else if (STATE == "playing") {
        layoutMovePad();
        layoutBowPad();
        document.getElementById("mainDi").style.background = COLOR;
    } else if (STATE == "upgrading") {
        console.log("abc");
        layoutUpgrades();
    } else {
        console.log("Warning bad state");
    }
        
}

                          
document.addEventListener("controlpad-message", (event) => {
    var msg = event.detail;
    if (DEBUG) {
        console.log("recv: " + msg);
    }

    // Split the message by colon
    const parts = msg.split(":");
    // Check if the first part is "upgrade"
    if (parts[0] !== "state") {
        console.log("Warning: non state message from game");
        return;
    }

    if (parts[1] === "joining") {
        STATE = "joining";
        clearElements();
        layoutElements();
    } else if (parts[1] === "playing") {
        STATE = "playing";
        COLOR = parts[2];
        clearElements();
        layoutElements();
    } else if (parts[1] === "upgrading") {
        STATE = "upgrading";
        COLOR = parts[2];
        clearElements();
        layoutElements();
    } else {
        console.log("TBD");
    }
    
    if (parts[0] === "upgrade") {
        // Display the upgrade message
        toggleUpgradePointsMessage(true);
        // Set the value of the number of upgrade points
        upgradePoints = parseInt(parts[1]); // Assuming the second part is the number of points
        // Update the message displaying the number of upgrade points
        updateUpgradePointsMessage();
        toggleUpgradeButtons(true);
    } if (parts[0] === "clear") {
        toggleUpgradeButtons(false);
        toggleUpgradePointsMessage(false);
    } else {
        // Set the background if the message is not "upgrade"
        document.getElementById("mainDi").style.background = msg;
    }
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
        button.style.height = '120px'; // Set height
        button.style.borderRadius = '10px'; // Make corners rounded
        // Create and append image element to the button
        const img = document.createElement('img');
        img.src = buttonData[i].imageSrc;
        img.style.width = '60px'; // Set image width (adjust as needed)
        img.style.height = '60px'; // Set image height (adjust as needed)
        img.style.display = 'block'; // Ensure the image is block-level
        img.style.margin = 'auto'; // Center the image within the button
        button.appendChild(img);

        // Add event listener to button
        button.addEventListener('click', function() {
            // Handle button click
            handleButtonClick(buttonData[i]);
        });

        container.appendChild(button); // Add button to container
    }

    // Append the container to the body of the document
    document.body.appendChild(container);
}

// Function to handle button click
function handleButtonClick(buttonData) {
    // Check if there are enough upgrade points
    if (upgradePoints > 0) {
        // Decrease the number of upgrade points
        upgradePoints--;
        // Update the message displaying the number of upgrade points
        updateUpgradePointsMessage();
        // Log the upgrade action
        console.log(`upgrade: ${buttonData.msg}`);
        // Send the upgrade action
        send_controlpad_message(`upgrade:${buttonData.msg}`);
        // Check if upgrade points are exhausted
        if (upgradePoints === 0) {
            // Disable and hide the buttons
            toggleUpgradeButtons(false);
            console.log(`ready:`);
            send_controlpad_message(`ready:`);
        }
    }
}

function toggleUpgradeButtons(enabled) {
    const buttons = document.querySelectorAll('button');

    buttons.forEach(button => {
        if (enabled) {
            button.removeAttribute('disabled');
            button.style.display = 'block';
        } else {
            button.setAttribute('disabled', 'disabled');
            button.style.display = 'none'; // Hide the button
        }
    });
}

function addUpgradePointsMessage() {
    const messageContainer = document.createElement('div');
    messageContainer.id = 'upgradePointsMessage';
    messageContainer.style.position = 'fixed';
    messageContainer.style.top = '50%';
    messageContainer.style.left = '50%';
    messageContainer.style.transform = 'translate(-50%, -50%)';
    messageContainer.style.fontSize = '20px'; // Adjust the font size as needed
    messageContainer.style.margin = '10px'; // Adjust the margins as needed
    document.body.appendChild(messageContainer);
}

function updateUpgradePointsMessage() {
    const message = document.getElementById('upgradePointsMessage');
    message.innerHTML = `Spend upgrade points!<br>You have ${upgradePoints} points.`;
}

function toggleUpgradePointsMessage(visible) {
    const message = document.getElementById('upgradePointsMessage');
    if (visible) {
        message.style.display = 'block';
    } else {
        message.style.display = 'none';
    }
}


//console.log("sanity");
addUpgradeButtons();
toggleUpgradeButtons(false);
addUpgradePointsMessage();
updateUpgradePointsMessage();
toggleUpgradePointsMessage(false);
