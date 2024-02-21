ESP32_BOARDS = [
    {
        "name":"custom",
        "state": {
            "dac":"dummy",
            "mclk":"0",
            "bck":"0",
            "ws":"0",
            "data":"0",
            "scl":"0",
            "sda":"0"
        }
    },
    {
       "name":"louder ESP32",
       "state": {
            "dac":"TAS5805M_staticPins",
            "mclk":"0",
            "bck":"26",
            "ws":"25",
            "data":"22",
            "scl":"27",
            "sda":"21"
        }
    },
    {
       "name":"μVox",
       "state": {
            "dac":"MA12070P",
            "mclk":"0",
            "bck":"5",
            "ws":"25",
            "data":"26",
            "scl":"22",
            "sda":"23",
            "enablePin": "19",
            "mutePin": "21"
       }
    }
 ]
