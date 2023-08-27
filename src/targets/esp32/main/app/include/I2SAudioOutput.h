#pragma once

#include <driver/gpio.h>
#include <driver/i2s.h>

#include "EuphAudioOutput.h"

namespace euph {

class I2SAudioOutput : public euph::AudioOutput {
 private:
  int expandFrom = 16;
  int expandTo = 32;
  std::atomic<bool> isReadable = false;
  bool isInstalled = false;
  std::mutex readingMutex;

  size_t bytesWritten = 0;

 public:
  I2SAudioOutput();
  ~I2SAudioOutput() {};

  void setupBindings(std::shared_ptr<euph::Context> ctx) override;

  bool supportsHardwareVolume() override;
  void configure(uint32_t sampleRate, uint8_t channels,
                 uint8_t bitwidth) override;
  void setVolume(uint8_t volume) override;
  void feedPCM(uint8_t* pcm, size_t size) override;

  void _install(int sampleRate, int bitsPerSample, int channelFormat,
                int commFormat, int mclk);
  void _setExpand(int from, int to);
  void _setReadable(bool isReadable);
  void _setPins(int mclk, int bck, int ws, int dataOut);
  void _uninstall();
};
}  // namespace euph
