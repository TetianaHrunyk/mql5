//+------------------------------------------------------------------+
//|                                                    Signal2MA.mqh |
//+------------------------------------------------------------------+
#include <Expert\ExpertSignal.mqh>
#include <Indicators\MyIndicators\PlainExtendedMAs.mqh>
#include <Trade\DealInfo.mqh>
// wizard description start
//+------------------------------------------------------------------+
//| Description of the class                                         |
//| Title=Signals of indicator '2 Moving Averages'                   |
//| Type=SignalAdvanced                                              |
//| Name=2 Moving Averages                                           |
//| ShortName=MA2                                                    |
//| Class=CSignalMA2                                                 |
//| Page=signal_ma                                                   |
//| Parameter=SlowPeriodMA,int,200,Period of slow averaging          |
//| Parameter=SlowShift,int,0,Time shift slow                        |
//| Parameter=SlowMethod,ENUM_MA_METHOD,MODE_SMA,Slow method         |
//| Parameter=SlowApplied,ENUM_APPLIED_PRICE,PRICE_CLOSE,Slow price  |
//| Parameter=FastPeriodMA,int,50,Period of fast averaging           |
//| Parameter=FastShift,int,0,Time shift fast                        |
//| Parameter=FastMethod,ENUM_MA_METHOD,MODE_SMA,Fast method         |
//| Parameter=FastApplied,ENUM_APPLIED_PRICE,PRICE_CLOSE,Fast price  |
//| Parameter=TrendValidationPeriod,int,20,Trend validtion period    |
//| Parameter=TrendValPeriodFast,int,10,Fast trend validtion period  |
//| Parameter=TrendValRatio,double,0.9,Trend following points ratio  |
//| Parameter=TotalMAChange,int,4,Total MA change                    |
//+------------------------------------------------------------------+
// wizard description end
//+------------------------------------------------------------------+
//| Class CSignalMA2.                                                |
//| Purpose: Class of generator of trade signals based on            |
//|          the '2 Moving Averages' indicator.                      |
//| Is derived from the CExpertSignal class.                         |
//+------------------------------------------------------------------+
class CSignalMA2 : public CExpertSignal
  {
protected:
   CiMA              m_ma_slow;             // object-indicator
   CiMA              m_ma_fast;             // object-indicator
   //CiPMASlope         m_ma_slope;            // object-indicator
   CPositionInfo     m_position;            // position info object
   //--- adjusted parameters
   int               m_ma_period_slow;      // the "period of averaging" parameter of the indicator
   int               m_ma_shift_slow;       // the "time shift" parameter of the indicator
   ENUM_MA_METHOD    m_ma_method_slow;      // the "method of averaging" parameter of the indicator
   ENUM_APPLIED_PRICE m_ma_applied_slow;    // the "object of averaging" parameter of the indicator

   int               m_ma_period_fast;      // the "period of averaging" parameter of the indicator
   int               m_ma_shift_fast;       // the "time shift" parameter of the indicator
   ENUM_MA_METHOD    m_ma_method_fast;      // the "method of averaging" parameter of the indicator
   ENUM_APPLIED_PRICE m_ma_applied_fast;    // the "object of averaging" parameter of the indicator

   int               m_trend_validation_period;//number of bars to confirm trend
   int               m_trend_validation_period_fast;//number of bars to confirm trend
   int               m_total_ma_change;
   double            m_adjusted_total_ma_change;
   double            m_trend_val_ratio;


   //--- "weights" of market models (0-100)
   int               m_pattern_0;      // model 0 "Slow chooses direction, crossover with fast gives signal"
   int               m_pattern_1;      // model 1 "MA Crossover"
   int               m_pattern_2;      // model 2 "Fast MA growing"
   int               m_pattern_3;      // model 3 "Slow MA growing, fast growing"
   //int               m_pattern_3;      // model 3 ""

public:
                     CSignalMA2(void);
                    ~CSignalMA2(void);
   //--- methods of setting adjustable parameters
   void              SlowPeriodMA(int value)                 { m_ma_period_slow=value;          }
   void              SlowShift(int value)                    { m_ma_shift_slow=value;           }
   void              SlowMethod(ENUM_MA_METHOD value)        { m_ma_method_slow=value;          }
   void              SlowApplied(ENUM_APPLIED_PRICE value)   { m_ma_applied_slow=value;         }

   void              FastPeriodMA(int value)                 { m_ma_period_fast=value;          }
   void              FastShift(int value)                    { m_ma_shift_fast=value;           }
   void              FastMethod(ENUM_MA_METHOD value)        { m_ma_method_fast=value;          }
   void              FastApplied(ENUM_APPLIED_PRICE value)   { m_ma_applied_fast=value;         }

   void              TrendValidationPeriod(int value)        { m_trend_validation_period=value; }
   void              TrendValPeriodFast(int value)           { m_trend_validation_period_fast=value; }
   void              TrendValRatio(double value)             { m_trend_val_ratio=value; }
   void              TotalMAChange(int value)                { m_total_ma_change=value; m_adjusted_total_ma_change=value*m_adjusted_point;}

   //--- methods of adjusting "weights" of market models
   void              Pattern_0(int value)                { m_pattern_0=value;          }
   void              Pattern_1(int value)                { m_pattern_1=value;          }
   void              Pattern_2(int value)                { m_pattern_2=value;          }
   void              Pattern_3(int value)                { m_pattern_3=value;          }
   //--- method of verification of settings
   virtual bool      ValidationSettings(void);
   //--- method of creating the indicator and timeseries
   virtual bool      InitIndicators(CIndicators *indicators);
   //--- methods of checking if the market models are formed
   virtual int       LongCondition(void);
   virtual int       ShortCondition(void);

protected:
   //--- method of initialization of the indicator
   bool              InitMA(CIndicators *indicators);
   //--- methods of getting data
   double            Slow(int ind)                         { return(m_ma_slow.Main(ind));     }
   double            Fast(int ind)                         { return(m_ma_fast.Main(ind));     }
   bool              CrossUp(int idx);
   bool              CrossDown(int idx);
   bool              CanShort(void);
   bool              CanLong(void);
   int               SelectPosition(void);
   bool              LossBarsLimitExceeded(void);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSignalMA2::CSignalMA2(void) : m_ma_period_slow(200),
   m_ma_shift_slow(0),
   m_ma_method_slow(MODE_SMA),
   m_ma_applied_slow(PRICE_CLOSE),
   m_ma_period_fast(50),
   m_ma_shift_fast(0),
   m_ma_method_fast(MODE_SMA),
   m_ma_applied_fast(PRICE_CLOSE),
   m_pattern_0(50),
   m_pattern_1(50),
   m_pattern_2(100),
   m_pattern_3(100),
   m_trend_validation_period(20),
   m_trend_validation_period_fast(10),
   m_trend_val_ratio(0.9),
   m_total_ma_change(8)
  {
//--- initialization of protected data
   m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalMA2::~CSignalMA2(void)
  {
  }
//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool CSignalMA2::ValidationSettings(void)
  {
//--- validation settings of additional filters
   if(!CExpertSignal::ValidationSettings())
      return(false);
//--- initial data checks
   if(m_ma_period_slow<=0 || m_ma_period_fast<=0)
     {
      printf(__FUNCTION__+": period MA must be greater than 0");
      return(false);
     }
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool CSignalMA2::InitIndicators(CIndicators *indicators)
  {
//--- check pointer
   if(indicators==NULL)
      return(false);
//--- initialization of indicators and timeseries of additional filters
   if(!CExpertSignal::InitIndicators(indicators))
      return(false);
//--- create and initialize MA indicator
   if(!InitMA(indicators))
      return(false);
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Initialize MA indicators.                                        |
//+------------------------------------------------------------------+
bool CSignalMA2::InitMA(CIndicators *indicators)
  {
//--- check pointer
   if(indicators==NULL)
      return(false);
//--- add object to collection
   if(!indicators.Add(GetPointer(m_ma_slow)))
     {
      printf(__FUNCTION__+": error adding object");
      return(false);
     }
//--- initialize object
   if(!m_ma_slow.Create(m_symbol.Name(),m_period,m_ma_period_slow,m_ma_shift_slow,m_ma_method_slow,m_ma_applied_slow))
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
//--- add object to collection
   if(!indicators.Add(GetPointer(m_ma_fast)))
     {
      printf(__FUNCTION__+": error adding object");
      return(false);
     }
//--- initialize object
   if(!m_ma_fast.Create(m_symbol.Name(),m_period,m_ma_period_fast,m_ma_shift_fast,m_ma_method_fast,m_ma_applied_fast))
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
////--- add object to collection
//   if(!indicators.Add(GetPointer(m_ma_slope)))
//     {
//      printf(__FUNCTION__+": error adding object");
//      return(false);
//     }
//--- initialize object
//if(!m_ma_slope.Create(m_symbol.Name(),m_period,1,m_ma_period_fast,m_ma_shift_fast,m_ma_method_fast,m_ma_applied_fast))
//  {
//   printf(__FUNCTION__+": error initializing object");
//   return(false);
//  }
//--- ok
   m_adjusted_total_ma_change=m_total_ma_change*m_adjusted_point;
   return(true);
  }

//+------------------------------------------------------------------+
//| Position select depending on netting or hedging                  |
//+------------------------------------------------------------------+
int CSignalMA2::SelectPosition(void)
  {
   bool position_open=false;
   int res=0;
//---
   if(IsHedging())
      position_open=m_position.SelectByMagic(m_symbol.Name(),m_magic);
   else
      position_open=m_position.Select(m_symbol.Name());

   if(position_open)
     {
      ENUM_POSITION_TYPE position_type = m_position.PositionType();
      if(position_type == POSITION_TYPE_BUY)
         res = 1;
      if(position_type == POSITION_TYPE_SELL)
         res = -1;
     }
//---
   return(res);
  }

//+------------------------------------------------------------------+
//| Fast MA crosses bottom up the slow MA                            |
//+------------------------------------------------------------------+
bool CSignalMA2::CrossUp(int idx)
  {
   return (Fast(idx+1) <= Slow(idx+1) && Fast(idx) > Slow(idx));
  }

//+------------------------------------------------------------------+
//| Fast MA crosses top down the slow MA                             |
//+------------------------------------------------------------------+
bool CSignalMA2::CrossDown(int idx)
  {
   return (Fast(idx+1) >= Slow(idx+1) && Fast(idx) < Slow(idx));
  }


//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int CSignalMA2::LongCondition(void)
  {
   int result=0;
   int idx   =StartIndex();
//double m = m_ma_slope.Main(idx);
   double ma_diff = Fast(idx)-Fast(idx+1);

   if(IS_PATTERN_USAGE(0))
     {
      // Price is above Slow MA
      if(Close(idx) > Slow(idx) || SelectPosition() == -1)
        {
         //if (Close(idx) > Slow(idx)) {
         double prev_close = Close(idx+1);
         double prev_fast = Fast(idx+1);
         double cur_close = Close(idx);
         double cur_fast = Fast(idx);
         if(prev_close < prev_fast && cur_close > cur_fast)
           {
            //if(m_ma_slope.Main(idx)>0)
            result = m_pattern_0;
           }
        }
     }

   if(IS_PATTERN_USAGE(1))
     {
      if(CrossUp(idx))
         result = m_pattern_1;
     }

   if(IS_PATTERN_USAGE(2))
     {
      int res = 0;
      for(int i =idx; i < m_trend_validation_period; i++)
        {
         if(Fast(i) <= Fast(i+1))
            res++;
        }
      if(res>(m_trend_validation_period-idx)*m_trend_val_ratio && Fast(idx) - Fast(idx+m_trend_validation_period) > m_adjusted_total_ma_change)
         result = m_pattern_2;
     }

//if(IS_PATTERN_USAGE(3) && LossBarsLimitExceeded())
//if(IS_PATTERN_USAGE(3) && !(Close(idx) - Slow(idx) > m_stop_level))
   if(IS_PATTERN_USAGE(3))
     {
      int res_slow = 0;
      int res_fast = 0;
      for(int i =idx; i < m_trend_validation_period; i++)
        {
         if(Slow(i) >= Slow(i+1))
            res_slow++;
         double slow_i = Slow(i);
         double slow_i1 = Slow(i+1);
         double fast_i = Fast(i);
         double fast_i1 = Fast(i+1);
         if(i < m_trend_validation_period_fast)
            if(Fast(i) >= Fast(i+1))
               res_fast++;
        }
      //if(
      //   res_slow>=(m_trend_validation_period-idx)*m_trend_val_ratio &&
      //   res_fast>=(m_trend_validation_period_fast-idx)*m_trend_val_ratio &&
      //   Slow(idx) - Slow(idx+m_trend_validation_period) > m_adjusted_total_ma_change
      //)
      if(
         (res_slow>=(m_trend_validation_period-idx)*m_trend_val_ratio ||
          Slow(idx) - Slow(idx+m_trend_validation_period) > m_adjusted_total_ma_change) &&
         res_fast>=(m_trend_validation_period_fast-idx)*m_trend_val_ratio

      )
         result = m_pattern_3;
     }

//--- return the result
   return(result);
  }
//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int CSignalMA2::ShortCondition(void)
  {
   int result=0;
   int idx   =StartIndex();
//double m = m_ma_slope.Main(idx);
   double ma_diff = Fast(idx)-Fast(idx+1);

   if(IS_PATTERN_USAGE(0))
     {
      // Price is below Slow MA
      if(Close(idx) < Slow(idx) || SelectPosition() == 1)
        {
         //if (Close(idx) < Slow(idx) ) {
         double prev_close = Close(idx+1);
         double prev_fast = Fast(idx+1);
         double cur_close = Close(idx);
         double cur_fast = Fast(idx);
         if(prev_close > prev_fast && cur_close < cur_fast)
           {
            //if(m_ma_slope.Main(idx)<-0)
            result = m_pattern_0;
           }

        }
     }

   if(IS_PATTERN_USAGE(1))
     {
      if(CrossDown(idx))
         result = m_pattern_1;
     }

   if(IS_PATTERN_USAGE(2))
     {
      int res = 0;
      for(int i = idx; i < m_trend_validation_period; i++)
        {
         if(Fast(i) <= Fast(i+1))
            res++;
        }
      if(res>=(m_trend_validation_period-idx)*m_trend_val_ratio && Fast(idx) - Fast(idx+m_trend_validation_period) < -m_adjusted_total_ma_change)
         result = m_pattern_2;
     }

//if(IS_PATTERN_USAGE(3) && LossBarsLimitExceeded())
//if(IS_PATTERN_USAGE(3) && !(Slow(idx) - Close(idx) > m_stop_level))
   if(IS_PATTERN_USAGE(3))
     {
      int res_slow = 0;
      int res_fast = 0;
      for(int i =idx; i < m_trend_validation_period; i++)
        {
         if(Slow(i) <= Slow(i+1))
            res_slow++;
         if(i < m_trend_validation_period_fast && Fast(i) <= Fast(i+1))
            res_fast++;
        }
      //if(
      //   res_slow>=(m_trend_validation_period-idx)*m_trend_val_ratio &&
      //   res_fast>=(m_trend_validation_period_fast-idx)*m_trend_val_ratio &&
      //   Slow(idx) - Slow(idx+m_trend_validation_period) < -m_adjusted_total_ma_change
      //)
      if(
         (res_slow>=(m_trend_validation_period-idx)*m_trend_val_ratio ||
          Slow(idx) - Slow(idx+m_trend_validation_period) < -m_adjusted_total_ma_change)
         && res_fast>=(m_trend_validation_period_fast-idx)*m_trend_val_ratio


      )
         result = m_pattern_3;
     }
//--- return the result
   return(result);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSignalMA2::LossBarsLimitExceeded(void)
  {
   bool res = true;
//--- select history for access
   HistorySelect(0,TimeCurrent());
//---
   int       orders=HistoryDealsTotal();  // total history deals
   int       losses=0;                    // number of consequent losing orders
   datetime  deal_time;
   CDealInfo deal;
//---
   for(int i=orders-1; i>=0; i--)
     {
      deal.Ticket(HistoryDealGetTicket(i));
      if(deal.Ticket()==0)
        {
         Print("HistoryDealGetTicket failed, no trade history");
         break;
        }
      //--- check symbol
      if(deal.Symbol()!=m_symbol.Name())
         continue;
      //--- check direction
      if(deal.Entry() != DEAL_ENTRY_OUT)
         continue;
      //--- check profit
      double profit=deal.Profit();
      if(profit>0.0)
         break;
      if(profit<0.0)
         losses++;
      deal_time = deal.Time();
      break;
     }
//---
   if(losses>0)
     {
      datetime time_current = TimeCurrent();
      datetime unix_time = time_current-time_current;
      datetime time_gone = time_current - deal_time;
      // TODO: make this work with all timeframes
      datetime time_limit = unix_time + 60*60*3;
      if(time_gone > time_limit)
         res = true;
      else
         res = false;
     }

//---
   return(res);
  }

//+------------------------------------------------------------------+
