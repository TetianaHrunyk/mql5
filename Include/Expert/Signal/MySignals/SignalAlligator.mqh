//+------------------------------------------------------------------+
//|                                                     SignalBB.mqh |
//+------------------------------------------------------------------+
#include <Expert\ExpertSignal.mqh>
#include <Trade\PositionInfo.mqh>
#include <Indicators\BillWilliams.mqh>
// wizard description start
//+------------------------------------------------------------------+
//| Description of the class                                         |
//| Title=Signals of indicator 'Alligator'                           |
//| Type=SignalAdvanced                                              |
//| Name=Alligator                                                   |
//| ShortName=Alligator                                              |
//| Class=CSignalAlligator                                           |
//| Page=signal_Alligator                                            |
//| Parameter=JawPeriod,int,13,Jaw Period                            |
//| Parameter=JawShift,int,8,Jaw Shift                               |
//| Parameter=TeethPeriod,int,8,Teeth Period                         |
//| Parameter=TeethShift,int,5,Teeth Shift                           |
//| Parameter=LipsPeriod,int,5,Lips Period                           |
//| Parameter=LipsShift,int,3,Lips Shift                             |
//| Parameter=DiffTight,int,10,Diff in pip for tight                 |
//| Parameter=DiffApart,int,5,Diff in pip for apart                  |
//| Parameter=Lookback,int,0,Number of prior periods to consider     |
//+------------------------------------------------------------------+
// wizard description end
//+------------------------------------------------------------------+
//| Class CSignalAlligator.                                          |
//| Purpose: Class of generator of trade signals based on            |
//|          the 'Alligator' indicator.                              |
//| Is derived from the CExpertSignal class.                         |
//+------------------------------------------------------------------+

