# TDTStimulatedResponseAnalysisGUI_v3

TDT Analysis of Electrically Stimulated Potentials (version 3)

Written by: Jeremy Ford copyright 2023,  GNU Public License v3.0

Based on an analysis pipeline originally from John Huguenard, Ph.D., Professor of Neurology and Neuological Sciences at Stanford University

Code uses packages provided by the TDT (Tucker Davis Technologies) API (application programming interface).

This software will import data gathered using TDT hardware and Synapse software, and allow the user to name channels of interest, define analysis windows, and run calculations over the windows of interest. Information can be saved throughout this process, and can be loaded in the future to re-analyze. This interface is guided so that the user only has access to the next section in the analysis process, and the GUI updates these sections along the way. 

For the purpose of this work, a recording refers to a single TDT tank (folder) that contains a .sev file for each electrode channel, which has the voltage versus time traces and associated metadata. An experiment, which are the different manipulations performed on the same brain slice (e.g. simulation intensity or chemical wash), may be made up of multiple recordings. This analysis code assumes that electrical stimulations occur during each recording. Each electrical stimulation pulse, and its elicited neurological response, is referred to as a sweep. In the provided example data, each recording uses a different stimulation intensity (in mA), and therefore the provided example data is a folder containing a single experiment in which each subfolder is a TDT tank containing a recording in which a different electrical stimulation intensity was used to elicit brain slice activity. 

This analysis pipeline automatically senses the number of recordings within an experiment folder (a base name for the TDT tank needs to be provided), and for each recording, data streams of interest are chopped up according to the number of sweeps, aligned relative to the electrical stimulation artifact for each sweep, and then sweeps are averaged together. For local field potential recordings (LFPs), the provided electrode spacing can be used to calculate the current source density (CSD). Users can then use the GUI to visualize LFPs and CSDs for each electrode channel across stimulation conditions (stimulation intensities) to define windows of interest over which to analyze the data.

## Getting started:

Start the GUI by running TDTAnalysisGUIv3.m .  This will launch the below window (Fig. 1).
 
![Image](https://github.com/user-attachments/assets/02b76e0e-f141-4a99-8035-c3ceb6529e70)
Figure 1. Launched analysis GUI.

## Load Data tab:
The Load Data tab is used to import new data or load previously imported data. A dataset consists of all recordings within the experiment. Default field values have been chosen to work with the provided sample data.

*Defining Parameters*
- **Total Number of Channels:** Define the number of electrode channels in the TDT recording: Default is 16
- **Number of Sweeps:** Define the number of sweeps (electrical stimulations) per recording. This should be the number of full sweeps based on the “Chopped Window Duration” parameter. Partial sweeps (e.g a Chopped Window Duration of 1 second with the recording ending 0.8 seconds after the final electrical stimulation) will result in an error. Default value is 1.
- **Chopped Window Duration [seconds]:** Define the window surrounding the electrical stimulation artifact. The window will be defined so that 5% of the window occurs before the artifact and 95% of the window occurs after the artifact. Default is 1 second.
- **Electrode Spacing [millimeters]:** Define the distance between each adjacent electrode channel in the multielectrode array. This assumes a 1-dimensional array with uniform spacing between electrodes. Default is 0.1 mm
- **Stimulation Intensities:** The name of this field suggests that the values must be stimulation intensities, but in fact these can be used as unique identifiers for each TDT tank within the experiment folder. Numerical values must be used and this should be a comma separated list. The number of unique identifier values should match the number of TDT tank folders within the experiment folder. The Synapse recording software automatically increments the values following the Tank base name. Tanks are identified by this pipeline and ordered based on their incremented value in the Tank name. Therefore, unique identifiers must be entered into the field to match with the ascending Tank incremental values (e.g. An experiment with Tank names “Rec3” and “Rec5” may have “10, 100” entered into the field to represent that Rec3 is associated with the value 10 and Rec5 is associated with the value 100). These values will be used as identifiers in subsequent plots and exported data, and shown as Stimulation Intensities. In the example data which the pipeline was built for, the experiment consists of recordings applying different electrical stimulation intensities, and so unique identifiers will appear as stimulation intensities in mA in the exported data. Default entry is “10, 20, 50, 100, 200, 300, 400, 500, 600”.
- **Base Naming Scheme:** Provide the base name for each TDT Tank folder. The pipeline will search the experiment folder for matching Tank names. Tanks will be imported in ascending numerical order using the incremented value following the Base Name.
- **Detect Outliers checkbox:** Select the Detect Outliers box to automatically detect sweeps with artifacts and broken channels. If sensed, .csv files will be generated that output which sweeps are outliers (based on the stimulation identifier and channel) and output which channel is being excluded and interpolated for CSD calculations.
    - **Artifact detection:** Two methods are used: 1) Sweeps within a recording are mean centered, and then the total absolute signal is summed for each sweep. Outlier detection is performed to determine if any sweep deviates from the distribution of sweeps based on a threshold of 7 standard deviations away from the mean total signal (Fig. 2A). 2) Each sweep is assessed for a progressively changing baseline offset by fitting a line between the pre stimulation sweep region (first 5% of sweep samples) and the end of the sweep (last 5% of sweep samples). The distribution of slopes for all sweeps is assessed for outliers based on a slope more than 7 standard deviations away from the average slope for all sweeps (Fig. 2B). Both metrics are performed for all channels in each recording. Some sweeps are identified as both slope and difference outliers (Fig. 2C)
    - **Broken channels:** These are detected using the total variation of each channel. The standard deviation of signal in each sweep is calculated, and then summed across all sweeps to get the total deviation within a recording, analyzing each channel separately. The total deviation is then averaged over all recordings in an experiment. This average total deviation is then compared across channels to detect outlier/broken channels (Fig. 3). Broken channels will be excluded from CSD calculation, and missing channels will have their LFPs interpolated to calculate the CSD.
  

