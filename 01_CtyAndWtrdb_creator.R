# Name: 01_CtyAndWtrdb_creator.R
# Purpose: Convert Biotics Exports to SQLite DB
# Authors: Jordana Anderson, Chris Tracey, Cameron Scott
# Created: 2022-11-11
#
#---------------------------------------------------

rm(list=ls()) # clean environments

# Settings from Script 00
if (!requireNamespace("here", quietly=TRUE)) install.packages("here")
require(here)
source(here::here("00_PathsAndSettings_CtyWtr.r"))

# Load tables
tbl_county <- read.table(sourceCnty, header=TRUE, sep="\t", colClasses=c("FIPS_CD"="character"))
tbl_watershed <- read.table(sourceWater, header=TRUE, sep="\t", colClasses=c("HUC8_CD"="character"))

##############################################################################################################
# add in NABA data

## Set up driver info and database path
DRIVERINFO <- "Driver={Microsoft Access Driver (*.mdb, *.accdb)};"
nabaPATH <- "X:/ZOOLOGY/NABA Deliverables (Jan2020)/Crayfish-Fish-MusselsSpeciesHUC_2020Jan05.accdb"
channel <- odbcDriverConnect(paste0(DRIVERINFO, "DBQ=", nabaPATH))
## Load data into R dataframe
nabaTable <- sqlQuery(channel, "SELECT * FROM [Species-HUC];",stringsAsFactors=FALSE)
close(channel) ## Close and remove channel
rm(channel, DRIVERINFO, nabaPATH)

## Connect to central biotics to pull out most recent data on sss
# con <- odbcConnect("bioticscentral.natureserve.org", uid="biotics_report", pwd=rstudioapi::askForPassword("Password"))
# Stop here and copy the "_data/queries/NABA_EGT_attributes.sql" query into Biotics.  Save the output to the input directory in the format of "NABA_EGT_attributes_YYYYMM.csv"

NABAegtid_file <- list.files(path=here::here("_data","input"), pattern=".csv$")  
NABAegtid_file # look at the output,choose which csv you want to load, and enter its location in the list (first = 1, second = 2, etc)
n <- 1
NABAegtid_file <- here::here("_data","input", NABAegtid_file[n])
nabaTableEGT <- read.csv(NABAegtid_file, stringsAsFactors=FALSE, colClasses = "character")  ## TEMPORARY STEP TO GET AROUND BIOTICS. THis has all the columns created
rm("NABAegtid_file", n) # clean up the environment

names(nabaTableEGT)

# replace NA with blanks in certain columns
nabaTableEGT <- nabaTableEGT %>% 
  mutate_at(c("G1G2ORUSESA_IND","G1G2_IND","ANYUSESA_IND","LE_IND","LT_IND","CANDPROP_IND","G1G2WOUSESA_IND"), ~replace_na(.,""))

# NABA_1_ind_1_LE_IND
nabaTableEGT[grep("E", nabaTableEGT$USESA_CD), "LE_IND" ] <- "Y" 
nabaTableEGT[grep("LE", nabaTableEGT$USESA_CD), "LE_IND" ] <- "Y" 

# NABA_1_ind_2_LT_IND
nabaTableEGT[grep("T", nabaTableEGT$USESA_CD), "LT_IND" ] <- "Y" 
nabaTableEGT[grep("LT", nabaTableEGT$USESA_CD), "LT_IND" ] <- "Y"

# NABA_1_ind_3_CandProp_IND
# nabaTableEGT[nabaTableEGT$LT_IND=="Y", "CANDPROP_IND" ] <- "Y"

# UPDATE "nabaTableEGT"
# SET "CANDPROP_IND" = "Y"
# WHERE ((NABA_EGT_attributes_202206.USESA_CD)="C") AND (is.null(NABA_EGT_attributes_202206.LE_IND)) AND (is.null(NABA_EGT_attributes_202206.LT_IND)) OR 
# ((NABA_EGT_attributes_202206.USESA_CD) %Like% "%PE") AND (is.null(NABA_EGT_attributes_202206.LE_IND)) AND (is.null(NABA_EGT_attributes_202206.LT_IND)) OR 
# ((NABA_EGT_attributes_202206.USESA_CD) %Like% "%PT") AND (is.null(NABA_EGT_attributes_202206.LE_IND)) AND (is.null(NABA_EGT_attributes_202206.LT_IND)) OR 
# ((NABA_EGT_attributes_202206.USESA_CD) %Like% "%PSA") AND (is.null(NABA_EGT_attributes_202206.LE_IND)) AND (is.null(NABA_EGT_attributes_202206.LT_IND));

