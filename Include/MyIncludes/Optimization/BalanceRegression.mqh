//+------------------------------------------------------------------+
//|                                            BalanceRegression.mqh |
//|                              Copyright © 2017, Vladimir Karputov |
//|                                           http://wmua.ru/slesar/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2017, Vladimir Karputov"
#property link      "http://wmua.ru/slesar/"
#property version   "1.000"
#include <Math\Alglib\alglib.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CBalanceRegression
  {
private:
   double            m_start_balance;                             // Start balance
   datetime          m_from_date;                                 // Start date
   bool              m_volume_norm;                               // volume normalization
   double            m_profit_stability;                          // Profit stability

public:
                     CBalanceRegression();
                    ~CBalanceRegression();
   //---
   void              SetStartBalance(const double start_balance)     { m_start_balance=start_balance; }
   void              SetFromDate(const datetime from_date)           { m_from_date=from_date;         }
   void              SetVolumeNormalization(const bool volume_norm)  { m_volume_norm=volume_norm;     }
   //---
   double            GetProfitStability(const datetime to_date);

protected:
   double            GetSetStartBalance(void) const                  { return(m_start_balance);       }
   bool              GetVolumeNormalization(void) const              { return(m_volume_norm);         }
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CBalanceRegression::CBalanceRegression(void) : m_start_balance(10000),
                                               m_from_date(0),
                                               m_volume_norm(true),
                                               m_profit_stability(0.0)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CBalanceRegression::~CBalanceRegression(void)
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CBalanceRegression::GetProfitStability(const datetime to_date)
  {
//---
   double   arr_profits[];                            // array of results deals 
   double   total_volume=0;                           // total volume
//--- request trade history 
   HistorySelect(m_from_date,to_date);
   uint total_deals=HistoryDealsTotal();
   ulong ticket_history_deal=0;
//--- for all deals 
   for(uint i=0;i<total_deals;i++)
     {
      //--- try to get deals ticket_history_deal 
      if((ticket_history_deal=HistoryDealGetTicket(i))>0)
        {
         long     deal_type         =HistoryDealGetInteger(ticket_history_deal,DEAL_TYPE);
         double   deal_volume       =HistoryDealGetDouble(ticket_history_deal,DEAL_VOLUME);
         double   deal_commission   =HistoryDealGetDouble(ticket_history_deal,DEAL_COMMISSION);
         double   deal_swap         =HistoryDealGetDouble(ticket_history_deal,DEAL_SWAP);
         double   deal_profit       =HistoryDealGetDouble(ticket_history_deal,DEAL_PROFIT);

         if(deal_type!=DEAL_TYPE_BUY && deal_type!=DEAL_TYPE_SELL)
            continue;

         if(deal_commission==0.0 && deal_swap==0.0 && deal_profit==0.0)
            continue;

         total_volume+=deal_volume;

         int arr_size=ArraySize(arr_profits);
         ArrayResize(arr_profits,arr_size+1,50);   // resize the aray

         if(arr_size==0)
            arr_profits[arr_size]=GetSetStartBalance()+deal_commission+deal_swap+deal_profit;
         else
            arr_profits[arr_size]=arr_profits[arr_size-1]+deal_commission+deal_swap+deal_profit;

         int d=0;
        }
     }
//--- synchronization of two arrays
   int arr_size=ArraySize(arr_profits);
   if(arr_size==0)
      return(0.0);
//--- CMatrixDouble object
   CMatrixDouble xy(arr_size,2);
   for(int i=0;i<arr_size;i++)
     {
      xy[i].Set(0,i+1);
      xy[i].Set(1,arr_profits[i]);
      //Print(arr_profits[i]); // for debag
     }
//--- linear regression construction
   CLinReg        linear_regression;
   CLinearModel   linear_model;
   CLRReport      linear_report;
   int retcode;
   linear_regression.LRBuild(xy,arr_size,1,retcode,linear_model,linear_report);
   if(retcode!=1)
     {
      Print("Linear regression failed, error code=",retcode);
      return(0.0);
     }
   int nvars;
   double coefficients[];
   linear_regression.LRUnpack(linear_model,coefficients,nvars);
   double coeff_a=coefficients[0];
   double coeff_b=coefficients[1];
   //PrintFormat("y = %.1f x + %.1f",coeff_a,coeff_b);
//--- сalculation of parameters
   double TrendProfit=((double)arr_size*coeff_a+coeff_b)-(1.0*coeff_a+coeff_b);  // the projection of the regression line on the "Y" axis 
   TrendProfit/=(double)arr_size;                                                // divided by the number of trades
   double TrendMSE=linear_report.m_rmserror;                                     // root mean square error on a training set
   double ProfitStability=TrendProfit/TrendMSE;
//--- normalize the trading volume
   if(GetVolumeNormalization())
      ProfitStability/=total_volume;
//--- we multiply by the number of deals - we aren't interested in passes which have few deals
   ProfitStability*=arr_size;
//---
   return(ProfitStability*10000.0);
   //return(ProfitStability);
  }
//+------------------------------------------------------------------+
