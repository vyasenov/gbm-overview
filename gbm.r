# THIS CODE WAS GENERATED BY CLAUDE 3.5 SONNET ON OCT 30, 2024

# Install and load required packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  tidyverse,
  caret,
  adabag,
  xgboost,
  lightgbm,
  catboost,
  Matrix
)

# Set seed for reproducibility
set.seed(123)

# Load and prepare the iris dataset
data(iris)
iris_shuffled <- iris[sample(nrow(iris)), ]

# Split data into training (80%) and testing (20%) sets
train_index <- createDataPartition(iris_shuffled$Species, p = 0.8, list = FALSE)
train_data <- iris_shuffled[train_index, ]
test_data <- iris_shuffled[-train_index, ]

# Prepare matrices for XGBoost and LightGBM
X_train <- as.matrix(train_data[, 1:4])
y_train <- as.integer(train_data$Species) - 1
X_test <- as.matrix(test_data[, 1:4])
y_test <- as.integer(test_data$Species) - 1

# Function to calculate accuracy
calculate_accuracy <- function(predicted, actual) {
  mean(predicted == actual)
}

# 1. AdaBoost
adaboost_model <- boosting(Species ~ ., data = train_data, boos = TRUE, mfinal = 100)
adaboost_pred <- predict(adaboost_model, test_data)
adaboost_accuracy <- calculate_accuracy(adaboost_pred$class, test_data$Species)

# 2. XGBoost
xgb_train <- xgb.DMatrix(data = X_train, label = y_train)
xgb_test <- xgb.DMatrix(data = X_test, label = y_test)

xgb_params <- list(
  objective = "multi:softmax",
  num_class = 3,
  eta = 0.3,
  max_depth = 6,
  nthread = 2
)

xgboost_model <- xgb.train(
  params = xgb_params,
  data = xgb_train,
  nrounds = 100
)

xgboost_pred <- predict(xgboost_model, xgb_test)
xgboost_accuracy <- calculate_accuracy(xgboost_pred, y_test)

# 3. LightGBM
lgb_train <- lgb.Dataset(X_train, label = y_train)
lgb_test <- lgb.Dataset(X_test, label = y_test)

lgb_params <- list(
  objective = "multiclass",
  num_class = 3,
  learning_rate = 0.1,
  num_leaves = 31,
  metric = "multi_logloss"
)

lightgbm_model <- lgb.train(
  params = lgb_params,
  data = lgb_train,
  nrounds = 100
)

lightgbm_pred <- predict(lightgbm_model, X_test)
lightgbm_pred <- max.col(matrix(lightgbm_pred, ncol = 3, byrow = TRUE)) - 1
lightgbm_accuracy <- calculate_accuracy(lightgbm_pred, y_test)

# 4. CatBoost
train_pool <- catboost.load_pool(X_train, label = y_train)
test_pool <- catboost.load_pool(X_test, label = y_test)

catboost_params <- list(
  iterations = 100,
  learning_rate = 0.1,
  depth = 6,
  loss_function = "MultiClass",
  verbose = FALSE
)

catboost_model <- catboost.train(train_pool, params = catboost_params)
catboost_pred <- catboost.predict(catboost_model, test_pool, prediction_type = "Class")
catboost_accuracy <- calculate_accuracy(catboost_pred, y_test)

# Create comparison table
results_df <- data.frame(
  Model = c("AdaBoost", "XGBoost", "LightGBM", "CatBoost"),
  Accuracy = c(adaboost_accuracy, xgboost_accuracy, lightgbm_accuracy, catboost_accuracy)
)

# Sort results by accuracy in descending order
results_df <- results_df[order(-results_df$Accuracy), ]
results_df$Accuracy <- sprintf("%.4f", results_df$Accuracy)

# Print formatted table
print("Model Performance Comparison:")
print(knitr::kable(results_df, format = "pipe", align = c("l", "r")))