# NABA_1_ind_4_AnyESA_IND
nabaTableEGT[nabaTableEGT$LT_IND=="Y", "ANYUSESA_IND" ] <- "Y"
nabaTableEGT[nabaTableEGT$LE_IND=="Y", "ANYUSESA_IND" ] <- "Y"
nabaTableEGT[grep("C", nabaTableEGT$USESA_CD), "ANYUSESA_IND" ] <- "Y"

# library(sqldf)
# a <- sqldf("select * from nabaTableEGT where USESA_CD = 'C' OR USESA_CD LIKE '%PE%' OR USESA_CD LIKE '%PT%' OR USESA_CD LIKE '%PSA%' ")
# nabaTableEGT[nabaTableEGT$LT_IND!="Y" & nabaTableEGT$LE_IND!="Y" & nabaTableEGT$USESA_CD=="C", "CANDPROP_IND"] <- "Y"
# nabaTableEGT[nabaTableEGT$LT_IND!="Y" & nabaTableEGT$LE_IND!="Y" & grep("PE", nabaTableEGT$USESA_CD), "CANDPROP_IND"] <- "Y"
# nabaTableEGT[nabaTableEGT$LT_IND!="Y" & nabaTableEGT$LE_IND!="Y" & nabaTableEGT$USESA_CD=="C", "CANDPROP_IND"] <- "Y"
# nabaTableEGT$CANDPROP_IND <- NA

# NABA_1_ind_5_G1G2woESA_IND #DO BOTH CONDITIONS NEED TO BE MET?
nabaTableEGT[nabaTableEGT$G1G2_IND=="Y", "G1G2woESA_IND" ] <- "Y"
nabaTableEGT[is.null(nabaTableEGT$ANYUSESA_IND), "G1G2woESA_IND" ] <- "Y"

# NABA_1_ind_6_G1G2orESA_IND
nabaTableEGT[nabaTableEGT$ANYUSESA_IND=="Y", "GIG2ORUSESA_IND" ] <- "Y"
nabaTableEGT[nabaTableEGT$G1G2_IND=="Y", "G1G2ORUSESA_IND" ] <- "Y"

# NABA_1_ind_7_counts
cat("There are",length(which(nabaTableEGT$G1G2_IND=="Y")),"species in the NABA dataset that are G1 or G2\\") 
cat("There are",length(which(nabaTableEGT$LE_IND=="Y")),"species in the NABA dataset that are Endangered\\") 
cat("There are",length(which(nabaTableEGT$LT_IND=="Y")),"species in the NABA dataset that are Threatened\\") 
cat("There are",length(which(nabaTableEGT$CANDPROP_IND=="Y")),"species in the NABA dataset that are Candidate/Proposed\\") 
cat("There are",length(which(nabaTableEGT$ANYUSESA_IND=="Y")),"species in the NABA dataset that have any ESA status\\") 
cat("There are",length(which(nabaTableEGT$G1G2WOUSESA_IND=="Y")),"species in the NABA dataset that are ...\\") 
cat("There are",length(which(nabaTableEGT$G1G2ORUSESA_IND=="Y")),"species in the NABA dataset that are ...\\") 

# Find duplicates in county table
# Jason's SQL for this step: In (SELECT [ELEMENT_GLOBAL_ID] FROM [Widget_NSX_cty_export_201904] As Tmp GROUP BY [ELEMENT_GLOBAL_ID],[STATE_COUNTY_FIPS_CD] HAVING Count(*)>1  And [STATE_COUNTY_FIPS_CD] = [Widget_NSX_cty_export_201904].[STATE_COUNTY_FIPS_CD])
library(sqldf)
select <- "SELECT tbl_county.ELEMENT_GLOBAL_ID"
from <- "FROM tbl_county"
group <- "GROUP BY ELEMENT_GLOBAL_ID, FIPS_CD"
count <- "HAVING COUNT(*) > 1"

