# FBDC-J — FlyBowlDataCapture (Jefferis fork)

MATLAB software for collecting video and experimental metadata for the
FlyBowl / FlyDisco arena. This is the Jefferis-lab fork of
[`kristinbranson/FlyBowlDataCapture`](https://github.com/kristinbranson/FlyBowlDataCapture),
with a selectable Teensy LED-controller layer added.

> This README is a Markdown rendering of the original documentation
> (previously `Docs/README.txt`, in Confluence wiki markup). The full
> historical doc and `UserGuide.pdf` remain under [`Docs/`](Docs).

## What's different in this fork

- **`TeensyLEDControl/`** — a **selectable Teensy LED-controller
  firmware** so the same code drives the optogenetics board whether it
  runs the old (`flybowl2015`) or new (`rgb_cmdarduino`) controller
  software. Pick the firmware at runtime; see
  [`TeensyLEDControl/README.md`](TeensyLEDControl/README.md).

## Overview

FlyBowlDataCapture is a MATLAB program for collecting video and
experimental metadata. The user selects which devices to record from,
enters metadata about the flies in the left panel of the GUI, clicks to
record the timestamps of events, and finally clicks to start recording.
A preview of the recorded frames, the frame rate, and the temperature
stream is shown after the devices are initialized. The program creates a
directory per experiment and writes the video, video diagnostics, video
log, temperature log, experiment log, and metadata into it.

## Running the program

In MATLAB, from the repository directory (which contains all the code),
run:

```matlab
FlyBowlDataCapture
```

On launch the GUI prompts for a **parameters file** tailored to your
experiment (see [Parameters](#parameters)). The layout is optimized for
two GUIs on a 1080×1920 monitor in portrait mode. Semaphore files under
`.GUIInstances/`, `.DetectCameras/`, `.TempRecordData/`, and
`.PreconRecordData/` let multiple MATLAB instances share the camera,
temperature probe, and sensors. Use `ListSemaphores` / `ClearSemaphores`
to inspect or clear them (do not clear while another GUI is running).

### Workflow

1. Enter metadata in the left panel (fly line, cross/sorting/starvation
   times, rig/plate/bowl, …). Controls are blue (default), grey (set),
   or orange (error/required).
2. Select the camera (**Device ID**) and **Initialize Camera**; select
   the **Temp Probe** channel and **Init Temp Probe**.
3. Click **Shift Fly Temp**, then **Flies Loaded**, then **Start
   Recording** (in that order).
4. **Save MetaData** any time; **Abort** to cancel (leaves an `ABORTED`
   marker); **Done** to finalize.

## Parameters

The parameters file (`FlyBowlDataCaptureParams_*.txt`) sets everything
below; example values in brackets. Create one per rig/experiment.

### Experiment & metadata
| Parameter | Description | Example |
|---|---|---|
| `Assay_Experimenters` | Possible experimenters | `hirokawaj,robiea` |
| `NFlies` | Expected flies per bowl | `20` |
| `Rearing_IncubatorIDs` | Possible incubator IDs | `1,2` |
| `MetaData_RearingProtocols` | Rearing protocol names (ordered per incubator) | `RearingProtocol0001_Morning,…` |
| `PreAssayHandling_CrossDate_Range` | Cross-date range, days before today | `4,10` |
| `PreAssayHandling_SortingDate_Range` | Sorting-date range | `0,2` |
| `PreAssayHandling_SortingHandlers` | Possible sorters | `hirokawaj,robiea` |
| `PreAssayHandling_StarvationDate_Range` | Starvation-date range | `0,2` |
| `PreAssayHandling_StarvationHandlers` | Possible starvers | `hirokawaj,robiea` |
| `Assay_Rigs` / `Assay_Plates` / `Assay_Bowls` | Possible rig / plate / bowl IDs | `1,2` / `01,02` / `1,2,3,4` |
| `RedoFlags` / `ReviewFlags` | Possible redo / review flags | `None,Rearing problem,…` |
| `MetaData_AssayName` | Assay name | `FlyBowl` |
| `MetaData_Effector` | Effector | `TrpA` |
| `MetaData_Gender` | Gender `{m,f,b}` | `b` |
| `MetaData_ExpProtocols` | Experiment protocol file | `ExperimentProtocol0001` |
| `MetaData_SortingHandlingProtocols` | Sorting protocol file | `SortingProtocol0001` |
| `MetaData_StarvationHandlingProtocols` | Starvation protocol file | `StarvationProtocol0001` |
| `MetaData_RoomTemperatureSetPoint` / `…HumiditySetPoint` | Set points | `29` / `60` |
| `DoQuerySage` | Query SAGE for line names (1/0) | `1` |
| `ExtraLineNames` | Extra line names to add | `DL-wildtype` |

### Camera / acquisition (Image Acquisition Toolbox)
| Parameter | Description | Example |
|---|---|---|
| `Imaq_Adaptor` | Camera adaptor name | `dcam` |
| `Imaq_DeviceName` | Camera name | `A622f` |
| `Imaq_VideoFormat` | Video format | `Format 7, Mode 0` |
| `Imaq_ROIPosition` | ROI: xmin,ymin,w,h | `0,0,1024,1024` |
| `Imaq_FrameRate` / `Imaq_MaxFrameRate` | Expected / max frame rate | `30.4` / `31` |
| `Imaq_Shutter` / `Imaq_Gain` | Shutter period / gain | `100` / `200` |
| `FileType` | Video extension (`fmf`/`ufmf`/`avi`) | `ufmf` |
| `RecordTime` | Seconds to record | `1000` |
| `PreviewUpdatePeriod` / `gdcamPreviewFrameInterval` | Preview update timing | `0` / `2` |

### Storage
| Parameter | Description | Example |
|---|---|---|
| `OutputDirectory` | Experiment dirs (per GUI instance) | `C:\…\data1,D:\data2` |
| `HardDriveName` | Drive names (ordered per OutputDirectory) | `Internal_C,HD3` |
| `TmpOutputDirectory` | Temp dirs (same disk as output) | `C:\…\tmpdata1,D:\tmpdata2` |
| `MovieFilePrefix` | Movie file prefix | `movie` |
| `MetaDataFileName` / `LogFileName` | Metadata / log file names | `Metadata.xml` / `Log.txt` |

### Temperature / humidity (Pico + Precon)
| Parameter | Description | Example |
|---|---|---|
| `DoRecordTemp` | Record temperature stream (1/0) | `1` |
| `TempProbePeriod` | Seconds between readings | `1` |
| `TempProbeChannels` / `TempProbeTypes` | Channels / thermocouple types | `1,2,3` / `K,K,K` |
| `TempProbeReject60Hz` | Reject 60 Hz (else 50 Hz) | `0` |
| `NPreconSamples` | Precon T/H samples at start (0 = off) | `5` |
| `PreconSensorSerialPort` | Precon serial port | `COM3` |
| `FrameRatePlotYLim` / `TempPlotYLim` | Plot y-limits | `0,35` / `15,45` |

### UFMF compression
`UFMFLogFileName`, `UFMFStatFileName`, `UFMFPrintStats`,
`UFMFStatStreamPrintFreq`, `UFMFStatComputeFrameErrorFreq`,
`UFMFStatPrintTimings`, `UFMFMaxFracFgCompress`, `UFMFMaxBGNFrames`,
`UFMFBGUpdatePeriod`, `UFMFBGKeyFramePeriod`, `UFMFMaxBoxLength`,
`UFMFBackSubThresh`, `UFMFNFramesInit`, `UFMFBGKeyFramePeriodInit` —
control the UFMF background model and diagnostics (see the format notes
in [`Docs/UFMFDiagnosticsFileFormat.txt`](Docs/UFMFDiagnosticsFileFormat.txt)).

## Output data

Each experiment directory (under `OutputDirectory`) contains:

- **`Log.txt`** — full event/warning/error log (mirrors the status
  window).
- **`Metadata.xml`** — all experiment metadata (assay, protocol,
  apparatus/camera/computer, flies, rearing/handling, environment,
  notes, flags).
- **`movie.<ext>`** — the video (UFMF unless configured otherwise).
- **`ufmf_diagnostics.txt`** / **`ufmf_log.txt`** — UFMF compression
  diagnostics and log.

The UFMF format is documented by the Branson lab (see `bransonlab:UFMF
File Description`); videos can be previewed with `playfmf` / `showufmf`
from JCtrax.

## License

Inherits the upstream FlyBowlDataCapture license. Third-party components
under `findjobj/` and `jfrc_metadata_tools/` retain their own licenses.
