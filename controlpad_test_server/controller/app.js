import { send_controlpad_message } from "./controlpad.js";
import { layoutMovePad, layoutBowPad } from "./joysticks.js";
import { layoutUpgrades } from "./upgrades.js";

export const DEBUG = true;

var STATE = "none";
var COLOR = "#eeeeee";
export var EQUIPMENT = {
    arrow: "Arrow_I",
    bow: "Bow_I",
    armor: "None",
    new_arrow: "Arrow_II",
    new_bow: "Bow_V",
    new_armor: "Armor_IV",
};

export var UP_POINTS = 2;

document.addEventListener("viewport-change", (event) => {
    clearElements();
    if (event.detail.isPortrait) {
        document.getElementById("turn-text").style.display = "block";
        return;
    }
    layoutElements(event.detail.viewWidth, event.detail.viewHeight);
});

export function clearElements() {
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
    // this is necessary for when the game receives a state message before the viewport-change event
    if (viewWidth < viewHeight) {
        document.getElementById("turn-text").style.display = "block";        
    }
    else {
        if (STATE == "none") {
            document.getElementById("wait-text").style.display = "block";
            //layoutUpgrades(); //
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
}


function update_equipment(old_e, new_e) {
    var old_parts = old_e.split(",");
    EQUIPMENT.arrow = old_parts[0];
    EQUIPMENT.bow = old_parts[1];
    EQUIPMENT.armor = old_parts[2];
    var new_parts = new_e.split(",");
    EQUIPMENT.new_arrow = new_parts[0];
    EQUIPMENT.new_bow = new_parts[1];
    EQUIPMENT.new_armor = new_parts[2];
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
        layoutElements(window.innerWidth, window.innerHeight);
    } else if (parts[1] === "playing") {
        STATE = "playing";
        COLOR = parts[2];
        clearElements();
        layoutElements(window.innerWidth, window.innerHeight);
    } else if (parts[1] === "upgrading") {
        STATE = "upgrading";
        COLOR = parts[2];
        UP_POINTS = parts[3];
        update_equipment(parts[4], parts[5]);
        clearElements();
        layoutElements(window.innerWidth, window.innerHeight);
    } else {
        console.log("TBD");
    }

/*    
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
*/

});

