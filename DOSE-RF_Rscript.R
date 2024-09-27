# ************************************************************************
#                DOSE-RF Code, Mollie Payne, 18/09/2024                  
# ************************************************************************

# Load necessary libraries
library(randomForest)
library(ggplot2)
library(coefplot)

# ************************************************************************
# Step One: Load Your Dataset  
# ************************************************************************

# Set the file destination and load the dataset
data <- read.csv("dataset.csv")  # Load dataset

# ************************************************************************
# Step Two: Specify your variables
# ************************************************************************

y <- ""  # One outcome (continuous)
x_r <- c()  # List of variables that predict dosehat
x_y <- c()  # List of variables for outcome model
s <- ""  # Variable that indicates session attendance
d <- ""  # Treatment Variable

table(data[[s]])  # Display session counts

m <- max(data[[s]], na.rm = TRUE)  # Maximum number of sessions

# ************************************************************************
# Step Three: Random Forest
# ************************************************************************

# Define Random Forest model with appropriate settings
# Numvars should be the square root of the number of variables in x_r
rf_model <- randomForest(as.factor(data[[s]]) ~ ., data = data[data[[d]] == 1, x_r], 
                         ntree = 200, mtry = 5)  # Number of trees: 200, mtry: sqrt(num predictors)

# Predict dosehat
data$dosehat <- predict(rf_model)

# ************************************************************************
# Step Four: Set up matrix
# ************************************************************************

# Create a matrix to store results
result <- matrix(NA, nrow = 3, ncol = m)
rownames(result) <- c("beta", "ll95", "ul95")
colnames(result) <- as.character(1:m)

# ************************************************************************
# Step Five: Run analysis.
# ************************************************************************

# Loop through the regressions for each session
for (i in 1:m) {
  
  # Filter rows where dosehat equals the session number
  session_data <- data[data$dosehat == i, ]
  
  # Check if sufficient data exists for the session
  if (nrow(session_data) > 1) {
    
    # Run the regression
    model <- lm(as.formula(paste(y, "~", d, "+", paste(x_y, collapse = "+"))), data = session_data)
    
    # Store the coefficient for treatment variable d
    result[1, i] <- coef(model)[d]
    
    # Compute and store the lower and upper 95% confidence intervals
    se <- summary(model)$coefficients[d, "Std. Error"]
    result[2, i] <- coef(model)[d] - 1.96 * se
    result[3, i] <- coef(model)[d] + 1.96 * se
    
  } else {
    # Insufficient observations, store missing values
    result[1, i] <- NA
    result[2, i] <- NA
    result[3, i] <- NA
  }
}

# Display the result matrix
print(result)

# ************************************************************************
# Step Six: View results in graph. 
# ************************************************************************

# Create a data frame for plotting
plot_data <- data.frame(
  Session = as.numeric(colnames(result)),
  Beta = result[1, ],
  LL95 = result[2, ],
  UL95 = result[3, ]
)

# Plot the results
ggplot(plot_data, aes(x = Session, y = Beta)) +
  geom_point() +
  geom_errorbar(aes(ymin = LL95, ymax = UL95), width = 0.2) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  scale_y_continuous(breaks = seq(-6, 1, 1)) +
  labs(y = "Treatment Effect", x = "Session", 
       title = "Causal Treatment Effect at Each Session") +
  theme_minimal()

# ************************************************************************
# End of File :)
