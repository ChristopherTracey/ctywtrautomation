# load packages
if (!requireNamespace("openxlsx", quietly=TRUE)) install.packages("openxlsx")
require(openxlsx)
if (!requireNamespace("sf", quietly = TRUE)) install.packages("sf")
require(sf)
if (!requireNamespace("arcgisbinding", quietly = TRUE)) install.packages("arcgisbinding")
require(arcgisbinding)
if (!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr")
require(dplyr)
if (!requireNamespace("tidyr", quietly = TRUE)) install.packages("tidyr")
require(tidyr)
if (!requireNamespace("lubridate", quietly = TRUE)) install.packages("lubridate")
require(lubridate)
if (!requireNamespace("reshape", quietly = TRUE)) install.packages("reshape")
require(reshape)
if (!requireNamespace("plyr", quietly = TRUE)) install.packages("plyr")
require(plyr)
if (!requireNamespace("dplyr", quietly=TRUE)) install.packages("dplyr")
require(dplyr)
if (!requireNamespace("RODBC", quietly=TRUE)) install.packages("RODBC")
require(RODBC)
# if (!requireNamespace("devtools", quietly=TRUE)) install.packages("devtools")
# require(devtools)
# install_github("ChristopherTracey/NatureServeTools")
library("NatureServeTools")

# load python
python_path <- 'C:/ProgramFiles/ArcGIS/Pro/bin/Python/envs/arcgispro-py3'
loadPython(python_path)

#load the arcgis license
arc.check_product()

# update refresh name 
updateName <- "_refresh202303a"

# path to old files 
#sourceCnty <- "S:/Projects/BLD_Standard_Products/County_Watershed_Data/_REFRESH_202203/Data/Source/Script_exports/widget_egt_county_export_202203_v4.txt"
sourceCnty <- "S:/Projects/_Workspaces/Christopher_Tracey/CountyWatershed/ctywtrautomation/_data/input/BLD_CTY_export_202402.dsv"
sourceWater <- "S:/Projects/BLD_Standard_Products/County_Watershed_Data/_REFRESH_202203/Data/Source/Script_exports/widget_egt_watershed_202203_export_v4.txt"

# path to feature classes
counties <- "S:/Data/External/Boundaries_Adminstrative/USGS/countyp010g.gdb/countyp010g"
watersheds <- "S:/Data/External/Hydrography/WatershedBoundaryDataset/WBD_National_GDB.gdb/WBDHU8"
states <- "S:/Data/External/Boundaries_Adminstrative/USGS/statesp010g.gdb/statesp010g"

# Make sure the input and output directories have been created:
ifelse(!dir.exists(here::here("_data")), dir.create(here::here("_data")), FALSE)
ifelse(!dir.exists(here::here("_data","input")), dir.create(here::here("_data","input")), FALSE)
ifelse(!dir.exists(here::here("_data","output")), dir.create(here::here("_data","output")), FALSE)
ifelse(!dir.exists(here::here("_data","output",updateName)), dir.create(here::here("_data","output",updateName)), FALSE)

# rdata file 
updateData <- here::here("_data","output",updateName,paste(updateName, "RData", sep="."))

# output database name
databasename <- here::here("_data","output",updateName,"test.sqlite")

# final fields for arcgis ***Need to double check if these are the correct fields
final_fields <- c("ELEMENT_GLOBAL_ID", "INFORMAL_TAX", "GNAME", "G_COMNAME", "G_RANK", "ROUNDED_G_RANK", "USESA_STATUS", "S_RANK", "S_RANK_ROUNDED", "MAX_OBS_YEAR", "BEST_EO_RANK", "OCC_SRC", "FIPS_CD", "COUNTY_NAME", "STATE_CD", "NSX_LINK")

# north america albers equal area conic projection
albersconic <- "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs" # ***DOUBLE CHECK***

# function to load species list ***Needed next refresh?
