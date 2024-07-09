library(ggplot2)
library(mosaic)
library(dplyr)

food <- read.csv("data/fastfood_calories.csv")


################ One Mean CI for avg chicken calories

# Filter the dataset for items that include "chicken" in their name (case-insensitive)
chicken_items <- food %>% 
  filter(grepl("chicken sandwich", item, ignore.case = TRUE))

# Normality Assumption Check using a histogram and Q-Q plot
hist(chicken_items$calories, main="Histogram of Chicken Item Calories", xlab="Calories")
qqnorm(chicken_items$calories)
qqline(chicken_items$calories)

# You could also use the Shapiro-Wilk test for normality
shapiro_test <- shapiro.test(chicken_items$calories)
print(shapiro_test)

# Outliers Check with a Boxplot
boxplot(chicken_items$calories, main="Boxplot of Chicken Item Calories", horizontal=TRUE)

# Homogeneity of variance test if comparing two or more groups (not needed for one-sample test)
# Bartlett’s test in case of equal sample sizes and Levene's test for unequal sample sizes can be used
# bartlett_test <- bartlett.test(calories ~ restaurant, data=chicken_items)
# print(bartlett_test)

# Calculate the sample mean and standard deviation of the calories
mean_calories <- mean(chicken_items$calories)
sd_calories <- sd(chicken_items$calories)
n <- nrow(chicken_items) # sample size

# Calculate the critical t-value for a 95% confidence interval
# You may need to adjust 'df' if your sample size is not large
alpha <- 0.05
df <- n - 1
t_critical <- qt(alpha / 2, df, lower.tail = FALSE)

# Calculate the standard error
se <- sd_calories / sqrt(n)
t_critical*se
# Calculate the confidence interval
ci_lower <- mean_calories - t_critical * se
ci_upper <- mean_calories + t_critical * se

# Display the confidence interval
ci <- c(ci_lower, ci_upper)
print(ci)

############################## one proportion fat content across all restaurants
# Calculate the number of items exceeding 1500mg of sodium
high_sodium_count <- sum(food$sodium > 1500)
# Total number of items
total_items <- nrow(food)
# Perform a binomial test to get the confidence interval
binom_test <- binom.test(high_sodium_count, total_items, conf.level = 0.95)
print(binom_test)
# The confidence interval is stored in binom_test$conf.int

total_items <- nrow(food)
p_hat <- high_sodium_count / total_items

# Set the confidence level
conf_level <- 0.95
alpha <- 1 - conf_level

# Find the z critical value
z_alpha_2 <- qnorm(1 - alpha / 2)

# Calculate the standard error
se <- sqrt(p_hat * (1 - p_hat) / total_items)

# Calculate the margin of error
me <- z_alpha_2 * se

# Calculate the confidence interval
ci_lower <- p_hat - me
ci_upper <- p_hat + me

# Output the confidence interval
ci <- c(ci_lower, ci_upper)
names(ci) <- c("Lower Bound", "Upper Bound")
ci

############################ one median
# Load the dataset
food <- read.csv("data/fastfood_calories.csv")
# We're interested in dietary fiber, so we'll focus on that column
fiber <- food$fiber
wilcox.test(fiber,conf.int=TRUE)

# Sort the dietary fiber data to get the order statistics
sorted_fiber <- sort(fiber)

# Find the sample size
n <- length(fiber)

# For a 95% confidence interval, our alpha is 0.05
alpha <- 0.05

# Now we find the lower and upper bounds of our confidence interval
# For the binomial distribution with p=0.5, we use the qbinom function for quantiles
lower_binom <- qbinom(alpha / 2, n, 0.5)
upper_binom <- qbinom(1 - alpha / 2, n, 0.5) + 1 # +1 because R is 1-indexed and the binom test is exclusive

# Get the lower and upper fiber values that correspond to these binomial quantiles
# We handle cases where lower_binom or upper_binom are 0 or n+1
lower_fiber <- ifelse(lower_binom >= 1, sorted_fiber[lower_binom], min(sorted_fiber))
upper_fiber <- ifelse(upper_binom <= n, sorted_fiber[upper_binom], max(sorted_fiber))

# Display the confidence interval for the median dietary fiber content
fiber_ci <- c(lower_fiber, upper_fiber)
names(fiber_ci) <- c("Lower Bound", "Upper Bound")
fiber_ci


# Assuming 'food' is already loaded with the data
# Extract the fiber content
fiber <- food$fiber

# Calculate the sample size
n <- length(fiber)

# Probability of success for median
p <- 0.5

