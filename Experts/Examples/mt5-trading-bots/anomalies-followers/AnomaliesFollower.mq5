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

#define EXPERT_MAGIC_NUMBER 1234502
//---
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\Oscilators.mqh>
#include <Indicators\Indicators.mqh>
//---
input double InpLots          =0.1; // Lots
input int    InpTakeProfit    =100;  // Take Profit (in pips)
input int    InpTrailingStop  =10;  // Trailing Stop Level (in pips)
input string    str1= "";             // ---------------------------------------------------
input int    InpATRPeriod     =14; // ATR Period
input int    InpATRSL         =2;  // ATRs to set sl
int    InpPeriodAMA     = 9;                  // AMA Period
int    InpMAPeriodFast  =2;           //Period of fast averaging
int    InpMAPeriodSlow  =30;          //Period of slow averaging
int    InpShift         =0;               //Time shift slow
ENUM_APPLIED_PRICE InpApplied        =PRICE_CLOSE;     //MA price
input string    str2= "";             // ---------------------------------------------------
input double        InpCandleSizeChange=2;             // Candle size change
int           InpMAChange=2;                // Min MA change
int           InpMALookback=1;              // Candle to analyze the change
input int           InpMinCandleSize  =10;              // Min Prev Candle Size in pips
input bool          InpTradeOnNewBars =true;



enum SIGNAL
  {
   BUY = 1,
   SELL = -1,
  };

//---
int ExtTimeOut=10; // time out in seconds between trade operations
//+------------------------------------------------------------------+
//| Simple BB advisor                                                |
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
   CiAMA             m_ma;                         // MA object indicator handle
   CiATR             m_atr;                        // ATR object indicator handle
   CIndicators       m_indicators;                 // indicator collection to fast recalculations
   //--- indicator buffers
   MqlRates          rates[];                      // Rates buffer
   //---
   double            m_ma_trend_threshold;
   double            m_traling_stop;
   double            m_take_profit;
   datetime          m_last_order_time;

   //--- expert-specific settings
   double            m_min_candle_size;
   double            m_min_ma_change;

public:
                     CSampleExpert(void);
                    ~CSampleExpert(void);
   bool              Init(void);
   void              Deinit(void);
   bool              Processing(void);

protected:
   bool              InitCheckParameters(const int digits_adjust);
   bool              InitIndicators(CIndicators *indicators);
   bool              LongClosed(void);
   bool              ShortClosed(void);
   bool              LongModified(void);
   bool              ShortModified(void);
   bool              LongOpened(void);
   bool              ShortOpened(void);
   bool              Signal(SIGNAL opportunity);
   bool              IsNewBar(void);
   double            CandleBody(int idx) {return(MathAbs(rates[idx].open-rates[idx].close));} ;
   bool              AnomalousCandle(double price);
   double            TrendFactor(SIGNAL opportunity);
   bool              MinMAChangeReached(SIGNAL opportunity);
   double            CurrSL(void) {return(MathMax(m_atr.Main(1)*InpATRSL, m_traling_stop));}
   datetime          LastOutDealTime(void);
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
  printf("Init");
//--- initialize common information
   m_symbol.Name(Symbol());                  // symbol
   m_trade.SetExpertMagicNumber(EXPERT_MAGIC_NUMBER); // magic
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
   m_traling_stop    =InpTrailingStop*m_adjusted_point;
   m_take_profit     =InpTakeProfit*m_adjusted_point;
//--- set default deviation for trading in adjusted points
   m_trade.SetDeviationInPoints(3*digits_adjust);
   m_min_candle_size=InpMinCandleSize*m_adjusted_point;
   m_min_ma_change=InpMAChange*m_adjusted_point;
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
//--- add MA object to collection
   if(!indicators.Add(GetPointer(m_ma)))
     {
      printf(__FUNCTION__+": error adding MA object");
      return(false);
     }
   if(!m_ma.Create(NULL,0,InpPeriodAMA,InpMAPeriodFast,InpMAPeriodSlow,InpShift,InpApplied))
     {
      printf(__FUNCTION__+": error MA initializing object");
      return(false);
     }
//--- add ATR object to collection
   if(!indicators.Add(GetPointer(m_atr)))
     {
      printf(__FUNCTION__+": error adding ATR object");
      return(false);
     }
   if(!m_atr.Create(NULL,0,InpATRPeriod))
     {
      printf(__FUNCTION__+": error ATR initializing object");
      return(false);
     }
//--- succeed
   return(true);
  }

//+------------------------------------------------------------------+
//|Get Last Market Deal Time                         |
//+------------------------------------------------------------------+
datetime CSampleExpert::LastOutDealTime(void)
  {
   datetime deal_time;
   HistorySelect(0,TimeCurrent());
   int orders=HistoryDealsTotal();  // total history deals
   CDealInfo deal;

   for(int i=orders-1; i>=0; i--)
     {
      deal.Ticket(HistoryDealGetTicket(i));
      if(deal.Ticket()==0)
        {
         Print("No trade history");
         break;
        }

      if(deal.Symbol()!=m_symbol.Name())
         continue;
      // TODO: only closed on stop loss
      if(deal.Entry() == DEAL_ENTRY_OUT)
        {
         deal_time = deal.Time();
         break;
        }
     }
   return(deal_time);
  }

