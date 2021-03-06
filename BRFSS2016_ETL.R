#### ETL SCRIPT BRFSS 2016 DATA ####
## R script that reads in BRFSS 2016 data, recodes values, and selects specific columns
## Fall 2017
## Civis Analytics
## R version 3.4.2

## ----------------------------< Prepare Workspace >------------------------------------
wd <- "~/Desktop/CDPH_breastcancer" # replace this with your own directory
setwd(wd)

## required packages
packages = c("readr",  # version 1.1.1
             "Hmisc",  # version 4.0-3
             "dplyr"   # version 0.7.4
)

## function that loads required packages; if not installed, then installs package first
loadPackage <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg)) 
    install.packages(new.pkg, dependencies = TRUE)
  sapply(pkg, require, character.only = TRUE)
}

## loop through necessary packages and install/load
for(package in packages){
  loadPackage(package)
}

## set environment options
options(scipen = 999)


## ----------------------------< Read in BRFSS 2016 Data >-------------------------------------
## download the BRFSS 2016 data in XPT format from https://www.cdc.gov/brfss/annual_data/annual_2016.html 
## save it in your working directory

## open up the Finder on a Mac, or Windows Explorer on a Windows machine and select the BRFSS 2016 data
a <- file.choose()
## run the code below to load the XPT file into your R environment
BRFSS_2016 <- sasxport.get(a)

#### OPTIONAL: write the data as a CSV file to read in easily later on
#write_csv(BRFSS_2016, "BRFSS_2016.csv", row.names = FALSE)


## -----------------------------< ETL data >---------------------------------

#### OPTIONAL: read in CSV file if wrote as CSV 
#BRFSS_2016 <- read_csv("BRFSS_2016.csv", col_types = cols(.default = col_double(), dlyother = col_character())) 

vars <- colnames(BRFSS_2016)

set.seed(123)
row_ids <- sample(seq(100000, 999999, by = 1), nrow(BRFSS_2016), replace = FALSE)  # create ID for each row/observation

