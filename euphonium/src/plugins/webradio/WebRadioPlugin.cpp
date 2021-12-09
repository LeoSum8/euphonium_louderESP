#include "WebRadioPlugin.h"
#include <HTTPStream.h>
#include <thread>

WebRadioPlugin::WebRadioPlugin(): bell::Task("radio", 6 * 1024, 1)
{
    name = "webradio";
    audioStream = std::make_shared<HTTPAudioStream>();
}

void WebRadioPlugin::loadScript(std::shared_ptr<ScriptLoader> scriptLoader)
{
    scriptLoader->loadScript("webradio_plugin", berry);
}

void WebRadioPlugin::setupBindings()
{
    berry->export_this("webradio_set_pause", this, &WebRadioPlugin::setPaused);
    berry->export_this("webradio_queue_url", this, &WebRadioPlugin::playRadioUrl);
}

void WebRadioPlugin::configurationUpdated()
{
}

void WebRadioPlugin::setPaused(bool isPaused)
{
    this->isPaused = isPaused;
    auto event = std::make_unique<PauseChangedEvent>(isPaused);
    this->luaEventBus->postEvent(std::move(event));
}

void WebRadioPlugin::playRadioUrl(std::string url, bool isAAC)
{
    if (isAAC) {
        std::cout << "is aac" << std::endl;
    }
    isRunning = false;
    radioUrlQueue.push({isAAC, url});
}

void WebRadioPlugin::shutdown() {
    EUPH_LOG(info, "webradio", "Shutting down...");
    isRunning = false;
    std::lock_guard lock(runningMutex);
    status = ModuleStatus::SHUTDOWN;
}

void WebRadioPlugin::runTask()
{
    std::pair<bool, std::string> url;

    while (true) {
        if (this->radioUrlQueue.wpop(url)) {
            std::lock_guard lock(runningMutex);
            isRunning = true;
            isPaused = false;
            status = ModuleStatus::RUNNING;

            EUPH_LOG(info, "webradio", "Starting WebRadio");
            // Shutdown all other modules
            audioBuffer->shutdownExcept(name); 
            auto event = std::make_unique<AudioTakeoverEvent>(name);
            this->luaEventBus->postEvent(std::move(event));

            if (url.first) {
                audioStream->querySongFromUrl(url.second, AudioCodec::AAC);
            } else {
                audioStream->querySongFromUrl(url.second, AudioCodec::MP3);
            }

            while (isRunning) {
                if (!isPaused) {
                    audioStream->decodeFrame(audioBuffer);
                    BELL_SLEEP_MS(10);
                } else {
                    BELL_SLEEP_MS(100);
                }
            }

        }
    }
}

void WebRadioPlugin::startAudioThread()
{
    startTask();
}
