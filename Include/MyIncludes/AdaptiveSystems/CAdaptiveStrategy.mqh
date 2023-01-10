//+------------------------------------------------------------------+
//|                                            CAdaptiveStrategy.mqh |
//|                        Copyright 2010, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

#include <Arrays\ArrayObj.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <CStrategyMA.mqh>
#include <CStrategyMAinv.mqh>
#include <CStrategyStoch.mqh>
//+------------------------------------------------------------------+
//| Class CAdaptiveStrategy                                          |
//+------------------------------------------------------------------+
class CAdaptiveStrategy
  {
protected:
   CArrayObj        *m_all_strategies;   // objects of trade strategies

   void              ProceedSignalReal(int state,double trade_volume);
   int               RealPositionDirection();

public:
   // initialization of the adaptive strategy
   int               Expert_OnInit();
   // deinitialization of the adaptive strategy
   int               Expert_OnDeInit(const int reason);
   // check of the trade conditions and opening of virtual positions
   void              Expert_OnTick();
   // 
  };
//+------------------------------------------------------------------+
//| The function of initialization of the adaptive Expert Advisor    |
//+------------------------------------------------------------------+
int CAdaptiveStrategy::Expert_OnInit()
  {
//--- Create array of objects m_all_strategies
//--- in it we will place our objects with strategies 
   m_all_strategies=new CArrayObj;
   if(m_all_strategies==NULL)
     {
      Print("Error of creation of the m_all_strategies object"); return(-1);
     }

// create 10 trade strategies CStrategyMA (trading by moving averages)
// initialize them, set parameters
// and add to the m_all_strategies container 
   for(int i=0; i<10; i++)
     {
      CStrategyMA *t_StrategyMA;
      t_StrategyMA=new CStrategyMA;
      if(t_StrategyMA==NULL)
        {
         delete m_all_strategies;
         Print("Error of creation of object of the CStrategyMA type");
         return(-1);
        }
      //set period for each strategy
      int period=3+i*10;
      // initialization of strategy
      t_StrategyMA.Initialization(period,true);
      // set details of the strategy
      t_StrategyMA.SetStrategyInfo(_Symbol,"[MA_"+IntegerToString(period)+"]",period,"Moving Averages "+IntegerToString(period));
      //t_StrategyMA.Set_Stops(3500,1000);
      
      t_StrategyMA.SetLots(0.1);

      //add object of the strategy to the m_all_strategies array of objects
      m_all_strategies.Add(t_StrategyMA);
     }


   // create 10 trade systems CStrategyMAinv (trading by moving strategies but the signals are reversed)
   // initialize them, set parameters
   // and add to the m_all_strategies container 
   for(int i=0; i<10; i++)
     {
      CStrategyMAinv *t_StrategyMAinv;
      t_StrategyMAinv =new CStrategyMAinv;
      if(t_StrategyMAinv==NULL)
        {
         delete m_all_strategies;
         Print("Error of creation of object of the CStrategyMAinv type");
         return(-1);
        }
      //set period for each strategy
      int period=3+i*10;
      // initialization of strategy
      t_StrategyMAinv.Initialization(period,true);
      // set details of the strategy
      t_StrategyMAinv.SetStrategyInfo(_Symbol,"[MAinv_"+IntegerToString(period)+"]",period,"Moving Averages [inverted]"+IntegerToString(period));
      //t_StrategyMA.Set_Stops(3500,1000);
      
      t_StrategyMAinv.SetLots(0.1);

      //add object of the strategy to the m_all_strategies array of objects
      m_all_strategies.Add(t_StrategyMAinv);
     }


/*
   for(int i=0; i<100; i++)
     {
      CStrategyMA *t_StrategyMA;
      t_StrategyMA=new CStrategyMA;
      if(t_StrategyMA==NULL)
        {
         delete m_all_strategies;
         Print("Error of creation of object of the CStrategyMA type");
         return(-1);
        }
      //set period for each strategy
      int period=3+i*10;
      // initialization of strategy
      t_StrategyMA.Initialization(period,true);
      // set details of the strategy
      t_StrategyMA.SetStrategyInfo(_Symbol,"[MA_"+IntegerToString(period)+"]",period,"Moving Averages "+IntegerToString(period));
      //add object of the strategy to the m_all_strategies array of objects
      m_all_strategies.Add(t_StrategyMA);
     }
*/

/*   for(int i=0; i<5; i++)
     {
      CStrategyStoch *t_StrategyStoch;
      t_StrategyStoch=new CStrategyStoch;
      if(t_StrategyStoch==NULL)
        {
         delete m_all_strategies;
         printf("Error of creation of object of the t_StrategyStoch type");
         return(-1);
        }
      //set period for each strategy
      int Kperiod=2+i*5;
      int Dperiod=2+i*5;
      int Slowing=3+i;
      // initialization of strategy
      t_StrategyStoch.Initialization(Kperiod,Dperiod,Slowing,true);
      // set details of the strategy
      string s=IntegerToString(Kperiod)+"/"+IntegerToString(Dperiod)+"/"+IntegerToString(Slowing);
      t_StrategyStoch.SetStrategyInfo(_Symbol,"[Stoch_"+s+"]",100+i," Stochastic "+s);
      //add object of the strategy to the m_all_strategies array of objects
      m_all_strategies.Add(t_StrategyStoch);
     }
*/
   for(int i=0; i<m_all_strategies.Total(); i++)
     {
      CSampleStrategy *t_SampleStrategy;
      t_SampleStrategy=m_all_strategies.At(i);
      Print(i," Strategy name:",t_SampleStrategy.StrategyName(),
              " Strategy ID:",t_SampleStrategy.StrategyID(),
              " Virt. trading:",t_SampleStrategy.IsVirtualTradeAllowed());
     }
//---
   return(0);
  }
