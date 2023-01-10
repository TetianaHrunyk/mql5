//+------------------------------------------------------------------+
//|                                               VIDYACrossover.mq5 |
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
#include <Expert\Signal\MySignals\SignalVIDYA.mqh>
//--- available trailing
#include <Expert\Trailing\TrailingFixedPips.mqh>
//--- available money management
#include <Expert\Money\MoneyFixedLot.mqh>
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
input string             Expert_Title                  ="VIDYACrossover"; // Document name
ulong                    Expert_MagicNumber            =31973;            //
bool                     Expert_EveryTick              =false;            //
//--- inputs for main signal
 int                Signal_ThresholdOpen          =10;               // Signal threshold value to open [0...100]
 int                Signal_ThresholdClose         =10;               // Signal threshold value to close [0...100]
 double             Signal_PriceLevel             =0.0;              // Price level to execute a deal
 int                Signal_Expiration             =4;                // Expiration of pending orders (in bars)
input string        str1="";                                        // ------------ VIDYA Settings -------------
input int                Svidya_FastPeriodCMO      =9;               // [SVIDYA] CMO Period Fast
input int                Svidya_FastPeriodMA       =12;               // [SVIDYA] MA Period Fast
input int                Svidya_FastShift          =0;                // [SVIDYA] Time shift Fast
input ENUM_APPLIED_PRICE Svidya_FastApplied        =PRICE_CLOSE;      // [SVIDYA] Fast price

input int                Svidya_SlowPeriodCMO      =20;               // [SVIDYA] CMO Period Slow
input int                Svidya_SlowPeriodMA       =50;               // [SVIDYA] MA Period Slow
input int                Svidya_SlowShift          =0;                // [SVIDYA] Time shift slow
input ENUM_APPLIED_PRICE Svidya_SlowApplied        =PRICE_CLOSE;      // [SVIDYA] Slow price
input string        str2="";                                        // ------------ Signal Specific Settings -------------
input int                Svidya_TrendValPeriodSlow =20;               // [SVIDYA] Trend validtion period slow
input int                Svidya_TrendValPeriodFast =10;               // [SVIDYA] Trend validtion period fast
input double             Svidya_TrendValRatio      =0.9;              // [SVIDYA] Trend following points ratio
input int                Svidya_TotalChange        =4;                // [SVIDYA] Total change
 double             Svidya_Weight             =1.0;              // [SVIDYA] Weight [0...1.0]

input string        str3="";                                        // ------------ Trailing Settings -------------
input double             Signal_StopLevel              =50.0;             // Stop Loss level (in points)
input double             Signal_TakeLevel              =50.0;             // Take Profit level (in points)
input int                Trailing_StopLevel  =30;               // Stop Loss trailing level (in points)
input int                Trailing_ProfitLevel=50;               // Take Profit trailing level (in points)

input string        str4="";                                        // ------------ Money Settings -------------
input double             Money_FixLot_Percent          =10.0;             // Percent
input double             Money_FixLot_Lots             =0.05;              // Fixed volume
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
//--- Creating filter CSignalVIDYA
   CSignalVIDYA *filter0=new CSignalVIDYA;
   if(filter0==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating filter0");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
   signal.AddFilter(filter0);
//--- Set filter parameters
   filter0.FastPeriodCMO(Svidya_FastPeriodCMO);
   filter0.FastPeriodMA(Svidya_FastPeriodMA);
   filter0.FastShift(Svidya_FastShift);
   filter0.FastApplied(Svidya_FastApplied);
   filter0.SlowPeriodCMO(Svidya_SlowPeriodCMO);
   filter0.SlowPeriodMA(Svidya_SlowPeriodMA);
   filter0.SlowShift(Svidya_SlowShift);
   filter0.SlowApplied(Svidya_SlowApplied);
   filter0.TrendValPeriodSlow(Svidya_TrendValPeriodSlow);
   filter0.TrendValPeriodFast(Svidya_TrendValPeriodFast);
   filter0.TrendValRatio(Svidya_TrendValRatio);
   filter0.TotalChange(Svidya_TotalChange);
   filter0.Weight(Svidya_Weight);
   filter0.Pattern_2(100);
   filter0.PatternsUsage(4);
//--- Creation of trailing object
   CTrailingFixedPips *trailing=new CTrailingFixedPips;
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
   trailing.StopLevel(Trailing_StopLevel);
   trailing.ProfitLevel(Trailing_ProfitLevel);
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
