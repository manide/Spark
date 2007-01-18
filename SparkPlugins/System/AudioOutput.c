//
//  AudioOutput.m
//  Labo Test
//
//  Created by Jean-Daniel Dupas on 09/01/07.
//  Copyright 2007 Adamentium. All rights reserved.
//

#include "AudioOutput.h"

static const
Float32 kAudioOutputVolumeLevels[] = { 
  0.00,
  0.06, 0.12, 0.19, 0.25,
  0.31, 0.37, 0.44, 0.50,
  0.56, 0.62, 0.69, 0.75,
  0.81, 0.87, 0.93, 1.00,
};
const
UInt32 kAudioOutputVolumeMaxLevel = 16;

SK_INLINE
UInt32 __AudioOutputVolumeGetLevel(Float32 output) {
  if (output <= 0.0)
    return 0;
  else if (output >= 1.0)
    return kAudioOutputVolumeMaxLevel;
  for (unsigned level = 0; level < kAudioOutputVolumeMaxLevel; level++) {
    /* If bewteen current level and next level */
    if (output < kAudioOutputVolumeLevels[level + 1]) {
      /* Round level */
      Float32 avg = (kAudioOutputVolumeLevels[level] + kAudioOutputVolumeLevels[level + 1]) / 2.0;
      return output < avg ? level : level + 1;
    }
  }
  return kAudioOutputVolumeMaxLevel;
}

OSStatus AudioOutputGetSystemDevice(AudioDeviceID *device) {
  UInt32 size = sizeof(AudioDeviceID);
  return AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice, &size, device);
}

OSStatus AudioOutputGetStereoChannels(AudioDeviceID device, UInt32 *left, UInt32 *right) {
  UInt32 channels[2];
  UInt32 size = sizeof(channels);
  OSStatus err = AudioDeviceGetProperty(device, 0, FALSE, kAudioDevicePropertyPreferredChannelsForStereo, &size, &channels);
  if (noErr == err) {
    if (left) *left = channels[0];
    if (right) *right = channels[1];
  }
  return err;
}

#pragma mark Volume
Boolean AudioOutputHasVolumeControl(AudioDeviceID device, Boolean *isWritable) {
  OSStatus err = AudioDeviceGetPropertyInfo(device, 0, FALSE, kAudioDevicePropertyVolumeScalar, NULL, isWritable);
  if (noErr == err) {
    return TRUE;
  } else {
    UInt32 channel;
    err = AudioOutputGetStereoChannels(device, &channel, NULL);
    if (noErr == err) {
      return noErr == AudioDeviceGetPropertyInfo(device, channel, FALSE, kAudioDevicePropertyVolumeScalar, NULL, isWritable);
    }
  }
  return FALSE;
}

OSStatus AudioOutputGetVolume(AudioDeviceID device, Float32 *left, Float32 *right) {
  UInt32 size = sizeof(Float32);
  OSStatus err = AudioDeviceGetProperty(device, 0, FALSE, kAudioDevicePropertyVolumeScalar, &size, left);
  if (noErr == err) {
    *right = *left;
  } else if (kAudioHardwareUnknownPropertyError == err) {
    UInt32 channels[2];
    size = sizeof(Float32);
    err = AudioOutputGetStereoChannels(device, &channels[0], &channels[1]);
    if (noErr == err) err = AudioDeviceGetProperty(device, channels[0], FALSE, kAudioDevicePropertyVolumeScalar, &size, left);
    if (noErr == err) err = AudioDeviceGetProperty(device, channels[1], FALSE, kAudioDevicePropertyVolumeScalar, &size, right);
  }
  return err;
}
OSStatus AudioOutputSetVolume(AudioDeviceID device, Float32 left, Float32 right) {
  OSStatus err = AudioDeviceSetProperty(device, NULL, 0, FALSE, kAudioDevicePropertyVolumeScalar, sizeof(Float32), &left);
  if (kAudioHardwareUnknownPropertyError == err) {
    UInt32 channels[2];
    err = AudioOutputGetStereoChannels(device, &channels[0], &channels[1]);
    if (noErr == err) err = AudioDeviceSetProperty(device, NULL, channels[0], FALSE, kAudioDevicePropertyVolumeScalar, sizeof(Float32), &left);
    if (noErr == err) err = AudioDeviceSetProperty(device, NULL, channels[1], FALSE, kAudioDevicePropertyVolumeScalar, sizeof(Float32), &right);
  }
  return err;
}

