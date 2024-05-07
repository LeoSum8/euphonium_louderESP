volume_strip = nil
class TAS5805M : DACDriver
    var volume_table
    var ma_addr
    def init()
        super(self).init()
        self.default_volume_table = [160, 98, 96, 94, 92, 89, 87, 85, 84, 82, 80, 78, 76, 75, 73, 71, 70, 68, 67, 65, 64, 62, 61, 60, 59, 57, 56, 55, 54, 53, 51, 50, 49, 48, 47, 46, 45, 44, 43, 43, 42, 41, 40, 39, 38, 38, 37, 36, 36, 35, 34, 34, 33, 32, 32, 31, 30, 30, 29, 29, 28, 28, 27, 27, 26, 26, 25, 25, 25, 24, 24, 23, 23, 23, 22, 22, 22, 21, 21, 21]
        self.name = "TAS5805M"
        self.ma_addr = 0x2D # found here: https://github.com/sonocotta/esp32-tas5805m-dac/blob/main/tas5805m.hpp
        self.type = DAC_DRIVER_AMPLIFIER
        self.hardware_volume_control = true
        self.datasheet_link = "https://www.ti.com/lit/ds/symlink/tas5805m.pdf?ts=1715082979361"
    end

    def init_i2s()

        # PINOUT: SDA: 21, SCL: 27, SDATA: 22, LRCLK: 25, BCLK: 26
        # All of I2S init logic goes here

        var config = I2SConfig()
        config.sample_rate = 44100
        config.bits_per_sample = 16
        
        # MCLK: 22.58MHz @ 44.1KHz - sufficient for running the dedicated dsp!
        config.mclk = 512       
        config.comm_format = I2S_COMM_FORMAT_I2S
        config.channel_format = I2S_CHANNEL_FMT_RIGHT_LEFT

        i2s.install(config)
        i2s.set_pins(self.get_i2s_pins())

        # Start I2C Driver
        i2c.install(self.get_gpio('sda'), self.get_gpio('scl'))

        # Enable Amplifier. Enable pin: 33
        # pull GPIO33 to HIGH, this will turn on the DAC (louder ESP32 specific)
        gpio.pin_mode(33, gpio.OUTPUT)
        gpio.digital_write(33, 1)

        # Setting to HI Z as seen in https://github.com/sonocotta/esp32-tas5805m-dac/blob/main/tas5805m.cpp
        i2c.write(self.ma_addr, 0x03, 0x02) 
        #sleep_ms(200)
        # Setting to PLAY as seen in https://github.com/sonocotta/esp32-tas5805m-dac/blob/main/tas5805m.cpp
        i2c.write(self.ma_addr, 0x03, 0x03) 

        # Set Volume to a safe level..
        i2c.write(self.ma_addr, 64, 220)

        # Init done.
    end

    def unload_i2s()
        i2s.disable_expand()
        i2s.uninstall()
        i2c.delete()
    end

    def set_volume(volume)
        var volume_table = self.get_volume_table()
        var volume_index = int(((volume / 100.0) * (volume_table.size() - 1)) + 0.5)
        
        i2c.write(self.ma_addr, 64, volume_table[volume_index])


    end

    def make_config_form(ctx, state)
        super(self).make_config_form(ctx, state)
        var pins_group = ctx.create_group('MA12070P_pins', { 'label': 'DAC binary pins' })
        
        pins_group.number_field('enablePin', {
            'label': "Enable Pin",
            'default': 0,
            'group': 'MA12070P_pins',
        })

        pins_group.number_field('mutePin', {
            'label': "Mute Pin",
            'default': 0,
            'group': 'MA12070P_pins',
        })
       
    end

end

hardware.register_driver(MA12070P())