query <- paste(select, from, group, count)
sqldf(query)

# Find duplicates in watershed table
# Jason's SQL for this step:  In (SELECT [ELEMENT_GLOBAL_ID] FROM [Widget_NSX_huc_export_201904] As Tmp GROUP BY [ELEMENT_GLOBAL_ID],[WATERSHED_CD_HUC8] HAVING Count(*)>1  And [WATERSHED_CD_HUC8] = [Widget_NSX_huc_export_201904].[WATERSHED_CD_HUC8])
select <- "SELECT tbl_watershed.ELEMENT_GLOBAL_ID"
from <- "FROM tbl_watershed"
group <- "GROUP BY ELEMENT_GLOBAL_ID, HUC8_CD"
count <- "HAVING COUNT(*) > 1"

query <- paste(select, from, group, count)
sqldf(query)

#
nabatable2 <- merge(nabaTable, nabaTableEGT, by.x=c("EGT_ID","G_COMNAME"), by.y=c("ELEMENT_GLOBAL_ID","G_COMNAME"), all.x=TRUE)
#nabatable2a <- nabatable2[c(names(tbl_watershed))]
names(nabaTable)
names(nabaTableEGT)
names(tbl_watershed)

names(nabatable2)[names(nabatable2) == "G_NAME"] <- "GNAME"
names(tbl_watershed)[names(tbl_watershed) == "ELEMENT_GLOBAL_ID"] <- "EGT_ID"

setdiff(names(nabatable2),names(tbl_watershed))
setdiff(names(tbl_watershed),names(nabatable2))

#watershed_table_check <- tbl_watershed[c(names(nabaTableEGT))]

#combined_table <- rbind(tbl_watershed_check, nabaTableEGT)

#########################################
# make a summary table of counts of species by county and watershed
library(dplyr)

tbl_county_sums <- tbl_county  %>%
  group_by(FIPS_CD)  %>%
    dplyr::summarize(
    count_allsp = n(),
    count_G1G2 = length(GNAME[G1G2_IND=='Y']),
    count_ESA = length(GNAME[ANYUSESA_IND=='Y']),
    count_G1G2ESA = length(unique(GNAME[ANYUSESA_IND=='Y'|G1G2_IND=='Y'])),
  )
tbl_county_sums$sym_count_G1G2ESA <- cut(tbl_county_sums$count_G1G2ESA, 
                                         breaks = c(0, .9, 5, 20, 50, 100, max(tbl_county_sums$count_G1G2ESA)), 
                                         labels=c("No Data", "1-5", "6-20", "21-50", "51-100",">100"), include.lowest=TRUE) 

tbl_watershed_sums <- tbl_watershed  %>%
  group_by(HUC8_CD)  %>%
  dplyr::summarize(
    count_allsp = n(),
    count_G1G2 = length(GNAME[G1G2_IND=='Y']),
    count_ESA = length(GNAME[ANYUSESA_IND=='Y']),
    count_G1G2ESA = length(unique(GNAME[ANYUSESA_IND=='Y'|G1G2_IND=='Y'])),
  )
tbl_watershed_sums$sym_count_G1G2ESA <- cut(tbl_watershed_sums$count_G1G2ESA, 
                                            breaks = c(0, .9, 5, 20, 50, 100, max(tbl_watershed_sums$count_G1G2ESA)), 
                                            labels=c("No Data", "1-5", "6-20", "21-50", "51-100",">100"), include.lowest=TRUE)


####################################################################################################################################
# make feature classes

wkpath <- here::here("_data", "output", updateName, paste0(updateName,".gdb"))

arcpy = import("arcpy")
arcpy$env$workspace <- here::here("_data", "output", updateName, paste0(updateName,".gdb"))#"C:/data" # Set the workspace

