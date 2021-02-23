using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace AmortizationScheduleApp
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public List<Row> parts;

        public MainWindow()
        {
            InitializeComponent();
        }

        private void SpitzerCalc_Click(object sender, RoutedEventArgs e)
        {
            if (string.IsNullOrEmpty(LoanAmount.Text))
            {
                MessageBox.Show("סכום ההלוואה הינו שדה חובה");
                return;
            }
            else if (string.IsNullOrEmpty(LoanPeriod.Text))
            {
                MessageBox.Show("תקופת ההלוואה הינה שדה חובה");
                return;
            }
            else if (string.IsNullOrEmpty(Interest.Text))
            {
                MessageBox.Show("ריבית הינה שדה חובה");
                return;
            }

            if (string.IsNullOrEmpty(Prime.Text))
            {
                Prime.Text = "0";
            }
            try
            {
                float pv = float.Parse(LoanAmount.Text);
                float rate = float.Parse(Interest.Text) + float.Parse(Prime.Text);
                int periods = int.Parse(LoanPeriod.Text);
                int top = 12;
                ExecuteStoredProcedure(pv, rate, periods, top);
                dataGridView.ItemsSource = parts;
                dataGridView.AutoGenerateColumns = true;
                if (parts.Count > 11)
                {
                    LoanRecycleCalc.IsEnabled = true;
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
            }
        }

        private void LoanRecycleCalc_Click(object sender, RoutedEventArgs e)
        {
            if (parts.Count > 11)
            {
                double pv = double.Parse(LoanAmount.Text);
                double principalPaymentsum = 0;
                for (int i = 0; i < 12; i++)
                {
                    principalPaymentsum += parts[i].PrincipalPaymentAmount;
                }
                float newPv = (float)((float)pv - principalPaymentsum);
                float newRate = 4.5f;
                int newPeriods = 48;
                int top = 48;
                ExecuteStoredProcedure(newPv, newRate, newPeriods, top);
                dataGridView.ItemsSource = parts;
                dataGridView.AutoGenerateColumns = true;
                LoanRecycleCalc.IsEnabled = false;
            }
        }

        private void ExecuteStoredProcedure(float pv, float rate, int periods, int top)
        {
            string connString = @"data source=DESKTOP-HFSR1GE\MSSQLSERVER01;initial catalog=AmortizationSchedules;integrated security=True";

            try
            {
                parts = new List<Row>();
                //sql connection object
                using (SqlConnection conn = new SqlConnection(connString))
                {

                    //set stored procedure name
                    string spName = @"dbo.[SelectSpitzerTable]";

                    //define the SqlCommand object
                    SqlCommand cmd = new SqlCommand(spName, conn);

                    SqlParameter param1 = new SqlParameter();
                    param1.ParameterName = "@PV";
                    param1.SqlDbType = SqlDbType.Float;
                    param1.Value = pv;

                    SqlParameter param2 = new SqlParameter();
                    param2.ParameterName = "@Rate";
                    param2.SqlDbType = SqlDbType.Float;
                    param2.Value = rate / 100;

                    SqlParameter param3 = new SqlParameter();
                    param3.ParameterName = "@Periods";
                    param3.SqlDbType = SqlDbType.Int;
                    param3.Value = periods;

                    SqlParameter param4 = new SqlParameter();
                    param4.ParameterName = "@Top";
                    param4.SqlDbType = SqlDbType.Int;
                    param4.Value = top;

                    //add the parameter to the SqlCommand object
                    cmd.Parameters.Add(param1);
                    cmd.Parameters.Add(param2);
                    cmd.Parameters.Add(param3);
                    cmd.Parameters.Add(param4);

                    //open connection
                    conn.Open();

                    //set the SQLCommand type to StoredProcedure
                    cmd.CommandType = CommandType.StoredProcedure;

                    //execute the stored procedure                   
                    SqlDataReader dr = cmd.ExecuteReader();

                    //check if there are records
                    if (dr.HasRows)
                    {
                        while (dr.Read())
                        {
                            parts.Add(new Row()
                            {
                                Priod = dr.GetDouble(0),
                                PaymentAmount = dr.GetDouble(1),
                                PrincipalPaymentAmount = dr.GetDouble(2),
                                InterestPaymentAmount = dr.GetDouble(3)
                            });
                        }
                    }
                    else
                    {
                        MessageBox.Show("No data found!");
                    }

                    //close data reader
                    dr.Close();

                    //close connection
                    conn.Close();
                }
            }
            catch (Exception ex)
            {
                //display error message
                MessageBox.Show("Exception: " + ex.Message);
            }

        }
    }
}
