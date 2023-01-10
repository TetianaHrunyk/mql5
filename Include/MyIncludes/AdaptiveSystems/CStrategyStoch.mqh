//+------------------------------------------------------------------+
//|                                               CStrategyStoch.mqh |
//|                        Copyright 2010, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include <CSampleStrategy.mqh>
//+------------------------------------------------------------------+
//| Class CStrategyStoch for implementation of virtual tradingby the |
//| strategy of intersection of lines of the stochastic oscillator   |
//+------------------------------------------------------------------+
class CStrategyStoch : public CSampleStrategy
  {
protected:
   int               m_handle;          // handle of the Stochastic Oscillator (iStochastic) indicator
   int               m_period_k;        // K-period (number of bars for calculation)
   int               m_period_d;        // D-period (period of primary smoothing)
   int               m_period_slowing;  // final smoothing
   double            m_main_line[];     // array for storing the values of indicator
   double            m_signal_line[];   // array for storing the values of indicator
public:
   // initialization of strategy
   int               Initialization(int period_k,int period_d,int period_slowing,bool virtual_trade_flag);
   // deinitialization of the strategy
   int               Deinitialization();
   // check of the trade conditions and opening of virtual positions
   bool              CheckTradeConditions();
  };
//+------------------------------------------------------------------+
//| Method of initialization of the strategy                         |
//+------------------------------------------------------------------+
int CStrategyStoch::Initialization(int period_k,int period_d,int period_slowing,bool virtual_trade_flag)
  {
// set periods for the oscillator
   m_period_k=period_k;
   m_period_d=period_d;
   m_period_slowing=period_slowing;

// set specified flag of the virtual position
   SetVirtualTradeFlag(virtual_trade_flag);

//set the indexation of array like in timeseries
   ArraySetAsSeries(m_rates,true);
   ArraySetAsSeries(m_main_line,true);
   ArraySetAsSeries(m_signal_line,true);

//create handle of the indicator 
   m_handle=iStochastic(_Symbol,_Period,m_period_k,m_period_d,m_period_slowing,MODE_SMA,STO_LOWHIGH);
   if(m_handle<0)
     {
      Alert("Error of creation of the Stochastic indicator - error number: ",GetLastError(),"!!");
      return(-1);
     }

   return(0);
  }
//+------------------------------------------------------------------+
//| Method of deinitialization of the strategy                       |
//+------------------------------------------------------------------+
int CStrategyStoch::Deinitialization()
  {
//close all the open positions
   Position_CloseOpenedPosition(m_position);
//release the handle of indicator
   IndicatorRelease(m_handle);
   return(0);
  };
//+------------------------------------------------------------------+
//| checking the trade conditions and opening the virtual positions  |
//+------------------------------------------------------------------+
bool CStrategyStoch::CheckTradeConditions()
  {
//call the function of recalculation of the parameters of position
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

   if((CopyBuffer(m_handle,0,0,3,m_main_line)<3) || (CopyBuffer(m_handle,1,0,3,m_signal_line)<3))
     {
      Alert("Error of copying the buffer of the Stochastic indicator - error number:",GetLastError());
      return(false);
     }

   // Buy condition: crossing the signal line upwards
   bool buy_condition=((m_signal_line[2]<m_main_line[2]) && (m_signal_line[1]>m_main_line[1]));
   // Sell condition: crossing the signal line from top downwards
   bool sell_condition=((m_signal_line[2]>m_main_line[2]) && (m_signal_line[1]<m_main_line[1]));

   int new_state=0;

   if(buy_condition) new_state=SIGNAL_OPEN_LONG;
   if(sell_condition) new_state=SIGNAL_OPEN_SHORT;

   if((GetSignalState()==SIGNAL_OPEN_SHORT) && (buy_condition)) new_state=SIGNAL_CLOSE_SHORT;
   if((GetSignalState()==SIGNAL_OPEN_LONG) && (sell_condition)) new_state=SIGNAL_CLOSE_LONG;

   if(GetSignalState()!=new_state)
     {
      SetSignalState(new_state);
     }

   return(true);
  };
//+------------------------------------------------------------------+