---
name: projected-hardware
description: 提供在 Android XR 投影设备（如音频眼镜和显示眼镜）上访问和管理硬件的说明与工作流。当在 Android 应用中为智能眼镜构建体验、需要访问相机和麦克风等设备硬件、处理眼镜特有的运行时权限，或使用 projected context 管理连接生命周期时使用。

license: Complete terms in LICENSE.txt
metadata:
  author: Google LLC
  last-updated: '2026-11-13'
  keywords:
  - Android XR
  - intelligent eyewear
  - audio glasses
  - display glasses
  - glasses hardware
  - ProjectedContext
  - projected context
  - runtime permissions
  - CameraX
  - audio recording
---

## Prerequisites

- You must use a `compileSdk` of 36 or higher.

## Connection and lifecycle management

Intelligent eyewear hardware is only accessible while the glasses are connected
to the host phone. Monitor connection state and manage resource lifecycles using
`ProjectedContext`. You must read
[Understand projected activities and projected contexts](references/android/develop/xr/jetpack-xr-sdk/glasses/support-different-types.md) to understand
how to get a projected context and [how to manage its lifecycle](references/android/develop/xr/jetpack-xr-sdk/glasses/check-availability.md).

## Request glasses hardware permissions

- **Hardware permissions and opt-in** : You must read [Request hardware permissions](references/android/develop/xr/jetpack-xr-sdk/request-hardware-permissions.md) to understand how to declare camera and microphone runtime permissions in the Android Manifest file, request runtime permissions in different scenarios, and handle permission results.

## Glasses hardware access and capabilities

- **Camera capture and CameraX** : You must read [Capture an image with the glasses' camera](references/android/develop/xr/jetpack-xr-sdk/access-hardware-projected-context.md) to understand the implementation patterns for capturing a photo with the glasses' camera using a `ProjectedContext`.
- **Bluetooth HFP audio and host device context** : Read [Use a projected
  context to access hardware](references/android/develop/xr/jetpack-xr-sdk/access-hardware-projected-context.md) to route `AudioRecord` to the glasses microphone over Bluetooth HFP (`TYPE_BLUETOOTH_SCO`, `VOICE_COMMUNICATION`, `setPreferredDevice`, and `setCommunicationDevice`) and to obtain the host phone context from a projected activity using `ProjectedContext.createHostDeviceContext(activity)` (annotated with `@OptIn(ExperimentalProjectedApi::class)` from `androidx.xr.projected.experimental.ExperimentalProjectedApi`).
