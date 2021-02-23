using System;
using System.Collections.Generic;
using System.Text;

namespace AmortizationScheduleApp
{
    public class Row
    {
        public Double Priod { get; set; }
        public Double PaymentAmount { get; set; }
        public Double PrincipalPaymentAmount { get; set; }
        public Double InterestPaymentAmount { get; set; }
    }
}
