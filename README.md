# ISOL
Scripts useful for ISOL experiments at SPES, in both front-end offline and online

## EPICS logger

Let us assume that you are in the TEST_ISOL folder.
In this folder there is the executable to log the data and this README file.
Create a new subfolder with the date of the experiment.
Move into this subfolder.
The command to start the logger is

```
./../epics_logger.sh -s .5 -c 20260612_output_p1.txt DlDiagDgbx01A_Fcup01:CurrAv Dl1SourIonz01A_Hcps02:Imon
argument -s sampling time
```

flag -c csv format in the output
list all the PVs that you want to save, in the example just two are reported
If successful, you should see:

```
Checking PV connectivity...
OK: DlDiagDgbx01A_Fcup01:CurrAv
OK: Dl1SourIonz01A_Hcps02:Imon

Logging started at: 2026-06-12 09:53:24
Sampling time: .5s
Press Ctrl+C to stop.
```

Leave this terminal in this state until you want to stop it with ctrl+c command.
Do NOT put any other command in this terminal, which is busy logging the data.

To check if the logger is working properly, check the last 10 rows (or more or less) of your output file.
To do so, open a new terminal in the same folder of your output file and insert the following command:

```
tail -n 10 20260612_output_p1.txt
```

you should see something like:

```
Timestamp,DlDiagDgbx01A_Fcup01:CurrAv,Dl1SourIonz01A_Hcps02:Imon
2026-06-12 09:53:24.879,0.0188803,325.401
2026-06-12 09:53:25.387,0.0291569,325.071
2026-06-12 09:53:25.901,0.0172073,325.376
2026-06-12 09:53:26.413,0.0274839,325.071
2026-06-12 09:53:26.927,0.0279619,325.413
2026-06-12 09:53:27.440,0.0174463,325.401
2026-06-12 09:53:27.948,0.0310688,325.083
```

Checking once every some time is good practice.

There are some scripts to print some specific PVs on the terminal.

```
bash get_current.sh
bash get_integrator.sh
bash get_machine_status.sh
```

## Oven controller

**To test**
