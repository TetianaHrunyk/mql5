//+------------------------------------------------------------------+
//|                                             AlligatorAdvisor.mq5 |
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
#include <Expert\Signal\SignalAlligator.mqh>
#include <Expert\Signal\SignalITF.mqh>
//--- available trailing
#include <Expert\Trailing\TrailingFixedPips.mqh>
//--- available money management
#include <Expert\Money\MoneyFixedLot.mqh>
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
input string Expert_Title                  ="AlligatorAdvisor"; // Document name
ulong        Expert_MagicNumber            =20427;              //
bool         Expert_EveryTick              =false;              //
//--- inputs for main signal
input int    Signal_ThresholdOpen          =100;                 // Signal threshold value to open [0...100]
input int    Signal_ThresholdClose         =100;                 // Signal threshold value to close [0...100]
input double Signal_PriceLevel             =0.0;                // Price level to execute a deal
input double Signal_StopLevel              =50.0;               // Stop Loss level (in points)
input double Signal_TakeLevel              =50.0;               // Take Profit level (in points)
input int    Signal_Expiration             =4;                  // Expiration of pending orders (in bars)

input string Blank1 = "------------Alligator Settings-----------------------------";
input int    Signal_Alligator_JawPeriod          =13;                 // Alligator(13,8,8,5,5,3,10,5,...) Jaw Period
input int    Signal_Alligator_JawShift           =8;                  // Alligator(13,8,8,5,5,3,10,5,...) Jaw Shift
input int    Signal_Alligator_TeethPeriod        =8;                  // Alligator(13,8,8,5,5,3,10,5,...) Teeth Period
input int    Signal_Alligator_TeethShift         =5;                  // Alligator(13,8,8,5,5,3,10,5,...) Teeth Shift
input int    Signal_Alligator_LipsPeriod         =5;                  // Alligator(13,8,8,5,5,3,10,5,...) Lips Period
input int    Signal_Alligator_LipsShift          =3;                  // Alligator(13,8,8,5,5,3,10,5,...) Lips Shift
input int    Signal_Alligator_DiffTight          =10;                 // Alligator(13,8,8,5,5,3,10,5,...) Diff in pip to consider lines tight
input int    Signal_Alligator_DiffApart          =5;                  // Alligator(13,8,8,5,5,3,10,5,...) Diff in pip to consider lines apart
input int    Signal_Alligator_Lookback           =0;                  // Alligator(13,8,8,5,5,3,10,5,...) Number of prior periods to consider
input double Signal_Alligator_Weight             =1.0;                // Alligator(13,8,8,5,5,3,10,5,...) Weight [0...1.0]

input string Blank2 = "------------Time Settings-----------------------------";
input int    Signal_ITF_GoodHourOfDay      =-1;                 // IntradayTimeFilter(-1,0,-1,...) Good hour
input int    Signal_ITF_BadHoursOfDay      =0;                  // IntradayTimeFilter(-1,0,-1,...) Bad hours (bit-map)
input int    Signal_ITF_GoodDayOfWeek      =-1;                 // IntradayTimeFilter(-1,0,-1,...) Good day of week
input int    Signal_ITF_BadDaysOfWeek      =0;                  // IntradayTimeFilter(-1,0,-1,...) Bad days of week (bit-map)
input double Signal_ITF_Weight             =1.0;                // IntradayTimeFilter(-1,0,-1,...) Weight [0...1.0]

input string Blank3 = "------------Trailing and Money Settings-----------------";
//--- inputs for trailing
input int    Trailing_FixedPips_StopLevel  =30;                 // Stop Loss trailing level (in points)
input int    Trailing_FixedPips_ProfitLevel=50;                 // Take Profit trailing level (in points)
//--- inputs for money
input double Money_FixLot_Percent          =10.0;               // Percent
input double Money_FixLot_Lots             =0.1;                // Fixed volume
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
//--- Creating filter CSignalAlligator
   CSignalAlligator *filter0=new CSignalAlligator;
   if(filter0==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating filter0");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
   signal.AddFilter(filter0);
//--- Set filter parameters
   filter0.JawPeriod(Signal_Alligator_JawPeriod);
   filter0.JawShift(Signal_Alligator_JawShift);
   filter0.TeethPeriod(Signal_Alligator_TeethPeriod);
   filter0.TeethShift(Signal_Alligator_TeethShift);
   filter0.LipsPeriod(Signal_Alligator_LipsPeriod);
   filter0.LipsShift(Signal_Alligator_LipsShift);
   filter0.DiffTight(Signal_Alligator_DiffTight);
   filter0.DiffApart(Signal_Alligator_DiffApart);
   filter0.Lookback(Signal_Alligator_Lookback);
   filter0.Weight(Signal_Alligator_Weight);
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