Figure 2. Example detected outlier sweeps. A) An outlier sweep detected based on total deviation from the average signal of the sweep. Top panel shows the outlier sweep (orange) with artifacts (arrows) overlaid on the average of the remaining sweeps (blue).  The bottom panel shows all of the kept sweeps that we not identified as outliers. B) Two outlier sweeps are detected based on the slope of the data between the start and end of the sweeps. Top panel shows the outlier sweeps (orange and yellow) overlaid on the average of the remaining sweeps (blue). Note that the end of the sweep never returns to baseline (arrow).  The bottom panel shows all of the kept sweeps that we not identified as outliers. C) Two outlier sweeps are detected, one based on the total signal (yellow), and one based on the total signal and the slope (orange). Top panel shows the outlier sweeps (orange and yellow) overlaid on the average of the remaining sweeps (blue). The bottom panel shows all of the kept sweeps that we not identified as outliers. In the top panels, blue is always the average of the kept sweeps whereas other colors correspond to the identified outlier sweep listed in the plot title. Information about the stimulation number (unique value given to each recording), the channel, and which sweeps were identified as outliers are shown in the plot title.



 

Figure 3. Detected broken channel. The total standard deviation across all sweeps within all recordings is plotted as function of channel for one data stream. Broken channels are identified as having much more variability than all other channels (red asterisk).



- **Filter checkbox:** Check the box to filter the data when it is imported. Fields to define the filter cutoffs will appear. If checked and data is filtered during import, checkboxes will appear later in the pipeline to allow visualization or analysis of filtered data.
    - **High Pass Cutoff:** Define the lower end of the filter’s passband
    - **Low Pass Cutoff:** Define the higher end of the filter’s passband
- **Known “Bad” Channels? Checkbox:** Select this box to manually define channels that are known to be broken/bad or need to be removed. Removed channels will be excluded for analysis and the data will instead be interpolated in an attempt to recover the information in the excluded channel.
    - **Bad Channels field:** Enter a comma separated list of the channels to be excluded, no spaces between adjacent entries.


*Importing Data*
- **Select Experiment To Import button:** Use this button to select the TDT data to import. A dialog box will appear. Use this box to select the experiment folder containing TDT recording Tanks. Tanks should follow a naming scheme with a base name followed by a number that the Synapse software automatically increments. Once selected, the first TDT Tank will be scanned to determine the data streams present. These data streams will appear in the list below the “Select Experiment To Import” button.  Note: Import assumes that the Tank folders are named in ascending order where each subsequent folder contains the data from the next unique identifier in the comma separated string entered into the “Stimulation Intensities” box. 
    - **Data Stream check boxes:** Once complete, the data streams in the acquired data will appear as check boxes. Select the check boxes that you wish to import (Fig. 4).


 
Figure 4. View of the GUI once an experiment folder has been chosen. Check boxes with streams of data identified in the first recording, numerically in the TDT tank name, will appear. Selected streams will be imported when “Import Data” is clicked.