BRFSS_2016_clean <- BRFSS_2016 %>%
  mutate(id = row_ids,
         state = x.state,
         breastcncr_nulls = ifelse(cncrtyp1 == 1, 1, 0),      # binary var indicating whether most recent cancer diagnosis was breast cancer; include NAs for empty/unknown
         breastcncr_nonulls = case_when(                      # binary var indicating whether most recent cancer diagnosis was breast cancer; change NAs for empty/unknown to 0
           cncrtyp1 == 1 ~ 1,
           TRUE ~ 0
         ),
         pvtresd = case_when(                                 # 1 = yes private residence, 0 = no private residence
           pvtresd1 == 1 | pvtresd3 == 1 ~ 1,
           pvtresd1 == 2 | pvtresd3 == 2 ~ 0,
           TRUE ~ as.numeric(NA)
         ),
         colg_hous = case_when(                              # 1 = yes college housing
           colghous == 1 | cclghous == 1 ~ 1,
           TRUE ~ as.numeric(NA)
         ),
         state_res = case_when(                              # 1 = yes state residence, 0 = no state residence
           stateres == 1 | cstate1 == 1 ~ 1,
           cstate1 == 2 ~ 0,
           TRUE ~ as.numeric(NA)
         ),
         adult_m = case_when(                                # 1 = yes adult male, 0 = not adult male
           ladult == 1 | cadult == 1 ~ 1,
           ladult == 2 | cadult == 2 ~ 0,
           TRUE ~ as.numeric(NA)
         ),
         adult_f = case_when(                                # 1 = yes adult female, 0 = not adult female
           ladult == 2 | cadult == 2 ~ 1,
           ladult == 1 | cadult == 1 ~ 0,
           TRUE ~ as.numeric(NA)
         ),
         num_adult = case_when(                              # num adults in house
           numadult <= 99 ~ numadult,
           hhadult < 77 ~ hhadult,
           hhadult >= 77 ~ as.numeric(NA),
           TRUE ~ as.numeric(NA)
         ),   
         num_men = nummen,
         num_women = numwomen,
         gen_hlth = ifelse(genhlth >= 7, NA, genhlth),               # general health status?; 1-5; 1 = Excellent, 5 = Poor
         phys_hlth = ifelse(physhlth == 88, 0,                       # Number of Days Physical Health Not Good (num days in past 30 days)
                            ifelse(physhlth >= 77, NA, physhlth)),
         ment_hlth = ifelse(menthlth == 88, 0,                       # Number of Days Mental Health Not Good (num days in past 30 days)
                            ifelse(menthlth >= 77, NA, menthlth)),
         poor_hlth = ifelse(poorhlth == 88, 0,                       # Inhibiting Poor Physical or Mental Health (num days in past 30 days)
                            ifelse(poorhlth >= 77, NA, poorhlth)),
         hlth_pln = ifelse(hlthpln1 == 1, 1,                         # have any health care coverage; 1 = yes, 0 = no
                           ifelse(hlthpln1 == 2, 0, NA)),
         persdoc = ifelse(persdoc2 == 3, 0,                          # have person you consider personal doc; 1 = yes, 0 = no, 2 = multiple
                          ifelse(persdoc2 > 3, NA, persdoc2)),
         doc_toocostly = ifelse(medcost == 2, 0,                     # time in past yr couldn't see doc bc cost; 1 = yes, 0 = no
                                ifelse(medcost > 2, NA, medcost)),
         checkup = ifelse(checkup1 > 4, NA, checkup1),               # time since last checkup; 1 = w/in yr, 2 = w/in 2 yrs, 3 = w/in 5 yrs, 4 = 5+ yrs
         exercise = ifelse(exerany2 == 2, 0,                         # exercise in past month; 1 = yes, 0 = no
                           ifelse(exerany2 > 2, NA, exerany2)),
         sleephrs = ifelse(sleptim1 > 24, NA, sleptim1),             # num hours of sleep on average
         heartattack = ifelse(cvdinfr4 == 2, 0,                      # heart attack?; 1 = yes, 0 = no
                              ifelse(cvdinfr4 > 2, NA, cvdinfr4)),
         coronaryheartdisease = ifelse(cvdcrhd4 == 2, 0,                   # coronary heart disease?; 1 = yes, 0 = no
                                       ifelse(cvdcrhd4 > 2, NA, cvdcrhd4)),
         stroke = ifelse(cvdstrk3 == 2, 0,                                 # stroke?; 1 = yes, 0 = no
                         ifelse(cvdstrk3 > 2, NA, cvdstrk3)),
         asthma = ifelse(asthma3 == 2, 0,                                  # asthma?; 1 = yes, 0 = no
                         ifelse(asthma3 > 2, NA, asthma3)),
         asthma_now = ifelse(asthnow == 2, 0,                              # asthma now?; 1 = yes, 0 = no
                             ifelse(asthnow > 2, NA, asthnow)),
         skin_cancer = ifelse(chcscncr == 2, 0,                            # skin cancer?; 1 = yes, 0 = no
                              ifelse(chcscncr > 2, NA, chcscncr)),
         cancer = ifelse(chcocncr == 2, 0,                                 # cancer other than skin?; 1 = yes, 0 = no
                         ifelse(chcocncr > 2, NA, chcocncr)),
         copd = ifelse(chccopd1 == 2, 0,                                   # chronic bronchitis?; 1 = yes, 0 = no
                       ifelse(chccopd1 > 2, NA, chccopd1)),
         arthritis = ifelse(havarth3 == 2, 0,                              # arthritis?; 1 = yes, 0 = no
                            ifelse(havarth3 > 2, NA, havarth3)),
         depression = ifelse(addepev2 == 2, 0,                             # depression?; 1 = yes, 0 = no
                             ifelse(addepev2 > 2, NA, addepev2)),
         kidneydisease = ifelse(chckidny == 2, 0,                          # kidney disease?; 1 = yes, 0 = no
                                ifelse(chckidny > 2, NA, chckidny)),
         diabetes = ifelse(diabete3 >= 3, 0,                               # diabetic?; 1 = yes, 0 = no
                           ifelse(diabete3 == 1, 1, NA)),
         borderline_diab = ifelse(diabete3 == 4 | prediab1 == 1, 1, 0),    # borderline diabetic?; 1 = yes, 0 = no
         preg_diab = ifelse(diabete3 == 2, 1, 0),                          # diabetes only when pregnant; 1 = yes, 0 = no
         age_diabetes = ifelse(diabage2 >= 98, NA, diabage2),              # age when diagnosed with diabetes; 97 = 97+ yrs
         female = ifelse(sex == 2, 1,                                      # female?; 1 = yes, 0 = no
                         ifelse(sex == 1, 0, NA)),
         married = ifelse(marital > 1, 0, marital),                        # married?; 1 = yes, 0 = no
         edu = ifelse(educa > 6, NA, educa),                               # education lvl; 1-6; 1 = no school or kindergarten, 6 = college grad
         home_own = ifelse(renthom1 >= 7, NA,                              # own home?; 1 = yes, 0 = no
                           ifelse(renthom1 > 1, 0, renthom1)),
         home_rent = ifelse(renthom1 >= 7, NA,                             # rent home?; 1 = yes, 0 = no
                            ifelse(renthom1 == 2, 1, 0)), 
         veteran = ifelse(veteran3 == 2, 0,                                # veteran?; 1 = yes, 0 = no
                          ifelse(veteran3 >= 7, NA, veteran3)),
         employed = ifelse(employ1 <= 2, 1,                                # employed?; 1 = yes, 0 = no
                           ifelse(employ1 == 9, NA, 0)),
         student = ifelse(employ1 == 6, 1,                                 # student?; 1 = yes, 0 = no
                          ifelse(employ1 == 9, NA, 0)),
         numchildren = ifelse(children == 88, 0,                           # num children in hh
                              ifelse(children > 88, NA, children)),
         incomelvl = ifelse(income2 >= 77, NA, income2),                   # income level; 1-8; 1 = less than 10k, 8 = 75k+
         internet_use = ifelse(internet == 2, 0,                           # use internet w/in past 30 days?; 1 = yes, 0 = no
                               ifelse(internet > 2, NA, internet)), 
         weight_kg = (wtkg3 / 100),                                        # weight in kg
         height_in = htin4,                                                # height in inches
         pregnant_now = ifelse(pregnant == 2, 0,                           # pregnant right now?; 1 = yes, 0 = no
                               ifelse(pregnant >= 7, NA, pregnant)),
         hard_hearing = ifelse(deaf == 2, 0,                               # deaf?; 1 = yes, 0 = no
                               ifelse(deaf >= 7, NA, deaf)),
         hard_seeing = ifelse(blind == 2, 0,                               # blind?; 1 = yes, 0 = no
                              ifelse(blind >= 7, NA, blind)),
         diff_decide = ifelse(decide == 2, 0,                              # difficulty deciding/concentrating?; 1 = yes, 0 = no
                              ifelse(decide >= 7, NA, decide)),
         diff_walk = ifelse(diffwalk == 2, 0,                              # difficulty walking/climbing stairs?; 1 = yes; 0 = no
                            ifelse(diffwalk >= 7, NA, diffwalk)),
         diff_dress = ifelse(diffdres == 2, 0,                             # difficulty dressing/bathing?; 1 = yes, 0 = no
                             ifelse(diffdres >= 7, NA, diffdres)),
         diff_alone = ifelse(diffalon == 2, 0,                             # difficulty doing tasks alone?; 1 = yes, 0 = no
                             ifelse(diffalon >= 7, NA, diffalon)),  
         smoked = ifelse(smoke100 == 2, 0,                                 # ever smoked 100 cigs in life?; 1 = yes, 0 = no
                         ifelse(smoke100 >= 7, NA, smoke100)), 
         smoke_freq = case_when(                                           # smoking frequency
           smokday2 == 2 ~ 1,   # smoke some days == 1
           smokday2 == 1 ~ 2,   # smoke everyday == 2
           smokday2 == 3 ~ 0,   # don't smoke == 0
           smokday2 >= 7 ~ as.numeric(NA),
           TRUE ~ smokday2
         ),
         snuff_freq = case_when(                                           # snuff use frequency 
           usenow3 == 2 ~ 1,   # use snuff some days == 1
           usenow3 == 1 ~ 2,   # use snuff everyday == 2
           usenow3 == 3 ~ 0,   # don't use snuff == 0
           usenow3 >= 7 ~ as.numeric(NA),
           TRUE ~ usenow3
         ),
         ecig_freq = case_when(                                            # ecig use frequency
           ecignow == 2 ~ 1,   # use ecig some days == 1
           ecignow == 1 ~ 2,   # use ecig everyday == 2
           ecignow == 3 ~ 0,   # don't use ecig == 0
           ecignow >= 7 ~ as.numeric(NA),
           TRUE ~ ecignow
         ),
         last_smoke = ifelse(lastsmk2 >= 77, NA, lastsmk2),               # how long since last smoke; 1-8; 1 = last month, 8 = never
         alc_past_week = case_when(                                       # days drinking alc in past week; 0-7
           alcday5 <= 107 ~ alcday5 - 100,
           alcday5 == 888 ~ 0, 
           TRUE ~ as.numeric(NA)
         ),                   
         alc_past_month = case_when(                                      # days drinking alc in past month; 0-30
           alcday5 >= 201 & alcday5 <= 230 ~ alcday5 - 200, 
           alcday5 == 888 ~ 0,
           TRUE ~ as.numeric(NA)
         ),
         avg_drinks = ifelse(avedrnk2 >= 77, NA, avedrnk2),               # avg num of drinks when drinking
         flu_vacc = ifelse(flushot6 == 2, 0,                              # flu shot?; 1 = yes, 0 = no
                           ifelse(flushot6 >= 7, NA, flushot6)),
         pnem_vacc = ifelse(pneuvac3 == 2, 0,
                            ifelse(pneuvac3 >= 7, NA, pneuvac3)),         # pneumonia shot?; 1 = yes, 0 = no
         tetanus_vacc = ifelse(tetanus < 4, 1,
                               ifelse(tetanus == 4, 0, NA)),              # tetanus shot?; 1 = yes, 0 = no
         num_fall = ifelse(fall12mn == 88, 0,
                           ifelse(fall12mn >= 77, NA, fall12mn)),         # num falls w/in past 12 months; 0-76
         num_bad_falls = ifelse(fallinj2 == 88, 0,
                                ifelse(fallinj2 >= 77, NA, fallinj2)),    # num falls w/in past 12 months result in bad inj; 0-76
         seatbelt_use = case_when(                                        # freq seatbelt usage; 0-4; 0 = never, 4 = always
           seatbelt == 5 | seatbelt == 8 ~ 0,
           seatbelt == 4 ~ 1,
           seatbelt == 3 ~ 2,
           seatbelt == 2 ~ 3,
           seatbelt == 1 ~ 4,
           seatbelt == 7 | seatbelt == 9 ~ as.numeric(NA),
           TRUE ~ as.numeric(seatbelt)
         ), 
         drunk_drive = ifelse(drnkdri2 == 88, 0,                          # days drunk driving in past 30 days
                              ifelse(drnkdri2 >= 99, NA, drnkdri2)),
         mammogram = ifelse(hadmam == 2, 0,                               # had mammogram?; 1 = yes, 0 = no
                            ifelse(hadmam >= 7, NA, hadmam)),
         last_mammogram = ifelse(howlong >= 7, NA, howlong),              # how long since last mam; 1-5; 1 = w/in yr, 5 = 5+ yrs
         pap = ifelse(hadpap2 == 2, 0,                                    # had pap smear?; 1 = yes, 0 = no
                      ifelse(hadpap2 >= 7, NA, hadpap2)),      
         last_pap = ifelse(lastpap2 >= 7, NA, lastpap2),                  # how long since last pap; 1-5; 1 = w/in yr, 5 = 5+ yrs
         hpv_test = ifelse(hpvtest == 2, 0,                               # had hpv test?; 1 = yes, 0 = no
                           ifelse(hpvtest >= 7, NA, hpvtest)),
         last_hpvtest = ifelse(hplsttst >= 7, NA, hplsttst),              # how long since last hpv test; 1-5; 1 = w/in yr, 5 = 5+ yrs
         hpv_vacc = ifelse(hpvadvc2 == 2 | hpvadvc2 == 3, 0,              # had hpv vacc?; 1 = yes, 0 = no
                           ifelse(hpvadvc2 >= 7, NA, hpvadvc2)),
         hysterectomy = ifelse(hadhyst2 == 2, 0,                          # had hysterectomy?; 1 = yes, 0 = no
                               ifelse(hadhyst2 >= 7, NA, hadhyst2)),     
         psa_test_discussion = ifelse(pcpsaad2 == 2 | pcpsadi1 == 2, 0,                   # discuss PSA test?; 1 = yes, 0 = no
                                      ifelse(pcpsaad2 >= 7 | pcpsadi1 >= 7, NA,
                                             ifelse(pcpsaad2 == 1 | pcpsadi1 == 1, 1, NA))),
         psa_test_suggest = ifelse(pcpsare1 == 2, 0,                                      # suggest PSA test?; 1 = yes, 0 = no
                                   ifelse(pcpsare1 >= 7, NA, pcpsare1)),
         psa_test = ifelse(psatest1 == 2, 0,                                              # had PSA test?; 1 = yes, 0 = no
                           ifelse(psatest1 >= 7, NA, psatest1)),
         last_psatest = ifelse(psatime >= 7, NA, psatime),                # time since last PSA test; 1-5; 1 = w/in yr, 5 = 5+ yrs
         fam_history_prostatecncr = case_when(                            # fam history of prostate cancer; 1 = yes, 0 = no
           pcpsars1 == 3 ~ 1,
           pcpsars1 >= 7 ~ as.numeric(NA),
           is.na(pcpsars1) ~ as.numeric(NA),
           TRUE ~ as.numeric(0)
         ),
         blood_stool_test = ifelse(bldstool == 2, 0,                      # ever had blood stool test?; 1 = yes, 0 = no
                                   ifelse(bldstool >= 7, NA, bldstool)),
         last_bloodstooltest = ifelse(lstblds3 >= 7, NA, lstblds3),       # how long since last blood stool test?; 1-5; 1 = w/in yr, 5 = 5+ yrs
         had_colsig = ifelse(hadsigm3 == 2, 0,
                             ifelse(hadsigm3 >= 7, NA, hadsigm3)),        # had sigmoidoscopy or colonoscopy?; 1 = yes, 0 = no
         sigmoidoscopy = ifelse(hadsgco1 == 1, 1,                         # most recent exam was sigmoidoscopy; 1 = yes, 0 = no
                                ifelse(hadsgco1 == 2, 0, NA)), 
         colonoscopy = ifelse(hadsgco1 == 2, 1,                           # most recent exam was colonoscopy; 1 = yes, 0 = no
                              ifelse(hadsgco1 == 1, 0, NA)),
         last_colsig = ifelse(lastsig3 >= 7, NA, lastsig3),               # last col/sig?; 1-6; 1 = w/in yr, 6 = 10+ yrs
         hiv_test = ifelse(hivtst6 == 2, 0,                               # tested for HIV?; 1 = yes, 0 = no
                           ifelse(hivtst6 >= 7, NA, hivtst6)),
         hiv_risk = ifelse(hivrisk4 == 2, 0,                              # HIV risk factors?; 1 = yes, 0 = no
                           ifelse(hivrisk4 >= 7, NA, hivrisk4)), 
         diabetes_test = ifelse(pdiabtst == 2, 0,                         # high blood sug/diabetes test in past 3 yrs?; 1 = yes, 0 = no
                                ifelse(pdiabtst >= 7, NA, pdiabtst)),
         insulin_now = ifelse(insulin == 2, 0,                                # taking insulin now?; 1 = yes, 0 = no
                              ifelse(insulin >= 9, NA, insulin)), 
         diabetes_consult = ifelse(doctdiab == 88, 0,                     # times see doctor in past yr for diabetes
                                   ifelse(doctdiab >= 77, NA, doctdiab)),
         feet_check = ifelse(feetchk == 88, 0,                            # times doctor check feet for sores/irritation in past yr?
                             ifelse(feetchk >= 77, NA, feetchk)),
         last_eyeexam = ifelse(eyeexam == 8, 0,                           # time since last eye exam; 1-4; 1 = w/in month, 4 = 2+ yrs
                               ifelse(eyeexam >= 7, NA, eyeexam)),
         retinopathy = ifelse(diabeye == 2, 0,                            # doctor said you have retinopathy?; 1 = yes, 0 = no
                              ifelse(diabeye >= 7, NA, diabeye)),
         diab_edu = ifelse(diabedu == 2, 0,                               # taken class on diabetes management?; 1 = yes, 0 = no
                           ifelse(diabedu >= 7, NA, diabedu)),
         pain_days = ifelse(painact2 == 88, 0,                            # num days debilitating pain in past month
                            ifelse(painact2 >= 77, NA, painact2)),
         sad_days = ifelse(qlmentl2 == 88, 0,                             # num days sad in past month
                           ifelse(qlmentl2 >= 77, NA, qlmentl2)),
         anxious_days = ifelse(qlstres2 == 88, 0,                         # num days anxious in past month
                               ifelse(qlstres2 >= 77, NA, qlstres2)),
         energized_days = ifelse(qlhlth2 == 88, 0,                        # num days health and energized in past month
                                 ifelse(qlhlth2 >= 77, NA, qlhlth2)),
         medicare_now = ifelse(medicare == 2, 0,                                # have medicare?; 1 = yes, 0 = no
                               ifelse(medicare >= 7, NA, medicare)),
         hc_employer = ifelse(hlthcvr1 == 1, 1,                                 # health care coverage from employer?; 1 = yes, 0 = no
                              ifelse(hlthcvr1 >= 77, NA, 0)),
         hc_personal = ifelse(hlthcvr1 == 2, 1,                                 # health care coverage from personal plan?; 1 = yes, 0 = no
                              ifelse(hlthcvr1 >= 77, NA, 0)),
         hc_medicare = ifelse(hlthcvr1 == 3, 1,                                 # health care coverage from medicare?; 1 = yes, 0 = no
                              ifelse(hlthcvr1 >= 77, NA, 0)),
         hc_medicaid = ifelse(hlthcvr1 == 4, 1,                                 # health care coverage from medicaid?; 1 = yes, 0 = no
                              ifelse(hlthcvr1 >= 77, NA, 0)),
         hc_tricare = ifelse(hlthcvr1 == 5, 1,                                  # health care coverage from tricare/VA?; 1 = yes, 0 = no
                             ifelse(hlthcvr1 >= 77, NA, 0)),
         hc_native = ifelse(hlthcvr1 == 6, 1,                                   # health care coverage from tribal health services?; 1 = yes, 0 = no
                            ifelse(hlthcvr1 >= 77, NA, 0)),   
         hc_none_current = ifelse(hlthcvr1 == 8, 1,                             # no health care coverage?; 1 = yes(no coverage), 0 = no(yes covered)
                                  ifelse(hlthcvr1 >= 77, NA, 0)),
         delay_appt = ifelse(delaymed == 2, 1,                                  # delay care b/c couldn't make appt in time; 1 = yes, 0 = no
                             ifelse(delaymed >= 7, NA, 0)),
         delay_wait = ifelse(delaymed == 3, 1,                                  # delay care b/c had to wait; 1 = yes, 0 = no
                             ifelse(delaymed >= 7, NA, 0)),
         delay_transport = ifelse(delaymed == 5, 1,                             # delay care b/c no transport; 1 = yes, 0 = no
                                  ifelse(delaymed >= 7, NA, 0)),
         hc_none_thisyr = ifelse(nocov121 == 2, 0,                              # time in past yr with no coverage?; 1 = yes, 0 = no
                                 ifelse(nocov121 >= 7, NA, nocov121)),
         drvisit = ifelse(drvisits == 88, 0,                                    # num doc visits in past year
                          ifelse(drvisits >= 77, NA, drvisits)),
         med_toocostly = ifelse(medscost == 2 | medscost == 3, 0,               # time in past yr didn't take meds bc cost?; 1 = yes, 0 = no
                                ifelse(medscost >= 7, NA, medscost)),
         satisfied_care = case_when(                                            # satisfied with care; 0-2; 0 = not at all, 3 = very 
           carercvd == 3 ~ 0,
           carercvd == 2 ~ 1,
           carercvd == 1 ~ 2,
           TRUE ~ as.numeric(NA)
         ),
         med_bills = ifelse(medbill1 == 2, 0,                                   # currently paying bills overtime?; 1 = yes, 0 = no
                            ifelse(medbill1 >= 7, NA, medbill1)),
         get_medadvic = ifelse(medadvic >= 5, NA, medadvic),                    # difficulty get med advice; 1-4; 1 = very easy, 4 = very difficult
         undrstnd_medadvic = ifelse(undrstnd >= 7, NA, undrstnd),               # difficult understand med advice; 1-4; 1 = very easy, 4 = very difficult
         understand_writtenmedadvic = ifelse(written >= 5, NA, written),        # difficult understand written med advice; 1-4; 1 = very easy, 4 = very difficult
         caregiver = ifelse(crgvexpt == 2, 0,                                   # expect give care in next 2 yrs; 1 = yes, 0 = no
                            ifelse(crgvexpt >= 7, NA, crgvexpt)),
         mem_loss = ifelse(cimemlos == 2, 0,                                    # confusion/mem loss in past year?; 1 = yes, 0 = no
                           ifelse(cimemlos >= 7, NA, cimemlos)), 
         mem_loss_assist = case_when(                                           # when need help, how often need assist?; 0-4; 0 = never, 4 = always
           cdassist == 5 ~ 0,
           cdassist == 4 ~ 1,
           cdassist == 3 ~ 2,
           cdassist == 2 ~ 3,
           cdassist == 1 ~ 4,
           TRUE ~ as.numeric(NA)
         ),
         mem_loss_gethelp = case_when(                                          # when need help, how often get assistance?; 0-4; 0 = never, 4 = always
           cdhelp == 5 ~ 0,
           cdhelp == 4 ~ 1,
           cdhelp == 3 ~ 2,
           cdhelp == 2 ~ 3,
           cdhelp == 1 ~ 4,
           TRUE ~ as.numeric(NA)
         ),
         mem_loss_inhibit = case_when(                                          # how often mem loss inhibit daily life/socializing?; 0-4; 0 = never, 4 = always
           cdsocial == 5 ~ 0,
           cdsocial == 4 ~ 1,
           cdsocial == 3 ~ 2,
           cdsocial == 2 ~ 3,
           cdsocial == 1 ~ 4,
           TRUE ~ as.numeric(NA)
         ),
         mem_loss_doctor = ifelse(cddiscus == 2, 0,                             # discuss mem loss with doctor?; 1 = yes, 0 = no
                                  ifelse(cddiscus >= 7, NA, cddiscus)),
         soda_day = ifelse(ssbsugr2 <= 199, ssbsugr2 - 100, NA),                      # num sodas per day
         soda_week = ifelse(ssbsugr2 >= 201 & ssbsugr2 <= 299, ssbsugr2 - 200, NA),   # num sodas per week
         soda_month = ifelse(ssbsugr2 >= 301 & ssbsugr2 <= 399, ssbsugr2 - 300, NA),  # num sodas per month
         sugarbev_day = ifelse(ssbfrut2 <= 199, ssbfrut2 - 100, NA),                      # num sugary drinks per day
         sugarbev_week = ifelse(ssbfrut2 >= 201 & ssbfrut2 <= 299, ssbfrut2 - 200, NA),   # num sugary drinks per week
         sugarbev_month = ifelse(ssbfrut2 >= 301 & ssbfrut2 <= 399, ssbfrut2 - 300, NA),  # num sugary drinks per month
         calorie = case_when(
           calrinfo == 5 | calrinfo == 6 ~ 0,
           calrinfo == 4 ~ 1,
           calrinfo == 3 ~ 2,
           calrinfo == 2 ~ 3,
           calrinfo == 1 ~ 4,
           TRUE ~ as.numeric(NA)
         ),
         marijuana = ifelse(marijana == 88, 0,                                    # num days use marijuana in past 30 days
                            ifelse(marijana >= 77, NA, marijana)),
         shingles_vacc = ifelse(shingle2 == 2, 0,                                 # got shingles vaccine?; 1 = yes, 0 = no
                                ifelse(shingle2 >= 7, NA, shingle2)), 
         sunburn = ifelse(numburn2 == 8, 0,                                       # num suburns in past year
                          ifelse(numburn2 >= 7, NA, numburn2)),
         num_types_cncr = ifelse(cncrdiff >= 7, NA, cncrdiff),                    # num types of cancer; 1-3; 1 = one, 3 = 3+
         age_diagnosis_cncr = ifelse(cncrage >= 98, NA, cncrage),                 # age when diagnosed with cancer
         cncr_treatment_now = ifelse(csrvtrt1 >= 2 & csrvtrt1 <= 4, 0,            # cancer treatment now?; 1 = yes, 0 = no
                                     ifelse(csrvtrt1 >= 7, NA, csrvtrt1)),
         cncr_treatment_done = ifelse(csrvtrt1 == 2, 1,                           # cancer treatment done?; 1 = yes, 0 = no
                                      ifelse(csrvtrt1 < 7, 0, NA)),
         cncr_treatment_coming = ifelse(csrvtrt1 == 4, 1,                         # cancer treatment soon?; 1 = yes, 0 = no
                                        ifelse(csrvtrt1 < 7, 0, NA)),
         cncr_treatment_refuse = ifelse(csrvtrt1 == 3, 1,                         # cancer treatment refused?; 1 = yes, 0 = no
                                        ifelse(csrvtrt1 < 7, 0, NA)),
         cncr_insurance = ifelse(csrvinsr == 2, 0,                                # cancer treatment covered by insurance?; 1 = yes, 0 = no
                                 ifelse(csrvinsr > 2, NA, csrvinsr)),
         cncr_clintrial = ifelse(csrvclin == 2, 0,                                # particip clin trial for cancer?; 1 = yes, 0 = no
                                 ifelse(csrvclin >= 7, NA, csrvclin)),
         cncr_trtmntpain = ifelse(csrvpain == 2, 0,                               # currently have pain from cncr treatment?; 1 = yes, 0 = no
                                  ifelse(csrvpain >= 7, NA, csrvpain)),
         breast_exam = ifelse(profexam == 2, 0,                                   # ever had clinical breast exam?; 1 = yes, 0 = no
                              ifelse(profexam >= 7, NA, profexam)),
         last_breastexam = ifelse(lengexam >= 7, NA, lengexam),                   # length since last breast exam; 1-5, 1 = w/in yr, 5 = 5+ yrs
         hetero = ifelse(sxorient >= 7, NA,                                       # heterosexual?; 1 = yes, 0 = no
                         ifelse(sxorient > 1, 0, sxorient)),
         homo = ifelse(sxorient >= 7, NA,                                         # homosexual?; 1 = yes, 0 = no
                       ifelse(sxorient != 2, 0, 1)),
         bisexual = ifelse(sxorient >= 7, NA,                                     # bisexual?; 1 = yes, 0 = no
                           ifelse(sxorient != 3, 0, 1)),             
         transgender = ifelse(trnsgndr == 4, 0,                                   # transgender?; 1 = yes, 0 = no
                              ifelse(trnsgndr < 4, 1, NA)),
         emo_support = case_when(                                                 # lvl of emotional support; 0-4; 0 = never, 4 = always
           emtsuprt == 5 ~ 0,
           emtsuprt == 4 ~ 1,
           emtsuprt == 3 ~ 2,
           emtsuprt == 2 ~ 3,
           emtsuprt == 1 ~ 4,
           TRUE ~ as.numeric(NA)
         ),
         life_dissatisfaction = ifelse(lsatisfy >= 7, NA, lsatisfy),  # lvl dissatisfaction with life; 1-4; 1 = v satisfied, 4 = v dissatisfied
         life_limited = ifelse(qlactlm2 == 2, 0,                      # life limited by emo/phys/mental factors?; 1 = yes, 0 = no
                               ifelse(qlactlm2 >= 7, NA, qlactlm2)),
         special_equip = ifelse(useequip == 2, 0,                     # have health prob requiring special equipment?; 1 = yes, 0 = no
                                ifelse(useequip >= 7, NA, useequip)),
         english = ifelse(qstlang == 1, 1,                            # questionnaire in english?; 1 = yes, 0 = no
                          ifelse(qstlang <= 99, 0, NA)),
         spanish = ifelse(qstlang == 2, 1,                            # questionnaire in spanish?; 1 = yes, 0 = no
                          ifelse(qstlang <= 99, 0, NA)),
         city = ifelse(mscode > 1, 0, mscode),                        # in city?; 1 = yes, 0 = no
         white = ifelse(x.mrace1 >= 77, NA,                           # race = white?; 1 = yes, 0 = no
                        ifelse(x.mrace1 > 1, 0, x.mrace1)),
         black = ifelse(x.mrace1 == 2, 1,                             # race = black?; 1 = yes, 0 = no
                        ifelse(x.mrace1 >= 77, NA, 0)),
         native = ifelse(x.mrace1 == 3, 1,                            # race/ethnicity = native?; 1 = yes, 0 = no
                         ifelse(x.mrace1 >= 77, NA, 0)),
         asian = ifelse(x.mrace1 == 4, 1,                             # race = asian?; 1 = yes, 0 = no
                        ifelse(x.mrace1 >= 77, NA, 0)),
         pacific_islander = ifelse(x.mrace1 == 5, 1,                  # race/ethnicity = pacific islander?; 1 = yes, 0 = no
                                   ifelse(x.mrace1 >= 77, NA, 0)),
         multiracial = ifelse(x.mrace1 == 7, 1,                       # multiracial?; 1 = yes, 0 = no
                              ifelse(x.mrace1 >= 77, NA, 0)),
         hispanic = ifelse(x.hispanc == 2, 0,                         # hispanic?; 1 = yes, 0 = no
                           ifelse(x.hispanc == 9, NA, x.hispanc)),  
         age = x.age80,                                               # age 18-80
         bmi = (x.bmi5 / 100),                                        # BMI
         obese = ifelse(x.rfbmi5 == 1, 0,
                        ifelse(x.rfbmi5 == 2, 1, NA))
  )

keep_vars <- setdiff(colnames(BRFSS_2016_clean), vars)  # new cols created to keep

BRFSS_2016_clean <- select(BRFSS_2016_clean, keep_vars)
BRFSS_2016_clean[is.na(BRFSS_2016_clean)] <- 0  # replace NAs with 0
