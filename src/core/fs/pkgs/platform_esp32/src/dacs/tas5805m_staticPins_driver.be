class TAS5805M_staticPins : DACDriver
    var ma_addr
    var vol_ctrl_reg
    var volume_table

    def init()        
        self.name = "TAS5805M_staticPins"
        self.ma_addr = 0x2D # found here: https://github.com/sonocotta/esp32-tas5805m-dac/blob/main/tas5805m.hpp
        self.vol_ctrl_reg = 0x4c # according to https://github.com/sonocotta/esp32-tas5805m-dac/blob/main/tas5805m.hpp
        self.hardware_volume_control = true
        self.default_volume_table = [160, 98, 96, 94, 92, 89, 87, 85, 84, 82, 80, 78, 76, 75, 73, 71, 70, 68, 67, 65, 64, 62, 61, 60, 59, 57, 56, 55, 54, 53, 51, 50, 49, 48, 47, 46, 45, 44, 43, 43, 42, 41, 40, 39, 38, 38, 37, 36, 36, 35, 34, 34, 33, 32, 32, 31, 30, 30, 29, 29, 28, 28, 27, 27, 26, 26, 25, 25, 25, 24, 24, 23, 23, 23, 22, 22, 22, 21, 21, 21]
        self.type = DAC_DRIVER_AMPLIFIER
    end

    def init_i2s()
        # I2S STAND MODE
        var config = I2SConfig()
        config.sample_rate = 44100
        config.bits_per_sample = 16
        config.mclk = 0
        config.comm_format = I2S_CHANNEL_FMT_RIGHT_LEFT
        config.channel_format = I2S_COMM_FORMAT_I2S

        i2s.install(config)
        i2s.set_pins([0 26 25 22])

        i2c.install(int(21), int(27))
        
        # pull GPIO33 to HIGH, this will turn on the DAC (louder ESP32 specific)
        # sleep_ms(1000)
        gpio.pin_mode(33, gpio.OUTPUT)
        gpio.digital_write(33, 1)

        # sleep_ms(200)
        # Setting to HI Z as seen in https://github.com/sonocotta/esp32-tas5805m-dac/blob/main/tas5805m.cpp
        i2c.write(self.ma_addr, 0x03, 0x02) 
        # sleep_ms(200)
        # Setting to PLAY as seen in https://github.com/sonocotta/esp32-tas5805m-dac/blob/main/tas5805m.cpp
        i2c.write(self.ma_addr, 0x03, 0x03) 

        # set volume
        # sleep_ms(200)
        i2c.write(self.ma_addr, self.vol_ctrl_reg, 220)  # volume
    end

    def unload_i2s()
        i2s.uninstall()        
        i2c.delete()
    end

    def set_volume(volume)
        # 0-255, where 0 = 0 Db, 255 = mute
        
        var volume_step = 1-(volume / 100.0)
        var actual_volume = int(volume_step * 255)
        i2c.write(self.ma_addr, self.vol_ctrl_reg, actual_volume) 
    end

    def make_config_form(ctx, state) 
        super(self).make_config_form(ctx, state)
    end
end

hardware.register_driver(TAS5805M_staticPins())
