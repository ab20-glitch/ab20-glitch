Create Database CustomerInsightProject;

Use customerinsight;


#1 Distribution of account balance across different regions?
SELECT 
    g.GeographyLocation AS Region,
    COUNT(bc.CustomerId) AS Num_Customers,
    AVG(bc.Balance) AS Avg_Balance
FROM 
    bank_churn bc
JOIN 
    customerinfo ci ON bc.CustomerId = ci.CustomerId
JOIN 
    geography g ON ci.GeographyID = g.GeographyID
GROUP BY 
    g.GeographyLocation;
        
#2 top 5 customers with the highest Estimated Salary in the last quarter of the year
SELECT
    CustomerId,
    Surname,
    EstimatedSalary
FROM
    customerinfo
WHERE
    EXTRACT(MONTH FROM 'Bank DOJ') IN (10, 11, 12)
ORDER BY
    EstimatedSalary DESC
LIMIT 5;    

#3 The average number of products used by customers who have a credit card.
Select avg(bc.NumOfProducts) as AvgNumofProductsWithCreditCard
From bank_churn bc
Join creditcard cc On bc.HasCrCard = cc.CreditID
Where cc.CreditID = 1;

#5 The average credit score of customers who have exited and those who remain.
SELECT
    AVG(CASE WHEN bc.Exited = 1 THEN bc.CreditScore ELSE NULL END) AS AvgCreditScoreExited,
    AVG(CASE WHEN bc.Exited = 0 THEN bc.CreditScore ELSE NULL END) AS AvgCreditScoreRemain
FROM
    bank_churn bc;
    
  #6 Gender with a higher average estimated salary and number of active accounts
SELECT
    g.GenderCategory AS Gender,
    AVG(ci.EstimatedSalary) AS AvgEstimatedSalary,
    COUNT(CASE WHEN bc.IsActiveMember = 1 THEN ci.CustomerId END) AS NumActiveAccounts
FROM
    customerinfo ci
JOIN
    gender g ON ci.GenderID = g.GenderId
JOIN
    bank_churn bc ON ci.CustomerId = bc.CustomerId
GROUP BY
    g.GenderCategory;
    
	#7 Segment the customers based on their credit score and identify the segment with the highest exit rate.
SELECT
    Segment,
    AVG(Exited) AS ExitRate
FROM (
    SELECT
        CASE
            WHEN CreditScore BETWEEN 800 AND 850 THEN 'Excellent'
            WHEN CreditScore BETWEEN 740 AND 799 THEN 'Very Good'
            WHEN CreditScore BETWEEN 670 AND 739 THEN 'Good'
            WHEN CreditScore BETWEEN 580 AND 669 THEN 'Fair'
            WHEN CreditScore BETWEEN 300 AND 579 THEN 'Poor'
            ELSE 'Unknown'
        END AS Segment,
        Exited
    FROM
        bank_churn
) AS SegmentedCustomers
GROUP BY
    Segment
ORDER BY
    ExitRate DESC;
    
    
   #8 Geographic region with the highest number of active customers with a tenure greater than 5 years.
SELECT
    g.GeographyLocation AS Region,
    COUNT(DISTINCT ci.CustomerId) AS NumActiveCustomers
FROM
    geography g
JOIN
    customerinfo ci ON g.GeographyID = ci.GeographyID
JOIN
    bank_churn bc ON ci.CustomerId = bc.CustomerId
WHERE
    bc.Tenure > 5
    AND bc.IsActiveMember = 1
GROUP BY
    g.GeographyLocation
ORDER BY
    NumActiveCustomers DESC
    Limit 1;

#9 Impact of having a credit card on customer churn, based on the available data
SELECT
    Category,
    AVG(Exited) AS ChurnRate
FROM
    bank_churn
GROUP BY
    HasCrCard;
    
  #10 Most common number of products used by customers who have exited
SELECT
    NumOfProducts,
    COUNT(*) AS NumExitedCustomers
FROM
    bank_churn
WHERE
    Exited = 1
GROUP BY
    NumOfProducts
ORDER BY
    COUNT(*) DESC
LIMIT 1;

#12 The relationship between the number of products and the account balance for customers who have exited.
SELECT
    NumOfProducts,
    AVG(Balance) AS AvgAccountBalance,
    COUNT(*) AS NumCustomersExited
FROM
    bank_churn
WHERE
    Exited = 1
GROUP BY
    NumOfProducts
ORDER BY
    NumOfProducts;

#15 Gender wise average income of male and female in each geography id alongwith the rank the according to the average value. 
SELECT
    ci.GeographyID,
    g.GenderCategory AS Gender,
    AVG(ci.EstimatedSalary) AS AvgIncome,
    DENSE_RANK() OVER (PARTITION BY ci.GeographyID ORDER BY AVG(ci.EstimatedSalary) DESC) AS GenderRank
FROM
    customerinfo ci
JOIN
    gender g ON ci.GenderID = g.GenderId
