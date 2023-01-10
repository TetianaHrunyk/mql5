//+------------------------------------------------------------------+
//|                                          2MALTFollowerSimple.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Expert\Expert.mqh>
//--- available signals
#include <Expert\Signal\MySignals\Signal2MA.mqh>
#include <Expert\Signal\SignalITF.mqh>
//--- available trailing
#include <Expert\Trailing\TrailingNone.mqh>
//--- available money management
#include <Expert\Money\MoneyFixedLot.mqh>
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
input string             Expert_Title                    ="2MALTFollowerSimple"; // Document name
ulong                    Expert_MagicNumber              =20891;                 //
bool                     Expert_EveryTick                =false;                 //
//--- inputs for main signal
input int                Signal_ThresholdOpen            =60;                    // Signal threshold value to open [0...100]
input int                Signal_ThresholdClose           =40;                    // Signal threshold value to close [0...100]
input double             Signal_PriceLevel               =0.0;                   // Price level to execute a deal
input double             Signal_StopLevel                =30.0;                  // Stop Loss level (in points)
input double             Signal_TakeLevel                =60.0;                  // Take Profit level (in points)
input int                Signal_Expiration               =4;                     // Expiration of pending orders (in bars)
      
input string             s1 = "";                                                // ----------------- Slow MA settings ----------------- 
// EURUDSD: 25 for longer term, 30 for more recent data                                            
input int                Signal_MA2_SlowPeriodMA         =30;                    // [S1] Period of slow averaging
input int                Signal_MA2_SlowShift            =2;                     // [S1] Time shift slow
input ENUM_MA_METHOD     Signal_MA2_SlowMethod           =MODE_SMA;              // [S1] Slow method
input ENUM_APPLIED_PRICE Signal_MA2_SlowApplied          =PRICE_CLOSE;           // [S1] Slow price

input string             s2 = "";                                                // ----------------- Fast MA settings ----------------- 
input int                Signal_MA2_FastPeriodMA         =14;                    // [S1]  Period of fast averaging
input int                Signal_MA2_FastShift            =1;                     // [S1]  Time shift fast
input ENUM_MA_METHOD     Signal_MA2_FastMethod           =MODE_EMA;              // [S1]  Fast method
input ENUM_APPLIED_PRICE Signal_MA2_FastApplied          =PRICE_CLOSE;           // [S1]  Fast price

input string             s3 = "";                                                // ----------------- Trend validation settings ---------
// EURUDSD: 19 for longer term, 21 for more recent data
input int                Signal_MA2_TrendValidationPeriod=21;                    // [S1]  Trend validtion period slow
input int                Signal_MA2_TrendValPeriodFast   =0;                     // [S1]  Trend validtion period fast
input double             Signal_MA2_TrendValRatio        =1;                     // [S1]  Trend validtion ratio
input int                Signal_MA2_TotalMAChange        =5;                     // [S1]  Total MA Change

double             Signal_MA2_Weight               =1.0;                        // [S1] Weight [0...1.0]

//input int                Signal_ITF_GoodHourOfDay        =-1;                    // IntradayTimeFilter(-1,0,-1,...) Good hour
//input int                Signal_ITF_BadHoursOfDay        =0;                     // IntradayTimeFilter(-1,0,-1,...) Bad hours (bit-map)
//input int                Signal_ITF_GoodDayOfWeek        =-1;                    // IntradayTimeFilter(-1,0,-1,...) Good day of week
//input int                Signal_ITF_BadDaysOfWeek        =0;                     // IntradayTimeFilter(-1,0,-1,...) Bad days of week (bit-map)
//input double             Signal_ITF_Weight               =1.0;                   // IntradayTimeFilter(-1,0,-1,...) Weight [0...1.0]

