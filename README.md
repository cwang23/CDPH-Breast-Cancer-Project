# Predicting Insurance Status and Risk of Breast Cancer
For this project, data scientists at Civis Analytics trained and cross-validated two different models. One model predicts the likelihood that an individual is uninsured. The other model predicts the likelihood that a woman is at-risk of developing breast cancer. We then use this information to create a map of Chicago that highlights areas where there are women who are uninsured and/or have a high risk of breast cancer. The Chicago Department of Public Health can implement the results of this project to conduct a targeted breast cancer screening campaign, so that women with the highest likelihood of developing breast cancer and/or not having health insurance are getting screened.

***A cross-validation study has shown that this model correctly predicts consecutive results for WNV virus about 80 percent of the time.

This GitHub repository provides all of the source code used to develop the model as well as create the map visualizations. Some of the data used in this project are also available in this repository. However, this code relies heavily on proprietary data and software that belong to Civis Analytics, so it cannot be executed without these resources. Furthermore, much of the code has been altered to protect such proprietary information. Nevertheless, it is still possible to review the code and understand the methodology we used to arrive at our results. 

## Data 
We utilized three datasets in this project:
1. Proprietary modeling data from Civis Analytics
2. Responses from a survey conducted from October to November 2017 by Civis Analytics
3. Behavioral Risk Factor Surveillance System (BRFSS) 2016 data, which is publicly available at: https://www.cdc.gov/brfss/annual_data/annual_2016.html

Only the de-identified survey response data is available in this repository. The BRFSS 2016 data can be accessed via the link above. 

5,497 individuals participated in our survey, of which 59% were female and 41% were male. We asked participants about their insurance status. We also asked a battery of questions related to breast cancer risk factors as identified by the Centers for Disease Control (CDC) (https://www.cdc.gov/cancer/breast/basic_info/risk_factors.htm) and Cancer Treatment Centers of America (https://www.cancercenter.com/breast-cancer/risk-factors/). 

To prepare the data for modeling, we matched the survey responses we collected to Civis Analytics’s proprietary data. We then recoded the BRFSS 2016 data and appended it to our data. A R script to clean and recode the BRFSS 2016 data is available in this repository (“BRFSS 2016 ETL.R”). 

We then used SEER 2010-2012 data to identify baseline risk values for breast cancer based off age and race. Using demographic information in Civis Analytics’s proprietary data, we were able to assign one of these baseline risk values to each individual in our data set. We also assigned relative risk values to each survey response by drawing on academic studies of breast cancer risk factors. We then multiplied the baseline risk values for breast cancer with the relative risk values assigned to each survey response, which resulted in an overall relative risk value for breast cancer. Next, we recoded our breast cancer risk variable to be a binary variable indicating high risk of breast cancer (1) or lower risk of breast cancer (0). We used a relative risk value of 0.05 as our cutoff, as this is approximately double the median baseline risk for breast cancer.

SEER 2010-2012 data available at: https://seer.cancer.gov/archive/csr/1975_2012/results_merged/topic_lifetime_risk.pdf (Table 4.17)

## Model
For both our uninsured and breast cancer risk models, we trained and tested multiple models using Civis Analytics’s proprietary software, CivisML, to find the best performing ones.

We used a sparse logistic model to predict an individual’s likelihood of having health insurance. The features in this model include proprietary data from Civis Analytics, such as an individual’s past history of health insurance. As most people in our training set had health insurance, we had to re-balance our dataset prior to training our models. 

***We used a ____ model to predict a women’s risk of developing breast cancer. 


## Model Performance
For both models, we looked at the ROC AUC to identify the best performing model, and we used this value to evaluate the performance of both models.

Overall, the “success rate” or number of individuals classified correctly depends on what is chosen as the cutoff for who is uninsured, or who is at a high risk of breast cancer. As the goal of this project is to inform a targeted campaign for breast cancer screening, we chose to cast a broad net. 
Thus, we tried to capture more positive results, which also led us to capture more individuals who may not be uninsured or have a high risk of breast cancer. In other words, we emphasized the recall of the models when determining the cutoffs.

We set the cutoff for the health insurance model at 0.5, and we set the cutoff for breast cancer risk at [WHAT IS THE CUTOFF]. This allowed us to capture as many people as possible who were uninsured or at risk of breast cancer as possible. 

***Based on previous results we chose a cutoff of 39%, which accurately predicts the positive results 78% of the time in the test case (94 / 120), and these predictions were correct 65% of the time (94 / 144).

## How to Run the Code
Python 3 and the R programming language were used to develop both models.

The R programming language is free and available for download at https://cran.r-project.org. We recommend RStudio as the IDE for this project. It is also free and can be downloaded at https://www.rstudio.com/.

We used Jupyter Notebooks to write and run our Python 3 code. Jupyter Notebooks allow you to run your code cell by cell, so that it can be broken up into small chunks. Python 3 and Jupyter Notebooks can be installed on your machine for free by downloading Anaconda. This link has installation instructions: https://jupyter.readthedocs.io/en/latest/install.html. 

“BRFSS 2016 ETL.R” is written in R. To run this code, you can download the BRFSS 2016 data into a directory, and then set this directory as your working directory in your R session.

“___.ipynb” and “___.ipynb” are written in Python 3 and are Jupyter Notebooks. Both notebooks have thorough explanations of the code, and you can step through their processes cell by cell. However, you cannot fully run these notebooks, as they rely heavily on proprietary data and software from Civis Analytics. 


## System Requirements
We recommend using RStudio as the IDE for the R programming language, and we recommend using Jupyter Notebooks to run the Python 3 notebooks. 

However, it is not possible to run the code in its entirety without access to Civis Analytics’s software and data.  

Within R you will need to install several libraries to run each script. If you do not already have these libraries installed, simply run the code at the beginning of the script under the heading "Set Up Workspace." 

For Python, you will also need to install several packages to run the code. To install these packages, you will need to run
____ pip install ____ in your command line interface. 
