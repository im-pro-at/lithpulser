# Lith Pulser (Logic Input Triggered High-resolution Pulser)

![design](docu/design.jpg?raw=true)

The lith pulser was developed to be used as a main controller for complex and time sensitive experiments.

Lith was developed at Technical University Vienna for controlling a quantum emitter experiment employing nitrogen vacancy centres (https://www.nature.com/articles/s41534-019-0236-x).

The controller can generate TTL-standard compatiple digital pulses at a time resolution of 1 ns with about 200 MHz bandwidth (depending on hardware used). 16 different sequences can be programmed, each may contain 128 pattern changes per output channel (14 channels). Furthermore the pulser offers sequence play control by two independently working mechanisms: 
1. sequences have a inate priority value and may have a timeout 
2. pre-set logic is triggered through optional digital-input channels.

Details on sequence play control:
1. A sequence can have a finite timeout value. Passing the timeout will trigger the sequence to be rerun which currently has timed out AND the highest priority value (lower sequence numbers have higher priority). 
2. Additionally, a logical condition can be programmed on detecting an event(s) at one or both of the two digital input channels within the user specified time period in the sequence. Detection and passing the logic condition then triggers fast change of the next sequence  to be played with a minimal delay time of 48 ns. This mechanism provides the basis for repeating sequences until success.

A sequence can be up to 4 seconds long and the time to switch between two sequences is always exactly 48ns. A default output pattern can be defined for periods in between sequences and when pulsing is switched off. Logging of sequence execution is available.

More information about the design can be found in documentation: https://github.com/im-pro-at/lithpulser/blob/master/docu/projekt.pdf

## Hardware 

At the moment only the STEMlab 125-10 from red pitaya is supported. 

https://www.redpitaya.com/p1/stemlab-125-10-starter-kit

It should be possible to port this project to other development boards as well and it should even run on an Z-7007S but this has not been tested.


## Get started

Follow this quick start guide to setup the Redpidaya: https://redpitaya.readthedocs.io/en/latest/quickStart/quickStart.html

Copy the files from the last release to the Redpidaya. This should help you to do that: https://redpitaya.readthedocs.io/en/latest/developerGuide/software/clt.html#saving-data-buffers

You need SSH access to the board: https://redpitaya.readthedocs.io/en/latest/developerGuide/os/ssh/ssh.html

Make the logger runable with the following command: "chmod +x logger" 

Run the logger with "./logger", This will load the FPGA design and save logging data in a binary format if enabled.

Open another SSH connection. 

Configure the lith pulser with the "monitor" command. Look at the test script for some inspiration: https://github.com/im-pro-at/lithpulser/blob/master/testscript.sh

After the experiment is finished you can run the decoder. If you want to run it on the Redpidaya you need to install java: 
*  "apt-get update"
*  "apt-get install default-jre"

Then run the decoder: "java -jar decoder-1.0.jar"

The results are saved in the folder "runs". If you need to save a lot of log data you can mount a network drive or an external hard disc to that folder. 

That's it. Have fun!

## Pin mapping

For the locations of the connections look at this Dokumentation: https://redpitaya.readthedocs.io/en/latest/developerGuide/125-14/extent.html

PIN Mapping:
*   I0:    DIO0_N 
*   I1:    DIO1_N
*   O0:    DIO0_P
*   O1:    DIO1_P
*   O2:    DIO2_P
*   O3:    DIO3_P
*   O4:    DIO4_P
*   O5:    DIO5_P
*   O6:    DIO6_P
*   O7:    DIO7_P
*   O8:    DIO2_N
*   O9:    DIO3_N
*   O10:    DIO4_N
*   O11:    DIO5_N
*   O12:    DIO6_N
*   O13:    DIO7_N

Status Leds:
*	0:	RUN
*	1:	Log overrun
*	2:	Sequence 1 active
*	3:	Sequence 2 active
*	4:	Sequence 3 active
*	5:	Sequence 4 active
*	6:	Sequence 5 active
*	7:	Sequence 6 active

## Build decoder 

Open the folder with Netbeans and hit build. 

## Build logger

The easiest way is to compile the logger on the target system. It's possible to cross compile but it's much more effort to do so.

Copy the source code to the redpidaya. 

Then just run: "make"


## Build the FPGA design 

Open Vivado (2016.2 was used).

Open the "TCL Console".

Type: "cd < folder of the source code >"

Type: "source redpitaya.tcl"

Then the project opens and just click "write bitstream".

When the build is finished copy "system_wrapper.bin" to the Redpidaya and name it "fpga.bin"

## FPGA Memory Interface

The following memory allocation is used for the memory mapped interface between the Linux operating system and the FPGA design:

You can use the command "monitor" from redpidaya https://github.com/RedPitaya/RedPitaya/tree/master/Test/monitor 

It should be pre installed on the redpitaya linux image.

| **Section Name** | **Start Address** | **Description** |
| --- | --- | --- |
| Control | 0x40000000 | In this section the global settings are accessible. Also the whole mechanism can be enabled or disabled. |
| Sequence 1 | 0x40010000 | All these sections correspond to different sequences. The number reflects the priority of the sequence. If two sequences need to be re-run the sequence with the lower number will be run first. A change from one sequence to another (or repeating the same) takes 48ns. |
| Sequence 2 | 0x40011000 |
| …. | … |
| Sequence 15 | 0x4001E000 |
| Sequence 16 | 0x4001F000 |

The Control section has the following mapping:

| **Name** | **Offset** | **Bits** | **R/W** | **Description** |
| --- | --- | --- | --- | --- |
| ID | 0x000 | 0:31 | R | Should read: &quot;0x0BADA550&quot; use to check if the design is loaded. |
| Run | 0x004 | 0 | R/W | If set to &quot;1&quot; the sequences are run. Counters and log buffer is flushed. If set to &quot;0&quot; the whole design stops. While &quot;0&quot; the output is set to the default pattern. |
| Clear | 0x008 | 0 | W | If set to &quot;1&quot; all settings and all patterns of sequences are set to default. The settings in the Control section are not affected. |
| Default Pattern | 0x010 | 0:13 | R/W | When Run is set to &quot;0&quot; this pattern will be output. |
| Log Level | 0x020 | 0:1 | R/W | There are two logging sources which can be enabled independently. If Bit 0 is set to &quot;1&quot; all counter values will be logged. If Bit 1 is set to &quot;1&quot; all sequence start times will be logged. |
| Log LO half | 0x030 | 0:31 | R | Read the lower half of the current log entry |
| Log UP half | 0x034 | 0:24 | R | Read the upper half of the current log entry |
| Log next | 0x038 | 0 | R | Check if there is a current log entry to read. If &quot;1&quot; a new log entry can be read from 0x030 and 0x034. If &quot;0&quot; there is no new log entry. |
| Log Overflow | 0x03C | 0 | R | If &quot;1&quot; is read the log buffer has overflown. Therefore, some of the log entries are lost.  The buffer can hold roughly up to 16.000 events. |


The log entries have the following decoding.  The first bit determines the type of the entry:

- Counter entry:

| **Bits** | **0** | **1:4** | **5:30** | **31:56** |
| --- | --- | --- | --- | --- |
| **Meaning** | &quot;0&quot; | Sequence Number | I0 Counter value | I1 Counter value |

- Start time entry:

| **Bits** | **0** | **1:4** | **5:56** |
| --- | --- | --- | --- |
| **Meaning** | &quot;1&quot; | Sequence Number | Start time in ns from the moment "Run" was set to &quot;1&quot; |

The memory mapping of the sequence sections is the same for all and has the following mapping:

| **Name** | **Offset** | **Bits** | **R/W** | **Description** |
| --- | --- | --- | --- | --- |
| Enable | 0x000 | 0 | R/W | If set to &quot;1&quot; this sequence will be enabled. If set to &quot;0&quot; this sequence will not be used. |
| Runs | 0x010 | 0:31 | R | Is the up to date value of the number of runs of this sequence. This value will be reset when "Run" is set to &quot;1&quot; |
| Rerun | 0x020 | 0:31 | R/W | Time in ns when the sequence has to be rerun (timeout value). This can be set to 0 for consant repetition when on the lowest sequence priority. The timeout value may be set to the time a certain routine has to be repeated. If the value is set to &quot;0xFFFFFFFF&quot; the sequence will never be repeated. |
| Length | 0x024 | 0:31 | R/W | Length of the sequence in ns. Due to the internal structure the lowest 3 bits are ignored. This means the length can only be a multiple of 8ns. |
| MTR Output | 0x030 | 0:13 | R/W | The Memory Transfer Register (MTR) for the output channel pattern. |
| MTR Time | 0x034 | 0:31 | R/W | The MTR for the output time in ns relative to the start of the sequence. |
| MTR Trigger | 0x038 | 0 | W | Due to the internal structure the channel/time patterns cannot be saved directly. For each channel pattern and time the values must be written to the MTRs. Then this register has be set to &quot;1&quot; to process the data. This must be repeated for every channel/time pattern. The patterns must be programmed ordered by time starting with the smallest value.   |
| LD Mode | 0x100 | 0:7 | R/W | This register is optionally used to set a logical condition on detected input. If the condition is not met the sequence is not changed. This mechanism is independent from the timeout. If set to &quot;0&quot; the condition is always passed. If set to &quot;1&quot; I0 must be in its limits. If set to &quot;2&quot; I1 must be in its limits. If set to &quot;3&quot; I0 AND I1 must be in its limits. If set to &quot;4&quot; I0 OR I1 must be in its limits. |
| LD I0 start | 0x110 | 0:31 | R/W | The start time of the window in which the events at the input are counted. This time is 128ns behind the output. |
| LD I0 stop | 0x114 | 0:31 | R/W | The stop time of the window in which the events are counted. This time is 128ns behind the output. |
| LD I0 min | 0x118 | 0:25 |   | The lower limit for the counter value to compare to. |
| LD I0 max | 0x11C | 0:25 |   | The higher limit for the counter value to compare to. |
| LD I1 start | 0x120 | 0:31 | R/W | The start time of the second window in which the events are counted. This time is 128ns behind the output. |
| LD I1 stop | 0x124 | 0:31 | R/W | The stop time of the window in which the events are counted. This time is 128ns behind the output. |
| LD I1 min | 0x128 | 0:25 |   | The lower limit for the counter value to compare to. |
| LD I1 max | 0x12C | 0:25 |   | The higher limit for the counter value to compare to. |
