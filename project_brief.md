# Project Documentation

### Project Description and Scope

I will be using telecoms data to analyse and visualise how crowd size changes over time in specific locations. This can be in the form of a time series or 
showing the most recent data. The work should display different demographics within each area and compare them over time. I can create a simple dashboard 
that updates in time with how the data is created and let users choose which demographics they want to see displayed.

### Learning Aim

The aim is to use Spark in R Studio, explore more Spark transformations, and link this learning to how analysis is primarily performed in my organisation 
(that being done in R).

### Project Data

The telecoms dataset shows the number of people per specific demographic combinations (age, gender, and purpose). This data is at the 'Middle layer super
output' level, which contains roughly 7000 shapes that cover the UK. The data is split by 5 minute intervals for each area, and the dataset is 234.53GB
of logical bytes (uncompressed data). The data contains valuable information on how different demographics travel depending on certain events. The velocity 
at which the data is created and the value it brings to the organisation can class it as Big Data.

### Business Questions

I can use this data to uncover patterns in travel of different demographic groups, or how specific large-scale events impact travel. In this case, I will
be looking at how train strikes affect travel for different demographics. Another aspect this data can give insight to is women's safety during large events.
I can see how crowd sizes change between men and women around these times and spot particular areas that see a significant decrease in women travelling.

### Resources - Cloud / On Premise / Costing

Reflect on the resources you have used, and what costs you might incur if your solution were to be scaled up.  You may make use of online costing tools 
for Azure or other platforms.  How does running your solution in the cloud compare to having dedicated on-premise equipment dedicated to this processing?  
This is really a focus on ROI (Return on Investment).  What return will be derived given the investment made (fixed cost and marginal cost).

I have used my local computer, but there is scope for analysing the entire dataset the way I have that would incure greater costs. Due to security issues,
only a certain size workstation is able to connect to and download from the internet, making running code like this on the cloud the most feasible option
if reading in the dataset into R in its entirety. However, there has been interest within the organisation for insights like the ones explored, so it may 
be worth incurring the costs to get these insights at a larger scale. 

### Reflection

Overall, the project worked well when using smaller datasets. This is mainly due to the version of Spark available through work is not compatible with the
`sparkbq` extension that would have allowed me to read in data directly instead of going through R itself. I had decided to use R since it's the most
common coding language in my organisation, but perhaps a more direct link from the data source and Spark would be more beneficial to analysing truly 
large datasets. I had aimed for a B grade by extending my learning to using Spark in a new coding language, even though the application wasn't able to be 
tested on an true big dataset. 
