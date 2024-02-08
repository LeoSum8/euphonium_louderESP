<p align="center">
<img src="docs/images/euph_darkaware.svg" width="32%" />
</p>

# Changes in this Fork
This fork's goal is to get euphonium working on the [louder ESP32 board](https://www.tindie.com/products/sonocotta/louder-esp32/) from Sonocotta.
For this, a DAC driver for the TAS5805m is added.
Currently this is only implemented for the old master branch of euphonium (outdated since 2022).
The up to date develop branch of euphonium relies on a nix-based build environment, which I am currently trying to get working.
Also it would require an ESP32 with 16mb flash which I currently don't have available. 

## Release
A flashable set of binary files is included here in the releases.

## Flashing
The release can be flased with:
```
esptool -p /dev/ttyACM0 -b 460800 --before default_reset --after hard_reset --chip esp32  write_flash --flash_mode dio --flash_size detect --flash_freq 40m 0x1000 build/bootloader/bootloader.bin 0x8000 build/partition_table/partition-table.bin 0x90000 build/recovery.bin 0x140000 build/euphonium-esp32.bin 0x10000 build/storage.bin
```

It comes preconfigured with the corrent DAC and GPIOs so all you need to do is configure your wifi.

## Building
I build using a docker based environment. The Dockerfile is included in this repo.

Optionally you can preconfigure the wifi during build process (see dockerfile)

Build the image:
```
sudo docker build -t euphonium_builder .
```
Rund the container:
```
sudo docker run -v /home/LeoSum8/euphonium/build_docker:/app/build euphonium_builder
```
the build output will be in `/home/LeoSum8/euphonium/build_docker`

# Euphonium

Highly extensible streaming audio player targeting low cost MCUs like ESP32. Currently under very rapid development, documentation coming soon.

## Documentation
You can access the project's documentation [here](https://feelfreelinux.github.io/euphonium/).

## Get involved
Join our matrix-room! We update the ESP32-Audio community there regularly, and are always open to input, and or questions, there. https://matrix.to/#/#esp32_audio:matrix.org
