# Amortization Schedule App

The application performs financial calculations such as:
- Calculation of a amortization schedule (Spitzer) for a loan.
- Calculation of loan recycling with changes in loan setup.

## Start
- First run the ```Init.sql``` file in your MSSQL.
- Open AmortizationScheduleApp in VisualStudio.
- Change connection string to **your data source** in ```MainWindow.xaml.cs``` file:
```c#
string connString = @"data source=DESKTOP-HFSR1GE\MSSQLSERVER01;initial catalog=AmortizationSchedules;integrated security=True";
```
- Run

## Results
![alt text](https://github.com/netanel208/Amortization-Schedule-App/blob/master/images/1.PNG)

- Fill the loan details.
- Then press the ```חשב לוח שפיצר ל12 חודשים``` button.

![alt text](https://github.com/netanel208/Amortization-Schedule-App/blob/master/images/2.PNG)

- After calculating the amortization schedule, the user may press the ```מיחזור חוב לאחר 12 חודשים(ריבית 4.5%)``` button.

![alt text](https://github.com/netanel208/Amortization-Schedule-App/blob/master/images/3.PNG)

![alt text](https://github.com/netanel208/Amortization-Schedule-App/blob/master/images/4.PNG)
