//+------------------------------------------------------------------+
//|                                                   SignalDEMA.mqh |
//|                   Copyright 2009-2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#include <Expert\ExpertSignal.mqh>
// wizard description start
//+------------------------------------------------------------------+
//| Description of the class                                         |
//| Title=Signals of indicator 'Moving Average'                      |
//| Type=SignalAdvanced                                              |
//| Name=Moving Average Trend                                        |
//| ShortName=MAT                                                    |
//| Class=CSignalMAT                                                 |
//| Page=signal_emat                                                 |
//| Parameter=PeriodMA,int,12,Period of averaging                    |
//| Parameter=MAMethod,ENUM_MA_METHOD,EMA,MA method applied            |
//| Parameter=Shift,int,0,Time shift                                 |
//| Parameter=Applied,ENUM_APPLIED_PRICE,PRICE_CLOSE,Prices series   |
//| Parameter=Lookback,int,4,Period to determine trend direction     |
//+------------------------------------------------------------------+
// wizard description end
//+------------------------------------------------------------------+
//| Class CSignalMAT.                                                |
//| Purpose: Class of generator of trade signals based on            |
//|          the 'Moving Average' indicator                          |
//|          intended to determine trend direction                   |
//| Is derived from the CExpertSignal class.                         |
//+------------------------------------------------------------------+
class CSignalMAT : public CExpertSignal
  {
protected:
   CiMA              m_ma;             // object-indicator
   //--- adjusted parameters
   int               m_ma_period;      // the "period of averaging" parameter of the indicator
   int               m_ma_shift;       // the "time shift" parameter of the indicator
   int               m_ma_lookback;    // the number of periods to look back to determine trend
   double               m_ma_threshold;    // the threshold (in pips) for confirming trend
   double m_adjusted_ma_threshold;
   ENUM_APPLIED_PRICE m_ma_applied;    // the "object of averaging" parameter" of the indicator
   ENUM_MA_METHOD    m_ma_method;        // the MA type
   //--- "weights" of market models (0-100)
   int               m_pattern_0;      // model 0 "price is on the necessary side from the indicator"
   int               m_pattern_1;      // model 1 "trend is reversing"


public:
                     CSignalMAT(void);
                    ~CSignalMAT(void);
   //--- methods of setting adjustable parameters
   void              PeriodMA(int value)                 { m_ma_period=value;          }
   void              Shift(int value)                    { m_ma_shift=value;           }
   void              MAMethod(ENUM_MA_METHOD value)      { m_ma_method=value;          }
   void              Lookback(int value)                 { m_ma_lookback=value;        }
   void              Threshold(double value)                 { m_ma_threshold=value; m_adjusted_ma_threshold=m_ma_threshold*m_adjusted_point;       }
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
   double            DiffMA(int ind)                     { return(MA(ind)-MA(ind+1));  }
   double            DiffOpenMA(int ind)                 { return(Open(ind)-MA(ind));  }
   double            DiffHighMA(int ind)                 { return(High(ind)-MA(ind));  }
   double            DiffLowMA(int ind)                  { return(Low(ind)-MA(ind));   }
   double            DiffCloseMA(int ind)                { return(Close(ind)-MA(ind)); }
   double            MADiffSum(int idx = 1);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSignalMAT::CSignalMAT(void) : m_ma_period(12),
                                 m_ma_shift(0),
                                 m_ma_applied(PRICE_CLOSE),
                                 m_ma_method(MODE_EMA),
                                 m_ma_threshold(0),
                                 m_ma_lookback(4),
                                 m_pattern_0(20),
                                 m_pattern_1(100)
  {
//--- initialization of protected data
   m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalMAT::~CSignalMAT(void)
  {
  }
//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool CSignalMAT::ValidationSettings(void)
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
   if(m_ma_lookback<=0)
     {
      printf(__FUNCTION__+": lookback period must be greater than 0");
      return(false);
     }
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool CSignalMAT::InitIndicators(CIndicators *indicators)
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
bool CSignalMAT::InitMA(CIndicators *indicators)
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
//--- ok
   return(true);
  }
  
//+------------------------------------------------------------------+
//| Total MA diff                                                    |
//+------------------------------------------------------------------+  
double CSignalMAT::MADiffSum(int idx = 1) {
   double total = 0;
   for (int i = 1; i <= m_ma_lookback+1; i++) {
      total += MA(i)-MA(i+1);
   }
   return(total);
}
 
//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int CSignalMAT::LongCondition(void)
  {
   int result=0;
   int idx   =StartIndex();
   
   if (IS_PATTERN_USAGE(1) && MADiffSum() > m_adjusted_ma_threshold) result = m_pattern_1;
   
   return(result);
  }
//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int CSignalMAT::ShortCondition(void)
  {
   int result=0;
   int idx   =StartIndex();
   
   if (IS_PATTERN_USAGE(1) && MADiffSum() < -m_adjusted_ma_threshold) result = m_pattern_1;
   
   return(result);
  }
//+------------------------------------------------------------------+