//+------------------------------------------------------------------+
//| Function of deinitialization of the adaptive Expert Advisor      |
//+------------------------------------------------------------------+
int CAdaptiveStrategy::Expert_OnDeInit(const int reason)
  {
// deinitialize all the strategies
   for(int i=0; i<m_all_strategies.Total(); i++)
     {
      CSampleStrategy *t_Strategy;
      t_Strategy=m_all_strategies.At(i);
      t_Strategy.SaveVirtualDeals(t_Strategy.StrategyName()+"_deals.txt");
      t_Strategy.Deinitialization();
     }
//delete the array of objects with the strategies 
   delete m_all_strategies;
   return(0);
  }

//int checkpoint_bars=1;
//+------------------------------------------------------------------+
//| Function of processing of tick of the adaptive Expert Advisor    |
//+------------------------------------------------------------------+
void CAdaptiveStrategy::Expert_OnTick()
  {
   CSampleStrategy *t_Strategy;
   // static int bar_counter;
   // Recalculate information about positions for all the strategies 
   for(int i=0; i<m_all_strategies.Total(); i++)
     {
      t_Strategy=m_all_strategies.At(i);
      t_Strategy.UpdatePositionData();
     }

   // The EA should check the conditions of performing new trade operation only when a new bar comes
   if(IsNewBar()==false) { return; }

//--- in case we need to execute CheckPoint each checkpoint_bars bars 
//   bar_counter++;  
//   if(bar_counter==checkpoint_bars)
//     {
//      //Print(bar counter," bars completed.");
//      bar_counter=0;
//     }

   // check the trade conditions for all the strategies 
   for(int i=0; i<m_all_strategies.Total(); i++)
     {
      t_Strategy=m_all_strategies.At(i);
      t_Strategy.CheckTradeConditions();
     }

   //perform the search for the best position
   //prepare the performance[] array 
   double performance[];
   ArrayResize(performance,m_all_strategies.Total());
   
   //request the current effectiveness of each position,
   //each strategy returns it in the Strategyperformance() function
   for(int i=0; i<m_all_strategies.Total(); i++)
     {
      t_Strategy=m_all_strategies.At(i);
      performance[i]=t_Strategy.StrategyPerformance();
     }
   // find the strategy (its index in the m_all_strategies container)
   //with the maximal value of Strategyperformance()
   int best_strategy_index=ArrayMaximum(performance,0,WHOLE_ARRAY);

   //it is the t_Strategy strategy
   t_Strategy=m_all_strategies.At(best_strategy_index);
   //request the direction of its current position
   int best_direction=t_Strategy.PositionDirection();

/*   string s=s+" "+t_Strategy.StrategyName()+" "+DoubleToString(t_Strategy.GetVirtualEquity())+" "+IntegerToString(best_direction);
   Print(TimeCurrent()," TOTAL=",m_all_strategies.Total(),
                       " BEST IND=",best_strategy_index,
                       " BEST STRATEGY="," ",t_Strategy.StrategyName(),
                       " BEST=",performance[best_strategy_index],"  =",
                       " BEST DIRECTION=",best_direction,
                       " Performance=",t_Strategy.StrategyPerformance());
*/
   //if the best strategy is losing and doesn't have open positions, it's better not to trade
   if((performance[best_strategy_index]<0) && (RealPositionDirection()==POSITION_NEUTRAL)) {return;}

   if(best_direction!=RealPositionDirection())
     {
      ProceedSignalReal(best_direction,t_Strategy.GetCurrentLots());
     }
  }
