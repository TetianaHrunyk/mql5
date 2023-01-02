//+------------------------------------------------------------------+
//|                                             TestPatternUsage.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#define IS_PATTERN_USAGE(p)          ((m_patterns_usage&(((int)1)<<p))!=0)

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   printf("Hello");
   int m_patterns_usage = 3;

   for(int i=0; i < 9; i++)
     {
      printf("Use patter %i: %b", i, IS_PATTERN_USAGE(i));
     }
  }
//+------------------------------------------------------------------+