enum SIGNAL
  {
   BUY = 1,
   SELL = -1,
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CSignalAlligator : public CExpertSignal
  {
protected:
   CiAlligator       m_alligator;             // object-indicator
   CPositionInfo     m_position;                 // position info object
   //--- adjusted parameters
   int               m_jaw_period;      // the jaw period
   int               m_jaw_shift;      // the jaw shift

   int               m_teeth_period;      // the teeth period
   int               m_teeth_shift;      // the teeth shift

   int               m_lips_period;      // the lips period
   int               m_lips_shift;      // the lips shift

   ENUM_MA_METHOD     m_ma_method;     // MA method applied
   ENUM_APPLIED_PRICE m_ma_applied;    // the "object of averaging" parameter of the indicator

   int                m_lookback;      // Number of periods to look back
   int                m_tight_diff;    // Pips to consider lines as tight
   int                m_apart_diff;    // Pips to consider lines as wide apart
   double             m_adjusted_tight_diff;    // Pips to consider lines as tight
   double             m_adjusted_apart_diff;    // Pips to consider lines as wide apart

   //--- "weights" of market models (0-100)
   int               m_pattern_0;      // model 0: Lines are close
   int               m_pattern_1;      // model 1: Lines are wide apart
   //int               m_pattern_2;      // model 2: Prev close crossed BB2
   //int               m_pattern_3;      // model 3: Cross and fail to cross

public:
                     CSignalAlligator(void);
                    ~CSignalAlligator(void);
   //--- methods of setting adjustable parameters

   void              JawPeriod(int value)                 { m_jaw_period=value;         }
   void              JawShift(int value)                  { m_jaw_shift=value;          }

   void              TeethPeriod(int value)                 { m_teeth_period=value;         }
   void              TeethShift(int value)                  { m_teeth_shift=value;          }

   void              LipsPeriod(int value)                 { m_lips_period=value;         }
   void              LipsShift(int value)                  { m_lips_shift=value;          }

   void              MAMethod(ENUM_MA_METHOD value)       { m_ma_method=value;         }
   void              Applied(ENUM_APPLIED_PRICE value)   { m_ma_applied=value;         }

   void              Lookback(int value)                { m_lookback=value;           }
   void              DiffTight(int value)                { m_tight_diff=value;  m_adjusted_tight_diff=value=m_adjusted_point;   }
   void              DiffApart(int value)                { m_apart_diff=value;  m_adjusted_apart_diff=value=m_adjusted_point;   }

   //--- methods of adjusting "weights" of market models
   void              Pattern_0(int value)                { m_pattern_0=value;          }
   void              Pattern_1(int value)                { m_pattern_1=value;          }
   //void              Pattern_2(int value)                { m_pattern_2=value;          }
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
   bool              InitAlligator(CIndicators *indicators);
   //--- helper methods
   int               CheckModel0(SIGNAL signal);
   int               CheckModel1(SIGNAL signal);
   //int               CheckModel2(SIGNAL signal);
   //int               CheckModel3(SIGNAL signal);

   // Helpers:
   double            Jaw(int idx)                             {return m_alligator.Jaw(idx);}
   double            Lips(int idx)                             {return m_alligator.Lips(idx);}
   double            Teeth(int idx)                             {return m_alligator.Teeth(idx);}
   bool              SelectPosition(void);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSignalAlligator::CSignalAlligator(void) :
   m_jaw_period(13),
   m_jaw_shift(8),
   m_teeth_period(8),
   m_teeth_shift(5),
   m_lips_period(5),
   m_lips_shift(3),
   m_ma_method(MODE_SMA),
   m_ma_applied(PRICE_CLOSE),
   m_pattern_0(100),
   m_pattern_1(100),
//m_pattern_2(80),
//m_pattern_3(80),
   m_lookback(0),
   m_tight_diff(5),
   m_apart_diff(10)
  {
//--- initialization of protected data
   m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
   m_adjusted_tight_diff = m_tight_diff*m_adjusted_point;
   m_adjusted_apart_diff = m_apart_diff*m_adjusted_point;
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalAlligator::~CSignalAlligator(void)
  {
  }
//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool CSignalAlligator::ValidationSettings(void)
  {
//--- validation settings of additional filters
   if(!CExpertSignal::ValidationSettings())
      return(false);
   if(m_jaw_period<=0 || m_jaw_shift < 0 || m_teeth_period <= 0 || m_teeth_shift < 0 || m_lips_period <= 0 || m_lips_shift < 0)
     {
      printf(__FUNCTION__+": period MA must be greater than 0");
      return(false);
     }
   if(m_lookback<0)
     {
      printf(__FUNCTION__+": period Lookback must be at least 0");
      return(false);
     }
   Print("Pattern usage: ", m_patterns_usage);
   Print("Model 0: ", IS_PATTERN_USAGE(0));
//Print("Model 1: ", IS_PATTERN_USAGE(1));
//Print("Model 2: ", IS_PATTERN_USAGE(2));
//Print("Model 3: ", IS_PATTERN_USAGE(3));
   return(true);
  }
//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool CSignalAlligator::InitIndicators(CIndicators *indicators)
  {
//--- check pointer
   if(indicators==NULL)
      return(false);
//--- initialization of indicators and timeseries of additional filters
   if(!CExpertSignal::InitIndicators(indicators))
      return(false);
//--- create and initialize Alligator indicator
   if(!InitAlligator(indicators))
      return(false);
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Initialize BB indicators.                                        |
//+------------------------------------------------------------------+
bool CSignalAlligator::InitAlligator(CIndicators *indicators)
  {
//--- check pointer
   if(indicators==NULL)
      return(false);
//--- add Alligator object to collection
   if(!indicators.Add(GetPointer(m_alligator)))
     {
      printf(__FUNCTION__+": error adding inner Alligator object");
      return(false);
     }
   if(!m_alligator.Create(m_symbol.Name(),m_period,m_jaw_period, m_jaw_shift, m_teeth_period, m_teeth_shift, m_lips_period, m_lips_shift, m_ma_method, m_ma_applied))
     {
      printf(__FUNCTION__+": error initializing inner Alligator object");
      return(false);
     }
   return(true);
  }

//+------------------------------------------------------------------+
//| Position select depending on netting or hedging                  |
//+------------------------------------------------------------------+
bool CSignalAlligator::SelectPosition(void)
  {
   bool res=false;
//---
   if(IsHedging())
      res=m_position.SelectByMagic(m_symbol.Name(),m_magic);
   else
      res=m_position.Select(m_symbol.Name());
//---
   return(res);
  }


//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int CSignalAlligator::LongCondition(void)
  {
   int result=0;

   if(IS_PATTERN_USAGE(0))
      result=CheckModel0(BUY);
   if(IS_PATTERN_USAGE(1))
      result=CheckModel1(BUY);
//if(IS_PATTERN_USAGE(2))
//   result=CheckModel2(BUY);
//if(IS_PATTERN_USAGE(3))
//   result=CheckModel3(BUY);

   return(result);
  }
//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int CSignalAlligator::ShortCondition(void)
  {
   int result = 0;

   if(IS_PATTERN_USAGE(0))
      result=CheckModel0(SELL);
   if(IS_PATTERN_USAGE(1))
      result=CheckModel1(SELL);
//if(IS_PATTERN_USAGE(2))
//   result=CheckModel2(SELL);
//if(IS_PATTERN_USAGE(3))
//   result=CheckModel3(SELL);

   return(result);
  }

//+------------------------------------------------------------------+
//| Model 0: Lines are close
//+------------------------------------------------------------------+
int CSignalAlligator::CheckModel0(SIGNAL signal)
  {
// Model 0 only for closing positions
   int res = 0;
   int idx = StartIndex();

   if(SelectPosition())
     {
      if(signal == BUY)
        {
         if(Lips(idx)-Jaw(idx) >= m_adjusted_tight_diff && Lips(idx) > Teeth(idx))
            res = m_pattern_0;
        }
      if(signal == SELL)
        {
         if(Lips(idx)-Jaw(idx) <= -m_adjusted_tight_diff && Lips(idx) < Teeth(idx))
            res = m_pattern_0;
        }
     }

   return(res);
  }


//+------------------------------------------------------------------+
//| Model 1: Lines are wide apart                                    |
//+------------------------------------------------------------------+
int CSignalAlligator::CheckModel1(SIGNAL signal)
  {
  //Model 1 only intended for opening positions
   int res = 0;
   int idx = StartIndex();

   if(!SelectPosition())
     {
      if(signal == BUY)
        {
         if(Lips(idx)-Jaw(idx) >= m_adjusted_apart_diff && Lips(idx) > Teeth(idx) && Close(idx) > Lips(idx))
            res = m_pattern_1;
        }
      if(signal == SELL)
        {
         if(Lips(idx)-Jaw(idx) <= -m_adjusted_apart_diff && Lips(idx) < Teeth(idx) && Close(idx) < Jaw(idx))
            res = m_pattern_1;
        }
     }

   return(res);
  }


////+------------------------------------------------------------------+
////| Model 2:                                        |
////+------------------------------------------------------------------+
//int CSignalAlligator::CheckModel2(SIGNAL signal)
//  {
//   int res = 0;
//
//   return(res);
//  }
//
////+------------------------------------------------------------------+
////| Model 3:                          |
////+------------------------------------------------------------------+
//int CSignalAlligator::CheckModel3(SIGNAL signal)
//  {
//   int res = 0;
//
//   return(res);
//  }
