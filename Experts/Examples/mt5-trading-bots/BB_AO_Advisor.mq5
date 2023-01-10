//+------------------------------------------------------------------+
//|                                                  MACD Sample.mq5 |
//|                   Copyright 2009-2017, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2009-2017, MetaQuotes Software Corp."
#property link        "http://www.mql5.com"
#property version     "5.50"
#property description "It is important to make sure that the expert works with a normal"
#property description "chart and the user did not make any mistakes setting input"
#property description "variables (Lots, TakeProfit, TrailingStop) in our case,"
#property description "we check TakeProfit on a chart of more than 2*trend_period bars"

#define MACD_MAGIC 12765023
#define IS_PATTERN_USAGE(m_patterns_usage, p)          ((m_patterns_usage&(((int)1)<<p))!=0)
//---
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Indicators.mqh>
#include <TimeChecker.mqh>

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

enum BB_STRATEGY
  {
   EXTREMUM_CROSS_FOLLOWED_BY_REVERSAL,
   CLOSE,
   TOUCH
  };

//---
input string Blank1 = ""; // --------------- Money Settings ---------------
input double InpLots          =0.1; // Lots
input int    InpTakeProfit    =70;  // Take Profit (in pips)
input int    InpTrailingStop  =30;  // Trailing Stop Level (in pips)

input string Blank2 = ""; // --------------- BB Settings ---------------
input int    InpMATrendPeriod =20;  // MA trend period
input BB_STRATEGY    InpBBTradingStrategy = TOUCH;  // BB trading strategy
input TRADE_RANGE   InpTradeRange = CORRIDOR;  // When to onen positions: on the edges of the bb, in the corridor or any time
input int InpBBLookbackPeriod = 5;   //How many bars prior to the current bar the touch can occur

input string Blank4 = ""; // --------------- AO Settings ---------------
input int     InpAOLookback = 5;  // Number of bars to confirm AO trend; If <= 0, won't check AO
input int     InpAOTrendTrendThreshold =4;  // Minimum diff in pips to consider trend as changed


input string Blank5 = ""; // --------------- Time Settings ---------------
input bool InpTradeOnNewBars   = true;
input int inp_start_hour       = 0;
input int inp_start_minute     = 0;
input int inp_end_hour         = 23;
input int inp_end_minute       = 59;

input string Blank6 = ""; // --------------- Days Settings ---------------
input bool Sunday    = false;
input bool Monday    = false;
input bool Tuesday   = true;
input bool Wednesday = true;
input bool Thursday  = true;
input bool Friday    = true;
input bool Saturday  = true;

int ExtTimeOut=10; // time out in seconds between trade operations
//+------------------------------------------------------------------+
//| Simple BB advisor
//| operates when the min/max is below BB,
//| and the next bar indicated trend reversal
//+------------------------------------------------------------------+
class CSampleExpert
  {
protected:
   double            m_adjusted_point;             // point value adjusted for 3 or 5 points
   CTrade            m_trade;                      // trading object
   CSymbolInfo       m_symbol;                     // symbol info object
   CPositionInfo     m_position;                   // trade position object
   CAccountInfo      m_account;                    // account info wrapper
   //--- indicators
   CiBands            m_bands_1;                     // Bollinger bands object indicator handle
   CiBands            m_bands_2;                     // Bollinger bands object indicator handle
   CIndicators        m_indicators;                 // indicator collection to fast recalculations
   CiAO               m_ao;                           // AO indicator
   //--- indicator buffers
   MqlRates          rates[];                      // Rates buffer
   //---
   double            m_ao_trend_threshold;
   double            m_traling_stop;
   double            m_take_profit;
   datetime          m_last_order_time;
   CTimeChecker      time_checker;

public:
                     CSampleExpert(void);
                    ~CSampleExpert(void);
   bool              Init(void);
   void              Deinit(void);
   bool              Processing(void);

protected:
   bool              IsNewBar(void);
   bool              InitCheckParameters(const int digits_adjust);
   bool              InitIndicators(CIndicators *indicators);
   bool              LongClosed(void);
   bool              ShortClosed(void);
   bool              LongModified(void);
   bool              ShortModified(void);
   bool              LongOpened(void);
   bool              ShortOpened(void);
   bool              Signal(SIGNAL opportunity);
   bool              IsPriceRangeValid(SIGNAL opportunity);
   bool              CheckAO(SIGNAL direction);
   void TestPatternUsage(void);
  };
