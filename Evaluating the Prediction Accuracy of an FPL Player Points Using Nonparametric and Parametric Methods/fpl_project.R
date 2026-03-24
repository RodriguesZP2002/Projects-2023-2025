library(dplyr)
library(ggplot2)
library(tidyverse)
library(caTools)
library(rpart)
library(caret)
library(tree)
library(corrplot)

fpl <- read.csv(choose.files())

#628 observations and 16 variables
#First look at a dataset there are 2 variables that can be focused as result variables - Points and Price
#Points are definedd depending on player performance
#Price is attributed depending on player performance - higher price = Better player

summary(fpl)

cor_matrix <- cor(fpl[, c("Goals_Scored", "Assists", "Yellow_Card", 
                          "Saves", "Red_Card", "Min_Played", 
                          "CS", "Shots_On_Target", "Goals_Conceded")])
corrplot(cor_matrix, method = "circle", type = "upper", tl.cex = 0.7)

#library(car)
#vif(fpllr)

#Goals_Scored         Assists           Saves     Yellow_Card        Red_Card      Min_Played              CS Shots_On_Target 
#6.536910        1.967248        1.665006        2.556524        1.034123       37.724830        9.896691        8.296370 
#Goals_Conceded 
#15.076968 

#Depending on the position different prameters have different values, defenders have a higher focus on goals succeded, clean sheets,etc..~
#Attackers and midfielders have more focus on Goals and Assits

#TSB - percentage of teams possessing the player --- How many fpl squads have the player not really needed, ccan it affect cost?
#CS - number of clean sheets kept by the player
#BPS - total sum of bonus points scored by the players

#Cross-Validation and Cp Estimates of Prediction Error CHAPTER 12
#How to construct an effective prediction rule and how to estimate the accuracy of its predictions. 
#Chapter 16-19 on Machine learning concern prediction rule construction. 
#But project is more on after choosing a particular rule how to estimate the predictive accuracy

#category_counts <- table(fpl$Position)
#print(category_counts)

#DEF FOR  GK MID 
#210  86  71 261 

#Training set, Validation set
sample <- sample.split(fpl$Position, SplitRatio = 0.7)
train  <- subset(fpl, sample == TRUE)
test   <- subset(fpl, sample == FALSE)

#Train
#DEF FOR  GK MID 
#147  60  50 183

#Test
#DEF FOR  GK MID 
#63  26  21  78
#Several competing rules and determine which is best

###
### PREDICTION RULE
###

#1. The prediction i want to give is the points of a player using the rest of the numerical variables as the predictors (Regression)

##
## LINEAR REGRESSION
##

#Train validation set
fpllr <- lm(Points ~ Goals_Scored + Assists + Saves + Yellow_Card +
     Red_Card + Min_Played + CS + Shots_On_Target + Goals_Conceded + BPS, data = train)

summary(fpllr)

####
#https://www.geeksforgeeks.org/cross-validation-in-r-programming/?ref=lbp

predictlr <- predict(fpllr, test)
data.frame( R2 = R2(predictlr, test$Points),
            RMSE = RMSE(predictlr, test$Points),
            MAE = MAE(predictlr, test$Points))

#     R2     RMSE      MAE
# 0.982308 5.093633 3.673213

#Leave one -out CV
train_control <- trainControl(method = "LOOCV")
loocvmodel <- train(Points ~ Goals_Scored + Assists + Saves + Yellow_Card + 
                      Red_Card + Min_Played + CS + Shots_On_Target + Goals_Conceded + BPS, data = fpl, 
               method = "lm",
               trControl = train_control)

print(loocvmodel)
rm(loocvmodel)

#  RMSE      Rsquared   MAE      
#5.015801  0.9833033  3.441961

#K-fold CV

#10-fold CV
train_control <- trainControl(method = "cv",
                              number = 10)
cvmodel <- train(Points ~ Goals_Scored + Assists + Saves + Yellow_Card + 
                      Red_Card + Min_Played + CS + Shots_On_Target + Goals_Conceded + BPS, data = fpl, 
                    method = "lm",
                    trControl = train_control)

print(cvmodel)
rm(cvmodel)

# RMSE      Rsquared   MAE     
#5.002471  0.9837767  3.475035

#Covariance penalty


##
## RIDGE REGRESSION (Standardize)
##

library(glmnet)

standardize = function(x){ 
  z <- (x - mean(x)) / sd(x) 
  return( z) 
}

numeric_columns <- sapply(fpl, is.numeric)


stdfpl <- as.data.frame(apply(fpl[, numeric_columns], 2, standardize))
stdtrain <-  as.data.frame(apply(train[, numeric_columns], 2, standardize))
stdtest <- as.data.frame(apply(test[, numeric_columns], 2, standardize))

