# Lith Pulser (Logic Input Triggered High-resolution Pulser)

The lith pulser was developt to be used as the main controller for a complex and time sensitive experiment. 

For the research project “Diamond” at The Institute of Atomic and Subatomic Physics which aims to 
characterize and exploit the remarkable quantum properties of defect centers in diamond this controlling mechanism was used. 

The controller can generate trigger pulses or logical input for other instruments at a resolution of 1ns.
16 different sequence can be programmed. This sequences can contain 128 Pattern changes for 14 digital output ports.

A sequence can have a timeout. If the programmed time is over the sequence is rerun. Additionally a logical condition can be programmed that can cause an immediately rerun.

For the logical condition 2 input ports are provided. The impulses on this ports are counted in an definable time interval.
If the count is not in an specified interval the sequence is repitedt. 
This can be used to get the test object into an base state and this process will be repitedt till the base state is reached. 

A sequence can be up to 4 second long and the time to switch between two sequences is exactly 48ns. 
If more the one sequence needs to be rerun the sequence with the lower number has the higher priority.




## Hardware 

At the moment only the STEMlab 125-10 from red pitaya is supported. 

https://www.redpitaya.com/p1/stemlab-125-10-starter-kit

But It schould not be a big Problem to port this Projekt to other development boards and it should even run on an Z-7007S but is not tested.


## Get started

Follow the folloing quick start guid to setup the redpidaya: https://redpitaya.readthedocs.io/en/latest/quickStart/quickStart.html

Copy the files form the last release to the redpidaya. This should help you to do that: https://redpitaya.readthedocs.io/en/latest/developerGuide/software/clt.html#saving-data-buffers

Then you need an ssh acess to the board: https://redpitaya.readthedocs.io/en/latest/developerGuide/os/ssh/ssh.html

Make the logger runabel with the following command: "chmod +x logger" 

Run the logger with "./logger" this will load the fpga design and save logging data in a bainary format if generated.

Open another ssh connection. 

Configure the lithpulser with the monitor command. Look at the test script for some inspiration: https://github.com/im-pro-at/lithpulser/blob/master/testscript.sh

After the experiment is finished you can run the decoder. If you want to run it on the redpidaya you need to Install java on the redpitaya: 
*  "apt-get update"
*  "apt-get install default-jre"

Then you can run the decoder: "java -jar decoder-1.0.jar"

The results are saved in the folder runs. If you need to save a lot of log data you can mount a network drive or an external hard dist to that folder. 

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



## Build decoder 

Open the folder with Netbeans and hit build. 

## Build logger

The easiest way is to compile the logger on the target system. It's possible to crosscompile but it's much more effort to do so.

Copy the source code to the redpidaya. 

Then just run: "make"


## Build the fpga design 

Open Vivado (2016.2 was used).

Open the tcl console.

Type: "cd < folder of the source code >"

Type: "source redpitaya.tcl"

Then the project opens and just click write bitstream.

When the build is finished copy "system_wrapper.bin" to the redpidaya and name it "fpga.bin"

## FPGA Memory Interface

The following memory allocation is used for the memory mapped interface between Linux operating system and the FPGA design:

You can use the commadn "monitor" from redpidaya https://github.com/RedPitaya/RedPitaya/tree/master/Test/monitor 

It schould be pre installed on the redpitaya linux image.

| **Section Name** | **Start Address** | **Description** |
| --- | --- | --- |
| Control | 0x40000000 | In this section the global settings are accessible. Also the whole mechanism can be enabled or disabled. |
| Sequence 1 | 0x40010000 | All these sections correspond to different sequences which can be used for tuning or measurement. The number reflects the priority of the sequence. If two sequences need to be re-run the sequence with the lower number will be run first. Therefore, tuning sequences should have lower numbers. A change from one sequence to another (or repeating the same) takes 48ns. |
| Sequence 2 | 0x40011000 |
| …. | … |
| Sequence 15 | 0x4001E000 |
| Sequence 16 | 0x4001F000 |

The Control section has the following mapping:

| **Name** | **Offset** | **Bits** | **R/W** | **Description** |
| --- | --- | --- | --- | --- |
| ID | 0x000 | 0:31 | R | Should read: &quot;0x0BADA550&quot;. Is used to check if the design is loaded. |
| Run | 0x004 | 0 | R/W | If set to &quot;1&quot; the whole design starts running. Also the counters and log buffer is flushed. If set to &quot;0&quot; the whole design stops. While &quot;0&quot; the output is set to the Default Pattern. |
| Clear | 0x008 | 0 | W | If set to &quot;1&quot; all setting and all patterns of all sequences are set to default. The settings in the Control section are not affected. |
| Default Pattern | 0x010 | 0:13 | R/W | When Run is set to &quot;0&quot; this pattern will be output. |
| Log Level | 0x020 | 0:1 | R/W | There are two logging sources which can be enabled independently:If Bit 0 is set to &quot;1&quot; all counter values will be logged.If Bit 1 is set to &quot;1&quot; all sequence start times will be logged. |
| Log LO half | 0x030 | 0:31 | R | Read the lower half of the current log entry |
| Log UP half | 0x034 | 0:24 | R | Read the upper half of the current log entry |
| Log next | 0x038 | 0 | R | Read if there is a current log entry to read.If &quot;1&quot; is read a new log entry can be read from 0x030 and 0x034. If &quot;0&quot; is read there is no new log entry. |
| Log Overflow | 0x03C | 0 | R | If &quot;1&quot; is read the log buffer is overflown. Therefore some of the log entries are lost.  The buffer can hold roughly up to 16.000 events. |


The log entries have the following decoding.  The first bit determines the type of the entry:

- Counter entry:

| **Bits** | **0** | **1:4** | **5:30** | **31:56** |
| --- | --- | --- | --- | --- |
| **Meaning** | &quot;0&quot; | Sequence Number | I0 Counter value | I1 Counter value |

- Start time entry:

| **Bits** | **0** | **1:4** | **5:56** |
| --- | --- | --- | --- |
| **Meaning** | &quot;1&quot; | Sequence Number | Start time in ns from the moment Run was set to &quot;1&quot; |

The memory mapping of all the sequence sections is the same and has the following mapping:

| **Name** | **Offset** | **Bits** | **R/W** | **Description** |
| --- | --- | --- | --- | --- |
| Enable | 0x000 | 0 | R/W | If set to &quot;1&quot; this sequence will be enabled. If set to &quot;0&quot; this sequence will not be used. |
| Runs | 0x010 | 0:31 | R | Is the up to date value of the number of runs of this sequence. This value will be reset when Run is set to &quot;1&quot; |
| Rerun | 0x020 | 0:31 | R/W | Time in ns which this sequence has to be rerun. For measurement sequences this can be set to 0. Therefore the sequence is repeated as often as possible.  For tuning this value must be set to the time the tuning has to be repeated. If the Value is set to &quot;0xFFFFFFFF&quot; the sequence will never be repeated. This is useful for an initialization sequence. |
| Length | 0x024 | 0:31 | R/W | Length of the sequence in ns. Done to the internal structure the lowest 3 bits are ignored. This means the length can only be a multiple of 8ns. |
| MTR Output | 0x030 | 0:13 | R/W | The Memory Transfer Register for the Output pattern. |
| MTR Time | 0x034 | 0:31 | R/W | The Memory Transfer Register for the Output time in ns relative to the start of the sequence. |
| MTR Trigger | 0x038 | 0 | W | Done to the internal structure the patterns cannot be saved directly. So for each pattern and time the values must be written to the MTRs. Then this register must be set to &quot;1&quot; to process the data. This must be repeated for all patterns. The pattern must also be programmed ordered by time starting with the smallest value.   |
| LD Mode | 0x100 | 0:7 | R/W | For tuning this register is used to set the condition to detect when the tuning is successful. If the condition is not true the sequence is repeated. This is independent from the rerun time.If set to &quot;0&quot; the condition is always true.If set to &quot;1&quot; I0 must be in its limits.If set to &quot;2&quot; I1 must be in its limits.If set to &quot;3&quot; I0 and I1 must be in its limits.If set to &quot;4&quot; I0 or I1 must be in its limits. |
| LD I0 start | 0x110 | 0:31 | R/W | The start time of the window in which the impulses are counted. This time is 128ns behind the output. |
| LD I0 stop | 0x114 | 0:31 | R/W | The stop time of the window in which the impulses are counted. This time is 128ns behind the output. |
| LD I0 min | 0x118 | 0:25 |   | The lower limit for the counter value to compare to. |
| LD I0 max | 0x11C | 0:25 |   | The higher limit for the counter value to compare to. |
| LD I1 start | 0x120 | 0:31 | R/W | The start time of the window in which the impulses are counted. This time is 128ns behind the output. |
| LD I1 stop | 0x124 | 0:31 | R/W | The stop time of the window in which the impulses are counted. This time is 128ns behind the output. |
| LD I1 min | 0x128 | 0:25 |   | The lower limit for the counter value to compare to. |
| LD I1 max | 0x12C | 0:25 |   | The higher limit for the counter value to compare to. |
