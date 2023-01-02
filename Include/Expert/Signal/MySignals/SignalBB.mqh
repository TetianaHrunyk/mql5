//+------------------------------------------------------------------+
//|                                                     SignalBB.mqh |
//+------------------------------------------------------------------+
#include <Expert\ExpertSignal.mqh>
#include <Indicators\Trend.mqh>
// wizard description start
//+------------------------------------------------------------------+
//| Description of the class                                         |
//| Title=Signals of indicator 'Bollinger Bands'                     |
//| Type=SignalAdvanced                                              |
//| Name=Bollinger Bands                                             |
//| ShortName=BB                                                     |
//| Class=CSignalBB                                                  |
//| Page=signal_bb                                                   |
//| Parameter=PeriodMA,int,20,Period of the main line                |
//| Parameter=Shift,int,0,Time shift                                 |
//| Parameter=Applied,ENUM_APPLIED_PRICE,PRICE_CLOSE,Prices series   |
//| Parameter=iMAPeriodMA,int,7,Extra MA period                      |
//| Parameter=iMAShift,int,0,Extra MA period time shift              |
//| Parameter=iMAApplied,ENUM_APPLIED_PRICE,PRICE_CLOSE,Prices series|
//| Parameter=iMAMethod,ENUM_APPLIED_PRICE,MODE_EMA,Extra MA method  |
//| Parameter=MALookback,int,5,MA lookback                           |
//| Parameter=Lookback,int,4,Periods to look back                    |
//| Parameter=Threshold,int,0,Pips to adjust touch                   |
//| Parameter=TradeRange,TRADE_RANGE,ANY,BB price range to trade     |
//| Parameter=TradeRangeWeight,int,1,Weight of the trade range       |
//+------------------------------------------------------------------+
// wizard description end
//+------------------------------------------------------------------+
//| Class CSignalBB.                                                 |
//| Purpose: Class of generator of trade signals based on            |
//|          the 'Bollinger Bands' indicator.                        |
//| Is derived from the CExpertSignal class.                         |
//+------------------------------------------------------------------+

enum SIGNAL
  {
   BUY = 1,
   SELL = -1,
  };

