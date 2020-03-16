# Lith Pulser (Logic Input Triggered High-resolution Pulser)

At the moment only the STEMlab 125-10 from red pitaya is supported. But It schould not be a big Problem to port this Projekt to other development boards and should even run on an Z-7007S but is not tested.

## Get started STEMlab 125-10

Follow the folloing quick start guid: https://redpitaya.readthedocs.io/en/latest/quickStart/quickStart.html

Then you need an ssh acess to the board: https://redpitaya.readthedocs.io/en/latest/developerGuide/os/ssh/ssh.html


## Compile logger

load the source code and the make file to the linux on the zync. You can cross compile it but this way is a lot easier.
install gcc
run make


## FPGA Memory Interface

The following memory allocation is used for the memory mapped interface between Linux operating system and the FPGA design:

You can use the monitor tool from redpidaya: https://github.com/RedPitaya/RedPitaya/tree/master/Test/monitor

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
