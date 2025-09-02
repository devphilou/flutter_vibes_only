import numpy as np
import os
from pydub import AudioSegment
import io

# Note frequencies (in Hz) for two octaves starting from C4 (Middle C)
NOTE_FREQUENCIES = {
    # First octave (C4-B4)
    'C4': 261.63,
    'Csharp4': 277.18,    # Also Db4
    'D4': 293.66,
    'Dsharp4': 311.13,    # Also Eb4
    'E4': 329.63,
    'F4': 349.23,
    'Fsharp4': 369.99,    # Also Gb4
    'G4': 392.00,
    'Gsharp4': 415.30,    # Also Ab4
    'A4': 440.00,
    'Asharp4': 466.16,    # Also Bb4
    'B4': 493.88,
    
    # Second octave (C5-B5)
    'C5': 523.25,
    'Csharp5': 554.37,
    'D5': 587.33,
    'Dsharp5': 622.25,
    'E5': 659.25,
    'F5': 698.46,
    'Fsharp5': 739.99,
    'G5': 783.99,
    'Gsharp5': 830.61,
    'A5': 880.00,
    'Asharp5': 932.33,
    'B5': 987.77
}

def generate_note(note, duration=1.0, sample_rate=44100, amplitude=0.5):
    """Generate a sine wave for a piano note"""
    frequency = NOTE_FREQUENCIES[note]
    t = np.linspace(0, duration, int(sample_rate * duration), False)
    wave = amplitude * np.sin(2 * np.pi * frequency * t)
    
    # Add simple envelope to make it sound more natural
    envelope = np.ones_like(wave)
    attack = int(0.05 * sample_rate)
    release = int(0.2 * sample_rate)
    envelope[:attack] = np.linspace(0, 1, attack)
    envelope[-release:] = np.linspace(1, 0, release)
    
    return (wave * envelope * 32767).astype(np.int16)

# Ensure audio directory exists
output_dir = 'audio' # Define output directory
os.makedirs(output_dir, exist_ok=True)

sample_rate = 44100 # Define sample rate

# Generate all notes in two octaves
print("Generating MP3 notes...")
for note in NOTE_FREQUENCIES.keys():
    wave_data = generate_note(note, sample_rate=sample_rate)

    # Create AudioSegment directly from numpy array bytes
    try:
        audio_segment = AudioSegment(
            wave_data.tobytes(), 
            frame_rate=sample_rate,
            sample_width=wave_data.dtype.itemsize, # Should be 2 for int16
            channels=1 # Mono
        )
        
        # Export as MP3 with a standard bitrate
        mp3_filename = f"{output_dir}/{note}.mp3"
        try:
             audio_segment.export(mp3_filename, format="mp3", bitrate="128k")
        except Exception as export_error:
            print(f"Error: Failed to export {note} as MP3: {export_error}")
            continue # Skip to next note if export fails

        # Delete the old .ogg file if it exists (from previous attempt)
        ogg_filename = f"{output_dir}/{note}.ogg"
        if os.path.exists(ogg_filename):
            os.remove(ogg_filename)
        print(f'Generated {note}.mp3')

    except Exception as e:
         print(f"\nError processing {note}: {e}")
         # Keep the detailed ffmpeg error message if it occurs during segment creation
         if "ffmpeg" in str(e).lower(): 
              print("This likely means ffmpeg is not installed or not found in your system's PATH.")
              print("Please install ffmpeg (e.g., 'brew install ffmpeg' on macOS, or download from ffmpeg.org) and try again.")
              break # Stop if ffmpeg is likely missing

print(f"\nDone generating MP3 files in: {output_dir}")
