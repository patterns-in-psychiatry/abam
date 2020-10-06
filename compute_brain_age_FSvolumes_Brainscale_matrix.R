
library(stringr)

dataaseg <- read.table("aseg_volumes.txt",header=T)
dataaparclh <- read.table("aparc_lh_volumes.txt",header=T)
dataaparcrh <- read.table("aparc_rh_volumes.txt",header=T)

colnames(dataaseg)[1] <- "ID"
colnames(dataaparclh)[1] <- "ID"
colnames(dataaparcrh)[1] <- "ID"

datacort <- merge(dataaparclh,dataaparcrh,by="ID",all.x=F,all.y=F)
data <- merge(datacort,dataaseg,by="ID",all.x=F,all.y=F)
subjects <- read.table("subjects_demo.txt",header=F)
if (dim(subjects)[2] == 1)
colnames(subjects) = c("ID")
if (dim(subjects)[2] == 2)
colnames(subjects) = c("ID","Age")


if ( dim(data)[1] != dim(dataaseg)[1] | dim(data)[1] != dim(dataaparclh)[1] | dim(data)[1] != dim(dataaparcrh)[1])
{
	print("There are missing variables in one of your freesurfer files, cannot compute brain age")
	quit()
}

if (length(setdiff(subjects[order(subjects$ID),"ID"],data[order(data$ID),"ID"]))>0)
{
	print("One or more subject codes are not present in the freesurfer files, cannot compute brain age")
	quit()
} 

if (dim(subjects)[2] == 1)
{
	print("Warning, no age column detected in input file, computing brain age only")
}
if (dim(subjects)[2] == 2)
{
	print("Age column detected in input file, also computing brain age with correction for regression to the mean")
}


# load matrices containing model weights and scaling factors
# variables in model_matrix were renamed (need libary stringr) according to 
load("Brainscale_FSvolumes_based_brain_age_models.Rdata")

suffixlist <- c("C","M","F")
modellist <- list(model_matrix_C,model_matrix_M,model_matrix_F)
# output matrix
output <- as.data.frame(matrix(nrow=dim(subjects)[1],ncol=1,dimnames=list(NULL,c("ID"))))
output[,"ID"] <- subjects[,"ID"]
if (dim(subjects)[2] == 2)
output[,"Age"] <- subjects[,2]

for (p in 1:length(modellist))
{

model_matrix <- modellist[[p]]
rownames(model_matrix) <-  str_replace(str_replace(str_replace(rownames(model_matrix),"L_","lh_"),"R_","rh_"),"_volavg","_volume")
VARlist <- str_replace(rownames(model_matrix),"_gc","")

# prepare data; divide by ICV 
for (var in VARlist)
{
	data[,sprintf("%s_gc",var)] <- data[,var]/data[,"EstimatedTotalIntraCranialVol"]
}
# compute data scaled by train_dat scale parameters and model scale parameters
for (var in VARlist)
{
	data[,sprintf("%s_gc_scaled",var)] <- (data[,sprintf("%s_gc",var)] - model_matrix[which(rownames(model_matrix)==sprintf("%s_gc",var)),"mean_scale_train"])/(model_matrix[which(rownames(model_matrix)==sprintf("%s_gc",var)),"sd_scale_train"]) 
}


# compute brain age by scaling variables and multiplying by weight
for (k in 1:25)
{
	# compute X*W + C, where X contains the input data (columns are sprintf("%s_gc_scaled",VARlist), rows are subjects
	# W are the weights (scaled by sigma_y/sigma_x_j)
	# C is a constant ( -sum_j (mu_x,j times sigma_y/sigma_x_j), plus mu_y)

X <- as.matrix(data[output$ID,sprintf("%s_gc_scaled",VARlist)])
W <- as.matrix((model_matrix[sprintf("%s_gc",VARlist),sprintf("weight_%i",k)]*model_matrix[sprintf("%s_gc",VARlist),sprintf("sd_model_y_%i",k)])/model_matrix[sprintf("%s_gc",VARlist),sprintf("sd_model_x_%i",k)])
C <- model_matrix[1,sprintf("mean_model_y_%i",k)] - sum((model_matrix[sprintf("%s_gc",VARlist),sprintf("mean_model_x_%i",k)]*model_matrix[sprintf("%s_gc",VARlist),sprintf("sd_model_y_%i",k)]*model_matrix[sprintf("%s_gc",VARlist),sprintf("weight_%i",k)])/model_matrix[sprintf("%s_gc",VARlist),sprintf("sd_model_x_%i",k)])
output[,sprintf("BA_%s_%i",suffixlist[p],k)] <- X%*%W + C
}

output[,sprintf("BA_%s",suffixlist[p])] <- rowMeans(output[,grep(sprintf("BA_%s_",suffixlist[p]),colnames(output))])
}

outlist <- c("ID","BA_C","BA_M","BA_F")	
if (dim(subjects)[2]==2)
{
output[,"BA_C_corrected"] <- t(output[,"BA_C"] - regression_output_C$coefficients[[1]] + (1-regression_output_C$coefficients[[2]])%*%output[,"Age"])
output[,"BA_M_corrected"] <- t(output[,"BA_M"] - regression_output_M$coefficients[[1]] + (1-regression_output_M$coefficients[[2]])%*%output[,"Age"])
output[,"BA_F_corrected"] <- t(output[,"BA_F"] - regression_output_F$coefficients[[1]] + (1-regression_output_F$coefficients[[2]])%*%output[,"Age"])
outlist <- c("ID","Age","BA_C","BA_C_corrected","BA_M","BA_M_corrected","BA_F","BA_F_corrected")
}
	
write.table(format(output[,outlist],digits=4),"Brain_age_predictions_Brainscale_model_FSvol.csv",col.names=T,row.names=F,quote=F,sep=",")

