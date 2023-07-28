STATE_PAUSED = 'paused'
STATE_LOADING = 'loading'
STATE_PLAYING = 'playing'
STATE_EMPTY = 'queue_empty'

class PlaybackState
  var current_track
  var settings
  var recently_played

  def init()
    self.current_track = self.create_default_track()
    self.settings = self.create_default_settings()
    self.recently_played = []

    events.register_native("trackInfo", def (data)
      self.notify_playback({
        'title': data['title'],
        'trackURI': data['uri'],
        'iconUrl': data['iconUrl'],
        'artist': data['artist'],
        'album': data['album'],
        'source': data['source'],
        'timestamp': core.get_time_ms(),
        'hidden': false
      })
    end)

    events.register_native("playbackState", def (data)
      self.settings['state'] = data['state']
      self.update_remote()
    end)
  end

  # initializes the current_track object
  def create_default_track()
    return {
      'title': '',
      'trackURI': '',
      'iconUrl': '',
      'artist': '',
      'album': '',
      'source': '',
      'timestamp': 0
    }
  end

  def append_recently_played(track)
    track['timestamp'] = core.get_timestamp()
    if self.recently_played.size() > 10
      self.recently_played.remove(-1)
    end

    self.recently_played.push(track)
  end

  def query_context_uri(name, context)
    core.query_context_uri(name + "://" + util.url_encode(context))
  end

  def notify_playback(track)
    self.current_track = track
    if self.current_track.find('hidden') == nil || !self.current_track.find('hidden')
      self.append_recently_played(track)
    end

    self.update_remote()
  end

  def update_volume(volume)
    self.settings['volume'] = volume
    # self.update_remote()
  end

  def notify_state(state)
    self.settings['state'] = state

    if state == STATE_PLAYING
      core.trigger_pause(false)
    end

    if state == STATE_PAUSED
      core.trigger_pause(true)
    end

    self.update_remote()

    # Broadcast playback event
    events.handle(EVENT_PLAYBACK_STATE_UPDATE, state)
  end

  # Called in order to send current state to the websocket connection
  def update_remote()
    http.emit_event('playback', self.get_state())
  end

  def get_state()
    return { 'settings': self.settings, 'track': self.current_track }
  end

  # intializes the settings object
  def create_default_settings()
    return {
      'volume': 0,
      'state': STATE_EMPTY
    }
  end
end

var playback_state = PlaybackState()
