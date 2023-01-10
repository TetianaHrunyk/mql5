//+------------------------------------------------------------------+
//|                                       Adaptive_Expert_Sample.mq5 |
//|                        Copyright 2010, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <CAdaptiveStrategy.mqh>

CAdaptiveStrategy Adaptive_Expert;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   return(Adaptive_Expert.Expert_OnInit());
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Adaptive_Expert.Expert_OnDeInit(reason);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   Adaptive_Expert.Expert_OnTick();
  }
//+------------------------------------------------------------------+
