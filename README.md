# Archers


## Setup

- **Windows Only**: Create The *gamenite* Folder
    - In **C:\Users\** create a new folder called **gamenite**
    - Right click on the **gamenite** folder and click **Properties**
    - Go to **Security** tab
    - Click the **Edit** button under the **Group or user names:** section
    - Select **Users** in the **Group or user names:** section of the new window
    - Check the box for **Full Control** and click **Apply**
    - Press **Ok** on both popup boxes
- **Linux Only**: Create the *requin* directory
    - `sudo mkdir /home/requin`
    - `sudo chown <your_username> /home/requin`

## Run the Test Controlpads Server
- install node if you don’t have it already
- Clone this repository: https://github.com/RecBox-Games/controlpad_test_server
- navigate to your checkout (either in terminal, cmdline, or powershell) and run `npm install`
- run the test server
    - **Windows:** `./start.bat`
    - **Linux:** `./start.sh`