enum TRADE_RANGE
  {
   CORRIDOR,
   EDGES,
   ANY,
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CSignalBB : public CExpertSignal
  {
protected:
   CiBands              m_bands_1;
   CiBands              m_bands_2;
   CiMA                 m_ma;
   //--- BB parameters
   int               m_bb_ma_period;      // the "period of averaging" parameter of the indicator
   int               m_bb_ma_shift;       // the "time shift" parameter of the indicator
   double            m_bb_std_inner;       // the std of the inner bollinger bands
   double            m_bb_std_outer;       // the std of the outer bollinger bands
   ENUM_APPLIED_PRICE m_bb_ma_applied;    // the "object of averaging" parameter of the indicator

   //--- MA parameters
   int               m_ma_period;      // ma period
   int               m_ma_shift;       // ma shift
   ENUM_MA_METHOD    m_ma_method;      // ma_method
   ENUM_APPLIED_PRICE m_ma_applied;    // ma price applied

   // --- signal specific parameters
   TRADE_RANGE        m_trade_range;   //trade range to trade
   int               m_lookback;    // Number of bars to look back
   double            m_threshold;      // Points to consider as touch
   int               m_trade_range_weight;      // Trade range weight
   int               m_ma_lookback;

   //--- "weights" of market models (0-100)
   int               m_pattern_0;      // model 0: Current price crosses BB2
   int               m_pattern_1;      // model 1: Prev extremum crossed BB2
   int               m_pattern_2;      // model 2: Prev close crossed BB2
   int               m_pattern_3;      // model 3: Cross and fail to cross
   int               m_pattern_4;      // model 4: MA Trend

public:
                     CSignalBB(void);
                    ~CSignalBB(void);
   //--- BB parameters
   void              PeriodMA(int value)                 { m_bb_ma_period=value;          }
   void              Shift(int value)                    { m_bb_ma_shift=value;           }
   void              StdInner(int value)                 { m_bb_std_inner=value;       }
   void              StdOuter(int value)                 { m_bb_std_outer=value;       }
   void              Applied(ENUM_APPLIED_PRICE value)   { m_bb_ma_applied=value;         }

   // --- MA parameters
   void              iMAPeriodMA(int value)                 { m_ma_period=value;          }
   void              iMAShift(int value)                    { m_ma_shift=value;           }
   void              iMAMethod(int value)                   { m_ma_method=value;           }
   void              iMAApplied(ENUM_APPLIED_PRICE value)   { m_ma_applied=value;         }

   // --- signal specific parameters
   void              Lookback(int value)                 { m_lookback=value;           }
   void              MALookback(int value)               { m_ma_lookback=value;           }
   void              Threshold(int value)                { m_threshold=value*m_adjusted_point;}
   void              TradeRangeWeight(int value)         { m_trade_range_weight=value; }
   void              TradeRange(TRADE_RANGE value)       { m_trade_range=value;}

   //--- methods of adjusting "weights" of market models
   void              Pattern_0(int value)                { m_pattern_0=value;          }
   void              Pattern_1(int value)                { m_pattern_1=value;          }
   void              Pattern_2(int value)                { m_pattern_2=value;          }
   void              Pattern_3(int value)                { m_pattern_3=value;          }
   void              Pattern_4(int value)                { m_pattern_4=value;          }
   //--- method of verification of settings
   virtual bool      ValidationSettings(void);
   //--- method of creating the indicator and timeseries
   virtual bool      InitIndicators(CIndicators *indicators);
   //--- methods of checking if the market models are formed
   virtual int       LongCondition(void);
   virtual int       ShortCondition(void);

protected:
   //--- method of initialization of the indicator
   bool              InitBB(CIndicators *indicators);
   //--- helper methods
   int               CheckModel0(SIGNAL signal);
   int               CheckModel1(SIGNAL signal);
   int               CheckModel2(SIGNAL signal);
   int               CheckModel3(SIGNAL signal);
   int               CheckModel4(SIGNAL signal);
   double            AdjustHigh(double price) {return price+m_threshold;};
   double            AdjustLow(double price) {return price-m_threshold;};
   int               IsPriceRangeValid(SIGNAL opportunity);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSignalBB::CSignalBB(void) : m_bb_ma_period(12),
   m_bb_ma_shift(0),
   m_bb_ma_applied(PRICE_CLOSE),
   m_bb_std_inner(1),
   m_bb_std_outer(2),
   m_ma_period(7),
   m_ma_shift(0),
   m_ma_method(MODE_EMA),
   m_ma_applied(PRICE_CLOSE),
   m_lookback(1),
   m_ma_lookback(5),
   m_threshold(0),
   m_trade_range(ANY),
   m_trade_range_weight(1),
   m_pattern_0(50),
   m_pattern_1(60),
   m_pattern_2(80),
   m_pattern_3(80),
   m_pattern_4(70)
  {
//--- initialization of protected data
   m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalBB::~CSignalBB(void)
  {
  }
//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool CSignalBB::ValidationSettings(void)
  {
//--- validation settings of additional filters
   if(!CExpertSignal::ValidationSettings())
      return(false);
   if(m_bb_ma_period<=0)
     {
      printf(__FUNCTION__+": period MA must be greater than 0");
      return(false);
     }
   if(m_lookback<0)
     {
      printf(__FUNCTION__+": period Loockback must be at least 0");
      return(false);
     }
   if(m_threshold<0)
     {
      printf(__FUNCTION__+": period Threshold must be at least 0");
      return(false);
     }
   if(m_bb_std_inner<=0 || m_bb_std_outer <=0 || m_bb_std_inner >= m_bb_std_outer)
     {
      printf(__FUNCTION__+": invalid setting for bb deviation");
      return(false);
     }
   return(true);
  }
//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool CSignalBB::InitIndicators(CIndicators *indicators)
  {
//--- check pointer
   if(indicators==NULL)
      return(false);
//--- initialization of indicators and timeseries of additional filters
   if(!CExpertSignal::InitIndicators(indicators))
      return(false);
//--- create and initialize BB indicator
   if(!InitBB(indicators))
      return(false);
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Initialize BB indicators.                                        |
//+------------------------------------------------------------------+
bool CSignalBB::InitBB(CIndicators *indicators)
  {
//--- check pointer
   if(indicators==NULL)
      return(false);
//--- add Bollinger Bands object to collection
   if(!indicators.Add(GetPointer(m_bands_1)))
     {
      printf(__FUNCTION__+": error adding inner BB object");
      return(false);
     }
   if(!m_bands_1.Create(m_symbol.Name(),m_period,m_bb_ma_period,m_bb_ma_shift,m_bb_std_inner,m_bb_ma_applied))
     {
      printf(__FUNCTION__+": error initializing inner BB object");
      return(false);
     }
   if(!indicators.Add(GetPointer(m_bands_2)))
     {
      printf(__FUNCTION__+": error adding outer BB object");
      return(false);
     }
   if(!m_bands_2.Create(m_symbol.Name(),m_period,m_bb_ma_period,m_bb_ma_shift,m_bb_std_outer,m_bb_ma_applied))
     {
      printf(__FUNCTION__+": error initializing outer BB object");
      return(false);
     }
   if(!indicators.Add(GetPointer(m_ma)))
     {
      printf(__FUNCTION__+": error adding MA object");
      return(false);
     }
   if(!m_ma.Create(m_symbol.Name(),m_period,m_ma_period,m_ma_shift,m_ma_method,m_ma_applied))
     {
      printf(__FUNCTION__+": error initializing outer BB object");
      return(false);
     }
   return(true);
  }
//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int CSignalBB::LongCondition(void)
  {
   int result=0;
   int trade_range_weight = IsPriceRangeValid(BUY) * m_trade_range_weight;

   if(IS_PATTERN_USAGE(0))
      result=CheckModel0(BUY);
   if(IS_PATTERN_USAGE(1))
      result=MathMax(result, CheckModel1(BUY));
   if(IS_PATTERN_USAGE(2))
      result=MathMax(result, CheckModel2(BUY));
   if(IS_PATTERN_USAGE(3))
     {
      if(!IS_PATTERN_USAGE(4) || !CheckModel4(SELL))
         result=MathMax(result, CheckModel3(BUY));
     }
   if(IS_PATTERN_USAGE(4))
      result=MathMax(result, CheckModel4(BUY));

   return(result*trade_range_weight);
  }
//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int CSignalBB::ShortCondition(void)
  {
   int result = 0;
   int trade_range_weight = IsPriceRangeValid(SELL) * m_trade_range_weight;

   if(IS_PATTERN_USAGE(0))
      result=CheckModel0(SELL);
   if(IS_PATTERN_USAGE(1))
      result=MathMax(result, CheckModel1(SELL));
   if(IS_PATTERN_USAGE(2))
      result=MathMax(result, CheckModel2(SELL));
   if(IS_PATTERN_USAGE(3))
      if(!IS_PATTERN_USAGE(4) || !CheckModel4(BUY))
         result=MathMax(result, CheckModel3(SELL));
   if(IS_PATTERN_USAGE(4))
      result=MathMax(result, CheckModel4(SELL));

   return(result*trade_range_weight);
  }

//+------------------------------------------------------------------+
//| Model 0: Current extremum crossed BB
//+------------------------------------------------------------------+
int CSignalBB::CheckModel0(SIGNAL signal)
  {

   int res = 0;
   int idx = StartIndex();

   if(signal == SELL)
      if(Open(idx) > m_bands_2.Upper(idx))
         res = m_pattern_0;

   if(signal == BUY)
      if(Close(idx) < m_bands_2.Lower(idx))
         res = m_pattern_0;

   return(res);
  }


//+------------------------------------------------------------------+
//| Model 1: Extremum crosses BB2                                    |
//+------------------------------------------------------------------+
int CSignalBB::CheckModel1(SIGNAL signal)
  {
   int res = 0;
   int idx = StartIndex();

   if(signal == SELL)
      for(int i = StartIndex(); i <= MathMax(m_lookback+idx, idx+1); i++)
        {
         if(AdjustHigh(High(i)) >= m_bands_2.Upper(i))
            res = m_pattern_1;
        }

   if(signal == BUY)
      for(int i = StartIndex(); i <= MathMax(m_lookback+idx, idx+1); i++)
        {
         if(AdjustLow(Low(i)) <= m_bands_2.Lower(i))
            res = m_pattern_1;
        }

   return(res);
  }


//+------------------------------------------------------------------+
//| Model 2: Close crosses BB2                                       |
//+------------------------------------------------------------------+
int CSignalBB::CheckModel2(SIGNAL signal)
  {
   int res = 0;
   int idx = StartIndex();

   if(signal == SELL)
      for(int i = StartIndex(); i <= MathMax(m_lookback+idx, idx+1); i++)
        {
         if(AdjustHigh(Open(i)) >= m_bands_2.Upper(i))
           {
            res = m_pattern_2;
            break;
           }
        }

   if(signal == BUY)
      for(int i = StartIndex(); i <= MathMax(m_lookback+idx, idx+1); i++)
        {
         if(AdjustLow(Close(i)) <= m_bands_2.Lower(i))
           {
            res = m_pattern_2;
            break;
           }
        }

   return(res);
  }

//+------------------------------------------------------------------+
//| Model 3: Crosses and then fails to cross                         |
//+------------------------------------------------------------------+
int CSignalBB::CheckModel3(SIGNAL signal)
  {
   int res = 0;
   int idx = StartIndex();

   if(signal == SELL)
      //if(Open(idx) < m_bands_2.Upper(idx) && Open(idx) > Close(idx))
      //  {
      for(int i = StartIndex()+1; i <= MathMax(m_lookback+idx, idx+1); i++)
        {
         if(Open(i) >= m_bands_2.Upper(i) && Close(i) <= m_bands_2.Upper(i))
           {
            res = m_pattern_3;
            break;
           }
         //}
        }

   if(signal == BUY)
      //if(Open(idx) > m_bands_2.Lower(idx) && Open(idx) < Close(idx))
      //{
      for(int i = StartIndex()+1; i <= MathMax(m_lookback+idx, idx+1); i++)
        {
         if(Open(i) <= m_bands_2.Lower(i) && Close(i) >= m_bands_2.Lower(i))
           {
            res = m_pattern_3;
            break;
           }
        }
//}

   return(res);
  }

//+------------------------------------------------------------------+
//| Model 4: MA Trend                                                |
//+------------------------------------------------------------------+
int CSignalBB::CheckModel4(SIGNAL signal)
  {
   int res = 0;
   int idx = StartIndex();
   int count = 0;
   int range = MathMax(m_ma_lookback+idx, idx+1);

   if(signal == SELL)
      for(int i = StartIndex(); i <= range; i++)
        {
         if(m_ma.Main(i) < m_ma.Main(i+1))
           {
            count++;
           }
        }

   if(signal == BUY)
      for(int i = StartIndex()+1; i <= range; i++)
        {
         if(m_ma.Main(i) > m_ma.Main(i+1))
           {
            count++;
           }
        }
   if(count >= range*0.9)
     {
      res = m_pattern_4;
     }
   return(res);
  }

//+------------------------------------------------------------------+
//|Check if the prices are in the correct range for opening a position
//+------------------------------------------------------------------+
int CSignalBB::IsPriceRangeValid(SIGNAL opportunity)
  {
   int idx   =StartIndex();
   bool res = 1;

   double price = Close(idx);

   if(m_trade_range == CORRIDOR)
     {
      if(price >= m_bands_1.Upper(idx) || price <= m_bands_1.Lower(idx))
         res = 0;
     }
   if(m_trade_range == EDGES)
     {
      res = 0;
      if(price > m_bands_1.Upper(idx) || price < m_bands_1.Lower(idx))
         res = 1;
     }
   return(res);
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