GROUP BY
    ci.GeographyID,
    g.GenderCategory;
    
   #16 The average tenure of the people who have exited in each age bracket (18-30, 30-50, 50+)
SELECT
    CASE
        WHEN ci.Age BETWEEN 18 AND 30 THEN '18-30'
        WHEN ci.Age BETWEEN 31 AND 50 THEN '31-50'
        ELSE '50+'
    END AS AgeBracket,
    AVG(bc.Tenure) AS AvgTenure
FROM
    bank_churn bc
JOIN
    customerinfo ci ON bc.CustomerId = ci.CustomerId
WHERE
    bc.Exited = 1
GROUP BY
    CASE
        WHEN ci.Age BETWEEN 18 AND 30 THEN '18-30'
        WHEN ci.Age BETWEEN 31 AND 50 THEN '31-50'
        ELSE '50+'
    END;
    
    #19 Rank each bucket of credit score as per the number of customers who have churned the bank.
    SELECT
    CASE
        WHEN CreditScore BETWEEN 300 AND 579 THEN 'Poor'
        WHEN CreditScore BETWEEN 580 AND 669 THEN 'Fair'
        WHEN CreditScore BETWEEN 670 AND 739 THEN 'Good'
        WHEN CreditScore BETWEEN 740 AND 799 THEN 'Very Good'
        WHEN CreditScore BETWEEN 800 AND 850 THEN 'Excellent'
    END AS CreditScoreBucket,
    COUNT(CASE WHEN Exited = 1 THEN 1 END) AS ChurnedCustomers,
    DENSE_RANK() OVER (ORDER BY COUNT(CASE WHEN Exited = 1 THEN 1 END) DESC) AS BucketRank
FROM
    bank_churn
GROUP BY
    CreditScoreBucket;

#20 According to the age buckets find the number of customers who have a credit card. Also retrieve those buckets who have lesser than average number of credit cards per bucket.
WITH CreditCardCounts AS (
    SELECT
        ci.AgeBucket,
        COUNT(DISTINCT bc.CustomerId) AS NumCustomers,
        SUM(cc.Category) AS NumCreditCardHolders
    FROM
        customerinfo ci
    LEFT JOIN
        bank_churn bc ON ci.CustomerId = bc.CustomerId
    LEFT JOIN
        creditcard cc ON bc.HasCrCard = cc.CreditID
    GROUP BY
        ci.AgeBucket
),
AverageCreditCards AS (
    SELECT
        AVG(NumCreditCardHolders) AS AvgCreditCards
    FROM
        CreditCardCounts
)
SELECT
    ccc.AgeBucket,
    ccc.NumCustomers,
    ccc.NumCreditCardHolders
FROM
    CreditCardCounts ccc
JOIN
    AverageCreditCards acc ON  ccc.NumCreditCardHolders < acc.AvgCreditCards


    
    #21 Rank the Locations as per the number of people who have churned the bank and average balance of the learners
   WITH ChurnedCustomersByLocation AS (
    SELECT
        g.GeographyLocation,
        COUNT(CASE WHEN c.Exited = 1 THEN 1 END) AS ChurnedCustomers,
        AVG(c.Balance) AS AverageBalance
    FROM
        bank_churn c
    INNER JOIN
        customerinfo b ON c.CustomerId = b.CustomerId
    INNER JOIN
        geography g ON b.GeographyID = g.GeographyID
    GROUP BY
        g.GeographyLocation
)
SELECT
    GeographyLocation,
    ChurnedCustomers,
    AverageBalance,
    DENSE_RANK() OVER (ORDER BY ChurnedCustomers DESC) AS ChurnRank,
    DENSE_RANK() OVER (ORDER BY AverageBalance DESC) AS BalanceRank
FROM
    ChurnedCustomersByLocation;
    
#22 As we can see that the “CustomerInfo” table has the CustomerID and Surname, now if we have to join it with a table where the primary key is also a combination of CustomerID and Surname, come up with a column where the format is “CustomerID_Surname”
 SELECT 
    CustomerId,
    Surname,
    CONCAT(CustomerID, '_', Surname) CustomerID_Surname,
    Age,
    GenderID,
    EstimatedSalary,
    GeographyID,
    DOJ
FROM
    customerinfo;
   
    
    #Subjective Question
#9 Segment customers based on demographics and account details
SELECT 
    g.GeographyLocation AS Region,
    COUNT(bc.CustomerId) AS Num_Customers,
    AVG(bc.Balance) AS Avg_Balance
FROM 
    bank_churn bc
JOIN 
    customerinfo ci ON bc.CustomerId = ci.CustomerId
JOIN 
    geography g ON ci.GeographyID = g.GeographyID
GROUP BY 
    g.GeographyLocation;

#14 In the “Bank_Churn” table how can you modify the name of the “HasCrCard” column to “Has_creditcard”?
ALTER TABLE Bank_Churn
CHANGE COLUMN HasCrCard Has_creditcard INT;

#To return back to original column name
ALTER TABLE Bank_Churn
CHANGE COLUMN Has_creditcard HasCrCard INT; 

