# counties  # note, need to document the source of the county dataset as USGS, last downloaded data, etc
counties_sf <- arc.open(counties)
counties_sf <- arc.select(counties_sf, fields=c("ADMIN_NAME","ADMIN_FIPS","STATE","STATE_FIPS","NAME","SQ_MILES","SUFFIX"), where_clause="STATE NOT IN ('VI', 'PR') AND POP<>-999")
counties_sf <- arc.data2sf(counties_sf)
setdiff(tbl_county_sums$FIPS_CD, counties_sf$ADMIN_FIPS)
setdiff(counties_sf$ADMIN_FIPS, tbl_county_sums$FIPS_CD)
counties_sf <- merge(counties_sf, tbl_county_sums, by.x="ADMIN_FIPS", by.y="FIPS_CD", all.x=TRUE)
counties_sf <- counties_sf[c("ADMIN_FIPS","ADMIN_NAME","NAME","STATE","STATE_FIPS","SQ_MILES","count_allsp","count_G1G2","count_ESA","count_G1G2ESA","sym_count_G1G2ESA","geometry")]
arc.delete(here::here("_data", "output", updateName, paste0(updateName,".gdb"), "counties_AllSpTot"))
arc.write(here::here("_data", "output", updateName, paste0(updateName,".gdb"), "counties_AllSpTot"), counties_sf, validate=TRUE, overwrite=TRUE)

# county related table of species
arc.write(here::here("_data", "output", updateName, paste0(updateName,".gdb"), "tbl_county"), tbl_county, overwrite=TRUE)

# need to build a relationship class in ArcPy
intable <- file.path(wkpath, "counties_AllSpTot")
jointable <- file.path(wkpath, "tbl_county")
rclass <- file.path(wkpath, "counties_AllSpTot_tbl_county")

# Create a relationship class
arcpy$CreateRelationshipClass_management(
  intable,
  jointable,
  rclass,
  "SIMPLE",
  "tbl_water",
  "watersheds_AllSpTot",
  "NONE",
  "ONE_TO_MANY",
  "NONE",
  "ADMIN_FIPS",
  "FIPS_CD"
)

# set the aliases to the watershed field names
arcpy$management$AlterField(in_table=intable, field="NAME", new_field_alias="County Name")
arcpy$management$AlterField(in_table=intable, field="STATE", new_field_alias="State")
arcpy$management$AlterField(in_table=intable, field="SQ_MILES", new_field_alias="Area (sqmi)")
arcpy$management$AlterField(in_table=intable, field="count_allsp", new_field_alias="Count - All Species")
arcpy$management$AlterField(in_table=intable, field="count_G1G2", new_field_alias="Count - G1/G2 Species")
arcpy$management$AlterField(in_table=intable, field="count_ESA", new_field_alias="Count - ESA Species")
arcpy$management$AlterField(in_table=intable, field="count_G1G2ESA", new_field_alias="Count - G1/G2 & ESA Species")

arcpy$management$AlterField(in_table=jointable, field="GNAME", new_field_alias="Scientific Name")
arcpy$management$AlterField(in_table=jointable, field="G_COMNAME", new_field_alias="Common Name")
arcpy$management$AlterField(in_table=jointable, field="G_RANK", new_field_alias="G-Rank")
arcpy$management$AlterField(in_table=jointable, field="ROUNDED_G_RANK", new_field_alias="Rounded G-Rank")
arcpy$management$AlterField(in_table=jointable, field="MAX_OBS_YEAR", new_field_alias="Most Recent Obs Year")
arcpy$management$AlterField(in_table=jointable, field="FIPS_CD", new_field_alias="FIPS Code")
arcpy$management$AlterField(in_table=jointable, field="COUNTY_NAME", new_field_alias="County Name")
arcpy$management$AlterField(in_table=jointable, field="NSX_LINK", new_field_alias="NS Explorer")