- **(Optional) Specify Save Location button:** By default, a folder named “AnalysisGUIResults” is created in the experiment folder. Selecting this button will allow the user to manually define where this folder is created.
- **(Optional) Set Path Where Folders Open button:** By default, dialog boxes open in the MATLAB working folder. Click this button to select where dialog boxes will open by default.
- **Import Data:** Clicking this button initiates reading data directly from the TDT tanks into MATLAB. During importing, data will be loaded into MATLAB from the TDT files, filtered (if selected), used to detect outlier sweeps and broken channels (if selected), and used to calculate the Current Source Density (CSD) from information in adjacent electrode channels using the “Electrode Spacing” value. If changes need to be made to any of these calculations, the data must be re-imported.  The importing process creates a folder within the experiment folder. In this folder will be all data and images generated by this code. The first piece of data will be a .mat file containing all imported data, “ImportedData.mat”, which can be loaded during future analysis sessions instead of importing the data again. If this file already exists, the user will be prompted for if they want to overwrite this file, or save a new imported data file with a date-time suffix specific to when it was created. After importing, the Select Windows tab will become selectable.
- **Load Data:** Load Data will allow the user to analyze data previously imported using this analysis code. A dialog box will pop up and the user should select the ImportedData.mat file generated during a previous session. The Select Windows tab will become selectable.



## Select Windows Tab:

*Overview*

The goal of this tab is to allow users to explore their data to identify interesting trends and manually define regions within the data to analyze. Users can define any number of windows to analyze across all data streams and variables (LFPs or CSDs), and view all windows created for each channel. Window definition requires the user to select a data stream, variable, and channel. To define a window, users must provide a window name, window start time, window end time, peak polarity (for measuring the maximum deflection), and area polarity (for area under the curve measurement). When working in the Select Windows tab, adjusting the data stream, variable, channel, or window extents will cause the plot to automatically update.

*Defining a window*
Use the radio buttons to select a data stream and variable of interest, and use the channel dropdown list to select the channel of the intended analysis window. Input a start and end time for the window, relative to the electrical stimulation artifact. The plot will automatically update based on the window extents. A window start time of zero will include voltage information from the electrical stimulation artifact. Give the window a name and provide analysis information about the polarity of the peak (positive = window maximum, negative = window minimum), and how to calculate the area under the curve (Fig. 5).


 
Figure 5. Parameters has been entered for the analysis window displayed.


Click the Accept Window button to log the window into Matlab memory. Doing so will update the Defined Windows list. Selecting the window from the Defined Windows list will allow you to see where the window was created (Fig. 6). Performed the previous steps again for the next window (Fig. 7). Multiple windows defined for the same channel, data stream, and variable will all appear on the Defined Windows list, and all can be viewed simultaneously by selecting “All” (Fig. 8). Window colors are randomized. None of the windows will be shown if “Select Window” is highlighted. To delete a defined window, highlight it in the Defined Windows dropdown menu and click the “Delete Selected Window” button. Once all analysis windows are defined, click the “Save Window Information” button to create a .mat file in the AnalysisGUIResults folder. If the folder already contains data for defined windows, the user will be prompted to either overwrite the previous windows or save a new window file with a date and time stamp. Saved windows can be imported using the “Load Window Information” button and selecting the appropriate window save file, which allows users to either continue defining analysis windows or move on to the analysis portion.
 

 
Figure 6. A defined window is overlaid on the plot when it is selected in the Defined Windows dropdown menu.


 
Figure 7. The selected Defined Window will not appear if defining a new window outside of the extents of the selected window. Defining a second window will update the Defined Window dropdown list. 


 
Figure 8. All defined windows will appear for the selected stream and channel if “All” is selected from the Defined Windows list.


*Select Windows tab controls*
- **Data Stream Radio buttons:** Choose which imported data stream to work with. Only streams selected for import on the Load Data tab will be available for selection.
- **Variable Radio buttons:** Choose which imported variable to plot. Only imported variables will be visible for selection.
    - **LFPs:** Raw local field potentials.
    - **CSDs:** Calculated current source density.
- **Plot Filtered Checkbox:** Visible if data was filtered upon import. Selecting will plot the filtered data.
- **Override Y Axis Checkbox:** Selecting will allow the user to override the default y-axis limits on the plot. When the box is selected, boxes to define the y-axis minimum and maximum limits will appear.
    - **Min:** Define the minimum extent of the y-axis
    - **Max:** Define the maximum extent of the y-axis
