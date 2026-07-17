######################################
## Script 02. Compile CHI list #######
######################################

##We no longer have access to the UPIP database, so CHI numbers cannot be
##resolved to their most recent version (the UPI) in-house. Instead, we have
##agreed with the CHI team that we will send them a list of all CHI numbers
##appearing in our data sources, and they will return the same list with a
##"upi" column added containing the UPI for each CHI.

##This script:
## 1. loads each cleaned source extract,
## 2. extracts all deaths since 2014 from NRS (saved for reuse in "03.Link sources.r"),
## 3. compiles a single de-duplicated list of CHI numbers across all sources,
## 4. saves the list as a csv to send to the CHI team.

##When the CHI team return the completed lookup, save it (columns: chi, upi)
##at chi_upi_lookup_path (see "00.setup.r") and then run "03.Link sources.r".

## run the setup file first#
source("00.setup.r")

##load cleaned sources####
smr_all <- readRDS("/PHI_conf/Dementia_Index/data/cleaned_extracts/smr_first_icd10.rds") %>% ungroup()
PDS <- readRDS("/PHI_conf/Dementia_Index/data/cleaned_extracts/PDS_clean.rds") %>% ungroup()
dementia_deaths <- readRDS("/PHI_conf/Dementia_Index/data/extracts/dementia_deaths.rds") %>% ungroup()
CHC <- readRDS("/PHI_conf/Dementia_Index/data/cleaned_extracts/CHC_clean.rds") %>% ungroup()
social_care <- readRDS("/PHI_conf/Dementia_Index/data/cleaned_extracts/SC_clean.rds") %>% ungroup()
PIS <- readRDS("/PHI_conf/Dementia_Index/data/cleaned_extracts/pis_clean.rds") %>% ungroup()

##extract all nrs deaths####
##all deaths since 2014, used in "03.Link sources.r" to add date of death.
##extracted here so their CHIs can be included in the list for the CHI team.
death_start_date <- as.Date("2014-01-01")
all_deaths <- as_tibble(
  dbGetQuery(
    SMRAConnection, paste0(
      "SELECT UPI_NUMBER,CHI, DATE_OF_BIRTH, DATE_OF_DEATH,
     YEAR_OF_REGISTRATION , REGISTRATION_DISTRICT, ENTRY_NUMBER ,
     SEX, POSTCODE,HEALTH_BOARD_AREA
    FROM ANALYSIS.GRO_DEATHS_C SMR
    WHERE DATE_OF_DEATH >= TO_DATE('", death_start_date, "', 'yyyy-mm-dd')
    ")
  )) %>% clean_names()

###use chi if upi unavlaible, remove those with missing chi and upi
all_deaths <- all_deaths %>%
  mutate(deaths_upi = case_when(is.na(upi_number)~ chi , T~upi_number)) %>%
  select(-chi, -upi_number) %>%
  filter(!is.na(deaths_upi))

saveRDS(all_deaths, "/PHI_conf/Dementia_Index/data/extracts/all_deaths.rds")

##compile the chi list####
chi_list <- tibble(
  chi = c(smr_all$upi_number,
          PDS$pds_chi_number,
          dementia_deaths$upi_number,
          CHC$CHC_UPI_NUMBER,
          social_care$upi_number,
          PIS$pis_pat_upi_c,
          all_deaths$deaths_upi)) %>%
  filter(!is.na(chi) & chi != "") %>%
  distinct()

##check validity - invalid CHIs will not get a UPI back from the CHI team
##and are left unchanged in "03.Link sources.r"
table(phsmethods::chi_check(chi_list$chi))

##save the list to send to the CHI team####
write_csv(chi_list, paste0(folder_data_path, "/lookups/chi_list_for_chi_team_",
                           Sys.Date(), ".csv"))