########################################
# watersheds # note, need to document the source of the county dataset as USGS, last downloaded data, etc
watersheds_sf <- arc.open(watersheds)
watersheds_sf <- arc.select(watersheds_sf, fields=c("loaddate","name","huc8","states","areasqkm"))
watersheds_sf <- arc.data2sf(watersheds_sf)
watersheds_sf <- merge(watersheds_sf, tbl_watershed_sums, by.x="huc8", by.y="HUC8_CD", all.x=TRUE)
watersheds_sf <- watersheds_sf[c("huc8","name","states","areasqkm","count_allsp","count_G1G2","count_ESA","count_G1G2ESA","sym_count_G1G2ESA","geometry")]
arc.delete(here::here("_data", "output", updateName, paste0(updateName,".gdb"), "watersheds_AllSpTot"))
arc.write(here::here("_data", "output", updateName, paste0(updateName,".gdb"), "watersheds_AllSpTot"), watersheds_sf, validate=TRUE, overwrite=TRUE)

# watershed related table of species
arc.write(here::here("_data", "output", updateName, paste0(updateName,".gdb"), "tbl_water"), tbl_watershed, overwrite=TRUE)

# need to build a relationship class in ArcPy
intable <- file.path(wkpath, "watersheds_AllSpTot")
jointable <- file.path(wkpath, "tbl_water")
rclass <- file.path(wkpath, "watersheds_AllSpTot_tbl_water")

# Create a relationship class
arcpy$CreateRelationshipClass_management(
  intable,
  jointable,
  rclass,
  "SIMPLE",
  "tbl_water",
  "watersheds_AllSpTot",
  "NONE",
  "ONE_TO_MANY",
  "NONE",
  "huc8",
  "HUC8_CD"
)

# set the aliases to the watershed field names
arcpy$management$AlterField(in_table=intable, field="name", new_field_alias="Watershed Name")
arcpy$management$AlterField(in_table=intable, field="states", new_field_alias="States")
arcpy$management$AlterField(in_table=intable, field="areasqkm", new_field_alias="Area (sqkm)")
arcpy$management$AlterField(in_table=intable, field="count_allsp", new_field_alias="Count - All Species")
arcpy$management$AlterField(in_table=intable, field="count_G1G2", new_field_alias="Count - G1/G2 Species")
arcpy$management$AlterField(in_table=intable, field="count_ESA", new_field_alias="Count - ESA Species")
arcpy$management$AlterField(in_table=intable, field="count_G1G2ESA", new_field_alias="Count - G1/G2 & ESA Species")

arcpy$management$AlterField(in_table=jointable, field="GNAME", new_field_alias="Scientific Name")
arcpy$management$AlterField(in_table=jointable, field="G_COMNAME", new_field_alias="Common Name")
arcpy$management$AlterField(in_table=jointable, field="G_RANK", new_field_alias="G-Rank")
arcpy$management$AlterField(in_table=jointable, field="ROUNDED_G_RANK", new_field_alias="Rounded G-Rank")
arcpy$management$AlterField(in_table=jointable, field="MAX_OBS_YEAR", new_field_alias="Most Recent Obs Year")
arcpy$management$AlterField(in_table=jointable, field="HUC8_CD", new_field_alias="HUC08")
arcpy$management$AlterField(in_table=jointable, field="HUC8_NAME", new_field_alias="Watershed Name")
arcpy$management$AlterField(in_table=jointable, field="NSX_LINK", new_field_alias="NS Explorer")

# clean up
rm(intable, jointable, rclass)

####################################################
# Create Derivative Products (e.g. ESA map for storymap)

# ESA storymap layer
tbl_county_sums_ESA <- tbl_county  %>%
  group_by(FIPS_CD)  %>%
  dplyr::summarize(
    count_Endangered = length(GNAME[LE_IND=='Y']),
    count_Threatened = length(GNAME[LT_IND=='Y']),
    count_TandE = length(GNAME[LE_IND=='Y']) + length(GNAME[LT_IND=='Y']),
  )
tbl_county_sums_ESA$sym_count_ESA <- cut(tbl_county_sums_ESA$count_TandE, 
                                         breaks = c(0, .9, 2, 5, 10, 15, max(tbl_county_sums_ESA$count_TandE)), 
                                         labels=c("0", "1-2", "3-5", "6-10", "11-15",paste0("16-",max(tbl_county_sums_ESA$count_TandE))), include.lowest=TRUE) 

