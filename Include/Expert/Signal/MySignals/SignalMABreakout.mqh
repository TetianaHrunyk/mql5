//+------------------------------------------------------------------+
//|                                             SignalMABreakout.mqh |
//+------------------------------------------------------------------+
#include <Expert\ExpertSignal.mqh>
#include <Indicators\MyIndicators\PlainExtendedMAs.mqh>
// wizard description start
//+------------------------------------------------------------------+
//| Description of the class                                         |
//| Title=Signal 'Moving Average Breakout'                           |
//| Type=SignalAdvanced                                              |
//| Name=Moving Average Breakout                                     |
//| ShortName=MABreakout                                             |
//| Class=CSignalMABreakout                                          |
//| Page=signal_mabreakout                                           |
//| Parameter=PeriodMA,int,12,Period of averaging                    |
//| Parameter=MAMethod,ENUM_MA_METHOD,MODE_EMA,MA method applied     |
//| Parameter=Shift,int,0,Time shift                                 |
//| Parameter=Applied,ENUM_APPLIED_PRICE,PRICE_CLOSE,Prices series   |
//| Parameter=Threshold,int,4,Distance from MA in pips to act        |
//+------------------------------------------------------------------+
// wizard description end
//+------------------------------------------------------------------+
//| Class CSignalMABreakout.                                         |
//| Purpose: Class of generator of trade signals based on            |
//|          the 'Moving Average' indicator                          |
//|          intended to determine Abreakout                         |
//| Is derived from the CExpertSignal class.                         |
//+------------------------------------------------------------------+
class CSignalMABreakout : public CExpertSignal
  {
protected:
   CiMA              m_ma;             // object-indicator
   CiPMASlope         m_ma_slope;            // object-indicator
   //--- adjusted parameters
   int               m_ma_period;      // the "period of averaging" parameter of the indicator
   int               m_ma_shift;       // the "time shift" parameter of the indicator
   double            m_ma_threshold;    // the threshold (in pips) for confirming trend
   double            m_adjusted_ma_threshold;
   int               m_candle_body;
   int               lookback;
   ENUM_APPLIED_PRICE m_ma_applied;    // the "object of averaging" parameter" of the indicator
   ENUM_MA_METHOD    m_ma_method;        // the MA type
   //--- "weights" of market models (0-100)
   int               m_pattern_0;      // model 0 "breakout: price is following the trend"
   int               m_pattern_1;      // model 1 "price is reversing"


public:
                     CSignalMABreakout(void);
                    ~CSignalMABreakout(void);
   //--- methods of setting adjustable parameters
   void              PeriodMA(int value)                 { m_ma_period=value;          }
   void              Shift(int value)                    { m_ma_shift=value;           }
   void              MAMethod(ENUM_MA_METHOD value)      { m_ma_method=value;          }
   void              Threshold(double value)             { m_ma_threshold=value; m_adjusted_ma_threshold=m_ma_threshold*m_adjusted_point;       }
   void              Applied(ENUM_APPLIED_PRICE value)   { m_ma_applied=value;         }
   //--- methods of adjusting "weights" of market models
   void              Pattern_0(int value)                { m_pattern_0=value;          }
   void              Pattern_1(int value)                { m_pattern_1=value;          }
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
   double            MA(int ind)                         { return(m_ma.Main(ind));     }
   double            Slope(int ind)                      { return(m_ma_slope.Main(ind));     }
   double            DiffMA(int ind)                     { return(MA(ind)-MA(ind+1));  }
   double            DiffOpenMA(int ind)                 { return(Open(ind)-MA(ind));  }
   double            DiffHighMA(int ind)                 { return(High(ind)-MA(ind));  }
   double            DiffLowMA(int ind)                  { return(Low(ind)-MA(ind));   }
   double            DiffCloseMA(int ind)                { return(Close(ind)-MA(ind)); }
   bool              BarRising(int idx)                  { return(Close(idx) > Open(idx));}
   bool              BarFalling(int idx)                 { return(Close(idx) < Open(idx));}
   bool              HasBody(int idx)                        { return (MathAbs(Open(idx)-Close(idx))>m_candle_body*m_adjusted_point);}
   bool              BreakUp(void);
   bool              BreakDown(void);
   bool              GoodLongBar(void);
   bool              GoodShortBar(void);

  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSignalMABreakout::CSignalMABreakout(void) : m_ma_period(12),
   m_ma_shift(0),
   m_ma_applied(PRICE_CLOSE),
   m_ma_method(MODE_EMA),
   m_ma_threshold(0),
   lookback(5),
   m_candle_body(1),
   m_pattern_0(100),
   m_pattern_1(100)
  {
//--- initialization of protected data
   m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalMABreakout::~CSignalMABreakout(void)
  {
  }
//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool CSignalMABreakout::ValidationSettings(void)
  {
//--- call of the method of the parent class
   if(!CExpertSignal::ValidationSettings())
      return(false);
//--- initial data checks
   if(m_ma_period<=0)
     {
      printf(__FUNCTION__+": period MA must be greater than 0");
      return(false);
     }
   if(m_ma_threshold<0)
     {
      printf(__FUNCTION__+": threshold period must be greater than 0");
      return(false);
     }
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool CSignalMABreakout::InitIndicators(CIndicators *indicators)
  {
//--- check pointer
   if(indicators==NULL)
      return(false);
//--- initialization of indicators and timeseries of additional filters
   if(!CExpertSignal::InitIndicators(indicators))
      return(false);
//--- create and initialize DEMA indicator
   if(!InitMA(indicators))
      return(false);
//--- ok
   m_adjusted_ma_threshold = m_ma_threshold*m_adjusted_point;
   return(true);
  }
//+------------------------------------------------------------------+
//| Create MA indicators.                                            |
//+------------------------------------------------------------------+
bool CSignalMABreakout::InitMA(CIndicators *indicators)
  {
//--- check pointer
   if(indicators==NULL)
      return(false);
//--- add indicator to collection
   if(!indicators.Add(GetPointer(m_ma)))
     {
      printf(__FUNCTION__+": error adding object");
      return(false);
     }
//--- initialize indicator
   if(!m_ma.Create(m_symbol.Name(),m_period,m_ma_period,m_ma_shift,m_ma_method,m_ma_applied))
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
//--- initialize object
   if(!m_ma_slope.Create(m_symbol.Name(),m_period,1,m_ma_period,0,m_ma_method,m_ma_applied))
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
//--- ok
   return(true);
//--- ok
   return(true);
  }

//+------------------------------------------------------------------+
//|  BreakUp                                                         |
//+------------------------------------------------------------------+
bool CSignalMABreakout::BreakUp(void)
  {
   int idx   =StartIndex();

   bool pre_prev_bar = BarRising(idx+2) && Open(idx+2) < MA(idx+2) && Close(idx+2) > MA(idx+2) && Slope(idx+2) > m_adjusted_ma_threshold && HasBody(idx+2);
   bool prev_bar = BarRising(idx+1) && Open(idx+1) > MA(idx+2) && Slope(idx+1) > m_adjusted_ma_threshold && HasBody(idx+1);
   bool cur_bar = m_symbol.Ask() > MA(idx) && Slope(idx+1) > m_adjusted_ma_threshold;

   return (pre_prev_bar && prev_bar && cur_bar);
  }

//+------------------------------------------------------------------+
//|  BreakDown                                                       |
//+------------------------------------------------------------------+
bool CSignalMABreakout::BreakDown(void)
  {
   int idx   =StartIndex();

   bool pre_prev_bar = BarFalling(idx+2) && Open(idx+2) > MA(idx+2) && Close(idx+2) < MA(idx+2) && Slope(idx+2) < -m_adjusted_ma_threshold && HasBody(idx+2);
   bool prev_bar = BarFalling(idx+1) && Open(idx+1) < MA(idx+2) && Slope(idx+1) < -m_adjusted_ma_threshold && HasBody(idx+1);
   bool cur_bar = m_symbol.Bid() < MA(idx) && Slope(idx+1) < - m_adjusted_ma_threshold;

   return (pre_prev_bar && prev_bar && cur_bar);
  }

//+------------------------------------------------------------------+
//|  Potentially profitable bar for long position                    |
//+------------------------------------------------------------------+
bool CSignalMABreakout::GoodLongBar(void)
  {
// Check that bar is rising and has body with a top wick
   bool res = true;
   for(int idx = 1; idx < lookback; idx++)
     {
      bool has_wick = High(idx) - Close(idx) > m_adjusted_ma_threshold*0.2;
      if(!BarRising(idx))
        {
         res = false;
         break;
        }
     }
   return res;
  }

//+------------------------------------------------------------------+
//|  Potentially profitable bar for short position                   |
//+------------------------------------------------------------------+
bool CSignalMABreakout::GoodShortBar(void)
  {
// Check that bar is falling and has body with a bottom wick
   bool res = true;
   for(int idx = 1; idx < lookback; idx++)
     {
      bool has_wick = Close(idx)-Low(idx) > m_adjusted_ma_threshold*0.2;
      if(!BarFalling(idx))
        {
         res = false;
         break;
        }
     }
   return res;

  }

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int CSignalMABreakout::LongCondition(void)
  {
   int result=0;
   int idx   =StartIndex();


   if(IS_PATTERN_USAGE(0) && BreakUp())
      result = m_pattern_0;

   return(result);
  }
//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int CSignalMABreakout::ShortCondition(void)
  {
   int result=0;
   int idx = StartIndex();


   if(IS_PATTERN_USAGE(0) && BreakDown())
      result = m_pattern_0;


   return(result);
  }
//+------------------------------------------------------------------+
