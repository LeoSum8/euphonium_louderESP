class TAS5805M : DACDriver
    var volume_table
    def init()        
        self.name = "TAS5805M"
        self.hardware_volume_control = true
        # define a volume table, saves up on log10
        self.volume_table = [255,160,120,100,90,85,80, 75, 70, 65, 61, 57, 53, 50, 47, 44, 41, 38, 35, 32, 29, 26, 23, 20, 17, 14, 12, 10, 8, 6, 4, 2, 0]
    end

    def init_i2s()
        var ADDRESS = 0x2D # found here: https://github.com/sonocotta/esp32-tas5805m-dac/blob/main/tas5805m.hpp
        # I2S STAND MODE
        var config = I2SConfig()
        config.sample_rate = 44100
        config.bits_per_sample = 16
        config.mclk = 0
        config.comm_format = I2S_CHANNEL_FMT_RIGHT_LEFT
        config.channel_format = I2S_COMM_FORMAT_I2S

        i2s.install(config)
        i2s.set_pins(self.get_i2s_pins())

        i2c.install(int(self.get_gpio('sda')), int(self.get_gpio('scl')))
        
        # pull GPIO33 to HIGH, this will turn on the DAC (louder ESP32 specific)
        sleep_ms(1000)
        gpio.pin_mode(33, gpio.OUTPUT)
        gpio.digital_write(33, 1)

        sleep_ms(100)
        # Setting to HI Z as seen in https://github.com/sonocotta/esp32-tas5805m-dac/blob/main/tas5805m.cpp
        i2c.write(ADDRESS, 0x03, 0x02) 
        sleep_ms(100)
        # Setting to PLAY as seen in https://github.com/sonocotta/esp32-tas5805m-dac/blob/main/tas5805m.cpp
        i2c.write(ADDRESS, 0x03, 0x03) 
    end

    def unload_i2s()
        i2s.uninstall()
    end

    def set_volume(volume)
        # 0-255, where 0 = 0 Db, 255 = mute
        var volume_step = volume / 100.0
        var actual_volume = int(volume_step * 32)
        # TAS5805M_DIG_VOL_CTRL_REGISTER = 0x4c according to https://github.com/sonocotta/esp32-tas5805m-dac/blob/main/tas5805m.hpp
        i2c.write(0x2D, 0x4c, self.volume_table[actual_volume])    
    end

    def make_config_form(ctx, state) 
        super(self).make_config_form(ctx, state)
    end
end

hardware.register_driver(TAS5805M())
