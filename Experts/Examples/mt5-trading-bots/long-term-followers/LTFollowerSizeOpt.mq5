//+------------------------------------------------------------------+
//|                                            LTFollowerSizeOpt.mq5 |
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
#include <Expert\Money\MoneySizeOptimized.mqh>
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
input string             Expert_Title                      ="LTFollowerSizeOpt"; // Document name
ulong                    Expert_MagicNumber                =1343;                //
bool                     Expert_EveryTick                  =false;               //
//--- inputs for main signal
input int                Signal_ThresholdOpen              =10;                  // Signal threshold value to open [0...100]
input int                Signal_ThresholdClose             =10;                  // Signal threshold value to close [0...100]
input double             Signal_PriceLevel                 =0.0;                 // Price level to execute a deal
input double             Signal_StopLevel                  =50.0;                // Stop Loss level (in points)
input double             Signal_TakeLevel                  =50.0;                // Take Profit level (in points)
input int                Signal_Expiration                 =4;                   // Expiration of pending orders (in bars)
//input int                Signal_MA2_SlowPeriodMA           =200;                 // 2 Moving Averages(200,0,...) Period of slow averaging
//input int                Signal_MA2_SlowShift              =0;                   // 2 Moving Averages(200,0,...) Time shift slow
//input ENUM_MA_METHOD     Signal_MA2_SlowMethod             =MODE_SMA;            // 2 Moving Averages(200,0,...) Slow method
//input ENUM_APPLIED_PRICE Signal_MA2_SlowApplied            =PRICE_CLOSE;         // 2 Moving Averages(200,0,...) Slow price
input int                Signal_MA2_FastPeriodMA           =50;                  // 2 Moving Averages(200,0,...) Period of fast averaging
input int                Signal_MA2_FastShift              =0;                   // 2 Moving Averages(200,0,...) Time shift fast
input ENUM_MA_METHOD     Signal_MA2_FastMethod             =MODE_SMA;            // 2 Moving Averages(200,0,...) Fast method
input ENUM_APPLIED_PRICE Signal_MA2_FastApplied            =PRICE_CLOSE;         // 2 Moving Averages(200,0,...) Fast price
input int                Signal_MA2_TrendValidationPeriod  =20;                  // 2 Moving Averages(200,0,...) Trend validtion period
input int                Signal_MA2_TotalMAChange          =4;                      // 2 Moving Averages(200,0,...) Total MA Change
input double             Signal_MA2_Weight                 =1.0;                 // 2 Moving Averages(200,0,...) Weight [0...1.0]
input int                Signal_ITF_GoodHourOfDay          =-1;                  // IntradayTimeFilter(-1,0,-1,...) Good hour
input int                Signal_ITF_BadHoursOfDay          =0;                   // IntradayTimeFilter(-1,0,-1,...) Bad hours (bit-map)
input int                Signal_ITF_GoodDayOfWeek          =-1;                  // IntradayTimeFilter(-1,0,-1,...) Good day of week
input int                Signal_ITF_BadDaysOfWeek          =0;                   // IntradayTimeFilter(-1,0,-1,...) Bad days of week (bit-map)
input double             Signal_ITF_Weight                 =1.0;                 // IntradayTimeFilter(-1,0,-1,...) Weight [0...1.0]
//--- inputs for money
input double             Money_SizeOptimized_DecreaseFactor=2.0;                 // Decrease factor
input double             Money_SizeOptimized_Percent       =10.0;                // Percent
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
   //filter0.SlowPeriodMA(Signal_MA2_SlowPeriodMA);
   //filter0.SlowShift(Signal_MA2_SlowShift);
   //filter0.SlowMethod(Signal_MA2_SlowMethod);
   //filter0.SlowApplied(Signal_MA2_SlowApplied);
   filter0.FastPeriodMA(Signal_MA2_FastPeriodMA);
   filter0.FastShift(Signal_MA2_FastShift);
   filter0.FastMethod(Signal_MA2_FastMethod);
   filter0.FastApplied(Signal_MA2_FastApplied);
   filter0.TrendValidationPeriod(Signal_MA2_TrendValidationPeriod);
   filter0.TotalMAChange(Signal_MA2_TotalMAChange);
   filter0.Weight(Signal_MA2_Weight);
   filter0.PatternsUsage(4);
//--- Creating filter CSignalITF
   CSignalITF *filter1=new CSignalITF;
   if(filter1==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating filter1");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
   signal.AddFilter(filter1);
//--- Set filter parameters
   filter1.GoodHourOfDay(Signal_ITF_GoodHourOfDay);
   filter1.BadHoursOfDay(Signal_ITF_BadHoursOfDay);
   filter1.GoodDayOfWeek(Signal_ITF_GoodDayOfWeek);
   filter1.BadDaysOfWeek(Signal_ITF_BadDaysOfWeek);
   filter1.Weight(Signal_ITF_Weight);
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
   CMoneySizeOptimized *money=new CMoneySizeOptimized;
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
   money.DecreaseFactor(Money_SizeOptimized_DecreaseFactor);
   money.Percent(Money_SizeOptimized_Percent);
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
