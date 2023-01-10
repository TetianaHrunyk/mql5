//+------------------------------------------------------------------+
//|                                                  CStrategyMA.mqh |
//|                        Copyright 2010, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include <CSampleStrategy.mqh>
//+------------------------------------------------------------------+
//| Class CStrategyMA for implementation of virtual trading          |
//| by the moving average strategy                                   |
//+------------------------------------------------------------------+
class CStrategyMA : public CSampleStrategy
  {
protected:
   int               m_handle;     // handle of the Moving Average (iMA) indicator
   int               m_period;     // period of the Moving Average indicator
   double            m_values[];   // array for storing the value of indicator
public:
   // initialization of strategy
   int               Initialization(int period,bool virtual_trade_flag);
   // deinitialization of the strategy
   int               Deinitialization();
   // check of the trade conditions and opening of virtual positions
   bool              CheckTradeConditions();
  };
//+------------------------------------------------------------------+
//| Method of initialization of the strategy                         |
//+------------------------------------------------------------------+
int CStrategyMA::Initialization(int period,bool virtual_trade_flag)
  {
   //set period for the moving average
   m_period=period;
   // set specified flag of the virtual position
   SetVirtualTradeFlag(virtual_trade_flag);

   //set the indexation of array like in timeseries
   ArraySetAsSeries(m_rates,true);
   ArraySetAsSeries(m_values,true);
   
   //create handle of the indicator 
   m_handle=iMA(_Symbol,_Period,m_period,0,MODE_EMA,PRICE_CLOSE);
   if(m_handle<0)
     {
      Alert("Error of creation of the MA indicator - error number: ",GetLastError(),"!!");
      return(-1);
     }

   return(0);
  }
//+------------------------------------------------------------------+
//| Method of deinitialization of the strategy                       |
//+------------------------------------------------------------------+
int CStrategyMA::Deinitialization()
  {
   Position_CloseOpenedPosition(m_position);
   IndicatorRelease(m_handle);
   return(0);
  };
//+------------------------------------------------------------------+
//| checking the trade conditions and opening the virtual positions  |
//+------------------------------------------------------------------+
bool CStrategyMA::CheckTradeConditions()
  {
   RecalcPositionProperties(m_position);
   double p_close;

//--- Get history data of last three bars
   if(CopyRates(_Symbol,_Period,0,3,m_rates)<0)
     {
      Alert("Error of copying history data - error:",GetLastError(),"!!");
      return(false);
     }
// Copy the current close price of the previous bar (this is bar 1)
   p_close=m_rates[1].close;  // close price of the previous bar          

   if(CopyBuffer(m_handle,0,0,3,m_values)<0)
     {
      Alert("Error of copying buffers of the Moving Average indicator - error number:",GetLastError());
      return(false);
     }

// Buy condition 1: MA rises
   bool buy_condition_1=(m_values[0]>m_values[1]) && (m_values[1]>m_values[2]);
// Buy condition 2: previous close price is higher than MA
   bool buy_condition_2=(p_close>m_values[1]);

// Sell condition 1: // MA falls
   bool sell_condition_1=(m_values[0]<m_values[1]) && (m_values[1]<m_values[2]);
// Sell condition 2: // previous close price is lower than MA   
   bool sell_condition_2=(p_close<m_values[1]);

   int new_state=0;

   if(buy_condition_1  &&  buy_condition_2) new_state=SIGNAL_OPEN_LONG;
   if(sell_condition_1 && sell_condition_2) new_state=SIGNAL_OPEN_SHORT;

   if((GetSignalState()==SIGNAL_OPEN_SHORT) && (buy_condition_1 || buy_condition_2)) new_state=SIGNAL_CLOSE_SHORT;
   if((GetSignalState()==SIGNAL_OPEN_LONG) && (sell_condition_1 || sell_condition_2)) new_state=SIGNAL_CLOSE_LONG;

   if(GetSignalState()!=new_state)
     {
      SetSignalState(new_state);
     }

   return(true);
  };
//+------------------------------------------------------------------+
