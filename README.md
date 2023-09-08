# Multi-modal Spontaneous Raman Microscopy Software
## Overview of Hardware and Software

This is a control software for a multi-modal spontaneous Raman microscope. The Raman microscope is built on a standard, inverted fluorescence microscope with custom code to carry out a multi-modal, -time, and -positional confocal Raman microscopy measurement. Although building a spontaneous Raman microscope is reasonably straightforward and well-documented (Ref. 1, except make sure to use a short-pass dichroic filter to allow for a dual fluorescent/Raman capable microscope and dual axis galvo mirror for XY scanning), to the best of our knowledge no previously existing software is able to support all multi-modal/time/position measurement on a galvo mirror-based confocal Raman microscope, which is necessary for live-cell time-lapse imaging. This is because Raman microscopes inherently obtain high-dimensional hyperspectral images, whereas standard commercial or open-source microscope control software is designed for 2D or, at most, 4D (XYZ and time) images with specific hardware requirements. 
To avoid the need for creating such software for Raman from scratch, we took a hybrid approach – we carried out the traditional fluorescence imaging based on µManager2, an open-source microscope control software, and combined it with a custom MATLAB script to carry out the galvo scanning, laser shutter control, and camera readout (Fig. H1 and Methods). To facilitate inter-software communication between µManager and MATLAB, we used a digital acquisition (DAQ) board to send trigger signals from µManager to MATLAB so the Raman acquisition sequence begins, and the camera/galvo mirror/laser shutter can be controlled through MATLAB. Overall, the basic fluorescence and multi-time/positional control and measurements are carried out by µManager, while Raman imaging is tricked in µManager as a ‘demo’ image, where in fact, a trigger is sent to the DAQ board and Raman imaging commences. We describe below in detail the required optics and software components and how to assemble them. 

## Optics requirement
*	Nd:YVO4 laser (Spectra Physics, Millennia) 
*	Continuous-wave (CW) Ti:Sapphire laser (Spectra Physics, model no. 3900S) 
*	Optical table, size > 1,200 mm × 3,000 mm × 457 mm
*	Fluorescence microscope (Olympus IX83 equipped with Orca Flash 4.0 v2) 
*	Stable stage (Prior, Motorized stage H117)
*	Digital acquisition Board (National Instruments, PCIe-6351) 
*	Spectrograph (Holospec f/1.8i 785 nm model) 
*	Cooled CCD camera (Princeton Instruments, cat. no. PIXIS100BR)
*	sCMOS camera for fluorescence (Hamamatsu Photonics, Orca Flash 4.0 v2)

## Software requirement
*	Windows 10 64 bit, >16GB RAM, >2 PCIe slots, 1TB storage
*	µManager 2.0 (https://micro-manager.org/ )
*	MATLAB 2020 or newer
*	MATLAB wrapper for NI-DAQmx library (https://github.com/tenss/MATLAB_DAQmx_examples)
*	Light Field 6 or newer (Princeton Instruments)
*	NI MAX 21.0 (National Instruments)
*	Custom MATLAB scripts (`initialize_start.m`, `interrupt.m`, `destructor.m`, and `experimentDataReady.m`)
## Setting up the hardware circuits, software, and procedure
1.	Install all software and connect components to the computer according to vendor recommendations. 
2.	Connect the laser shutter to a digital output port (DO1), the two galvo mirror control wires to analog output ports (AO1/2), and the camera readout output port to a digital input port `PFI0` on the DAQ board. The `PFI0` port must be used here in order to replace the internal clock of the DAQ board with the camera readout trigger. 
3.	Connect a digital output port (DO2) to an analog input port (AI1) on the DAQ board. DO2 will be controlled by µManager, and AI1 will be monitored by the MATLAB script to decide whether or not to begin a Raman imaging sequence. 
4.	Open µManager and load the settings file (raman_fluorescence.cfg) during startup. This settings file includes settings for an Olympus IX83 microscope equipped with six fluorescence channels and additional settings for Raman imaging (channel denoted as `Raman`).
5.	Mount the sample on the microscope. Be sure to use a quartz glass substrate as standard coverslips produce auto-fluorescence signals, overwhelming the Raman spectra.
6.	In the Multi-Dimensional Acquisition (MDA) panel, choose all imaging channels (including brightfield, fluorescence, and Raman) and the number of time points, XY positions, and z-stacks. 
7.	Set exposure times for each channel. IMPORTANT: Give some margin to the Raman channel exposure time. During this Raman channel measurement in µManager, the MATLAB script is initiated, and scanning is carried out. If the µManager Raman channel exposure time is shorter than the actual measurement carried out in the script, MATLAB will crash.
8.	Open MATLAB and move to the directory where all custom scripts are present.
9.	Rewrite all parameters in `initialize_start.m` such as pixel dwell time, scanning range, scanning step, location/name to save measurements, and Raman peak to show a 2D image after every successful measurement. 
10.	Run `initialize_start.m`. `initialize_start.m` will open Light Field, the Raman camera control software, and will begin monitoring the DAQ board analog input port AI1, which continuously monitors any signal coming from µManager. 
11.	After the message “monitoring trigger” appears, start the µManager MDA measurement. This will start measuring all channels (brightfield, fluorescence, and Raman). 
12.	After a successful Raman imaging, MATLAB will output a 2D plot of the Raman imaging focusing on a single peak.
13.	If you need to interrupt a measurement: First, stop the MDA sequence in µManager. Then run `interrupt.m` in MATLAB followed by `destructor.m`. This releases and closes any objects related to Light Field or the DAQ board software. Restart MATLAB and redo from 9. 
14.	To finish measurement and close software: Assuming that the MDA sequence has been completed in µManager, run `destructor.m` and close both MATLAB and µManager.
