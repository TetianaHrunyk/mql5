//+------------------------------------------------------------------+
//|                                       Pending Expert Advisor.mq5 |
//|                                                     Andrew Young |
//|                                 http://www.expertadvisorbook.com |
//+------------------------------------------------------------------+

#property copyright "Andrew Young"
#property link      "http://www.expertadvisorbook.com"
#property description "A simple pending order system that opens two pending stop orders at the open of a new bar, and deletes any open orders."

/*
 Creative Commons Attribution-NonCommercial 3.0 Unported
 http://creativecommons.org/licenses/by-nc/3.0/

 You may use this file in your own personal projects. You
 may modify it if necessary. You may even share it, provided
 the copyright above is present. No commercial use permitted. 
*/


#include <Mql5Book\Trade.mqh>
CTrade Trade;

#include <Mql5Book\Pending.mqh>
CPending Pending;


// Input variables
input int AddPoints = 100;
input double TradeVolume=0.1;
input int StopLoss=1000;
input int TakeProfit=1000;


// Global variables 
bool glBuyPlaced, glSellPlaced;
datetime glLastBarTime;


// OnTick() event handler
void OnTick()
{
	
	// Time and price data
	MqlRates rates[];
	ArraySetAsSeries(rates,true);
	int copy = CopyRates(_Symbol,_Period,0,3,rates);
	
	
	// Check for new bar
	bool newBar = false;
	if(glLastBarTime != rates[0].time) 
	{
		if(glLastBarTime > 0) newBar = true;
		glLastBarTime = rates[0].time;
	}


	// Place pending order on open of new bar
	if(newBar == true)
	{
		
		// Get pending order tickets
		ulong tickets[];
		Pending.GetTickets(_Symbol,tickets);
		int numTickets = ArraySize(tickets);
		
		
		// Close any open pending orders
		if(Pending.TotalPending(_Symbol) > 0)
		{
			for(int i = 0; i < numTickets; i++)
			{
				Trade.Delete(tickets[i]);
			}
		}
		
		
		// Open pending buy stop order
		double orderPrice = rates[1].high + (AddPoints * _Point);
		orderPrice = AdjustAboveStopLevel(_Symbol,orderPrice);
		
		double stopLoss = BuyStopLoss(_Symbol,StopLoss,orderPrice);
		double takeProfit = BuyTakeProfit(_Symbol,TakeProfit,orderPrice);
		
		Trade.BuyStop(_Symbol,TradeVolume,orderPrice,stopLoss,takeProfit);
		
		
		// Open pending sell stop order
		orderPrice = rates[1].low - (AddPoints * _Point);
		orderPrice = AdjustBelowStopLevel(_Symbol,orderPrice);
		
		stopLoss = SellStopLoss(_Symbol,StopLoss,orderPrice);
		takeProfit = SellTakeProfit(_Symbol,TakeProfit,orderPrice);
		
		Trade.SellStop(_Symbol,TradeVolume,orderPrice,stopLoss,takeProfit);

	}
}