# Check the conditions for normal approximation
np <- n * p
nq <- n * (1 - p) # q is 1 - p

# Ensure that both np and n(1-p) are at least 5
if (np >= 5 && nq >= 5) {
  # Proceed with normal approximation
  
  # Calculate the z critical value for a 90% confidence interval
  alpha <- 0.10 # 1 - 0.90
  z_alpha_2 <- qnorm(1 - alpha / 2)
  
  # Since the binomial is symmetric around n/2 for p = 0.5, the mean μ = n/2
  mu <- np
  
  # The standard deviation σ of the binomial distribution
  sigma <- sqrt(n * p * (1 - p))
  
  # Calculate the normal approximation to the binomial
  lower_bound <- mu - z_alpha_2 * sigma
  upper_bound <- mu + z_alpha_2 * sigma
  
  # Apply continuity correction by subtracting and adding 0.5 from the bounds
  lower_bound <- lower_bound - 0.5
  upper_bound <- upper_bound + 0.5
  
  # Convert these bounds to ranks and get the corresponding fiber content
  # Ensure the bounds are within the range of ranks
  lower_rank <- max(1, ceiling(lower_bound))
  upper_rank <- min(n, floor(upper_bound))
  
  # Get the confidence interval for the fiber content
  ci_lower <- fiber[order(fiber)][lower_rank]
  ci_upper <- fiber[order(fiber)][upper_rank]
  
  cat("90% CI for the median fiber content (using normal approximation):", ci_lower, "to", ci_upper, "grams\n")
  
} else {
  cat("Normal approximation conditions not met: np =", np, "and n(1-p) =", nq, "\n")
}

########################## paired data
food2 <- read.csv("data/ms_annual_data_2022Sheet1.csv")
head(food2)

# Filter for cheeseburgers in the item_description from Carl's Jr and Wendy's
cheeseburgers <- food2[grepl("cheeseburger", food2$item_description, ignore.case = TRUE) &
                         (food2$restaurant == "Carls Jr" | food2$restaurant == "Wendy's"),]

# Calculate the healthiness index (protein / total fat) for each cheeseburger
cheeseburgers$healthiness_index <- as.numeric(cheeseburgers$protein) / as.numeric(cheeseburgers$total_fat)

# Separate the data for Carl's Jr and Wendy's
carls_jr_data <- cheeseburgers[cheeseburgers$restaurant == "Carls Jr",]
wendys_data <- cheeseburgers[cheeseburgers$restaurant == "Wendy's",]

# Ensure data is suitable for a t-test; if not enough data points, consider another statistical approach
if(nrow(carls_jr_data) > 1 & nrow(wendys_data) > 1) {
  # Perform a t-test to compare the means between the two groups and find the confidence interval
  t_test_result <- t.test(carls_jr_data$healthiness_index, wendys_data$healthiness_index, var.equal = FALSE)
  
  # Print the confidence interval from the t-test result
  print(t_test_result$conf.int)
} else {
  print("Not enough data points for a t-test. Consider gathering more data or using a different statistical approach.")
}
#Confidence Interval: The interval [-0.1411460, 0.1046707] suggests that, with 95% confidence, the true difference in the average healthiness index between cheeseburgers from Carl's Jr and Wendy's lies within this range.
#Negative to Positive Range: Since the confidence interval includes both negative and positive values, it indicates that the data does not provide strong evidence to conclude that one restaurant's cheeseburgers are definitively healthier (according to the healthiness index) than the other's. In statistical terms, the confidence interval includes 0, suggesting there isn't a statistically significant difference in the healthiness index between the two sets of cheeseburgers at the 95% confidence level.
#No Clear Winner: The overlap around zero means we cannot say for sure that the healthiness index is higher for cheeseburgers from Carl's Jr compared to Wendy's, or vice versa, based on this sample. The data does not strongly support the claim that one restaurant's cheeseburgers have a better protein to fat ratio than the other's.

#################### Paired data but separate:
# Load the dataset
food2 <- read.csv("data/ms_annual_data_2022Sheet1.csv")

# Identify non-numeric entries in the protein column
non_numeric_protein <- grep("[^0-9.]", food2$protein)

# If you want to see the problematic entries
if(length(non_numeric_protein) > 0) {
  print(food2$protein[non_numeric_protein])
}

# One approach is to set these problematic entries to NA and then omit them
food2$protein[non_numeric_protein] <- NA

# Ensure that the protein and total fat columns are numeric and handle any NAs
food2$protein <- as.numeric(as.character(food2$protein))
food2$total_fat <- as.numeric(as.character(food2$total_fat))

