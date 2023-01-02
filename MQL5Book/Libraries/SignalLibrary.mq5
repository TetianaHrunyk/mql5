//+------------------------------------------------------------------+
//|                                                SignalLibrary.mq5 |
//|                                                     Andrew Young |
//|                                 http://www.expertadvisorbook.com |
//+------------------------------------------------------------------+

// An example of a library that returns a trading signal to a program


#property library

#include <Mql5Book\Indicators.mqh>
CiRSI RSI;

bool BuySignal(string pSymbol, ENUM_TIMEFRAMES pTimeframe, int pPeriod, ENUM_APPLIED_PRICE pPrice) export
{
	RSI.Init(pSymbol,pTimeframe,pPeriod,pPrice);
	
	if(RSI.Main() < 30) return(true);
	else return(false);
}

bool SellSignal(string pSymbol, ENUM_TIMEFRAMES pTimeframe, int pPeriod, ENUM_APPLIED_PRICE pPrice) export
{
	RSI.Init(pSymbol,pTimeframe,pPeriod,pPrice);
	
	if(RSI.Main() > 70) return(true);
	else return(false);
}