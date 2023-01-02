//+------------------------------------------------------------------+
//| 									 					 Pending Order Breakout |
//|                                                     Andrew Young |
//|                                 http://www.expertadvisorbook.com |
//+------------------------------------------------------------------+

/*
 Creative Commons Attribution-NonCommercial 3.0 Unported
 http://creativecommons.org/licenses/by-nc/3.0/

 You may use this file in your own personal projects. You
 may modify it if necessary. You may even share it, provided
 the copyright above is present. No commercial use permitted. 
*/


// Trade
#include <Mql5Book\Trade.mqh>
CTrade Trade;

// Price
#include <Mql5Book\Price.mqh>

// Money management
#include <Mql5Book\MoneyManagement.mqh>

// Timer
#include <Mql5Book\Timer.mqh>
CTimer Timer;

// Pending
#include <Mql5Book\Pending.mqh>
CPending Pending;



//+------------------------------------------------------------------+
//| Expert information                                               |
//+------------------------------------------------------------------+

#property copyright "Andrew Young"
#property version   "1.00"
#property description ""
#property link      "http://www.expertadvisorbook.com"



//+------------------------------------------------------------------+
//| Input variables                                                  |
//+------------------------------------------------------------------+



sinput string MM; 	// Money Management
input bool UseMoneyManagement = true;
input double RiskPercent = 2;
input double FixedVolume = 0.1;

sinput string TS; 	// Trade Settings
input int HighLowBars = 8;
input int TakeProfit = 0;

sinput string TI; 	// Timer
input int StartHour = 8;
input int StartMinute = 0;
input int EndHour = 20;
input int EndMinute = 0;
input bool UseLocalTime = false;



//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+

bool glBuyPlaced, glSellPlaced;



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
{
   return(0);
}



//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
{

	// Timer
	bool timerOn = Timer.DailyTimer(StartHour,StartMinute,EndHour,EndMinute,UseLocalTime);
	
	if(timerOn == false)
	{
		if(PositionSelect(_Symbol) == true) Trade.Close(_Symbol);
		
		int total = Pending.TotalPending(_Symbol);
		if(total > 0)
		{
			ulong tickets[];
			Pending.GetTickets(_Symbol,tickets);
			
			for(int i=0; i<total; i++)
			{
				Trade.Delete(tickets[i]);
			}
		}
		
		glBuyPlaced = false;
		glSellPlaced = false;
	}
	
	
	// Order placement
	if(timerOn == true)
	{
		
		// Highest high, lowest low
		double hHigh = HighestHigh(_Symbol,_Period,HighLowBars);
		double lLow = LowestLow(_Symbol,_Period,HighLowBars);
		
		double diff = (hHigh - lLow) / _Point;
		
		
		// Money management
		double tradeSize;
		if(UseMoneyManagement == true) tradeSize = MoneyManagement(_Symbol,FixedVolume,RiskPercent,(int)diff);
		else tradeSize = VerifyVolume(_Symbol,FixedVolume);
		
		
		// Open pending buy stop order
		if(Pending.BuyStop(_Symbol) == 0 && glBuyPlaced == false)
		{
			double orderPrice = hHigh;
			orderPrice = AdjustAboveStopLevel(_Symbol,orderPrice);
			
			double buyStop = lLow;
			double buyProfit = BuyTakeProfit(_Symbol,TakeProfit,orderPrice);
			
			glBuyPlaced = Trade.BuyStop(_Symbol,tradeSize,orderPrice,buyStop,buyProfit);
		}
		
		
		// Open pending sell stop order
		if(Pending.SellStop(_Symbol) == 0 && glSellPlaced == false)
		{
			double orderPrice = lLow;
			orderPrice = AdjustBelowStopLevel(_Symbol,orderPrice);
			
			double sellStop = hHigh;
			double sellProfit = SellTakeProfit(_Symbol,TakeProfit,orderPrice);
			
			glSellPlaced = Trade.SellStop(_Symbol,tradeSize,orderPrice,sellStop,sellProfit);
		}
		
		
	} // Order placement end
	

}


