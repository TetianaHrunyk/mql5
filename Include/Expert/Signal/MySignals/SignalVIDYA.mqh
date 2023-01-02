//+------------------------------------------------------------------+
//|                                                  SignalVIDYA.mqh |
//+------------------------------------------------------------------+
#include <Expert\ExpertSignal.mqh>
#include <Indicators\MyIndicators\PlainExtendedMAs.mqh>
#include <Trade\DealInfo.mqh>
// wizard description start
//+------------------------------------------------------------------+
//| Description of the class                                         |
//| Title=Signals of indicator '2 VIDYA'                             |
//| Type=SignalAdvanced                                              |
//| Name=2 VIDYA                                                     |
//| ShortName=2 VIDYA                                                |
//| Class=CSignalVIDYA                                               |
//| Page=signal_vidya                                                |
//| Parameter=FastPeriodCMO,int,9,CMO Period Fast                    |
//| Parameter=FastPeriodMA,int,12,MA Period Fast                     |
//| Parameter=FastShift,int,0,Time shift Fast                        |
//| Parameter=FastApplied,ENUM_APPLIED_PRICE,PRICE_CLOSE,Fast price  |
//| Parameter=SlowPeriodCMO,int,20,CMO Period Slow                   |
//| Parameter=SlowPeriodMA,int,50,MA Period Slow                     |
//| Parameter=SlowShift,int,0,Time shift slow                        |
//| Parameter=SlowApplied,ENUM_APPLIED_PRICE,PRICE_CLOSE,Slow price  |
//| Parameter=TrendValPeriodSlow,int,20,Trend validtion period slow  |
//| Parameter=TrendValPeriodFast,int,10,Trend validtion period fast  |
//| Parameter=TrendValRatio,double,0.9,Trend following points ratio  |
//| Parameter=TotalChange,int,4,Total change                         |
//+------------------------------------------------------------------+
// wizard description end
//+------------------------------------------------------------------+
//| Class CSignalVIDYA.                                              |
//| Purpose: Class of generator of trade signals based on            |
//|          the 'VIDYA' indicator.                                  |
//| Is derived from the CExpertSignal class.                         |
//+------------------------------------------------------------------+
class CSignalVIDYA : public CExpertSignal
  {
protected:
   CiVIDyA              m_vidya_slow;             // object-indicator
   CiVIDyA              m_vidya_fast;             // object-indicator
   //CiPMASlope         m_vidya_slope;            // object-indicator
   CPositionInfo     m_position;            // position info object
   //--- adjusted parameters
   int               m_vidya_ma_period_slow;   // MA period slow
   int               m_vidya_cmo_period_slow;  // CMO period slow
   int               m_vidya_shift_slow;       // Shift slow
   ENUM_APPLIED_PRICE m_vidya_applied_slow;    // Price applied slow

   int               m_vidya_ma_period_fast;   // MA period fast
   int               m_vidya_cmo_period_fast;  // CMO period fast
   int               m_vidya_shift_fast;       // Shift fast
   ENUM_APPLIED_PRICE m_vidya_applied_fast;    // Price applied fast

   int               m_trend_validation_period_slow;//number of bars to confirm trend
   int               m_trend_validation_period_fast;//number of bars to confirm trend
   int               m_total_change;
   double            m_adjusted_total_change;
   double            m_trend_validation_ratio;


   //--- "weights" of market models (0-100)
   int               m_pattern_0;      // model 0 "Price is above fast VIDYA"
   int               m_pattern_1;      // model 1 "VIDYA Crossover"
   int               m_pattern_2;      // model 2 "Following trend"
   //int               m_pattern_3;      // model 3 ""

public:
                     CSignalVIDYA(void);
                    ~CSignalVIDYA(void);
   //--- methods of setting adjustable parameters
   void              SlowPeriodMA(int value)                 { m_vidya_ma_period_slow=value;       }
   void              SlowShift(int value)                    { m_vidya_shift_slow=value;           }
   void              SlowPeriodCMO(int value)                { m_vidya_cmo_period_slow=value;      }
   void              SlowApplied(ENUM_APPLIED_PRICE value)   { m_vidya_applied_slow=value;         }

   void              FastPeriodMA(int value)                 { m_vidya_ma_period_fast=value;       }
   void              FastShift(int value)                    { m_vidya_shift_fast=value;           }
   void              FastPeriodCMO(int value)                { m_vidya_cmo_period_fast=value;      }
   void              FastApplied(ENUM_APPLIED_PRICE value)   { m_vidya_applied_fast=value;         }

   void              TrendValPeriodSlow(int value)           { m_trend_validation_period_slow=value; }
   void              TrendValPeriodFast(int value)           { m_trend_validation_period_fast=value; }
   void              TrendValRatio(double value)             { m_trend_validation_ratio=value; }
   void              TotalChange(int value)                  { m_total_change=value; m_adjusted_total_change=value*m_adjusted_point;}

   //--- methods of adjusting "weights" of market models
   void              Pattern_0(int value)                { m_pattern_0=value;          }
   void              Pattern_1(int value)                { m_pattern_1=value;          }
   void              Pattern_2(int value)                { m_pattern_2=value;          }
   //void              Pattern_3(int value)                { m_pattern_3=value;          }

   //--- method of verification of settings
   virtual bool      ValidationSettings(void);

   //--- method of creating the indicator and timeseries
   virtual bool      InitIndicators(CIndicators *indicators);

   //--- methods of checking if the market models are formed
   virtual int       LongCondition(void);
   virtual int       ShortCondition(void);

protected:
   //--- method of initialization of the indicator
   bool              InitVIDYA(CIndicators *indicators);
   //--- methods of getting data
   double            Slow(int ind)                         { return(m_vidya_slow.Main(ind));     }
   double            Fast(int ind)                         { return(m_vidya_fast.Main(ind));     }
   int               SelectPosition(void);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSignalVIDYA::CSignalVIDYA(void) :
   m_vidya_ma_period_slow(50),
   m_vidya_cmo_period_slow(20),
   m_vidya_shift_slow(0),
   m_vidya_applied_slow(PRICE_CLOSE),
   m_vidya_ma_period_fast(12),
   m_vidya_cmo_period_fast(9),
   m_vidya_shift_fast(0),
   m_vidya_applied_fast(PRICE_CLOSE),
   m_pattern_0(50),
   m_pattern_1(50),
//m_pattern_2(100),
//m_pattern_3(100),
   m_trend_validation_period_slow(20),
   m_trend_validation_period_fast(10),
   m_trend_validation_ratio(0.9),
   m_total_change(8)
  {
//--- initialization of protected data
   m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalVIDYA::~CSignalVIDYA(void)
  {
  }
//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool CSignalVIDYA::ValidationSettings(void)
  {
//--- validation settings of additional filters
   if(!CExpertSignal::ValidationSettings())
      return(false);
//--- initial data checks
   if(m_vidya_ma_period_slow<=0 || m_vidya_ma_period_fast<=0)
     {
      printf(__FUNCTION__+": period MA must be greater than 0");
      return(false);
     }
     
   if(m_trend_validation_period_slow > m_trend_validation_period_fast)
     {
      printf(__FUNCTION__+": Slow trend validation period must be greater than fast period");
      return(false);
     }

//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool CSignalVIDYA::InitIndicators(CIndicators *indicators)
  {
//--- check pointer
   if(indicators==NULL)
      return(false);
//--- initialization of indicators and timeseries of additional filters
   if(!CExpertSignal::InitIndicators(indicators))
      return(false);
//--- create and initialize MA indicator
   if(!InitVIDYA(indicators))
      return(false);
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Initialize MA indicators.                                        |
//+------------------------------------------------------------------+
bool CSignalVIDYA::InitVIDYA(CIndicators *indicators)
  {
//--- check pointer
   if(indicators==NULL)
      return(false);
//--- add object to collection
   if(!indicators.Add(GetPointer(m_vidya_slow)))
     {
      printf(__FUNCTION__+": error adding object");
      return(false);
     }
//--- initialize object
   if(!m_vidya_slow.Create(m_symbol.Name(),m_period,m_vidya_cmo_period_slow,m_vidya_ma_period_slow,m_vidya_shift_slow,m_vidya_applied_slow))
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
//--- add object to collection
   if(!indicators.Add(GetPointer(m_vidya_fast)))
     {
      printf(__FUNCTION__+": error adding object");
      return(false);
     }
//--- initialize object
   if(!m_vidya_fast.Create(m_symbol.Name(),m_period,m_vidya_cmo_period_fast,m_vidya_ma_period_fast,m_vidya_shift_fast,m_vidya_applied_fast))
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
//--- ok
   m_adjusted_total_change=m_total_change*m_adjusted_point;
   return(true);
  }

//+------------------------------------------------------------------+
//| Position select depending on netting or hedging                  |
//+------------------------------------------------------------------+
int CSignalVIDYA::SelectPosition(void)
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
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int CSignalVIDYA::LongCondition(void)
  {
   int result=0;
   int idx   =StartIndex();

// Close is above Fast VIDYA
   if(IS_PATTERN_USAGE(0))
     {
      if(Close(idx) > Fast(idx))
        {
         result = m_pattern_0;
        }
     }

// Crossover
   if(IS_PATTERN_USAGE(1))
     {
      if(Fast(idx+1) < Slow(idx+1) && Fast(idx) > Slow(idx))
         result = m_pattern_1;
     }

// Following trend
   if(IS_PATTERN_USAGE(2))
     {
      int fast_trend = 0;
      int slow_trend = 0;
      for(int i = idx; i <= m_trend_validation_period_slow+idx; i ++)
        {
         if(i < m_trend_validation_period_fast && Fast(i) > Fast(i+1))
           {
            fast_trend++;
           }
         if(Slow(i) > Slow(i+1))
           {
            slow_trend++;
           }
        }

      if(
         slow_trend >= m_trend_validation_period_slow * m_trend_validation_ratio &&
         fast_trend >= m_trend_validation_period_fast * m_trend_validation_ratio &&
         Slow(idx) - Slow(m_trend_validation_period_slow+idx) > m_adjusted_total_change
      )
         result = m_pattern_2;
     }

//--- return the result
   return(result);
  }
//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int CSignalVIDYA::ShortCondition(void)
  {
   int result=0;
   int idx   =StartIndex();

// Close is below Fast VIDYA
   if(IS_PATTERN_USAGE(0))
     {
      if(Close(idx) < Fast(idx))
        {
         result = m_pattern_0;
        }
     }

// Crossover
   if(IS_PATTERN_USAGE(1))
     {
      if(Fast(idx+1) > Slow(idx+1) && Fast(idx) < Slow(idx))
         result = m_pattern_1;
     }

// Following trend
   if(IS_PATTERN_USAGE(2))
     {
      int fast_trend = 0;
      int slow_trend = 0;
      for(int i = idx; i <= m_trend_validation_period_slow+idx; i ++)
        {
         if(i < m_trend_validation_period_fast && Fast(i) < Fast(i+1))
           {
            fast_trend++;
           }
         if(Slow(i) < Slow(i+1))
           {
            slow_trend++;
           }
        }
      if(
         slow_trend >= m_trend_validation_period_slow * m_trend_validation_ratio &&
         fast_trend >= m_trend_validation_period_fast * m_trend_validation_ratio &&
         Slow(idx) - Slow(m_trend_validation_period_slow+idx) < -m_adjusted_total_change
      )
         result = m_pattern_2;
     }

//--- return the result
   return(result);
  }


//+------------------------------------------------------------------+