input string             s4 = "";                                                // ----------------- Money settings ----------------- 
input double             Money_FixLot_Percent            =10.0;                  // Percent
input double             Money_FixLot_Lots               =0.05;                  // Fixed volume
//+------------------------------------------------------------------+
//| Global expert object                                             |
//+------------------------------------------------------------------+
CExpert ExtExpert;
//+------------------------------------------------------------------+
//| Initialization function of the expert                            |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Initializing expert
   if(!ExtExpert.Init(Symbol(),Period(),Expert_EveryTick,Expert_MagicNumber))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing expert");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Creating signal
   CExpertSignal *signal=new CExpertSignal;
   if(signal==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating signal");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//---
   ExtExpert.InitSignal(signal);
   signal.ThresholdOpen(Signal_ThresholdOpen);
   signal.ThresholdClose(Signal_ThresholdClose);
   signal.PriceLevel(Signal_PriceLevel);
   signal.StopLevel(Signal_StopLevel);
   signal.TakeLevel(Signal_TakeLevel);
   signal.Expiration(Signal_Expiration);
//--- Creating filter CSignalMA2
   CSignalMA2 *filter0=new CSignalMA2;
   if(filter0==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating filter0");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
   signal.AddFilter(filter0);
//--- Set filter parameters
   filter0.SlowPeriodMA(Signal_MA2_SlowPeriodMA);
   filter0.SlowShift(Signal_MA2_SlowShift);
   filter0.SlowMethod(Signal_MA2_SlowMethod);
   filter0.SlowApplied(Signal_MA2_SlowApplied);
   
   filter0.FastPeriodMA(Signal_MA2_FastPeriodMA);
   filter0.FastShift(Signal_MA2_FastShift);
   filter0.FastMethod(Signal_MA2_FastMethod);
   filter0.FastApplied(Signal_MA2_FastApplied);
   
   filter0.TrendValidationPeriod(Signal_MA2_TrendValidationPeriod);
   filter0.TrendValPeriodFast(Signal_MA2_TrendValPeriodFast);
   filter0.TrendValRatio(Signal_MA2_TrendValRatio);
   filter0.TotalMAChange(Signal_MA2_TotalMAChange);
   filter0.Weight(Signal_MA2_Weight);
   filter0.PatternsUsage(10);
//--- Creating filter CSignalITF
//   CSignalITF *filter1=new CSignalITF;
//   if(filter1==NULL)
//     {
//      //--- failed
//      printf(__FUNCTION__+": error creating filter1");
//      ExtExpert.Deinit();
//      return(INIT_FAILED);
//     }
//   signal.AddFilter(filter1);
////--- Set filter parameters
//   filter1.GoodHourOfDay(Signal_ITF_GoodHourOfDay);
//   filter1.BadHoursOfDay(Signal_ITF_BadHoursOfDay);
//   filter1.GoodDayOfWeek(Signal_ITF_GoodDayOfWeek);
//   filter1.BadDaysOfWeek(Signal_ITF_BadDaysOfWeek);
//   filter1.Weight(Signal_ITF_Weight);
//--- Creation of trailing object
   CTrailingNone *trailing=new CTrailingNone;
   if(trailing==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating trailing");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Add trailing to expert (will be deleted automatically))
   if(!ExtExpert.InitTrailing(trailing))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing trailing");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Set trailing parameters
//--- Creation of money object
   CMoneyFixedLot *money=new CMoneyFixedLot;
   if(money==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating money");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Add money to expert (will be deleted automatically))
   if(!ExtExpert.InitMoney(money))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing money");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Set money parameters
   money.Percent(Money_FixLot_Percent);
   money.Lots(Money_FixLot_Lots);
//--- Check all trading objects parameters
   if(!ExtExpert.ValidationSettings())
     {
      //--- failed
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Tuning of all necessary indicators
   if(!ExtExpert.InitIndicators())
     {
      //--- failed
      printf(__FUNCTION__+": error initializing indicators");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- ok
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Deinitialization function of the expert                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ExtExpert.Deinit();
  }
//+------------------------------------------------------------------+
//| "Tick" event handler function                                    |
//+------------------------------------------------------------------+
void OnTick()
  {
   ExtExpert.OnTick();
  }
//+------------------------------------------------------------------+
//| "Trade" event handler function                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
   ExtExpert.OnTrade();
  }
//+------------------------------------------------------------------+
//| "Timer" event handler function                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   ExtExpert.OnTimer();
  }
//+------------------------------------------------------------------+
