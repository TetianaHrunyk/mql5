//+------------------------------------------------------------------+
//|                                               BB_MACD_Expert.mq5 |
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
#include <Expert\Signal\SignalBB.mqh>
#include <Expert\Signal\SignalMACD.mqh>
#include <Expert\Signal\SignalITF.mqh>
//--- available trailing
#include <Expert\Trailing\TrailingParabolicSAR.mqh>
//--- available money management
#include <Expert\Money\MoneyFixedRisk.mqh>
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
input string             Expert_Title                 ="BB_MACD_Expert"; // Document name
ulong                    Expert_MagicNumber           =12862;            //
bool                     Expert_EveryTick             =false;            //
//--- inputs for main signal
input int                Signal_ThresholdOpen         =10;               // Signal threshold value to open [0...100]
input int                Signal_ThresholdClose        =10;               // Signal threshold value to close [0...100]
input double             Signal_PriceLevel            =0.0;              // Price level to execute a deal
input double             Signal_StopLevel             =50.0;             // Stop Loss level (in points)
input double             Signal_TakeLevel             =50.0;             // Take Profit level (in points)
input int                Signal_Expiration            =4;                // Expiration of pending orders (in bars)
input int                Signal_BB_PeriodMA           =20;               // Bollinger Bands(20,0,...) Period of the main line
input int                Signal_BB_Shift              =0;                // Bollinger Bands(20,0,...) Time shift
input ENUM_APPLIED_PRICE Signal_BB_Applied            =PRICE_CLOSE;      // Bollinger Bands(20,0,...) Prices series
input int                Signal_BB_Lookback           =20;               // Bollinger Bands Lookback
input double             Signal_BB_Weight             =1.0;              // Bollinger Bands(20,0,...) Weight [0...1.0]
input int                Signal_MACD_PeriodFast       =12;               // MACD(12,24,9,PRICE_CLOSE) Period of fast EMA
input int                Signal_MACD_PeriodSlow       =24;               // MACD(12,24,9,PRICE_CLOSE) Period of slow EMA
input int                Signal_MACD_PeriodSignal     =9;                // MACD(12,24,9,PRICE_CLOSE) Period of averaging of difference
input ENUM_APPLIED_PRICE Signal_MACD_Applied          =PRICE_CLOSE;      // MACD(12,24,9,PRICE_CLOSE) Prices series
input double             Signal_MACD_Weight           =1.0;              // MACD(12,24,9,PRICE_CLOSE) Weight [0...1.0]
input int                Signal_ITF_GoodHourOfDay     =-1;               // IntradayTimeFilter(-1,0,-1,...) Good hour
input int                Signal_ITF_BadHoursOfDay     =0;                // IntradayTimeFilter(-1,0,-1,...) Bad hours (bit-map)
input int                Signal_ITF_GoodDayOfWeek     =-1;               // IntradayTimeFilter(-1,0,-1,...) Good day of week
input int                Signal_ITF_BadDaysOfWeek     =0;                // IntradayTimeFilter(-1,0,-1,...) Bad days of week (bit-map)
input double             Signal_ITF_Weight            =1.0;              // IntradayTimeFilter(-1,0,-1,...) Weight [0...1.0]
//--- inputs for trailing
input double             Trailing_ParabolicSAR_Step   =0.02;             // Speed increment
input double             Trailing_ParabolicSAR_Maximum=0.2;              // Maximum rate
//--- inputs for money
input double             Money_FixRisk_Percent        =10.0;             // Risk percentage
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
   filter0.PeriodMA(Signal_BB_PeriodMA);
   filter0.Shift(Signal_BB_Shift);
   filter0.Applied(Signal_BB_Applied);
   filter0.Weight(Signal_BB_Weight);
   filter0.Lookback(Signal_BB_Lookback);
//--- Creating filter CSignalMACD
   CSignalMACD *filter1=new CSignalMACD;
   if(filter1==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating filter1");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
   signal.AddFilter(filter1);
//--- Set filter parameters
   filter1.PeriodFast(Signal_MACD_PeriodFast);
   filter1.PeriodSlow(Signal_MACD_PeriodSlow);
   filter1.PeriodSignal(Signal_MACD_PeriodSignal);
   filter1.Applied(Signal_MACD_Applied);
   filter1.Weight(Signal_MACD_Weight);
//--- Creating filter CSignalITF
   CSignalITF *filter2=new CSignalITF;
   if(filter2==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating filter2");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
   signal.AddFilter(filter2);
//--- Set filter parameters
   filter2.GoodHourOfDay(Signal_ITF_GoodHourOfDay);
   filter2.BadHoursOfDay(Signal_ITF_BadHoursOfDay);
   filter2.GoodDayOfWeek(Signal_ITF_GoodDayOfWeek);
   filter2.BadDaysOfWeek(Signal_ITF_BadDaysOfWeek);
   filter2.Weight(Signal_ITF_Weight);
//--- Creation of trailing object
   CTrailingPSAR *trailing=new CTrailingPSAR;
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
   trailing.Step(Trailing_ParabolicSAR_Step);
   trailing.Maximum(Trailing_ParabolicSAR_Maximum);
//--- Creation of money object
   CMoneyFixedRisk *money=new CMoneyFixedRisk;
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
   money.Percent(Money_FixRisk_Percent);
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
