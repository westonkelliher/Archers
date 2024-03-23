import { send_controlpad_message } from "./controlpad.js";
import { EQUIPMENT, clearElements } from "./app.js";
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
    populateUpDiv(upDiv1, "arrow", EQUIPMENT.arrow, EQUIPMENT.new_arrow);
    

    //// Arrow Upgrade ////
    var upDiv2 = document.getElementById("up2");
    upDiv2.style.top = "2%";
    upDiv2.style.left = "50%";
    upDiv2.style.transform = "translate(-50%, 0%)";
    //
    populateUpDiv(upDiv2, "bow", EQUIPMENT.bow, EQUIPMENT.new_bow);
    

    //// Armor Upgrade ////
    var upDiv3 = document.getElementById("up3");
    upDiv3.style.top = "2%";
    upDiv3.style.right = "1%";
    //
    populateUpDiv(upDiv3, "armor", EQUIPMENT.armor, EQUIPMENT.new_armor);
    
}


function populateUpDiv(upDiv, type, old_equip_name, new_equip_name) {
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
    //// Top Square
    var old_square = document.createElement('img');
    old_square.src = "./resources/equipment_box_inactive.png";
    old_square.style.position = "absolute";
    old_square.style.top = "0vh";
    old_square.style.left = "50%";
    old_square.style.transform = "translate(-50%, 0%)";
    old_square.style.width = "36vh";
    old_square.style.height = "36vh";
    upDiv.appendChild(old_square);
    //
    var old_equip = document.createElement('img');
    old_equip.src = "./resources/equipment/" + old_equip_name + ".png";
    old_equip.style.position = "absolute";
    old_equip.style.top = "22%";
    old_equip.style.left = "50%";
    old_equip.style.transform = "translate(-50%, -50%)";
    old_equip.style.width = "26vh";
    upDiv.appendChild(old_equip);
    //// Return if no available upgrade
    if (new_equip_name == "nothing") {
        upDiv.onclick = () => {};
        return;
    }
    //// Downward Graphic
    var arrow = document.createElement('img');
    arrow.src = "./resources/arrow_down.png";
    arrow.style.position = "absolute";
    arrow.style.top = "49.5%";
    arrow.style.left = "50%";
    arrow.style.transform = "translate(-50%, -50%)";
    arrow.style.width = "16vh";
    arrow.style.height = "16vh";
    upDiv.appendChild(arrow);
    //// Bottom Square
    var new_square = document.createElement('img');
    new_square.src = "./resources/equipment_box_active.png";
    new_square.style.position = "absolute";
    new_square.style.bottom = "0vh";
    new_square.style.left = "50%";
    new_square.style.transform = "translate(-50%, 0%)";
    new_square.style.width = "36vh";
    new_square.style.height = "36vh";
    upDiv.appendChild(new_square);
    //
    var new_equip = document.createElement('img');
    new_equip.src = "./resources/equipment/" + new_equip_name + ".png";
    new_equip.style.position = "absolute";
    new_equip.style.top = "78%";
    new_equip.style.left = "50%";
    new_equip.style.transform = "translate(-50%, -50%)";
    new_equip.style.width = "26vh";
    upDiv.appendChild(new_equip);
    ////
    upDiv.onclick = () => {
        send_controlpad_message("upgrade:" + type);
        clearElements();
        send_controlpad_message("state-request");
    };
}