# Filter for cheeseburgers from Carl's Jr and Wendy's, omitting NA values
cheeseburgers <- subset(food2, grepl("cheeseburger", item_description, ignore.case = TRUE) &
                          (restaurant %in% c("Carls Jr", "Wendy's")) &
                          !is.na(protein) & !is.na(total_fat))

# Calculate the healthiness index (protein / total fat) for each cheeseburger
cheeseburgers$healthiness_index <- with(cheeseburgers, protein / total_fat)

# Separate the data for Carl's Jr and Wendy's
carls_jr_data <- subset(cheeseburgers, restaurant == "Carls Jr")
wendys_data <- subset(cheeseburgers, restaurant == "Wendy's")

# Calculate pooled variance
n1 <- nrow(carls_jr_data)
n2 <- nrow(wendys_data)
var1 <- var(carls_jr_data$healthiness_index)
var2 <- var(wendys_data$healthiness_index)

# Check if both variances are numbers and not NA
if(!is.na(var1) && !is.na(var2) && n1 > 1 && n2 > 1) {
  sp_squared <- ((n1 - 1) * var1 + (n2 - 1) * var2) / (n1 + n2 - 2)
  
  # Calculate the standard error and degrees of freedom
  se_difference <- sqrt(sp_squared * (1/n1 + 1/n2))
  df <- n1 + n2 - 2
  
  # Calculate the t critical value for a 95% CI
  alpha <- 0.05
  t_critical <- qt(1 - alpha/2, df)
  
  # Calculate the confidence interval
  mean_difference <- mean(carls_jr_data$healthiness_index) - mean(wendys_data$healthiness_index)
  ci_lower <- mean_difference - t_critical * se_difference
  ci_upper <- mean_difference + t_critical * se_difference
  
  # Output all relevant values
  cat("Sample sizes: n1 =", n1, ", n2 =", n2, "\n")
  cat("Sample means: mean1 =", mean(carls_jr_data$healthiness_index), ", mean2 =", mean(wendys_data$healthiness_index), "\n")
  cat("Pooled variance (S^2_p) =", sp_squared, "\n")
  cat("Standard error of the difference =", se_difference, "\n")
  cat("Degrees of freedom (df) =", df, "\n")
  cat("Confidence interval: [", ci_lower, ",", ci_upper, "]\n")
} else {
  cat("Variance calculation error: Ensure you have more than one observation for each restaurant and that there are no NA values.\n")
}

##################paired 2021 and 2022
food2021 <- read.csv("data/menustat_2021_dataset_1.csv")
food2022 <- read.csv("data/ms_annual_data_2022Sheet1.csv")

# Filter for Wendy's burgers in both datasets
wendys_burgers_2021 <- subset(food2021, grepl("Burgers", food_category, ignore.case = TRUE) & restaurant == "Wendy's")
wendys_burgers_2022 <- subset(food2022, grepl("Burgers", food_category, ignore.case = TRUE) & restaurant == "Wendy's")

wendys_burgers_2021$protein <- as.numeric(as.character(wendys_burgers_2021$protein))
wendys_burgers_2021$total_fat <- as.numeric(as.character(wendys_burgers_2021$total_fat))

wendys_burgers_2022$protein <- as.numeric(as.character(wendys_burgers_2022$protein))
wendys_burgers_2022$total_fat <- as.numeric(as.character(wendys_burgers_2022$total_fat))


# Calculate the healthiness index for Wendy's burgers for both years
wendys_burgers_2021$healthiness_index <- wendys_burgers_2021$protein / wendys_burgers_2021$total_fat
wendys_burgers_2022$healthiness_index <- wendys_burgers_2022$protein / wendys_burgers_2022$total_fat

# Merge the 2021 and 2022 data on 'menu_item_id' to find common burgers
paired_wendys_burgers <- merge(
  wendys_burgers_2021[, c('menu_item_id', 'healthiness_index')],
  wendys_burgers_2022[, c('menu_item_id', 'healthiness_index')],
  by = 'menu_item_id',
  suffixes = c("_2021", "_2022")
)

# Clean NA values due to division by zero or missing values
paired_wendys_burgers <- na.omit(paired_wendys_burgers)

# Calculate the difference in healthiness index between the two years
paired_wendys_burgers$healthiness_index_diff <- paired_wendys_burgers$healthiness_index_2022 - paired_wendys_burgers$healthiness_index_2021

# Perform a paired t-test
t_test_result <- t.test(paired_wendys_burgers$healthiness_index_2021, paired_wendys_burgers$healthiness_index_2022, paired = TRUE)