counties_sf <- arc.open(counties)
counties_sf <- arc.select(counties_sf, fields=c("ADMIN_NAME","ADMIN_FIPS","STATE","STATE_FIPS","NAME","SQ_MILES","SUFFIX"), where_clause="STATE NOT IN ('VI', 'PR') AND POP<>-999")
counties_sf <- arc.data2sf(counties_sf)
setdiff(tbl_county_sums_ESA$FIPS_CD, counties_sf$ADMIN_FIPS)
setdiff(counties_sf$ADMIN_FIPS, tbl_county_sums_ESA$FIPS_CD)
counties_ESA_sf <- merge(counties_sf, tbl_county_sums_ESA, by.x="ADMIN_FIPS", by.y="FIPS_CD", all.x=TRUE)
counties_ESA_sf <- counties_ESA_sf[c("ADMIN_FIPS","ADMIN_NAME","NAME","STATE","STATE_FIPS","SQ_MILES","count_Endangered","count_Threatened","count_TandE","sym_count_ESA","geometry")]

counties_ESA_sf[c("count_Endangered", "count_Threatened", "count_TandE", "sym_count_ESA")][is.na(counties_ESA_sf[c("count_Endangered", "count_Threatened", "count_TandE", "sym_count_ESA")])] <- 0

arc.delete(here::here("_data", "output", updateName, paste0(updateName,".gdb"), "counties_ESA"))
arc.write(here::here("_data", "output", updateName, paste0(updateName,".gdb"), "counties_ESA"), counties_ESA_sf, validate=TRUE, overwrite=TRUE)

ESAtable <- file.path(wkpath, "counties_ESA")
# set the aliases to the watershed field names
arcpy$management$AlterField(in_table=ESAtable, field="NAME", new_field_alias="County Name")
arcpy$management$AlterField(in_table=ESAtable, field="STATE", new_field_alias="State")
arcpy$management$AlterField(in_table=ESAtable, field="SQ_MILES", new_field_alias="Area (sqmi)")
arcpy$management$AlterField(in_table=ESAtable, field="count_Endangered", new_field_alias="Count - ESA Endangered")
arcpy$management$AlterField(in_table=ESAtable, field="count_Threatened", new_field_alias="Count - ESA Threatened")
arcpy$management$AlterField(in_table=ESAtable, field="count_TandE", new_field_alias="Count - ESA Endangered or Threatened")


# Botanical Subset at the State level for Wes - ESA species
tbl_state_sums_BSA <- tbl_county  %>%
  filter(MAJOR_SUBGROUP2=='Flowering Plants' | MAJOR_SUBGROUP2=='Conifers and relatives') %>%
  group_by(STATE_CD)  %>% # 
  dplyr::summarize(
    count_Endangered = n_distinct(GNAME[LE_IND=='Y']),
    count_Threatened = n_distinct(GNAME[LT_IND=='Y']),
    count_TandE = count_Endangered + count_Threatened
  )
tbl_state_sums_BSA$sym_count_ESA <- cut(tbl_state_sums_BSA$count_TandE, 
                                         breaks = c(0, .9, 2, 5, 10, 15, max(tbl_state_sums_BSA$count_TandE)), 
                                         labels=c("0", "1-2", "3-5", "6-10", "11-15",paste0("16-",max(tbl_state_sums_BSA$count_TandE))), include.lowest=TRUE) 

states_sf <- arc.open(states)
states_sf <- arc.select(states_sf, fields=c("STATE_ABBR","STATE_FIPS","TYPE","NAME","SQ_MILES"), where_clause="STATE_ABBR NOT IN ('VI', 'PR') AND POP<>-999 AND TYPE<>'Water'" )
states_sf <- arc.data2sf(states_sf)
setdiff(tbl_state_sums_BSA$STATE_CD, states_sf$STATE_ABBR)
setdiff(states_sf$STATE_ABBR, tbl_state_sums_BSA$STATE_CD)
states_BSA_sf <- merge(states_sf, tbl_state_sums_BSA, by.x="STATE_ABBR", by.y="STATE_CD", all.x=TRUE)
states_BSA_sf <- states_BSA_sf[c("STATE_ABBR","NAME","STATE_FIPS","SQ_MILES","count_Endangered","count_Threatened","count_TandE","sym_count_ESA","geometry")]

