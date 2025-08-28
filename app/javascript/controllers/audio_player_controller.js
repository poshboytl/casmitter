import { Controller } from "@hotwired/stimulus"
import { Howl } from 'howler'

export default class extends Controller {
  static targets = [
    "title", 
    "artist", 
    "currentTime", 
    "duration", 
    "progressBar", 
    "progressSlider",
    "playButton", 
    "playIcon", 
    "pauseIcon",
    "prevButton", 
    "nextButton",
    "volumeSlider", 
    "volumeText",
    "loadingState",
    "errorState",
    "coverImage"
  ]

  static values = {
    src: String,
    title: String,
    artist: String
  }

  connect() {
    console.log('AudioPlayer controller connected')
    this.isPlaying = false
    this.currentTrackIndex = 0
    this.playlist = []
    this.currentSound = null
    this.updateInterval = null
    
    this.initializePlayer()
    this.setupEventListeners()
  }

  disconnect() {
    this.cleanup()
  }

  initializePlayer() {
    if (this.srcValue) {
      this.loadTrack(this.srcValue)
    }
  }

  setupEventListeners() {
    // Progress slider events
    this.progressSliderTarget.addEventListener('mousedown', this.onProgressSliderMouseDown.bind(this))
    this.progressSliderTarget.addEventListener('input', this.onProgressSliderInput.bind(this))
    this.progressSliderTarget.addEventListener('change', this.onProgressSliderChange.bind(this))
    
    // Volume slider events
    this.volumeSliderTarget.addEventListener('input', this.onVolumeSliderInput.bind(this))
  }

  loadTrack(src) {
    this.showLoading()
    this.hideError()
    
    // Cleanup previous sound
    if (this.currentSound) {
      this.currentSound.unload()
    }

    this.currentSound = new Howl({
      src: [src],
      html5: true,
      preload: true,
      volume: this.volumeSliderTarget.value / 100,
      onload: () => {
        console.log('Audio loaded successfully')
        this.hideLoading()
        this.updateDuration()
        this.startProgressUpdate()
      },
      onloaderror: (id, error) => {
        console.error('Failed to load audio:', error)
        this.hideLoading()
        this.showError()
      },
      onplay: () => {
        this.isPlaying = true
        this.updatePlayButton()
      },
      onpause: () => {
        this.isPlaying = false
        this.updatePlayButton()
      },
      onstop: () => {
        this.isPlaying = false
        this.updatePlayButton()
        this.resetProgress()
      },
      onend: () => {
        this.isPlaying = false
        this.updatePlayButton()
        this.resetProgress()
        // Auto-play next track if available
        if (this.playlist.length > 1) {
          this.next()
        }
      }
    })
  }

  togglePlay() {
    if (!this.currentSound) return

    if (this.isPlaying) {
      this.pause()
    } else {
      this.play()
    }
  }

  play() {
    if (this.currentSound) {
      this.currentSound.play()
    }
  }

  pause() {
    if (this.currentSound) {
      this.currentSound.pause()
    }
  }

  stop() {
    if (this.currentSound) {
      this.currentSound.stop()
    }
  }

  previous() {
    if (this.playlist.length > 1) {
      this.currentTrackIndex = (this.currentTrackIndex - 1 + this.playlist.length) % this.playlist.length
      this.loadTrackFromPlaylist()
    }
  }

  next() {
    if (this.playlist.length > 1) {
      this.currentTrackIndex = (this.currentTrackIndex + 1) % this.playlist.length
      this.loadTrackFromPlaylist()
    }
  }

  loadTrackFromPlaylist() {
    const track = this.playlist[this.currentTrackIndex]
    if (track) {
      this.titleTarget.textContent = track.title || 'Unknown Track'
      this.artistTarget.textContent = track.artist || 'Unknown Artist'
      this.loadTrack(track.src)
    }
  }

  setVolume() {
    const volume = this.volumeSliderTarget.value / 100
    this.volumeTextTarget.textContent = `${Math.round(volume * 100)}%`
    
    if (this.currentSound) {
      this.currentSound.volume(volume)
    }
  }

  onVolumeSliderInput() {
    this.setVolume()
  }

  onProgressSliderMouseDown() {
    this.pauseProgressUpdate()
  }

  onProgressSliderInput() {
    const percent = this.progressSliderTarget.value
    this.progressBarTarget.style.width = `${percent}%`
  }

  onProgressSliderChange() {
    if (this.currentSound) {
      const percent = this.progressSliderTarget.value / 100
      const seekTime = this.currentSound.duration() * percent
      this.currentSound.seek(seekTime)
    }
    this.startProgressUpdate()
  }

  startProgressUpdate() {
    if (this.updateInterval) {
      clearInterval(this.updateInterval)
    }
    
    this.updateInterval = setInterval(() => {
      this.updateProgress()
    }, 100)
  }

  pauseProgressUpdate() {
    if (this.updateInterval) {
      clearInterval(this.updateInterval)
      this.updateInterval = null
    }
  }

  updateProgress() {
    if (!this.currentSound || !this.isPlaying) return

    const currentTime = this.currentSound.seek()
    const duration = this.currentSound.duration()
    
    if (duration > 0) {
      const percent = (currentTime / duration) * 100
      this.progressBarTarget.style.width = `${percent}%`
      this.progressSliderTarget.value = percent
      
      this.currentTimeTarget.textContent = this.formatTime(currentTime)
    }
  }

  updateDuration() {
    if (this.currentSound) {
      const duration = this.currentSound.duration()
      this.durationTarget.textContent = this.formatTime(duration)
    }
  }

  updatePlayButton() {
    if (this.isPlaying) {
      this.playIconTarget.classList.add('hidden')
      this.pauseIconTarget.classList.remove('hidden')
      // Start cover image rotation
      this.startCoverRotation()
    } else {
      this.playIconTarget.classList.remove('hidden')
      this.pauseIconTarget.classList.add('hidden')
      // Stop cover image rotation
      this.stopCoverRotation()
    }
  }

  resetProgress() {
    this.progressBarTarget.style.width = '0%'
    this.progressSliderTarget.value = 0
    this.currentTimeTarget.textContent = '0:00'
  }

  formatTime(seconds) {
    if (!isFinite(seconds)) return '0:00'
    
    const minutes = Math.floor(seconds / 60)
    const remainingSeconds = Math.floor(seconds % 60)
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`
  }

  showLoading() {
    this.loadingStateTarget.classList.remove('hidden')
  }

  hideLoading() {
    this.loadingStateTarget.classList.add('hidden')
  }

  showError() {
    this.errorStateTarget.classList.remove('hidden')
  }

  hideError() {
    this.errorStateTarget.classList.add('hidden')
  }

  // Public methods for external use
  loadPlaylist(playlist) {
    this.playlist = playlist
    if (playlist.length > 0) {
      this.currentTrackIndex = 0
      this.loadTrackFromPlaylist()
    }
  }

  setTrack(src, title, artist) {
    this.titleTarget.textContent = title || 'Unknown Track'
    this.artistTarget.textContent = artist || 'Unknown Artist'
    this.loadTrack(src)
  }

  startCoverRotation() {
    if (this.hasCoverImageTarget) {
      this.coverImageTarget.style.animation = 'spin 3s linear infinite'
    }
  }

  stopCoverRotation() {
    if (this.hasCoverImageTarget) {
      this.coverImageTarget.style.animation = 'none'
    }
  }

  cleanup() {
    this.pauseProgressUpdate()
    this.stopCoverRotation()
    if (this.currentSound) {
      this.currentSound.unload()
      this.currentSound = null
    }
  }
}
