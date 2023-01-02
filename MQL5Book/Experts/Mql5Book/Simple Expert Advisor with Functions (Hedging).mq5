//+------------------------------------------------------------------+
//| 							Simple Expert Advisor w/ Functions (Hedging) |
//|                                                     Andrew Young |
//|                                 http://www.expertadvisorbook.com |
//+------------------------------------------------------------------+

#property copyright "Andrew Young"
#property link      "http://www.expertadvisorbook.com"
#property description "Same as Simple Expert Advisor, but using the functions and classes defined in the include files."

/*
 Creative Commons Attribution-NonCommercial 3.0 Unported
 http://creativecommons.org/licenses/by-nc/3.0/

 You may use this file in your own personal projects. You
 may modify it if necessary. You may even share it, provided
 the copyright above is present. No commercial use permitted. 
*/


#include <Mql5Book\TradeHedge.mqh>
CTradeHedge Trade;
CPositions Positions;

// Price
#include <Mql5Book\Price.mqh>
CBars Price;

// Indicators 
#include <Mql5Book\Indicators.mqh>
CiMA MA;


// Input variables
input double TradeVolume=0.1;
input int StopLoss=1000;
input int TakeProfit=1000;

input int MAPeriod = 10;
input ENUM_MA_METHOD MAMethod = 0;
input int MAShift = 0;
input ENUM_APPLIED_PRICE MAPrice = PRICE_CLOSE;

input int MagicNumber = 12345;


// Global variables 
bool glBuyPlaced, glSellPlaced;


// OnInit() event handler
void OnInit()
{
   Trade.MagicNumber(MagicNumber);
}


// OnTick() event handler
void OnTick()
{
	
	// Moving average
	MA.Init(_Symbol,_Period,MAPeriod,MAShift,MAMethod,MAPrice);
   
   
   // Update prices
	Price.Update(_Symbol,_Period);
	
	
	// Get current market orders
	ulong buyTicket = 0, sellTicket = 0;
		
	if(Positions.Buy(MagicNumber) == 1) 
	{
	   ulong buyTickets[];
	   Positions.GetBuyTickets(MagicNumber, buyTickets);
	   buyTicket = buyTickets[0];
	   glBuyPlaced = true;
	}
	
	if(Positions.Sell(MagicNumber) == 1) 
	{
	   ulong sellTickets[];
	   Positions.GetSellTickets(MagicNumber, sellTickets);
	   sellTicket = sellTickets[0];
	   glSellPlaced = true;
	}
   
   
   // Open buy market order
   if(Price.Close() > MA.Main() && glBuyPlaced == false)
   {
   	// Close sell order
   	if(sellTicket > 0)
   	{
   	   Trade.Close(sellTicket);
   	}
   	
   	// Open buy order
   	buyTicket = Trade.Buy(_Symbol,TradeVolume);
		
		// Modify SL/TP
		if(buyTicket > 0)
		{
			PositionSelectByTicket(buyTicket);
			double positionOpenPrice = PositionOpenPrice(buyTicket);
	
			double buyStopLoss = BuyStopLoss(_Symbol,StopLoss,positionOpenPrice);
			if(buyStopLoss > 0) buyStopLoss = AdjustBelowStopLevel(_Symbol,buyStopLoss);
			
			double buyTakeProfit = BuyTakeProfit(_Symbol,TakeProfit,positionOpenPrice);
			if(buyTakeProfit > 0) buyTakeProfit = AdjustAboveStopLevel(_Symbol,buyTakeProfit);
			
			if(buyStopLoss > 0 || buyTakeProfit > 0) Trade.ModifyPosition(buyTicket,buyStopLoss,buyTakeProfit);
			
			glSellPlaced = false;
		} 
   }
   
   
   // Open sell market order
   else if(Price.Close() < MA.Main() && glSellPlaced == false)
   {
   	// Close buy order
   	if(buyTicket > 0)
   	{
   	   Trade.Close(buyTicket);
   	}
   	
   	sellTicket = Trade.Sell(_Symbol,TradeVolume);
		
		// Modify SL/TP
		if(sellTicket > 0)
		{
			PositionSelectByTicket(buyTicket);
			double positionOpenPrice = PositionOpenPrice(buyTicket);
			
			double sellStopLoss = SellStopLoss(_Symbol,StopLoss,positionOpenPrice);
			if(sellStopLoss > 0) sellStopLoss = AdjustAboveStopLevel(_Symbol,sellStopLoss);
			
			double sellTakeProfit = SellTakeProfit(_Symbol,TakeProfit,positionOpenPrice);
			if(sellTakeProfit > 0) sellTakeProfit = AdjustBelowStopLevel(_Symbol,sellTakeProfit);
			
			if(sellStopLoss > 0 || sellTakeProfit > 0) Trade.ModifyPosition(sellTicket,sellStopLoss,sellTakeProfit);
			
			glBuyPlaced = false;
		} 
   } 
    
}