X_train <- model.matrix(Points ~ Goals_Scored + Assists + Yellow_Card + Saves +
                    Red_Card + Min_Played + CS + Shots_On_Target + Goals_Conceded + BPS, data = train)[, -1]
y_train <- train$Points

X_test <- model.matrix(Points ~ Goals_Scored + Assists + Yellow_Card + Saves +
                          Red_Card + Min_Played + CS + Shots_On_Target + Goals_Conceded + BPS, data = test)[, -1]
y_test <- test$Points

cv.ridge <- cv.glmnet(x = X_train, y = y_train, alpha = 0) 
plot(cv.ridge)

cv.ridge$lambda.min 
coef(cv.ridge, s = "lambda.min") 

cv.ridge$lambda.1se 
coef(cv.ridge, s = "lambda.1se") 

ridge<-train(y = y_train,
             x = X_train,
             method = 'glmnet', 
             tuneGrid = expand.grid(alpha = 0, lambda = 6.434233)
             
) 

# Make the predictions
predictions_ridge <- ridge %>% predict(X_test)

# Print R squared scores
data.frame(
  Ridge_R2 = R2(predictions_ridge, y_test),
  RMSE = RMSE(predictions_ridge, y_test),
  MAE = MAE(predictions_ridge, y_test))
#Lambda = 1
#  Ridge_R2     RMSE       MAE
#  0.9629087 0.2603359 0.2022157

#Lambda.min = 0.09449372
#Ridge_R2      RMSE       MAE
# 0.9761805 0.1587925 0.1126717

#Lambda.1se = 0.1504607
#Ridge_R2      RMSE       MAE
#0.9742522 0.1673335 0.1186933

####NON-STANDARDIZED
#LAMBDA.MIN = 3.681905
# Ridge_R2     RMSE      MAE
# 0.9764706 6.106504 4.162237

#LAMBDA.1SE = 4.867261
#Ridge_R2     RMSE      MAE
# 0.9753478 6.300314 4.284257
#----------------------------------------------------------------
train_control <- trainControl(method = "LOOCV")
cvmodel <- train(Points ~ Goals_Scored + Assists + Saves + Yellow_Card + 
                   Red_Card + Min_Played + CS + Shots_On_Target + Goals_Conceded + BPS, data = fpl, 
                 method = "glmnet",
                 tuneGrid = expand.grid(alpha = 0, lambda= 6.434233),
                 trControl = train_control)

print(cvmodel)
#Lambda = 1
#  RMSE       Rsquared   MAE      
# 0.2473984  0.9675001  0.1851934

#Lambda.min
#  RMSE       Rsquared   MAE       
#0.1397238  0.9813544  0.09805163

#Lambda.1se
# RMSE       Rsquared   MAE      
#0.1475723  0.9800032  0.1033691

###CV to find best lambda

train_control <- trainControl(method = "cv",
                              number = 10)
cvmodel <- train(Points ~ Goals_Scored + Assists + Saves + Yellow_Card + 
                   Red_Card + Min_Played + CS + Shots_On_Target + Goals_Conceded + BPS, data = stdfpl, 
                 method = "glmnet",
                 tuneGrid = expand.grid(alpha = 0, lambda= lambda_seq),
                 trControl = train_control)
print(cvmodel)
rm(cvmodel)

# lambda        RMSE       Rsquared   MAE  
#0.07943282  0.1392180  0.9817416  0.09806861



#-----------------------------------------------------------------------------------------------------------

##
##Lasso Regression 
##

X_train <- model.matrix(Points ~ Goals_Scored + Assists + Yellow_Card + Saves +
                          Red_Card + Min_Played + CS + Shots_On_Target + Goals_Conceded + BPS, data = train)[, -1]
y_train <- train$Points

X_test <- model.matrix(Points ~ Goals_Scored + Assists + Yellow_Card + Saves +
                         Red_Card + Min_Played + CS + Shots_On_Target + Goals_Conceded + BPS, data = test)[, -1]
y_test <- test$Points

cv.ridge <- cv.glmnet(x = X_train, y = y_train, alpha = 1) 
plot(cv.ridge)

cv.ridge$lambda.min 
coef(cv.ridge, s = "lambda.min") 

cv.ridge$lambda.1se 
coef(cv.ridge, s = "lambda.1se") 

lasso<-train(y = y_train,
             x = X_train,
             method = 'glmnet', 
             tuneGrid = expand.grid(alpha = 1, lambda = 0.4233296)
             
) 
# Make the predictions
predictions_lasso <- lasso %>% predict(X_test)

# Print R squared scores
data.frame(
  Ridge_R2 = R2(predictions_lasso, y_test),
  RMSE = RMSE(predictions_lasso, y_test),
  MAE = MAE(predictions_lasso, y_test))

