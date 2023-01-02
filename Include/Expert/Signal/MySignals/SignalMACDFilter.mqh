//+------------------------------------------------------------------+
//|                                             SignalMACDFilter.mqh |
//+------------------------------------------------------------------+
#include <Expert\ExpertSignal.mqh>
// wizard description start
//+------------------------------------------------------------------+
//| Description of the class                                         |
//| Title=Signals of oscillator 'MACD' intended for filtering        |
//| Type=SignalAdvanced                                              |
//| Name=MACD_Filter                                                 |
//| ShortName=MACD_Filter                                            |
//| Class=CSignalMACD                                                |
//| Page=signal_macd                                                 |
//| Parameter=PeriodFast,int,12,Period of fast EMA                   |
//| Parameter=PeriodSlow,int,24,Period of slow EMA                   |
//| Parameter=PeriodSignal,int,9,Period of averaging of difference   |
//| Parameter=Applied,ENUM_APPLIED_PRICE,PRICE_CLOSE,Prices series   |
//| Parameter=Threshold,int,10,Min required diff for main and signal |
//+------------------------------------------------------------------+
// wizard description end
//+------------------------------------------------------------------+
//| Class CSignalMACD.                                               |
//| Purpose: Class of generator of trade signals based on            |
//|          the 'Moving Average Convergence/Divergence' oscillator. |
//| Is derived from the CExpertSignal class.                         |
//+------------------------------------------------------------------+
class CSignalMACD : public CExpertSignal
  {
protected:
   CiMACD            m_MACD;           // object-oscillator
   //--- adjusted parameters
   int               m_period_fast;    // the "period of fast EMA" parameter of the oscillator
   int               m_period_slow;    // the "period of slow EMA" parameter of the oscillator
   int               m_period_signal;  // the "period of averaging of difference" parameter of the oscillator
   ENUM_APPLIED_PRICE m_applied;       // the "price series" parameter of the oscillator
   int               m_threshold;      // min reuired diff between main and signal
   double            m_adjusted_threshold;
   //--- "weights" of market models (0-100)
   int               m_pattern_0;      // model 0 "the oscillator has required direction"
   int               m_pattern_1;      // model 1 "reverse of the oscillator to required direction"

public:
                     CSignalMACD(void);
                    ~CSignalMACD(void);
   //--- methods of setting adjustable parameters
   void              PeriodFast(int value)             { m_period_fast=value;           }
   void              PeriodSlow(int value)             { m_period_slow=value;           }
   void              PeriodSignal(int value)           { m_period_signal=value;         }
   void              Applied(ENUM_APPLIED_PRICE value) { m_applied=value;               }
   void              Threshold(int value)              { m_threshold=value; m_adjusted_threshold=m_threshold*m_adjusted_point;}
   //--- methods of adjusting "weights" of market models
   void              Pattern_0(int value)              { m_pattern_0=value;             }
   void              Pattern_1(int value)              { m_pattern_1=value;             }

   //--- method of verification of settings
   virtual bool      ValidationSettings(void);
   //--- method of creating the indicator and timeseries
   virtual bool      InitIndicators(CIndicators *indicators);
   //--- methods of checking if the market models are formed
   virtual int       LongCondition(void);
   virtual int       ShortCondition(void);

protected:
   //--- method of initialization of the oscillator
   bool              InitMACD(CIndicators *indicators);
   //--- methods of getting data
   double            Main(int ind)                     { return(m_MACD.Main(ind));      }
   double            Signal(int ind)                   { return(m_MACD.Signal(ind));    }
   double            DiffMain(int ind)                 { return(Main(ind)-Main(ind+1)); }
   double            State(int ind) { return(Main(ind)-Signal(ind)); }
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSignalMACD::CSignalMACD(void) : m_period_fast(12),
   m_period_slow(24),
   m_period_signal(9),
   m_applied(PRICE_CLOSE),
   m_pattern_0(40),
   m_pattern_1(60),
   m_threshold(10)

  {
//--- initialization of protected data
   m_used_series=USE_SERIES_HIGH+USE_SERIES_LOW;
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalMACD::~CSignalMACD(void)
  {
  }
//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool CSignalMACD::ValidationSettings(void)
  {
//--- validation settings of additional filters
   if(!CExpertSignal::ValidationSettings())
      return(false);
//--- initial data checks
   if(m_period_fast>=m_period_slow)
     {
      printf(__FUNCTION__+": slow period must be greater than fast period");
      return(false);
     }
   if(m_threshold < 0)
     {
      printf(__FUNCTION__+": threshold cannot be negative");
      return(false);
     }
   else
     {
      m_adjusted_threshold = m_threshold*m_adjusted_point;
     }
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool CSignalMACD::InitIndicators(CIndicators *indicators)
  {
//--- check of pointer is performed in the method of the parent class
//---
//--- initialization of indicators and timeseries of additional filters
   if(!CExpertSignal::InitIndicators(indicators))
      return(false);
//--- create and initialize MACD oscilator
   if(!InitMACD(indicators))
      return(false);
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Initialize MACD oscillators.                                     |
//+------------------------------------------------------------------+
bool CSignalMACD::InitMACD(CIndicators *indicators)
  {
//--- add object to collection
   if(!indicators.Add(GetPointer(m_MACD)))
     {
      printf(__FUNCTION__+": error adding object");
      return(false);
     }
//--- initialize object
   if(!m_MACD.Create(m_symbol.Name(),m_period,m_period_fast,m_period_slow,m_period_signal,m_applied))
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
//--- ok
   return(true);
  }

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int CSignalMACD::LongCondition(void)
  {
   int result=0;
   int idx   =StartIndex();
//--- check direction of the main line
   if (Main(idx) > Signal(idx)) {
      if (IS_PATTERN_USAGE(0)) result = m_pattern_0;
      if (IS_PATTERN_USAGE(1) && Main(idx) - Signal(idx)> m_adjusted_threshold) result = m_pattern_1;
   }
//--- return the result
   return(result);
  }
//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int CSignalMACD::ShortCondition(void)
  {
   int result=0;
   int idx   =StartIndex();
//--- check direction of the main line
   if (Main(idx) < Signal(idx)) {
      if (IS_PATTERN_USAGE(0)) result = m_pattern_0;
      if (IS_PATTERN_USAGE(1) && Signal(idx) - Main(idx)  > m_adjusted_threshold) result = m_pattern_1;
   }
//--- return the result
   return(result);
  }
//+------------------------------------------------------------------+