- **Channel Dropdown List:** The list of channels for the selected Variable will appear here. Clicking on a channel will update the plot. 
- **Window Name:** Define the name of the current analysis window.
- **Window Start field:** Define the start of the window for the currently highlighted channel of interest. The entered value is the time after the identified electrical stimulation artifact. The plot will automatically adjust. Note: values are in milliseconds.
- **Window End field:** Define the end of the window for the currently highlighted channel of interest. The entered value is the time after the identified electrical stimulation artifact. The plot will automatically adjust. Note: values are in milliseconds.
- **Peak Value Toggle:** Use this toggle switch to adjust the polarity of the peak value in the analysis window (positive or negative). When analyzing windows, “Positive” will find the maximum voltage (or current source density [V/mm2]) within window, while “Negative” will find the minimum value within the window.
- **Area Calculation Knob:** Define if the area under the curve calculation over the window should only be over the Positive values, Negative values, Total, or Rectified area. “Positive” will calculate only positive area and ignore negative area.  “Negative” will calculate only negative area and ignore positive area. “Total” will calculate the Positive area - Negative area. “Rectified” will calculate Positive area + Negative Area.
- **Accept Window Button:** Clicking this button will log the currently defined window information for the currently highlighted channel and data stream, and update the list of Defined Windows. All defined windows will be analyzed. 
- **Defined Windows Dropdown List:** All currently defined analysis windows for the selected Data Stream, Variable, and Channel will appear here. This list automatically updates to windows defined for the currently selected data stream, variable, and channel. To view the defined window, select it from the dropdown list. This will overlay a box on top of the current plot showing the selected window. To view all defined windows, select “All”. To view the plot with none of the defined Windows, select “Select Window”.
- **Delete Selected Window Button:** Clicking this button will delete the currently highlighted analysis window in the Defined Windows dropdown list.
- **Save Window Information:** Clicking this button will write all analysis window information to a .mat file. This .mat file can be loaded in the future to continue previously initiated analysis or to apply the same window information to a different experiment. 
- **Load Window Information:** Load a previously saved set of analysis windows. Navigate to the appropriate window file in the AnalysisGUIResults folder.

## Analyze Tab:

*Analysis Overview*
Once analysis windows have been defined and saved, the Analyze tab will be selectable (Fig. 9). This tab will be auto-populated with the data streams that were imported and a checkbox will be visible to opt to perform analysis on the filtered data if data was filtered upon import. Users will select all data streams and variables (LFPs and CSDs) that they want analyzed. Currently available analysis metrics include taking the maximum or minimum value within each analysis window (Peak), calculating the area under the curve (Area), finding the maximum first derivative of the data (polarity of the Peak value matters), and finding the maximum second derivative of the data (polarity of the Peak value matters). Clicking the analyze button will apply selected analyses to all selected data and output both a .mat file and a .csv file with the results. 
 
Figure 9. Analyze tab becomes available once a window file has been saved.

*Analyze tab controls*
- **Streams to Analyze:** Select which data streams to analyze. Only data streams with defined windows can be analyzed.
- **Variables:** Select which variables to analyze (LFPs and/or CSDs)
- **Analyses:** Select which analyses to run. This will be expanded in future versions.
    - **Peak:** The maximum deflection of the data is calculated. If a window’s peak polarity is “Positive”, the maximum over the analysis window is calculated. If a window’s peak polarity is “Negative”, the minimum over the analysis window is calculated.
    - **Area:** The area under the curve is calculated. If a window’s area calculation was defined as “Positive”, only positive area (above zero) will be included in the calculation. If a window’s area calculation was defined as “Negative”, only negative area (below zero) will be included in the calculation. If a window’s area calculation was defined as “Total”, the negative area will be subtracted from the positive area. If a window’s area calculation was defined as “Rectified”, the absolute value of the sweeps will be used to calculate the sum of the positive and negative areas.
    - **Maximum First Derivative:** The first temporal derivative of the sweeps is calculated and the maximum value is extracted. By default, the time window (dt in dV/dt) is set to 1 ms. If the peak polarity of the analysis window is defined as positive for a window of interest, then the maximum value of the first derivative is reported. If the peak polarity of the analysis window is defined as negative, then the minimum (greatest negative) value of the first derivative is reported. Therefore, the maximum value of the first derivative on the leading edge of the peak is reported.
    - **Maximum Second Derivative:** The second temporal derivative of the sweeps is calculated and the maximum value is extracted. By default, the time window (dt in dV/dt) is set to 1 ms. If the peak polarity of the analysis window is defined as positive for a window of interest, then the minimum value of the second derivative (most negative) is reported. If the peak polarity of the analysis window is defined as negative, then the maximum value of the second derivative is reported.
- **Analyze Filtered Data:** Visible if data was filtered upon importing. Calculates analyses on the filtered data.
- **Analyze:** Analyses will be calculated for all defined windows. Upon completion, a .mat file and a date-time stamped .csv file will be written into the AnalysisGUIResults folder containing all results. If the code senses that the .mat file already exists, then it will prompt the user to either overwrite the file or create a new on with a date-time stamp.