states_BSA_sf[c("count_Endangered", "count_Threatened", "count_TandE", "sym_count_ESA")][is.na(states_BSA_sf[c("count_Endangered", "count_Threatened", "count_TandE", "sym_count_ESA")])] <- 0

arc.delete(here::here("_data", "output", updateName, paste0(updateName,".gdb"), "states_BSA"))
arc.write(here::here("_data", "output", updateName, paste0(updateName,".gdb"), "states_BSA"), states_BSA_sf, validate=TRUE, overwrite=TRUE)

BSAtable <- file.path(wkpath, "states_ESA")
# set the aliases to the watershed field names
arcpy$management$AlterField(in_table=BSAtable, field="NAME", new_field_alias="State Name")
arcpy$management$AlterField(in_table=BSAtable, field="STATE_ABBR", new_field_alias="State Abbreviation")
arcpy$management$AlterField(in_table=BSAtable, field="SQ_MILES", new_field_alias="Area (sqmi)")
arcpy$management$AlterField(in_table=BSAtable, field="count_G1G#", new_field_alias="Count - G1G3")

###############################################################
# Botanical Subset at the State level for Wes - G1G3 species
tbl_state_sums_BSAG1G3 <- tbl_county  %>%
  filter(MAJOR_SUBGROUP2=='Flowering Plants' | MAJOR_SUBGROUP2=='Conifers and relatives') %>%
  group_by(STATE_CD)  %>% # 
  dplyr::summarize(
    count_G1G3 = n_distinct(GNAME[ROUNDED_G_RANK %in% c("G1","G2","G3")])
  )

tbl_state_sums_BSAG1G3$sym_count_G1G3 <- cut(tbl_state_sums_BSAG1G3$count_G1G3, 
                                        breaks = c(0, .9, 2, 5, 10, 15, max(tbl_state_sums_BSAG1G3$count_G1G3)), 
                                        labels=c("0", "1-2", "3-5", "6-10", "11-15",paste0("16-",max(tbl_state_sums_BSAG1G3$count_G1G3))), include.lowest=TRUE) 

states_sf <- arc.open(states)
states_sf <- arc.select(states_sf, fields=c("STATE_ABBR","STATE_FIPS","NAME","SQ_MILES"), where_clause="STATE_ABBR NOT IN ('VI', 'PR') AND POP<>-999 AND TYPE<>'Water'")
states_sf <- arc.data2sf(states_sf)
setdiff(tbl_state_sums_BSAG1G3$STATE_CD, states_sf$STATE_ABBR)
setdiff(states_sf$STATE_ABBR, tbl_state_sums_BSAG1G3$STATE_CD)
states_BSAG1G3_sf <- merge(states_sf, tbl_state_sums_BSAG1G3, by.x="STATE_ABBR", by.y="STATE_CD", all.x=TRUE)
states_BSAG1G3_sf <- states_BSAG1G3_sf[c("STATE_ABBR","NAME","STATE_FIPS","SQ_MILES","count_G1G3","sym_count_G1G3","geometry")]

states_BSAG1G3_sf[c("count_G1G3", "sym_count_G1G3")][is.na(states_BSAG1G3_sf[c("count_G1G3", "sym_count_G1G3")])] <- 0

arc.delete(here::here("_data", "output", updateName, paste0(updateName,".gdb"), "states_BSAG1G3"))
arc.write(here::here("_data", "output", updateName, paste0(updateName,".gdb"), "states_BSAG1G3"), states_BSAG1G3_sf, validate=TRUE, overwrite=TRUE)

BSAG1G3table <- file.path(wkpath, "states_BSAG1G3")
# set the aliases to the watershed field names
arcpy$management$AlterField(in_table=BSAG1G3table, field="NAME", new_field_alias="State Name")
arcpy$management$AlterField(in_table=BSAG1G3table, field="STATE_ABBR", new_field_alias="State Abbreviation")
arcpy$management$AlterField(in_table=BSAG1G3table, field="SQ_MILES", new_field_alias="Area (sqmi)")
arcpy$management$AlterField(in_table=BSAG1G3table, field="count_G1G3", new_field_alias="Count - G1G3")

