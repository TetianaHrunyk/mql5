//+------------------------------------------------------------------+
//|                                              BBSignalAdvisor.mq5 |
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
#include <Expert\Signal\MySignals\SignalBB.mqh>
//--- available trailing
#include <Expert\Trailing\TrailingNone.mqh>
//--- available money management
#include <Expert\Money\MoneyFixedLot.mqh>
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
input string             Expert_Title         ="BBSignalAdvisor"; // Document name
ulong                    Expert_MagicNumber   =3925;              //
bool                     Expert_EveryTick     =false;             //
//--- inputs for main signal
 int                S_ThresholdOpen =60;                // Signal threshold value to open [0...100]
 int                S_ThresholdClose=10;                // Signal threshold value to close [0...100]
 double             S_PriceLevel    =0.0;               // Price level to execute a deal
 int                S_Expiration    =2;                 // Expiration of pending orders (in bars)

 int                S_BB_PeriodMA   =20;                // [BB] Period of the main line
 int                S_BB_Shift      =0;                 // [BB] Time shift
 ENUM_APPLIED_PRICE S_BB_Applied    =PRICE_CLOSE;       // [BB] Prices series

input string             comment0 = "";                      //  ----------------- MA Settings -----------------  
input int                S_BB_iMAPeriodMA   =20;                // [BB] Period of the main line
input int                S_BB_iMAShift      =0;                 // [BB] Time shift
input ENUM_MA_METHOD     S_BB_iMAMethod     =MODE_EMA;          // [BB] Method
 ENUM_APPLIED_PRICE S_BB_iMAApplied    =PRICE_CLOSE;       // [BB] Prices series
 
input string             comment1 = "";                      //  ----------------- Signal Specific Settings -----------------  
input int                S_BB_Lookback   =4;                 // [BB] Periods to look back
input int                S_BB_MALookback  =5;                // [BB] MA Lookback
input int                S_BB_Threshold  =0;                 // [BB] Pips to adjust touch
input TRADE_RANGE        S_BB_TradeRange =ANY;               // [BB] BB price range to trade
 int                S_BB_TradeRangeWeight  =1;          // [BB] Weight of the trade range 
 double             S_BB_Weight     =1.0;               // [BB] Weight [0...1.0]


input string             comment2 = "";                      //  ----------------- Money Settings -----------------                 
input double             S_StopLevel     =30.0;              // Stop Loss level (in points)
input double             S_TakeLevel     =50.0;              // Take Profit level (in points)
input double             Money_FixLot_Percent =10.0;              // Percent
input double             Money_FixLot_Lots    =0.1;               // Fixed volume
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
   signal.ThresholdOpen(S_ThresholdOpen);
   signal.ThresholdClose(S_ThresholdClose);
   signal.PriceLevel(S_PriceLevel);
   signal.StopLevel(S_StopLevel);
   signal.TakeLevel(S_TakeLevel);
   signal.Expiration(S_Expiration);
//--- Creating filter CSignalBB
   CSignalBB *filter0=new CSignalBB;
   if(filter0==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating filter0");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
   signal.AddFilter(filter0);
//--- Set filter parameters
   filter0.PeriodMA(S_BB_PeriodMA);
   filter0.Shift(S_BB_Shift);
   filter0.Applied(S_BB_Applied);
   filter0.Lookback(S_BB_Lookback);
   filter0.Threshold(S_BB_Threshold);
   filter0.Weight(S_BB_Weight);
   filter0.TradeRange(S_BB_TradeRange);
   filter0.TradeRangeWeight(S_BB_TradeRangeWeight);
   filter0.iMAApplied(S_BB_iMAApplied);
   filter0.iMAMethod(S_BB_iMAMethod);
   filter0.iMAPeriodMA(S_BB_iMAPeriodMA);
   filter0.iMAShift(S_BB_iMAShift);
   filter0.MALookback(S_BB_MALookback);
   
   filter0.Pattern_1(50);
   filter0.Pattern_3(70); 
   filter0.Pattern_4(80);
   filter0.PatternsUsage(10);
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