#pragma mark -
#pragma mark Mute
Boolean AudioOutputHasMuteControl(AudioDeviceID device, Boolean *isWritable) {
  return noErr == AudioDeviceGetPropertyInfo(device, 0, FALSE, kAudioDevicePropertyMute, NULL, isWritable);
}

OSStatus AudioOutputIsMuted(AudioDeviceID device, Boolean *mute) {
  UInt32 value = 0;
  UInt32 size = sizeof(UInt32);
  OSStatus err = AudioDeviceGetProperty(device, 0, FALSE, kAudioDevicePropertyMute, &size, &value);
  if (noErr == err) {
    *mute = value ? TRUE : FALSE;
  }
  return err;  
}

OSStatus AudioOutputSetMuted(AudioDeviceID device, Boolean mute) {
  UInt32 value = mute ? 1 : 0;
  return AudioDeviceSetProperty(device,
                                NULL, //time stamp not needed
                                0, //channel 0 is master channel
                                FALSE,  //for an output device
                                kAudioDevicePropertyMute,
                                sizeof(UInt32), &value);
}

#pragma mark High Level Functions
static 
OSStatus _AudioOutputSetVolume(AudioDeviceID device, Float32 left, Float32 right, Float32 volume) {
  Float32 balance = SKFloatEquals(right, 0.0) ? 1.0 : left / right;
  if (left > right) {
    left = volume;
    right = SKFloatEquals(right, 0.0) ? 0.0 : left / balance;
  } else {
    right = volume;
    left = right * balance;
  }
  left = (left < 0.0) ? 0.0 : ((left > 1.0) ? 1.0 : left);
  right = (right < 0.0) ? 0.0 : ((right > 1.0) ? 1.0 : right);
  return AudioOutputSetVolume(device, left, right);
}

OSStatus AudioOutputVolumeUp(AudioDeviceID device, UInt32 *level) {
  Float32 right, left;
  OSStatus err = AudioOutputGetVolume(device, &left, &right);
  if (noErr == err) {
    Float32 max = left > right ? left : right;
    UInt32 lvl = __AudioOutputVolumeGetLevel(max);
    if (kAudioOutputVolumeMaxLevel == lvl) {
      /* If not max level */
      if (!SKFloatEquals(max, 1.0)) {
        err = _AudioOutputSetVolume(device, left, right, 1.0);
      }
    } else {
      lvl++;
      check(lvl <= kAudioOutputVolumeMaxLevel);
      err = _AudioOutputSetVolume(device, left, right, kAudioOutputVolumeLevels[lvl]);
    }
    if (level) *level = lvl;
  }
  return err;
}
OSStatus AudioOutputVolumeDown(AudioDeviceID device, UInt32 *level) {
  Float32 right, left;
  OSStatus err = AudioOutputGetVolume(device, &left, &right);
  if (noErr == err) {
    Float32 max = left > right ? left : right;
    UInt32 lvl = __AudioOutputVolumeGetLevel(max);
    if (0 == lvl) {
      /* If not min level */
      if (!SKFloatEquals(max, 0.0)) {
        err = _AudioOutputSetVolume(device, left, right, 0.0);
      }
    } else {
      lvl--;
      check(lvl <= kAudioOutputVolumeMaxLevel);
      err = _AudioOutputSetVolume(device, left, right, kAudioOutputVolumeLevels[lvl]);
    }
    if (level) *level = lvl;
  }
  return err;
}
/* 0 - 16 */
OSStatus AudioOutputVolumeGetLevel(AudioDeviceID device, UInt32 *level) {
  Float32 right, left;
  OSStatus err = AudioOutputGetVolume(device, &left, &right);
  if (noErr == err) {
    Float32 max = left > right ? left : right;
    if (level) *level = __AudioOutputVolumeGetLevel(max);
  }
  return err;
}