# Brain age computation from T1-weighted images
Appendix to Brouwer et al., (2020), The speed of development of adolescent brain age depends on sex and is genetically determined.
 
This brain age model is trained on 1.5T T1-weighted scans of children and adolescents aged 9 – 22 year from the BrainSCALE study (van Soelen et al., 2012; Koenis et al., 2018). Please note that the model should not be used for subjects out of this range. Also note that due to different scanners / acquisition protocols your brain age estimates will likely contain an offset so we encourage you to calibrate your data (see Additional information below).

## Prerequisites: 

-	FreeSurfer run for all the subjects you want brain age for. Please note, the original model was built on FS5.3 output. We tested the model using FS6.0 output and brain ages correlated highly (r > 0.94) with the original estimates. When applied to your own data, please make sure to calibrate. 
-	Text file “subjects_demo.txt” containing a column with subject IDs matching the FreeSurfer IDs [mandatory]. If you also want brain age estimates that are corrected for regression to the mean [Le et al., 2018], add a second column [optional] containing chronological age in years. Columns should be space or tab delimited. 
-	R installation including the library “stringr”  <br> \# install if needed with install.packages("stringr",repos="http://cloud.r-project.org")
- The compute_brain_age_FSvolumes_Brainscale.R script 
- The models - Brainscale_FSvolumes_based_brain_age_models.Rdata


## Step 1: Extract the necessary volumes. 

We are assuming that the system where you ran FreeSurfer is linux or MacOS based. Put your subjects_demo.txt file in your FreeSurfer SUBJECTS_DIR (make sure this points to the right directory; use export SUBJECTS_DIR=… ) and run

`>	cat subjects_demo.txt | awk '{ print $1 }' > subjects.txt` <br>
`>  asegstats2table --subjectsfile subjects.txt --meas volume -t aseg_volumes.txt` <br>
`>	aparcstats2table --subjectsfile subjects.txt --meas volume --hemi lh  -t aparc_lh_volumes.txt` <br>
`>	aparcstats2table --subjectsfile subjects.txt --meas volume --hemi rh -t aparc_rh_volumes.txt` <br>

## Step 2: Compute brain ages

Put the 3 resulting files aseg_volumes.txt / aparc_lh_volumes.txt / aparc_rh_volumes.txt and the subjects_demo.txt in the same folder as the R script and .Rdata model file and run in a terminal

`>	R --slave --no-save < compute_brain_age_FSvolumes_Brainscale.R`

This will give you an output file with three brain ages: 

- BA_C for the model that was based on males + females combined
- BA_M for the model that was based on males
- BA_F for the model that was based on females

If you added an age column to your subjects_demo.txt file you will also get age,
BA_C_corrected, BA_M_corrected and BA_F_corrected which are brain age estimates that were corrected for regression to the mean.

## Additional information

### Calibration

Our brain age models are based on scans from one type of scanner using a specific acquisition protocol. Different scanners and protocols most certainly will result in different estimates of ROI volumes by FreeSurfer, thus leading to a bias in the estimated brain age:

BA' = Σ<sub>*j</sub> w<sub>j* \* </sub>*x<sub>j*'*</sub>* + *b* = Σ<sub>*j</sub> w<sub>j</sub>\*(x<sub>j</sub>* + *d<sub>j</sub>*) + *b* = Σ<sub>*j</sub> w<sub>j</sub>\*x<sub>j</sub>* + *b* + Σ<sub>*j</sub> w<sub>j</sub>\*d<sub>j</sub>* = BA + bias,

where the sum (Σ) over *j* refers to all the volumes, *w* refers to the weight, *x* refers to the measured volumes, *b* is a constant, and *d* is an offset of volume *j* on a different scanner. Variables with primes (' ) refer to the different scanner; variables without primes to our original scanner.

If you expect the mean brain age gap in your sample to be zero, you may adjust the estimates BA' by subtracting the mean difference mean(BA') - mean(age).

If you want to associate BA gaps with other measures, you may choose to not adjust the BAs (and gaps), since correlations coefficients are not sensitive to shifts.

If you want to compare BA gaps between two or more groups (e.g., with one group being a reference group, e.g., healthy controls), you also don’t need to adjust: differences between the groups are relative measures and absolute values are not important.

### References

Brouwer, R.M., Schutte, J., Janssen, R., Boomsma, D.I., Hulshoff Pol, H.E., Schnack, H.G. (Accepted for publication, Cerebral Cortex, 2020). The speed of development of adolescent brain age depends on sex and is genetically determined.

Koenis, M.M.G., Brouwer, R.M., Swagerman, S.C., van Soelen, I.L.C., Boomsma, D.I., Hulshoff Pol, H.E. (2018). Association between structural brain network efficiency and intelligence increases during adolescence. Human Brain Mapping 39(2); 822-836. https://doi.org/10.1002/hbm.23885.

Le, T. T., Kuplicki, R. T., McKinney, B. A., Yeh, H.-W., Thompson, W. K., & Paulus, M. P. (2018). A Nonlinear Simulation Framework Supports Adjusting for Age When Analyzing BrainAGE. Frontiers in Aging Neuroscience, 10 (October), 1–11. https://doi.org/10.3389/fnagi.2018.00317

van Soelen, I. L., Brouwer, R. M., Peper, J. S., van Leeuwen, M., Koenis, M. M., van Beijsterveldt, T. C., … Boomsma, D. I. (2012). Brain SCALE: brain structure and cognition: an adolescent longitudinal twin study into the genetic etiology of individual differences. Twin Res Hum Genet, 15(3), 453–467. https://doi.org/10.1017/thg.2012.4