//+------------------------------------------------------------------+
//|Check if the last deal was in another bar                         |
//+------------------------------------------------------------------+
bool CSampleExpert::IsNewBar(void)
  {
   bool res = true;
   if(InpTradeOnNewBars)
     {
      datetime time=iTime(Symbol(),Period(),0);
      datetime last_out_deal = LastOutDealTime();
      if(last_out_deal > time)
         res = false;
      //if (res == false) printf("Cannot open positions on the same bar");
     }
   return(res);
  }

//+------------------------------------------------------------------+
//| Check if MA is reflecting market chanegs                         |
//+------------------------------------------------------------------+
bool CSampleExpert::MinMAChangeReached(SIGNAL opportunity)
  {
   bool res = false;
   int idx = 2;
   if(InpMALookback > 2)
      idx=InpMALookback;
   if(opportunity == SELL)
     {
      if(m_ma.Main(1)-m_ma.Main(idx) < -m_min_ma_change)
         res = true;
     }
   if(opportunity == BUY)
     {
      if(m_ma.Main(1)-m_ma.Main(idx) > m_min_ma_change)
         res = true;
     }
   return(res);
  }

//+------------------------------------------------------------------+
//| Check for AnomalousCandle                                               |
//+------------------------------------------------------------------+
bool CSampleExpert::AnomalousCandle(double price)
  {
   double prev_candle_body = MathMax(CandleBody(1), 0.0000001);
   double cur_candle_body = MathAbs(price-rates[0].open);
   double ratio = cur_candle_body/prev_candle_body;
   return prev_candle_body>m_min_candle_size && ratio > InpCandleSizeChange;
  }

//+------------------------------------------------------------------+
//| Check for Trend Factor                                           |
//+------------------------------------------------------------------+
double CSampleExpert::TrendFactor(SIGNAL opportunity)
  {
   double res = 1;
   double ma_change_weight = 5;
   double candle_change_weight = 2.5;
   double ma_change = (m_ma.Main(1) - m_ma.Main(2))*ma_change_weight;
   double candle_change = (rates[1].open - rates[1].close)*candle_change_weight;
   if(opportunity == SELL)
     {
      res-=ma_change;
      res-=candle_change;
     }
   if(opportunity == BUY)
     {
      res+= ma_change;
      res+=candle_change;
     }
   return(res);
  }

//+------------------------------------------------------------------+
//| Check for signal                                                 |
//+------------------------------------------------------------------+
bool CSampleExpert::Signal(SIGNAL opportunity)
  {
   bool res = false;
   double price_open = rates[0].open;
   if(opportunity == SELL)
     {
      double price = m_symbol.Bid();
      //if(AnomalousCandle(price) && price-rates[0].open < 0)
      double ratio = price_open/price;
      double threshold = 1+InpCandleSizeChange/100;
      double trend_factor = TrendFactor(SELL);
      double adjusted_threshold = threshold/trend_factor;
      //if(price_open/price > (1+InpCandleSizeChange/100)/TrendFactor(SELL) )
      //if(price < rates[1].low   && MinMAChangeReached(SELL))
      if(price < rates[1].low  && AnomalousCandle(price))
        {
         res = true;
        }
     }
   else
      if(opportunity == BUY)
        {
         double price = m_symbol.Ask();
         double ratio = price_open/price;
         double threshold = 1-InpCandleSizeChange/100;
         double trend_factor = TrendFactor(BUY);
         double adjusted_threshold = threshold/trend_factor;
         //if(price_open/price < (1-InpCandleSizeChange/100)/TrendFactor(BUY) )
         //if(price > rates[1].high && AnomalousCandle(price) && MinMAChangeReached(BUY))
         if(price > rates[1].high && AnomalousCandle(price))
           {
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
   if(Signal(SELL))
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
   if(Signal(BUY))
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
   bool   res=false;
   double curr_sl = CurrSL();
//--- check for trailing stop
   if(InpTrailingStop>0)
     {
      if(m_symbol.Bid()-m_position.StopLoss()>curr_sl)
        {
         double sl=NormalizeDouble(m_symbol.Bid()-curr_sl,m_symbol.Digits());
         double tp=m_position.TakeProfit();

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
//--- result
   return(res);
  }
//+------------------------------------------------------------------+
//| Check for short position modifying                               |
//+------------------------------------------------------------------+
bool CSampleExpert::ShortModified(void)
  {
   bool   res=false;
   double curr_sl = CurrSL();
//--- check for trailing stop
   if(InpTrailingStop>0)
     {

      if(m_position.StopLoss()-m_symbol.Ask()>curr_sl)
        {
         double sl=NormalizeDouble(m_symbol.Ask()+curr_sl,m_symbol.Digits());
         double tp = m_position.TakeProfit();

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
   if(Signal(BUY) && IsNewBar())
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
            printf("Position by %s to be opened",Symbol());
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

   if(Signal(SELL) && IsNewBar())
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
   int copied_rates = CopyRates(NULL, 0, 0, 20, rates);
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
      if(Bars(Symbol(),Period())>2*InpPeriodAMA)
        {
         //--- change limit time by timeout in seconds if processed
         if(ExtExpert.Processing())
            limit_time=TimeCurrent()+ExtTimeOut;
        }
     }
  }
//+------------------------------------------------------------------+