#lambda.min = 0.001164963
#   Ridge_R2      RMSE       MAE
# 0.9802423 0.1417949 0.1002193

#lambda.1se = 0.01086448
# Ridge_R2      RMSE       MAE
# 0.9789929 0.1481825 0.1074939

#NON STANDARDIZED
#LAMBDA MIN = 0.04981793
#Ridge_R2     RMSE      MAE
# 0.9804271 5.451869 3.708066

#LAMBDA.1SE = 0.4233296
#Ridge_R2     RMSE      MAE
# 0.9791799 5.715309 4.019967
#-------------
#CV
train_control <- trainControl(method = "cv",
                              number = 10)
cvmodel <- train(Points ~ Goals_Scored + Assists + Saves + Yellow_Card + 
                   Red_Card + Min_Played + CS + Shots_On_Target + Goals_Conceded + BPS, data = fpl, 
                 method = "glmnet",
                 tuneGrid = expand.grid(alpha = 1, lambda= 0.4233296),
                 trControl = train_control)

print(cvmodel)

#lambda = 1 
#RMSE       Rsquared  MAE      
#0.9973272  NaN       0.8224561

#lambda.min = 0.001164963
#RMSE       Rsquared   MAE       
#0.1284819  0.9834044  0.08918993

#lambda.1se = 0.01086448
#RMSE       Rsquared   MAE       
#0.1355696  0.9829183  0.09574199

train_control <- trainControl(method = "cv",
                              number = 10)
cvmodel <- train(Points ~ Goals_Scored + Assists + Saves + Yellow_Card + 
                   Red_Card + Min_Played + CS + Shots_On_Target + Goals_Conceded + BPS, data = stdfpl, 
                 method = "glmnet",
                 tuneGrid = expand.grid(alpha = 1, lambda= lambda_seq),
                 trControl = train_control)
print(cvmodel)
rm(cvmodel)

#lambda        RMSE       Rsquared   MAE       
#0.01000000  0.1342471  0.9827264  0.09499731

##
## TREE REGRESSOR
##

#Validation set 
fpldt <- rpart(Points ~ Goals_Scored + Assists + Yellow_Card + Saves +
              Red_Card + Min_Played + CS + Shots_On_Target + Goals_Conceded + BPS, data = train)

library(rpart.plot)

# Plot the decision tree
rpart.plot(fpldt, main = "Regression Tree for FPL Points Prediction")
predictdt <- predict(fpldt, test)
data.frame( R2 = R2(predictdt, test$Points),
            RMSE = RMSE(predictdt, test$Points),
            MAE = MAE(predictdt, test$Points))

#      R2     RMSE      MAE
# 0.8706474 13.12517 8.934202
 
#LOOCross-validation 

train_control <- trainControl(method = "LOOCV")
loocvmodel <- train(Points ~ Goals_Scored + Assists + Saves + Yellow_Card + 
                      Red_Card + Min_Played + CS + Shots_On_Target + Goals_Conceded + BPS, data = fpl, 
                    method = "rpart1SE",
                    trControl = train_control)

print(loocvmodel)
rm(loocvmodel)

#  RMSE      Rsquared   MAE     
#12.59517  0.8948064  8.815001

#K-Fold Cv
train_control <- trainControl(method = "cv",
                              number = 10)
cvmodel <- train(Points ~ Goals_Scored + Assists + Saves + Yellow_Card + 
                   Red_Card + Min_Played + CS + Shots_On_Target + Goals_Conceded + BPS, data = fpl, 
                 method = "rpart1SE",
                 trControl = train_control)

print(cvmodel)
rm(cvmodel)

#  RMSE      Rsquared   MAE     
#13.01513  0.8957923  9.067723



##
## Covariance penalties Mallows Cp
##
#https://people.eecs.berkeley.edu/~jordan/sail/readings/archive/efron_Cp.pdf


#linear regression
fpllr <- lm(Points ~ Goals_Scored + Assists + Saves + Yellow_Card +
              Red_Card + Min_Played + CS + Shots_On_Target + Goals_Conceded + BPS, data = train)
#CP mallows

#Ridge regression
ridge<-train(y = y_train,
             x = X_train,
             method = 'glmnet', 
             tuneGrid = expand.grid(alpha = 0, lambda = 6.434233)
             
) 
#Ridge lambda = 6.434233
#Cp mallows

#Lasso
lasso<-train(y = y_train,
             x = X_train,
             method = 'glmnet', 
             tuneGrid = expand.grid(alpha = 1, lambda = 0.4233296))
#lasso lambda = 0.4233296
#Cp mallows


####Combination Bootstrap method

####################################################################################################
####################################################################################################
####################################################################################################

