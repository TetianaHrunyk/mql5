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

#define MACD_MAGIC 1234502
//---
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Indicators.mqh>

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
input double InpLots          =0.1; // Lots
input int    InpTakeProfit    =70;  // Take Profit (in pips)
input int    InpTrailingStop  =20;  // Trailing Stop Level (in pips)
input int    InpMATrendPeriod =20;  // MA trend period
input int    InpATRPeriod     =14;  // ATR Period
input int    InpMinAtrLevel   = 4;  // Min ATR in pips
input BB_STRATEGY    InpBBTradingStrategy =EXTREMUM_CROSS_FOLLOWED_BY_REVERSAL;  // BB trading strategy
input bool   InpValidateMATrend =true;  // Check if trend is positive or negative before deals
input int    InpMATrendValidationPeriod =3;  // The period the trend has to be observed to apply signal
input int    InpMATrendValidationThreshold =2;  // Minimum diff in pips to consider trend as changed
input TRADE_RANGE   InpTradeRange = CORRIDOR;  // When to onen positions: on the edges of the bb, in the corridor or any time

//---Time setting
input bool InpTradeOnNewBars   = true;


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
   CiATR              m_atr;                        // ATR indicator
   //--- indicator buffers
   MqlRates          rates[];                      // Rates buffer
   //---
   double            m_ma_trend_threshold;
   double            m_traling_stop;
   double            m_take_profit;
   double            m_min_atr;
   datetime          m_last_order_time;

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
   bool              MATrendObserved(SIGNAL direction);
   bool              ValidateMATrend(SIGNAL direction);
   bool              CheckATRLevel();
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
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSampleExpert::~CSampleExpert(void)
  {
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
   m_ma_trend_threshold=InpMATrendValidationThreshold*m_adjusted_point;
   m_traling_stop    =InpTrailingStop*m_adjusted_point;
   m_take_profit     =InpTakeProfit*m_adjusted_point;
   m_min_atr         =InpMinAtrLevel*m_adjusted_point;
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
//--- add ATR object to collection
   if(!indicators.Add(GetPointer(m_atr)))
     {
      printf(__FUNCTION__+": error adding ATR object");
      return(false);
     }
   if(!m_atr.Create(NULL,0,14))
     {
      printf(__FUNCTION__+": error ATR initializing object");
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
//|Check if the ATR level is ok                                      |
//+------------------------------------------------------------------+
bool CSampleExpert::CheckATRLevel(void){
   bool res = true;
   if (m_atr.Main(0) < m_min_atr) res = false;
   return(res);
}

//+------------------------------------------------------------------+
//|Check if MA confirms positive or negative trend                   |
//+------------------------------------------------------------------+
bool CSampleExpert::MATrendObserved(SIGNAL direction)
  {
   bool res = true;
   for(int i=0; i<InpMATrendValidationPeriod-1; i++)
     {
      // negative trend?
      if(direction == BUY)
        {
         if(m_bands_1.Base(i) - m_bands_1.Base(i+1) <= m_ma_trend_threshold)
           {
            res=false;
            break;
           }
        }
      // positive trend?
      if(direction == SELL)
        {
         if(m_bands_1.Base(i) - m_bands_1.Base(i+1) >= m_ma_trend_threshold)
           {
            res=false;
            break;
           }
        }
     }
   return(res);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSampleExpert::ValidateMATrend(SIGNAL direction)
  {
   bool is_valid = true;
   if(InpValidateMATrend)
      is_valid = MATrendObserved(direction);
   return (is_valid);
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
      if(price >= m_bands_1.Upper(0) || price <= m_bands_1.Lower(0))
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
      if(opportunity == SELL)
      {
         if(rates[1].close <= m_bands_2.Lower(1))
            res = true;
      }
      if(opportunity == BUY)
         if(rates[1].close >= m_bands_2.Upper(1))
            res = true;
     }
   
   if(InpBBTradingStrategy == TOUCH)
     {
      if(opportunity == SELL)
      {
         if(rates[1].low <= m_bands_2.Lower(1))
            res = true;
      }
      if(opportunity == BUY)
         if(rates[1].high >= m_bands_2.Upper(1))
            res = true;
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
   if(Signal(SELL) && IsPriceRangeValid(SELL) && ValidateMATrend(BUY))
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
   if(Signal(BUY) && IsPriceRangeValid(BUY) && ValidateMATrend(SELL))
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
   if(IsNewBar() && Signal(BUY) && IsPriceRangeValid(BUY) && ValidateMATrend(BUY) && CheckATRLevel())
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
//--- check for short position (SELL) possibility);
   if(IsNewBar() && Signal(SELL) && IsPriceRangeValid(SELL) && ValidateMATrend(SELL) && CheckATRLevel())
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
   CopyRates(NULL, 0, 0, 3, rates);
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
