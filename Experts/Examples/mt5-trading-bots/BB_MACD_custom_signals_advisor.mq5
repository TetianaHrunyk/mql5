//+------------------------------------------------------------------+
//|                               BB_MACD_custom_signals_advisor.mq5 |
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
#include <Expert\Signal\SignalMACDFilter.mqh>
#include <Expert\Signal\SignalITF.mqh>
//--- available trailing
#include <Expert\Trailing\TrailingFixedPips.mqh>
//--- available money management
#include <Expert\Money\MoneyFixedLot.mqh>
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
input string             Expert_Title                   ="BB_MACD_custom_signals_advisor"; // Document name
ulong                    Expert_MagicNumber             =9743;                             //
bool                     Expert_EveryTick               =false;                            //
//--- inputs for main signal
input int                Signal_ThresholdOpen           =10;                               // Signal threshold value to open [0...100]
input int                Signal_ThresholdClose          =10;                               // Signal threshold value to close [0...100]
input double             Signal_PriceLevel              =0.0;                              // Price level to execute a deal
input double             Signal_StopLevel               =50.0;                             // Stop Loss level (in points)
input double             Signal_TakeLevel               =50.0;                             // Take Profit level (in points)
input int                Signal_Expiration              =4;                                // Expiration of pending orders (in bars)

input string Blank1 = "------------- BB Settings ----------------------";
input int                Signal_BB_PeriodMA             =20;                               // Bollinger Bands(20,0,...) Period of the main line
input int                Signal_BB_Shift                =0;                                // Bollinger Bands(20,0,...) Time shift
input ENUM_APPLIED_PRICE Signal_BB_Applied              =PRICE_CLOSE;                      // Bollinger Bands(20,0,...) Prices series
input double             Signal_BB_Weight               =1.0;                              // Bollinger Bands(20,0,...) Weight [0...1.0]
input int                Signal_BB_Lookback             =4;                                // Bollinger Bands Lookback
input int                Signal_BB_Threshold            =0;                                // Bollinger Bands Thereshold

input string Blank2 = "------------- MACD Settings ----------------------";
input int                Signal_MACD_Filter_PeriodFast  =12;                               // MACD Filter(12,24,9,...) Period of fast EMA
input int                Signal_MACD_Filter_PeriodSlow  =24;                               // MACD Filter(12,24,9,...) Period of slow EMA
input int                Signal_MACD_Filter_PeriodSignal=9;                                // MACD Filter(12,24,9,...) Period of averaging of difference
input ENUM_APPLIED_PRICE Signal_MACD_Filter_Applied     =PRICE_CLOSE;                      // MACD Filter(12,24,9,...) Prices series
input int                Signal_MACD_Filter_Threshold   =10;                               // MACD Filter(12,24,9,...) Min required diff for main and signal
input double             Signal_MACD_Filter_Weight      =0.1;                              // MACD Filter(12,24,9,...) Weight [0...1.0]

input string Blank3 = "------------- Time Settings ----------------------";
input int                Signal_ITF_GoodHourOfDay       =-1;                               // IntradayTimeFilter(-1,0,-1,...) Good hour
input int                Signal_ITF_BadHoursOfDay       =0;                                // IntradayTimeFilter(-1,0,-1,...) Bad hours (bit-map)
input int                Signal_ITF_GoodDayOfWeek       =-1;                               // IntradayTimeFilter(-1,0,-1,...) Good day of week
input int                Signal_ITF_BadDaysOfWeek       =0;                                // IntradayTimeFilter(-1,0,-1,...) Bad days of week (bit-map)
input double             Signal_ITF_Weight              =1.0;                              // IntradayTimeFilter(-1,0,-1,...) Weight [0...1.0]

input string Blank4 = "------------- Trailing Settings ------------------";
input int                Trailing_FixedPips_StopLevel   =30;                               // Stop Loss trailing level (in points)
input int                Trailing_FixedPips_ProfitLevel =50;                               // Take Profit trailing level (in points)

input string Blank5 = "------------- Money Settings ---------------------";
input double             Money_FixLot_Percent           =10.0;                             // Percent
input double             Money_FixLot_Lots              =0.1;                              // Fixed volume
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
   filter0.Threshold(Signal_BB_Threshold);
// ---------BB PATTERN ------------------
   //filter0.EveryTick(true);
   filter0.PatternsUsage(4);
   filter0.Pattern_2(100);

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
   filter1.PeriodFast(Signal_MACD_Filter_PeriodFast);
   filter1.PeriodSlow(Signal_MACD_Filter_PeriodSlow);
   filter1.PeriodSignal(Signal_MACD_Filter_PeriodSignal);
   filter1.Applied(Signal_MACD_Filter_Applied);
   filter1.Threshold(Signal_MACD_Filter_Threshold);
   filter1.Weight(Signal_MACD_Filter_Weight);
   
// ---------MACD PATTERN ------------------
   filter1.PatternsUsage(1);
   filter1.Pattern_0(100);
   
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
   trailing.StopLevel(Trailing_FixedPips_StopLevel);
   trailing.ProfitLevel(Trailing_FixedPips_ProfitLevel);
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
