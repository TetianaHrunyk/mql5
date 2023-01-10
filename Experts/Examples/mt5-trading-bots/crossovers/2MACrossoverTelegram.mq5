//+------------------------------------------------------------------+
//|                                         2MACrossoverTelegram.mq5 |
//+------------------------------------------------------------------+
#property version   "1.00"
//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <MyIncludes\Telegram\TelegramForExpert.mqh>
//--- available signals
#include <Expert\Signal\MySignals\Signal2MA.mqh>
//--- available trailing
#include <Expert\Trailing\TrailingFixedPips.mqh>
//--- available money management
#include <Expert\Money\MoneyFixedLot.mqh>

#include <MyIncludes\Optimization\BalanceRegression.mqh>
CBalanceRegression m_balance_regression;

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
input string             Expert_Title                    ="2MACrossover"; // Document name
ulong                    Expert_MagicNumber              =9739346;          //
bool                     Expert_EveryTick                =false;          //
//--- inputs for main signal
int                Signal_ThresholdOpen            =10;             // Signal threshold value to open [0...100]
int                Signal_ThresholdClose           =10;             // Signal threshold value to close [0...100]
double             Signal_PriceLevel               =0.0;            // Price level to execute a deal
int                Signal_Expiration               =4;              // Expiration of pending orders (in bars)

input string             str1="";                                         // ----------- MA settings --------------
input int                Signal_MA2_SlowPeriodMA         =40;             // [2MA] Period of slow averaging
input int                Signal_MA2_SlowShift            =0;              // [2MA] Time shift slow
input ENUM_MA_METHOD     Signal_MA2_SlowMethod           =MODE_EMA;       // [2MA] Slow method
input ENUM_APPLIED_PRICE Signal_MA2_SlowApplied          =PRICE_CLOSE;    // [2MA] Slow price
input int                Signal_MA2_FastPeriodMA         =12;             // [2MA] Period of fast averaging
input int                Signal_MA2_FastShift            =0;              // [2MA] Time shift fast
input ENUM_MA_METHOD     Signal_MA2_FastMethod           =MODE_EMA;       // [2MA] Fast method
input ENUM_APPLIED_PRICE Signal_MA2_FastApplied          =PRICE_CLOSE;    // [2MA] Fast price

int                Signal_MA2_TrendValidationPeriod=20;             // [2MA] Trend validtion period
int                Signal_MA2_TrendValPeriodFast   =10;             // [2MA] Fast trend validtion period
double             Signal_MA2_TrendValRatio        =0.9;            // [2MA] Trend following points ratio
int                Signal_MA2_TotalMAChange        =4;              // [2MA] Total MA change
double             Signal_MA2_Weight               =1.0;            // [2MA] Weight [0...1.0]

input string             str2="";                                         // ----------- Trailing settings --------------
input double             Signal_StopLevel                =30.0;           // Stop Loss level (in points)
input double             Signal_TakeLevel                =50.0;           // Take Profit level (in points)
input int                Trailing_FixedPips_StopLevel    =30;             // Stop Loss trailing level (in points)
input int                Trailing_FixedPips_ProfitLevel  =50;             // Take Profit trailing level (in points)

input string             str3="";                                         // ----------- Money settings --------------
input double             Money_FixLot_Percent            =10.0;           // Percent
input double             Money_FixLot_Lots               =0.05;            // Fixed volume

input string             str4="";                                         // ----------- Telegram settings -----------
input bool InpSendMessages = false;                                       // Send telegram messages?
input bool InpLogMessages = true;                                        // Log messages to console?

string InpChatId="@TaniasTrades"; //Chat ID
string InpToken="5700264604:AAGLO4pcTZGNssAYYQH7smz1Tu8-JsfPJCU";//Token

//+------------------------------------------------------------------+
//| Global expert object                                             |
//+------------------------------------------------------------------+
CExpertWithTelegram ExtExpert;

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
//--- Set parameters of CBalanceRegression
   m_balance_regression.SetStartBalance(AccountInfoDouble(ACCOUNT_BALANCE));
   m_balance_regression.SetFromDate(TimeCurrent());
   m_balance_regression.SetVolumeNormalization(false);
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
   filter0.PatternsUsage(2);
   filter0.Pattern_1(100);
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
//--- Initializing messenger
   int interval = MathMax(1800, MathFloor(PeriodSeconds()/2));
   if(!ExtExpert.InitMessenger(InpSendMessages, InpLogMessages, InpToken, InpChatId, interval))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing expert");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
   if(InpSendMessages || InpLogMessages)
      EventSetTimer(interval);

//--- ok
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Deinitialization function of the expert                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ExtExpert.Deinit();
   if(InpSendMessages || InpLogMessages)
      EventKillTimer();
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
//|                                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
   double   param=0.0;


//  Balance max + min Drawdown + Trades Number:
//double  balance = TesterStatistics(STAT_PROFIT);
//double  balance_dd = TesterStatistics(STAT_BALANCEDD_PERCENT);
//double  profit_factor = TesterStatistics(STAT_PROFIT_FACTOR);
//double  recovery_factor = TesterStatistics(STAT_RECOVERY_FACTOR);

//   double  profit_trades = TesterStatistics(STAT_PROFIT_TRADES);
//   double  loss_trades = TesterStatistics(STAT_LOSS_TRADES);
//   double  prof_loss_trades = profit_trades/loss_trades;
//
//   //if(balance_dd < 40 && profit_factor >= 1.8 && prof_loss_trades >= 1.5 && recovery_factor > 3)
//   //  {
//      double adjusted_balance_dd;
//      if(balance_dd > 0)
//         adjusted_balance_dd = 1/balance_dd;
//      else
//         adjusted_balance_dd = 100;
//      param = adjusted_balance_dd * profit_factor;
//   //}
//return(profit_factor*recovery_factor);

   double ret=m_balance_regression.GetProfitStability(TimeCurrent());
   return(ret);
  }
//+------------------------------------------------------------------+