//+------------------------------------------------------------------+
//| Returns the direction (0,+1,-1) of the current real positions    |
//+------------------------------------------------------------------+
int CAdaptiveStrategy::RealPositionDirection()
  {
   int direction=POSITION_NEUTRAL;
   CPositionInfo posinfo;

   if(posinfo.Select(_Symbol)) // if there are open positions
     {
      if(posinfo.Type()==POSITION_TYPE_BUY) direction=POSITION_LONG;    // a buy positions is opened
      if(posinfo.Type()==POSITION_TYPE_SELL) direction=POSITION_SHORT;  // a sell positions is opened
     }
   return(direction);
  }
//+------------------------------------------------------------------+
//| This method is intended for "synchronization" of the current     |
//| real trade position with the state values (state)                |
//+------------------------------------------------------------------+
void CAdaptiveStrategy::ProceedSignalReal(int state,double trade_volume)
  {
   CPositionInfo posinfo;
   CTrade trade;

   bool buy_opened=false;
   bool sell_opened=false;

   if(posinfo.Select(_Symbol)) // if there are open positions
     {
      if(posinfo.Type()==POSITION_TYPE_BUY) buy_opened=true;    // a buy position is opened
      if(posinfo.Type()==POSITION_TYPE_SELL) sell_opened=true;  // a sell position is opened

      // if state = 0, then we need to close the open positions
      if((state==POSITION_NEUTRAL) && (buy_opened || sell_opened))
        {
         if(!trade.PositionClose(_Symbol,200))
            Print(trade.ResultRetcodeDescription());
        }
      //reverse: close a buy position and open a sell position
      if((state==POSITION_SHORT) && (buy_opened))
        {
         if(!trade.PositionClose(_Symbol,200))
            Print(trade.ResultRetcodeDescription());
         if(!trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,trade_volume,SymbolInfoDouble(_Symbol,SYMBOL_BID),0,0))
            Print(trade.ResultRetcodeDescription());
        }
      //reverse: close a sell position and open a buy position
      if(((state==POSITION_LONG) && (sell_opened)))
        {
         if(!trade.PositionClose(_Symbol,200))
            Print(trade.ResultRetcodeDescription());
         if(!trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,trade_volume,SymbolInfoDouble(_Symbol,SYMBOL_ASK),0,0))
            Print(trade.ResultRetcodeDescription());
        }
     }
   else // if there are no open positions
     {
      // open a buy position
      if(state==POSITION_LONG)
        {
         if(!trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,trade_volume,SymbolInfoDouble(_Symbol,SYMBOL_ASK),0,0))
            Print(trade.ResultRetcodeDescription());
        }
      // open a sell position
      if(state==POSITION_SHORT)
        {
         if(!trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,trade_volume,SymbolInfoDouble(_Symbol,SYMBOL_BID),0,0))
            Print(trade.ResultRetcodeDescription());
        }
     }
  }
///-------------------------------------------------------------------  