###############################################################
# Botanical Subset at the Region level for Wes - G1G3 species
regions <- data.frame(state=c("AK","AL","AR","AZ","CA","CO","CT","FL","GA","HI","IA","ID","IL","IN","KS","KY","LA","MA","MD","ME","MI","MN","MO","MS","MT","NC","ND","NE","NH","NJ","NM","NV","NY","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VA","VT","WA","WI","WV","WY"),region=c("","Southeast","Southeast","Southwest","Pacific Southwest","Mountain Prairie","Northeast","Southeast","Southeast","","Midwest","Pacific","Midwest","Midwest","Mountain Prairie","Southeast","Southeast","Northeast","Northeast","Northeast","Midwest","Midwest","Midwest","Southeast","Mountain Prairie","Southeast","Mountain Prairie","Mountain Prairie","Northeast","Northeast","Southwest","Pacific Southwest","Northeast","Midwest","Southwest","Pacific","Northeast","Northeast","Southeast","Mountain Prairie","Southeast","Southwest","Mountain Prairie","Northeast","Northeast","Pacific","Midwest","Northeast","Mountain Prairie")) #,"Northeast","Northeast","Pacific","Midwest","Northeast","Mountain Prairie"

tbl_county1 <- merge(tbl_county, regions, by.x="STATE_CD", by.y="state")

tbl_state_sums_BSARegion <- tbl_county1  %>%
  filter(MAJOR_SUBGROUP2=='Flowering Plants' | MAJOR_SUBGROUP2=='Conifers and relatives') %>%
  group_by(region)  %>% # 
  dplyr::summarize(
    count_G1G3 = n_distinct(GNAME[ROUNDED_G_RANK %in% c("G1","G2","G3")])
  )

tbl_state_sums_BSARegion$sym_count_G1G3 <- cut(tbl_state_sums_BSARegion$count_G1G3, 
                                             breaks = c(0, 50, 100, 200, 500, 750, max(tbl_state_sums_BSARegion$count_G1G3)), 
                                             labels=c("1-50", "51-100", "101-200", "201-500", "501-750",paste0("750-",max(tbl_state_sums_BSARegion$count_G1G3))), include.lowest=TRUE) 

states_sf <- arc.open(states)
states_sf <- arc.select(states_sf, fields=c("STATE_ABBR","STATE_FIPS","NAME","SQ_MILES"), where_clause="STATE_ABBR NOT IN ('VI', 'PR') AND POP<>-999 AND TYPE<>'Water'")
states_sf <- arc.data2sf(states_sf)
states_sf <- merge(states_sf, regions, by.x="STATE_ABBR", by.y="state")
states_sf <- st_make_valid(states_sf)
region_sf <- states_sf %>% group_by(region) %>% dplyr::summarize() 


setdiff(tbl_state_sums_BSARegion$region, region_sf$region)
setdiff(region_sf$region, tbl_state_sums_BSARegion$region)
region_BSAG1G3_sf <- merge(region_sf, tbl_state_sums_BSARegion, by.x="region", by.y="region", all.x=TRUE)
region_BSAG1G3_sf <- region_BSAG1G3_sf[c("region","count_G1G3","sym_count_G1G3","geometry")]

region_BSAG1G3_sf[c("count_G1G3", "sym_count_G1G3")][is.na(region_BSAG1G3_sf[c("count_G1G3", "sym_count_G1G3")])] <- 0

arc.delete(here::here("_data", "output", updateName, paste0(updateName,".gdb"), "region_BSAG1G3"))
arc.write(here::here("_data", "output", updateName, paste0(updateName,".gdb"), "region_BSAG1G3b"), region_BSAG1G3_sf, validate=TRUE, overwrite=TRUE)

BSAG1G3table <- file.path(wkpath, "region_BSAG1G3b")
# set the aliases to the watershed field names
arcpy$management$AlterField(in_table=BSAG1G3table, field="region", new_field_alias="Region")
arcpy$management$AlterField(in_table=BSAG1G3table, field="count_G1G3", new_field_alias="Count - G1G3")


######################################
# create metadata


#########################################
# create preview graphics


########################################
# create information for marketplace page