//--- global expert
CSampleExpert ExtExpert;
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSampleExpert::CSampleExpert(void) : m_adjusted_point(0),
   m_traling_stop(0),
   m_take_profit(0)
  {
   ArraySetAsSeries(rates,true);
   bool trading_days[] = {Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday};
   time_checker.Init(inp_start_hour, inp_start_minute, inp_end_hour, inp_end_minute, trading_days);
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSampleExpert::~CSampleExpert(void)
  {
  }
  
void CSampleExpert::TestPatternUsage(void){
//---
   printf("Hello");
   int m_patterns_usage = 8;

   for(int i=0; i < 9; i++)
     {
      printf("Use pattern %i", i);
      Print(IS_PATTERN_USAGE(m_patterns_usage, i));
     }
   Print("Done");
  }
//+------------------------------------------------------------------+
//| Initialization and checking for input parameters                 |
//+------------------------------------------------------------------+
bool CSampleExpert::Init(void)
  {
//--- initialize common information
   m_symbol.Name(Symbol());                  // symbol
   m_trade.SetExpertMagicNumber(MACD_MAGIC); // magic
   m_trade.SetMarginMode();
   m_trade.SetTypeFillingBySymbol(Symbol());
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   long digits = m_symbol.Digits();
   int point = m_symbol.Point();
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=m_symbol.Point()*digits_adjust;
//--- set default deviation for trading in adjusted points
   m_ao_trend_threshold=InpAOTrendTrendThreshold*m_adjusted_point;
   m_traling_stop    =InpTrailingStop*m_adjusted_point;
   m_take_profit     =InpTakeProfit*m_adjusted_point;
//--- set default deviation for trading in adjusted points
   m_trade.SetDeviationInPoints(3*digits_adjust);
//---
   if(!InitCheckParameters(digits_adjust))
      return(false);
   CIndicators *indicators_ptr=GetPointer(m_indicators);
   if(!InitIndicators(indicators_ptr))
      return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Checking for input parameters                                    |
//+------------------------------------------------------------------+
bool CSampleExpert::InitCheckParameters(const int digits_adjust)
  {
//--- initial data checks
   if(InpTakeProfit*digits_adjust<m_symbol.StopsLevel())
     {
      printf("Take Profit must be greater than %d",m_symbol.StopsLevel());
      return(false);
     }
   if(InpTrailingStop*digits_adjust<m_symbol.StopsLevel())
     {
      printf("Trailing Stop must be greater than %d",m_symbol.StopsLevel());
      return(false);
     }
//--- check for right lots amount
   if(InpLots<m_symbol.LotsMin() || InpLots>m_symbol.LotsMax())
     {
      printf("Lots amount must be in the range from %f to %f",m_symbol.LotsMin(),m_symbol.LotsMax());
      return(false);
     }
   if(MathAbs(InpLots/m_symbol.LotsStep()-MathRound(InpLots/m_symbol.LotsStep()))>1.0E-10)
     {
      printf("Lots amount is not corresponding with lot step %f",m_symbol.LotsStep());
      return(false);
     }
//--- warning
   if(InpTakeProfit<=InpTrailingStop)
      printf("Warning: Trailing Stop must be less than Take Profit");
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Initialization of the indicators                                 |
//+------------------------------------------------------------------+
bool CSampleExpert::InitIndicators(CIndicators *indicators)
  {
//--- check pointer
   if(indicators==NULL)
      return(false);
//--- add Bollinger Bands object to collection
   if(!indicators.Add(GetPointer(m_bands_1)))
     {
      printf(__FUNCTION__+": error adding BB1 object");
      return(false);
     }
   if(!m_bands_1.Create(NULL,0,InpMATrendPeriod,0,1,PRICE_CLOSE))
     {
      printf(__FUNCTION__+": error BB1 initializing object");
      return(false);
     }
//--- add Bollinger Bands object to collection
   if(!indicators.Add(GetPointer(m_bands_2)))
     {
      printf(__FUNCTION__+": error adding BB2 object");
      return(false);
     }
   if(!m_bands_2.Create(NULL,0,InpMATrendPeriod,0,2,PRICE_CLOSE))
     {
      printf(__FUNCTION__+": error BB2 initializing object");
      return(false);
     }    
//--- add AO object to collection
   if(!indicators.Add(GetPointer(m_ao)))
     {
      printf(__FUNCTION__+": error adding AO object");
      return(false);
     }
   if(!m_ao.Create(NULL,0))
     {
      printf(__FUNCTION__+": error AO initializing object");
      return(false);
     }
//--- succeed
   return(true);
  }

//+------------------------------------------------------------------+
//|Check if the last deal was in another bar                         |
//+------------------------------------------------------------------+
bool CSampleExpert::IsNewBar(void)
  {
   bool res = true;
   if(InpTradeOnNewBars)
     {
      res = false;
      datetime time=iTime(Symbol(),Period(),0);
      if(time!=m_last_order_time)
         res = true;
      //if (res == false) printf("Cannot open positions on the same bar");
     }
   return(res);
  }

//+------------------------------------------------------------------+
//|Check if the AO trend                                             |
//+------------------------------------------------------------------+
bool CSampleExpert::CheckAO(SIGNAL direction){
   bool res = true;
   double cur_prev_diff;
   if (InpAOLookback > 0) 
   {
      if (m_ao.Main(1) <= m_ao_trend_threshold) res=false;
      for (int i = 0; i <= InpAOLookback; i++) {
         cur_prev_diff = m_ao.Main(i) - m_ao.Main(i+1);
         if (direction == BUY && cur_prev_diff >= 0) res = false;
         if (direction == SELL && cur_prev_diff <= 0) res = false;
      }
   }
   if (res) {
      double this_bar = m_ao.Main(0);
      double prev_bar = m_ao.Main(1);
      printf("*****************   Diff: %f, trend confirmed, direction: %i, ", cur_prev_diff, direction);
   }
   return(res);
}

//+------------------------------------------------------------------+
//|Check if the prices are in the correct rabge for opening a position
//+------------------------------------------------------------------+
bool CSampleExpert::IsPriceRangeValid(SIGNAL opportunity)
  {

   bool res = true;
   double price=0;
   if(opportunity == SELL)
      price=m_symbol.Bid();
   if(opportunity == BUY)
      price=m_symbol.Ask();

   if(InpTradeRange == CORRIDOR)
     {
      if(price >= m_bands_1.Upper(0) && price <= m_bands_1.Lower(0))
         res = false;
     }
   if(InpTradeRange == EDGES)
     {
      res = false;
      if(opportunity == SELL && price > m_bands_1.Upper(0))
         res = true;
      if(opportunity == BUY && price < m_bands_1.Lower(0))
         res = true;
      //if(price > m_bands_1.Lower(0) && price < m_bands_1.Upper(0))
      //   res = false;
     }
   return(res);
  }


//+------------------------------------------------------------------+
//| Check for signal                                                 |
//+------------------------------------------------------------------+
bool CSampleExpert::Signal(SIGNAL opportunity)
  {
   bool res = false;

   if(InpBBTradingStrategy == EXTREMUM_CROSS_FOLLOWED_BY_REVERSAL)
     {
      if(opportunity == SELL)
         if(rates[2].high >= m_bands_2.Upper(2) && rates[1].high < m_bands_2.Upper(1))
            res = true;
      if(opportunity == BUY)
         if(rates[2].low <= m_bands_2.Lower(2) && rates[1].low > m_bands_2.Lower(1))
            res = true;
     }

   if(InpBBTradingStrategy == CLOSE)
     {
      for(int i=0; i<=InpBBLookbackPeriod; i++)
        {
         if(opportunity == SELL)
            if(rates[i].close >= m_bands_2.Upper(i))
               res = true;
         if(opportunity == BUY)
            if(rates[i].close <= m_bands_2.Lower(i))
               res = true;
        }

     }


   if(InpBBTradingStrategy == TOUCH)
     {
      for(int i=0; i<=InpBBLookbackPeriod; i++)
        {
         if(opportunity == SELL)
            if(rates[i].high >= m_bands_2.Upper(i))
               res = true;
         if(opportunity == BUY)
            if(rates[i].low <= m_bands_2.Lower(i))
               res = true;
        }
     }


   return(res);
  }

//+------------------------------------------------------------------+
//| Check for long position closing                                  |
//+------------------------------------------------------------------+
bool CSampleExpert::LongClosed(void)
  {
   bool res=false;
//--- Sell
   if(Signal(SELL) && IsPriceRangeValid(SELL) && CheckAO(SELL))
     {
      //--- close position
      if(m_trade.PositionClose(Symbol()))
         printf("Long position by %s to be closed",Symbol());
      else
         printf("Error closing position by %s : '%s'",Symbol(),m_trade.ResultComment());
      //--- processed and cannot be modified
      res=true;
     }
   return(res);
  }
//+------------------------------------------------------------------+
//| Check for short position closing                                 |
//+------------------------------------------------------------------+
bool CSampleExpert::ShortClosed(void)
  {
   bool res=false;
//--- should it be closed?
   if(Signal(BUY) && IsPriceRangeValid(BUY) && CheckAO(BUY))
     {
      //--- close position
      if(m_trade.PositionClose(Symbol()))
         printf("Short position by %s to be closed",Symbol());
      else
         printf("Error closing position by %s : '%s'",Symbol(),m_trade.ResultComment());
      //--- processed and cannot be modified
      res=true;
     }
//--- result
   return(res);
  }
//+------------------------------------------------------------------+
//| Check for long position modifying                                |
//+------------------------------------------------------------------+
bool CSampleExpert::LongModified(void)
  {
   bool res=false;
//--- check for trailing stop
   if(InpTrailingStop>0)
     {
      if(m_symbol.Bid()-m_position.PriceOpen()>m_adjusted_point*InpTrailingStop)
        {
         double sl=NormalizeDouble(m_symbol.Bid()-m_traling_stop,m_symbol.Digits());
         double tp=m_position.TakeProfit();
         if(m_position.StopLoss()<sl || m_position.StopLoss()==0.0)
           {
            //--- modify position
            if(m_trade.PositionModify(Symbol(),sl,tp))
               printf("Long position by %s to be modified",Symbol());
            else
              {
               printf("Error modifying position by %s : '%s'",Symbol(),m_trade.ResultComment());
               printf("Modify parameters : SL=%f,TP=%f",sl,tp);
              }
            //--- modified and must exit from expert
            res=true;
           }
        }
     }
//--- result
   return(res);
  }
//+------------------------------------------------------------------+
//| Check for short position modifying                               |
//+------------------------------------------------------------------+
bool CSampleExpert::ShortModified(void)
  {
   bool   res=false;
//--- check for trailing stop
   if(InpTrailingStop>0)
     {
      if((m_position.PriceOpen()-m_symbol.Ask())>(m_adjusted_point*InpTrailingStop))
        {
         double sl=NormalizeDouble(m_symbol.Ask()+m_traling_stop,m_symbol.Digits());
         double tp=m_position.TakeProfit();
         if(m_position.StopLoss()>sl || m_position.StopLoss()==0.0)
           {
            //--- modify position
            if(m_trade.PositionModify(Symbol(),sl,tp))
               printf("Short position by %s to be modified",Symbol());
            else
              {
               printf("Error modifying position by %s : '%s'",Symbol(),m_trade.ResultComment());
               printf("Modify parameters : SL=%f,TP=%f",sl,tp);
              }
            //--- modified and must exit from expert
            res=true;
           }
        }
     }
//--- result
   return(res);
  }
//+------------------------------------------------------------------+
//| Check for long position opening                                  |
//+------------------------------------------------------------------+
bool CSampleExpert::LongOpened(void)
  {
   bool res=false;
//--- check for long position (BUY) possibility
   bool timer_on = time_checker.IsTimerOn();
   if(IsNewBar() && timer_on && Signal(BUY) && IsPriceRangeValid(BUY) && CheckAO(BUY))
     {
      double price=m_symbol.Ask();
      double tp   =m_symbol.Bid()+m_take_profit;
      double sl   =NormalizeDouble(m_symbol.Bid()-m_traling_stop,m_symbol.Digits());
      //--- check for free money
      if(m_account.FreeMarginCheck(Symbol(),ORDER_TYPE_BUY,InpLots,price)<0.0)
         printf("We have no money. Free Margin = %f",m_account.FreeMargin());
      else
        {
         //--- open position
         if(m_trade.PositionOpen(Symbol(),ORDER_TYPE_BUY,InpLots,price,sl,tp))
           {
            m_last_order_time=iTime(Symbol(),Period(), 0);
            printf("Position by %s to be opened at %i:%i:%i");
           }

         else
           {
            printf("Error opening BUY position by %s : '%s'",Symbol(),m_trade.ResultComment());
            printf("Open parameters : price=%f,TP=%f",price,tp);
           }
        }
      //--- in any case we must exit from expert
      res=true;
     }
//--- result
   return(res);
  }
//+------------------------------------------------------------------+
//| Check for short position opening                                 |
//+------------------------------------------------------------------+
bool CSampleExpert::ShortOpened(void)
  {
   bool res=false;
//--- check for short position (SELL) possibility
   bool timer_on = time_checker.IsTimerOn();
   if(IsNewBar() && timer_on && Signal(SELL) && IsPriceRangeValid(SELL) && CheckAO(SELL))
     {
      double price=m_symbol.Bid();
      double tp   =m_symbol.Ask()-m_take_profit;
      double sl   =NormalizeDouble(m_symbol.Ask()+m_traling_stop,m_symbol.Digits());
      //--- check for free money
      if(m_account.FreeMarginCheck(Symbol(),ORDER_TYPE_SELL,InpLots,price)<0.0)
         printf("We have no money. Free Margin = %f",m_account.FreeMargin());
      else
        {
         //--- open position
         if(m_trade.PositionOpen(Symbol(),ORDER_TYPE_SELL,InpLots,price,sl,tp))
           {
            m_last_order_time=iTime(Symbol(),Period(), 0);
            printf("Position by %s to be opened",Symbol());

           }
         else
           {
            printf("Error opening SELL position by %s : '%s'",Symbol(),m_trade.ResultComment());
            printf("Open parameters : price=%f,TP=%f",price,tp);
           }
        }
      //--- in any case we must exit from expert
      res=true;
     }
//--- result
   return(res);
  }
//+------------------------------------------------------------------+
//| main function returns true if any position processed             |
//+------------------------------------------------------------------+
bool CSampleExpert::Processing(void)
  {
//--- refresh rates
   if(!m_symbol.RefreshRates())
      return(false);

//--- refresh indicators
   m_indicators.Refresh();
   CopyRates(NULL, 0, 0, InpBBLookbackPeriod+1, rates);
//--- it is important to enter the market correctly,
//--- but it is more important to exit it correctly...
//--- first check if position exists - try to select it
   if(m_position.Select(Symbol()))
     {
      if(m_position.PositionType()==POSITION_TYPE_BUY)
        {
         //--- try to close or modify long position
         if(LongClosed())
            return(true);
         if(LongModified())
            return(true);
        }
      else
        {
         //--- try to close or modify short position
         if(ShortClosed())
            return(true);
         if(ShortModified())
            return(true);
        }
     }
//--- no opened position identified
   else
     {
      // TODO: exclude mondays and only trade between 10 and 18 oclock including
      //--- check for long position (BUY) possibility
      if(LongOpened())
         return(true);
      //--- check for short position (SELL) possibility
      if(ShortOpened())
         return(true);
     }
//--- exit without position processing
   return(false);
  }
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(void)
  {
//--- create all necessary objects
   if(!ExtExpert.Init())
      return(INIT_FAILED);
//--- secceed
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert new tick handling function                                |
//+------------------------------------------------------------------+
void OnTick(void)
  {
   static datetime limit_time=0; // last trade processing time + timeout
//--- don't process if timeout
   if(TimeCurrent()>=limit_time)
     {
      //--- check for data
      if(Bars(Symbol(),Period())>2*InpMATrendPeriod)
        {
         //--- change limit time by timeout in seconds if processed
         if(ExtExpert.Processing())
            limit_time=TimeCurrent()+ExtTimeOut;
        }
     }
  }
//+------------------------------------------------------------------+