# Calculate the mean difference
mean_difference <- mean(paired_wendys_burgers$healthiness_index_diff)

# Calculate the 95% confidence interval for the mean difference
conf_int <- t_test_result$conf.int

# Output the confidence interval
conf_int

#################SLR and slope
food2 <- read.csv("data/ms_annual_data_2022Sheet1.csv")
non_numeric_carb <- grep("[^0-9.]", food2$carbohydrates)
non_numeric_sugar <- grep("[^0-9.]", food2$sugar)

food2$carbohydrates[non_numeric_carb] <- NA
food2$sugar[non_numeric_sugar] <- NA

clean_food2 <- na.omit(food2[, c("carbohydrates", "sugar")])

food2$carbohydrates <- as.numeric(as.character(food2$carbohydrates))
food2$sugar <- as.numeric(as.character(food2$sugar))

# Fit a linear model to explore the relationship between carbohydrates and sugar
model <- lm(sugar ~ carbohydrates, data = food2)

# Summary of the model to view coefficients, R-squared, etc.
summary(model)

# Calculate the 95% confidence interval for the slope (carbohydrates coefficient)
confint(model, "carbohydrates", level = 0.95)

# Plotting the regression line
ggplot(food2, aes(x = carbohydrates, y = sugar)) +
  geom_point(alpha = 0.5) +  # Scatterplot with slightly transparent points
  geom_smooth(method = "lm", se = TRUE, color = "blue") + # Add regression line with confidence interval
  labs(x = "Carbohydrates", y = "Sugar", title = "SLR of Sugar on Carbohydrates")

#The positive correlation between carbohydrates and sugars suggests that many fast food items may contain high levels of added sugars, contributing significantly to their total carbohydrate content. High intake of added sugars is linked to various health issues, including obesity, type 2 diabetes, and cardiovascular disease, due to their calorie-dense yet nutritionally poor nature.

################################# Monte Carlo Simulatoions:

#####One mean:
set.seed(123) # For reproducibility
true_mean <- 542.25
true_sd <- 305.96
sample_size <- 178
alpha <- 0.05
num_simulations <- 10000
coverage_count <- 0

for(i in 1:num_simulations) {
  # Generate a random sample from the normal distribution
  sample <- rnorm(sample_size, mean = true_mean, sd = true_sd)
  
  # Calculate the sample mean and standard deviation
  sample_mean <- mean(sample)
  sample_sd <- sd(sample)
  
  # Calculate the t critical value
  t_critical <- qt(1 - alpha/2, df = sample_size - 1)
  
  # Calculate the confidence interval
  ci_lower <- sample_mean - t_critical * (sample_sd / sqrt(sample_size))
  ci_upper <- sample_mean + t_critical * (sample_sd / sqrt(sample_size))
  
  # Check if the true mean is within the confidence interval
  if(true_mean >= ci_lower && true_mean <= ci_upper) {
    coverage_count <- coverage_count + 1
  }
}

# Estimate the coverage probability
coverage_probability <- coverage_count / num_simulations
coverage_probability

standard_error <- sqrt(coverage_probability * (1 - coverage_probability) / num_simulations)
print(standard_error)


# source: https://www.lri.fr/~fanis/courses/Stats2019/lectures/lecture3.pdf
#http://www.faculty.ucr.edu/~jflegal/Final_Thesis_twosided.pdf


################## Monte Carlo for one-proportion
set.seed(12)  # For reproducibility
p <- p_hat  # True proportion
n <- 515  # Sample size
alpha <- 0.05  # Significance level
z_alpha_2 <- qnorm(1 - alpha / 2)  # Critical z value for two-tailed test
num_simulations <- 10000  # Number of simulations
coverage_count <- 0  # Initialize counter for coverage

for (i in 1:num_simulations) {
  # Simulate a binomial experiment
  successes <- rbinom(1, n, p)
  # Calculate sample proportion
  p_hat <- successes / n
  # Calculate standard error
  se_hat <- sqrt(p_hat * (1 - p_hat) / n)
  # Calculate confidence interval
  ci_lower <- p_hat - z_alpha_2 * se_hat
  ci_upper <- p_hat + z_alpha_2 * se_hat
  
  # Check if the true proportion is within the confidence interval
  if (p >= ci_lower && p <= ci_upper) {
    coverage_count <- coverage_count + 1
  }
}

# Estimate the coverage probability
coverage_probability <- coverage_count / num_simulations
coverage_probability
standard_error <- sqrt(coverage_probability * (1 - coverage_probability) / num_simulations)
print(standard_error)
