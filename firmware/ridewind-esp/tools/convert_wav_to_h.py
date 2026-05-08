#!/usr/bin/env python3
"""
Convert WAV files to ESP32-compatible C header files for engine_synth.
Output format: 8-bit signed integers, 22050Hz sample rate.
Usage: python convert_wav_to_h.py input.wav output.h ARRAY_NAME NATIVE_RPM
"""

import sys
import wave
import numpy as np
import os

TARGET_SAMPLE_RATE = 22050

def convert_wav_to_h(input_wav, output_h, array_name, native_rpm):
    if not os.path.exists(input_wav):
        print(f"Error: {input_wav} not found")
        return

    with wave.open(input_wav, 'rb') as wf:
        n_channels = wf.getnchannels()
        sample_width = wf.getsampwidth()
        frame_rate = wf.getframerate()
        n_frames = wf.getnframes()
        
        print(f"Input: {input_wav}")
        print(f"  Channels: {n_channels}, Width: {sample_width}, Rate: {frame_rate}, Frames: {n_frames}")
        
        # Read all frames
        raw_data = wf.readframes(n_frames)
        
        # Convert to numpy array based on sample width
        if sample_width == 1:
            dtype = np.int8
        elif sample_width == 2:
            dtype = np.int16
        else:
            print(f"Unsupported sample width: {sample_width}")
            return
            
        # Handle multi-channel by taking first channel
        if n_channels > 1:
            samples = np.frombuffer(raw_data, dtype=dtype).reshape(-1, n_channels)[:, 0]
        else:
            samples = np.frombuffer(raw_data, dtype=dtype)
            
        # Resample if necessary
        if frame_rate != TARGET_SAMPLE_RATE:
            from scipy import signal
            num_samples = int(len(samples) * TARGET_SAMPLE_RATE / frame_rate)
            samples = signal.resample(samples, num_samples)
            print(f"  Resampled to {TARGET_SAMPLE_RATE}Hz ({num_samples} samples)")
        else:
            print(f"  Sample rate matches target ({TARGET_SAMPLE_RATE}Hz)")
            
        # Convert to 8-bit signed
        if dtype == np.int16:
            samples = (samples / 256).astype(np.int8)
        else:
            samples = samples.astype(np.int8)
            
        # Write header file
        with open(output_h, 'w') as f:
            f.write(f"#pragma once\n")
            f.write(f"#include <stdint.h>\n")
            f.write(f"#define {array_name.upper()}_SAMPLE_RATE {TARGET_SAMPLE_RATE}\n")
            f.write(f"#define {array_name.upper()}_SAMPLE_COUNT {len(samples)}\n")
            f.write(f"static const int8_t {array_name}_samples[] = {{\n")
            
            for i in range(0, len(samples), 16):
                chunk = samples[i:i+16]
                line = ", ".join(str(s) for s in chunk)
                f.write(f"{line},\n")
                
            f.write("};\n")
            
        print(f"Output: {output_h} ({len(samples)} samples)")

if __name__ == "__main__":
    if len(sys.argv) < 5:
        print("Usage: python convert_wav_to_h.py input.wav output.h array_name native_rpm")
        print("Example: python convert_wav_to_h.py idle.wav engine_idle.h engine_idle 800")
        sys.exit(1)
        
    convert_wav_to_h(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
